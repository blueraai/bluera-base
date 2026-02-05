#!/bin/bash
# bluera-base Global Memory Library
# Provides functions for managing global memories stored in ~/.claude/.bluera/bluera-base/memories/
# Memories are markdown files with YAML frontmatter for metadata

# Source config library for global config functions
# Try multiple approaches for different contexts
if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
  _MEMORY_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
  if [[ -f "${_MEMORY_SCRIPT_DIR}/config.sh" ]]; then
    # shellcheck source=./config.sh
    source "${_MEMORY_SCRIPT_DIR}/config.sh"
  fi
fi

# Fallback: define bluera_global_config_dir if not already defined
if ! type bluera_global_config_dir &>/dev/null; then
  bluera_global_config_dir() {
    echo "${HOME}/.claude/.bluera/bluera-base"
  }
fi

# =============================================================================
# Directory Access
# =============================================================================

# Get the memories directory path
# Usage: mem_dir=$(bluera_memory_dir)
bluera_memory_dir() {
  echo "$(bluera_global_config_dir)/memories"
}

# Initialize memory directory structure
# Usage: bluera_memory_init
bluera_memory_init() {
  local mem_dir
  mem_dir=$(bluera_memory_dir)

  if ! mkdir -p "$mem_dir" 2>/dev/null; then
    echo "Error: Cannot create memory directory: $mem_dir" >&2
    return 1
  fi
}

# =============================================================================
# UUID Generation (Portable)
# =============================================================================

# Generate a unique ID for a memory
# Usage: id=$(bluera_memory_generate_id)
bluera_memory_generate_id() {
  local uuid

  # Try uuidgen (macOS, some Linux)
  if command -v uuidgen &>/dev/null; then
    uuid=$(uuidgen | tr '[:upper:]' '[:lower:]')
  # Try /proc/sys/kernel/random/uuid (Linux)
  elif [[ -r /proc/sys/kernel/random/uuid ]]; then
    uuid=$(cat /proc/sys/kernel/random/uuid)
  # Fallback: generate from timestamp + random
  else
    uuid=$(printf '%08x-%04x-%04x-%04x-%012x' \
      "$((RANDOM * RANDOM))" \
      "$RANDOM" \
      "$((RANDOM & 0x0fff | 0x4000))" \
      "$((RANDOM & 0x3fff | 0x8000))" \
      "$((RANDOM * RANDOM * RANDOM))")
  fi

  # Return short form (first 8 chars) for readability
  echo "${uuid:0:8}"
}

# =============================================================================
# File Locking (mkdir-based for portability)
# =============================================================================

# Acquire a lock for a memory file
# Usage: bluera_memory_lock <id>
bluera_memory_lock() {
  local id="$1"
  local mem_dir lock_dir max_wait=5 waited=0

  mem_dir=$(bluera_memory_dir)
  lock_dir="$mem_dir/.lock-$id"

  while ! mkdir "$lock_dir" 2>/dev/null; do
    ((waited++))
    if ((waited >= max_wait)); then
      echo "Error: Failed to acquire lock for memory $id after ${max_wait}s" >&2
      return 1
    fi
    sleep 1
  done
}

# Release a lock for a memory file
# Usage: bluera_memory_unlock <id>
bluera_memory_unlock() {
  local id="$1"
  local mem_dir lock_dir

  mem_dir=$(bluera_memory_dir)
  lock_dir="$mem_dir/.lock-$id"

  rmdir "$lock_dir" 2>/dev/null || true
}

# =============================================================================
# Frontmatter Parsing
# =============================================================================

# Extract YAML frontmatter from a memory file
# Usage: frontmatter=$(bluera_memory_parse_frontmatter <file>)
bluera_memory_parse_frontmatter() {
  local file="$1"

  if [[ ! -f "$file" ]]; then
    echo "Error: File not found: $file" >&2
    return 1
  fi

  # Extract content between first --- and second ---
  sed -n '/^---$/,/^---$/p' "$file" | sed '1d;$d'
}

# Get a specific field from frontmatter
# Usage: value=$(bluera_memory_get_field <id> <field>)
bluera_memory_get_field() {
  local id="$1"
  local field="$2"
  local mem_dir file frontmatter

  mem_dir=$(bluera_memory_dir)
  file="$mem_dir/${id}.md"

  if [[ ! -f "$file" ]]; then
    echo "Error: Memory not found: $id" >&2
    return 1
  fi

  frontmatter=$(bluera_memory_parse_frontmatter "$file")

  # Parse YAML field (simple single-line values)
  echo "$frontmatter" | grep "^${field}:" | sed "s/^${field}:[[:space:]]*//" | sed 's/^"\(.*\)"$/\1/'
}

# Get tags from a memory (returns space-separated list)
# Usage: tags=$(bluera_memory_get_tags <id>)
bluera_memory_get_tags() {
  local id="$1"
  local mem_dir file

  mem_dir=$(bluera_memory_dir)
  file="$mem_dir/${id}.md"

  if [[ ! -f "$file" ]]; then
    echo "Error: Memory not found: $id" >&2
    return 1
  fi

  # Extract tags array from frontmatter
  # Look for lines starting with "  - " after "tags:"
  awk '
    /^tags:/ { in_tags = 1; next }
    in_tags && /^  - / { gsub(/^  - /, ""); printf "%s ", $0 }
    in_tags && /^[^ ]/ { exit }
    /^---$/ && in_tags { exit }
  ' "$file" | sed 's/[[:space:]]*$//'
}

# =============================================================================
# Escaping Utilities
# =============================================================================

# Escape special characters for grep
# Usage: escaped=$(bluera_memory_escape_grep "$query")
bluera_memory_escape_grep() {
  local query="$1"
  # Escape grep metacharacters: . * [ ] ^ $ \ + ? { } | ( )
  # shellcheck disable=SC2016 # Single quotes intentional - literal regex escaping
  printf '%s' "$query" | sed 's/[.[\*^$()+?{|]/\\&/g'
}

# =============================================================================
# CRUD Operations
# =============================================================================

# Create a new memory
# Usage: id=$(bluera_memory_create "Title" [--tags tag1,tag2])
bluera_memory_create() {
  local title="" tags=""

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --tags)
        tags="$2"
        shift 2
        ;;
      *)
        if [[ -z "$title" ]]; then
          title="$1"
        fi
        shift
        ;;
    esac
  done

  if [[ -z "$title" ]]; then
    echo "Error: Title is required" >&2
    return 1
  fi

  local id mem_dir file timestamp tmp_file

  bluera_memory_init || return 1

  id=$(bluera_memory_generate_id)
  mem_dir=$(bluera_memory_dir)
  file="$mem_dir/${id}.md"
  tmp_file="$mem_dir/.tmp-${id}.md"
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Build frontmatter
  {
    echo "---"
    echo "id: \"$id\""
    echo "created: \"$timestamp\""
    echo "updated: \"$timestamp\""
    echo "tags:"
    if [[ -n "$tags" ]]; then
      # Split comma-separated tags (portable approach)
      echo "$tags" | tr ',' '\n' | while read -r tag; do
        # Normalize: lowercase, trim whitespace
        tag=$(echo "$tag" | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        [[ -n "$tag" ]] && echo "  - $tag"
      done
    fi
    echo "---"
    echo ""
    echo "# $title"
    echo ""
  } > "$tmp_file"

  # Atomic write
  if ! mv "$tmp_file" "$file"; then
    echo "Error: Failed to create memory file" >&2
    rm -f "$tmp_file"
    return 1
  fi

  echo "$id"
}

# Read a memory file
# Usage: content=$(bluera_memory_read <id>)
bluera_memory_read() {
  local id="$1"
  local mem_dir file

  mem_dir=$(bluera_memory_dir)
  file="$mem_dir/${id}.md"

  if [[ ! -f "$file" ]]; then
    echo "Error: Memory not found: $id" >&2
    return 1
  fi

  cat "$file"
}

# Update a frontmatter field in a memory
# Usage: bluera_memory_update <id> <field> <value>
bluera_memory_update() {
  local id="$1"
  local field="$2"
  local value="$3"
  local mem_dir file tmp_file timestamp

  mem_dir=$(bluera_memory_dir)
  file="$mem_dir/${id}.md"
  tmp_file="$mem_dir/.tmp-${id}.md"

  if [[ ! -f "$file" ]]; then
    echo "Error: Memory not found: $id" >&2
    return 1
  fi

  bluera_memory_lock "$id" || return 1

  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Update the field and the updated timestamp
  awk -v field="$field" -v value="$value" -v ts="$timestamp" '
    BEGIN { in_frontmatter = 0; field_updated = 0 }
    /^---$/ {
      in_frontmatter = !in_frontmatter
      print
      next
    }
    in_frontmatter && $0 ~ "^" field ":" {
      print field ": \"" value "\""
      field_updated = 1
      next
    }
    in_frontmatter && /^updated:/ {
      print "updated: \"" ts "\""
      next
    }
    { print }
  ' "$file" > "$tmp_file"

  # Atomic write
  if ! mv "$tmp_file" "$file"; then
    echo "Error: Failed to update memory file" >&2
    rm -f "$tmp_file"
    bluera_memory_unlock "$id"
    return 1
  fi

  bluera_memory_unlock "$id"
}

# Delete a memory
# Usage: bluera_memory_delete <id>
bluera_memory_delete() {
  local id="$1"
  local mem_dir file

  mem_dir=$(bluera_memory_dir)
  file="$mem_dir/${id}.md"

  if [[ ! -f "$file" ]]; then
    echo "Error: Memory not found: $id" >&2
    return 1
  fi

  bluera_memory_lock "$id" || return 1

  if ! rm "$file"; then
    echo "Error: Failed to delete memory" >&2
    bluera_memory_unlock "$id"
    return 1
  fi

  bluera_memory_unlock "$id"
  echo "Deleted memory: $id"
}

# Add tags to a memory
# Usage: bluera_memory_add_tags <id> <tag1> [tag2] ...
bluera_memory_add_tags() {
  local id="$1"
  shift
  local new_tags=("$@")
  local mem_dir file tmp_file timestamp

  mem_dir=$(bluera_memory_dir)
  file="$mem_dir/${id}.md"
  tmp_file="$mem_dir/.tmp-${id}.md"

  if [[ ! -f "$file" ]]; then
    echo "Error: Memory not found: $id" >&2
    return 1
  fi

  bluera_memory_lock "$id" || return 1

  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Get existing tags
  local existing_tags
  existing_tags=$(bluera_memory_get_tags "$id")

  # Build combined tag list (deduplicated)
  local all_tags=()
  for tag in $existing_tags; do
    all_tags+=("$tag")
  done
  for tag in "${new_tags[@]}"; do
    tag=$(echo "$tag" | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    # Check if already exists
    local found=0
    for existing in "${all_tags[@]}"; do
      [[ "$existing" == "$tag" ]] && found=1 && break
    done
    [[ $found -eq 0 ]] && [[ -n "$tag" ]] && all_tags+=("$tag")
  done

  # Rewrite file with updated tags
  awk -v ts="$timestamp" -v tags="${all_tags[*]}" '
    BEGIN {
      in_frontmatter = 0
      in_tags = 0
      split(tags, tag_array, " ")
    }
    /^---$/ {
      if (in_frontmatter && in_tags) {
        # Print new tags before closing frontmatter
        for (i in tag_array) {
          print "  - " tag_array[i]
        }
        in_tags = 0
      }
      in_frontmatter = !in_frontmatter
      print
      next
    }
    in_frontmatter && /^tags:/ {
      print "tags:"
      in_tags = 1
      next
    }
    in_frontmatter && in_tags && /^  - / {
      # Skip old tags
      next
    }
    in_frontmatter && in_tags && /^[a-z]/ {
      # End of tags section, print new tags first
      for (i in tag_array) {
        print "  - " tag_array[i]
      }
      in_tags = 0
      # Continue processing current line
    }
    in_frontmatter && /^updated:/ {
      print "updated: \"" ts "\""
      next
    }
    { print }
  ' "$file" > "$tmp_file"

  if ! mv "$tmp_file" "$file"; then
    echo "Error: Failed to update memory file" >&2
    rm -f "$tmp_file"
    bluera_memory_unlock "$id"
    return 1
  fi

  bluera_memory_unlock "$id"
}

# =============================================================================
# Query Operations
# =============================================================================

# List memories
# Usage: bluera_memory_list [--limit N] [--tags TAG]
bluera_memory_list() {
  local limit=10 tag_filter=""

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --limit)
        limit="$2"
        shift 2
        ;;
      --tags)
        tag_filter="$2"
        shift 2
        ;;
      *)
        shift
        ;;
    esac
  done

  local mem_dir
  mem_dir=$(bluera_memory_dir)

  if [[ ! -d "$mem_dir" ]]; then
    echo "No memories found"
    return 0
  fi

  local count=0

  # Sort by modification time (newest first)
  # shellcheck disable=SC2045 # ls -t needed for mtime sort; -f guard handles edge cases
  for file in $(ls -t "$mem_dir"/*.md 2>/dev/null); do
    [[ -f "$file" ]] || continue

    local id title tags
    id=$(basename "$file" .md)

    # Skip temp/lock files
    [[ "$id" == .* ]] && continue

    # Get title (first # heading)
    title=$(grep '^# ' "$file" | head -1 | sed 's/^# //')

    # Get tags
    tags=$(bluera_memory_get_tags "$id" 2>/dev/null)

    # Filter by tag if specified
    if [[ -n "$tag_filter" ]]; then
      if ! echo "$tags" | grep -qw "$tag_filter"; then
        continue
      fi
    fi

    # Print in format: id | title | [tags]
    printf "%-10s | %-50s | [%s]\n" "$id" "${title:0:50}" "$tags"

    ((count++))
    [[ $count -ge $limit ]] && break
  done

  if [[ $count -eq 0 ]]; then
    echo "No memories found"
  fi
}

# Search memories by content or tags
# Usage: bluera_memory_search <query>
bluera_memory_search() {
  local query="$1"
  local mem_dir

  if [[ -z "$query" ]]; then
    echo "Error: Search query required" >&2
    return 1
  fi

  mem_dir=$(bluera_memory_dir)

  if [[ ! -d "$mem_dir" ]]; then
    echo "No memories found"
    return 0
  fi

  # Escape special characters for grep
  local escaped_query
  escaped_query=$(bluera_memory_escape_grep "$query")

  # Search using grep
  local found=0
  for file in "$mem_dir"/*.md; do
    [[ -f "$file" ]] || continue

    local id
    id=$(basename "$file" .md)

    # Skip temp/lock files
    [[ "$id" == .* ]] && continue

    if grep -qi "$escaped_query" "$file" 2>/dev/null; then
      local title tags
      title=$(grep '^# ' "$file" | head -1 | sed 's/^# //')
      tags=$(bluera_memory_get_tags "$id" 2>/dev/null)

      printf "%-10s | %-50s | [%s]\n" "$id" "${title:0:50}" "$tags"
      ((found++))
    fi
  done

  if [[ $found -eq 0 ]]; then
    echo "No memories matching '$query'"
  fi
}

# Get memory content (body only, without frontmatter)
# Usage: body=$(bluera_memory_get_body <id>)
bluera_memory_get_body() {
  local id="$1"
  local mem_dir file

  mem_dir=$(bluera_memory_dir)
  file="$mem_dir/${id}.md"

  if [[ ! -f "$file" ]]; then
    echo "Error: Memory not found: $id" >&2
    return 1
  fi

  # Skip frontmatter, return rest
  sed -n '/^---$/,/^---$/!p' "$file" | sed '1{/^$/d}'
}
