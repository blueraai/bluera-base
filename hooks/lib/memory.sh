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

# Generate a unique ID for a memory (with collision protection)
# Usage: id=$(bluera_memory_generate_id)
bluera_memory_generate_id() {
  local uuid mem_dir short_id max_attempts=5 attempt=0

  mem_dir=$(bluera_memory_dir)

  while ((attempt < max_attempts)); do
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

    short_id="${uuid:0:8}"

    # Check for collision (file already exists)
    if [[ ! -f "$mem_dir/${short_id}.md" ]]; then
      echo "$short_id"
      return 0
    fi

    ((attempt++))
  done

  echo "Error: Failed to generate unique ID after $max_attempts attempts" >&2
  return 1
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
# Deduplication (hash-based, cross-platform)
# =============================================================================

# Normalize content for comparison (lowercase, strip punct, collapse whitespace)
# Usage: normalized=$(bluera_memory_normalize "$text")
bluera_memory_normalize() {
  local text="$1"
  echo "$text" | tr '[:upper:]' '[:lower:]' | sed 's/[[:punct:]]//g' | tr -s ' ' | xargs
}

# Generate content hash for dedup (cross-platform: Linux + macOS)
# Usage: hash=$(bluera_memory_content_hash "$text")
bluera_memory_content_hash() {
  local text="$1"
  local normalized
  normalized=$(bluera_memory_normalize "$text")

  # Fallback chain: md5sum (Linux) → md5 (macOS) → openssl md5 → base64
  if command -v md5sum &>/dev/null; then
    echo -n "$normalized" | md5sum | cut -d' ' -f1
  elif command -v md5 &>/dev/null; then
    echo -n "$normalized" | md5 -q
  elif command -v openssl &>/dev/null; then
    echo -n "$normalized" | openssl md5 | awk '{print $NF}'
  else
    # Last resort: base64 with URL-safe chars (replace +/ with AZ)
    echo -n "$normalized" | base64 | tr '+/' 'AZ' | head -c 32
  fi
}

# Check if similar memory exists by comparing hashes of TITLES
# Returns 0 if duplicate found, 1 if unique
# Usage: bluera_memory_is_duplicate "$content" && echo "duplicate"
bluera_memory_is_duplicate() {
  local content="$1"
  local new_hash
  new_hash=$(bluera_memory_content_hash "$content")

  local mem_dir
  mem_dir=$(bluera_memory_dir)
  [[ ! -d "$mem_dir" ]] && return 1

  for file in "$mem_dir"/*.md; do
    [[ -f "$file" ]] || continue
    # Skip temp/lock files
    [[ "$(basename "$file")" == .* ]] && continue

    # Extract title from the file (first H1 heading after frontmatter)
    local title
    title=$(grep '^# ' "$file" | head -1 | sed 's/^# //')
    [[ -z "$title" ]] && continue

    # Hash the title and compare
    local existing_hash
    existing_hash=$(bluera_memory_content_hash "$title")
    [[ "$new_hash" == "$existing_hash" ]] && return 0
  done
  return 1
}

# =============================================================================
# Auto-Tagging (word-boundary matching)
# =============================================================================

# Auto-generate tags from content using word boundaries
# Usage: tags=$(bluera_memory_auto_tags "$content" "$source")
bluera_memory_auto_tags() {
  local content="$1"
  local source="${2:-manual}"
  local project
  project=$(basename "${CLAUDE_PROJECT_DIR:-$PWD}" | tr '[:upper:]' '[:lower:]')

  local tags="$source,$project"

  # Word-boundary matching to avoid false positives (contest != test)
  echo "$content" | grep -qiw "test\|testing\|tests" && tags="$tags,testing"
  echo "$content" | grep -qiw "git\|commit\|branch" && tags="$tags,git"
  echo "$content" | grep -qiw "build\|compile" && tags="$tags,build"
  echo "$content" | grep -qiw "error\|fix\|bug" && tags="$tags,error"
  echo "$content" | grep -qiw "api\|endpoint\|rest" && tags="$tags,api"

  echo "$tags"
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

  local id mem_dir file timestamp tmp_file content_hash

  bluera_memory_init || return 1

  id=$(bluera_memory_generate_id)
  mem_dir=$(bluera_memory_dir)
  file="$mem_dir/${id}.md"
  tmp_file="$mem_dir/.tmp-${id}.md"
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Hash the title for deduplication (title-only for consistency with is_duplicate)
  content_hash=$(bluera_memory_content_hash "$title")

  # Build frontmatter
  {
    echo "---"
    echo "id: \"$id\""
    echo "created: \"$timestamp\""
    echo "updated: \"$timestamp\""
    echo "content_hash: \"$content_hash\""
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

# =============================================================================
# Import Function (from project learnings)
# =============================================================================

# Import learnings from CLAUDE.local.md to global memory
# Usage: bluera_memory_import_learnings [--dry-run]
bluera_memory_import_learnings() {
  local dry_run=""
  [[ "${1:-}" == "--dry-run" ]] && dry_run="1"

  # Check if memory system is enabled
  local mem_enabled
  mem_enabled=$(bluera_get_config ".memory.enabled" "false")
  if [[ "$mem_enabled" != "true" ]]; then
    echo "Global memory is disabled. Enable with: /bluera-base:config set .memory.enabled true"
    return 1
  fi

  # Source autolearn for markers
  local script_dir="${BASH_SOURCE%/*}"
  local start_marker end_marker
  if [[ -f "$script_dir/autolearn.sh" ]]; then
    # shellcheck source=./autolearn.sh
    source "$script_dir/autolearn.sh"
    start_marker="${BLUERA_LEARN_START:-<!-- AUTO:bluera-base:learned -->}"
    end_marker="${BLUERA_LEARN_END:-<!-- END:bluera-base:learned -->}"
  else
    start_marker="<!-- AUTO:bluera-base:learned -->"
    end_marker="<!-- END:bluera-base:learned -->"
  fi

  # Find target file
  local target_file="CLAUDE.local.md"
  if type bluera_autolearn_target_file &>/dev/null; then
    target_file=$(bluera_autolearn_target_file 2>/dev/null || echo "CLAUDE.local.md")
  fi

  [[ ! -f "$target_file" ]] && { echo "No learnings file found: $target_file"; return 1; }

  # Escape markers for sed (handle < > ! / characters)
  local start_escaped end_escaped
  start_escaped=$(printf '%s' "$start_marker" | sed 's/[<>!/]/\\&/g')
  end_escaped=$(printf '%s' "$end_marker" | sed 's/[<>!/]/\\&/g')

  local learnings
  learnings=$(sed -n "/${start_escaped}/,/${end_escaped}/p" "$target_file" | grep '^-' | sed 's/^- //')

  local imported=0 skipped=0
  local project
  project=$(basename "$PWD" | tr '[:upper:]' '[:lower:]')

  while IFS= read -r learning; do
    [[ -z "$learning" ]] && continue

    if bluera_memory_is_duplicate "$learning"; then
      ((skipped++))
      [[ -n "$dry_run" ]] && echo "Skip (duplicate): $learning"
      continue
    fi

    if [[ -n "$dry_run" ]]; then
      echo "Would import: $learning"
      ((imported++))
    else
      local tags
      tags=$(bluera_memory_auto_tags "$learning" "imported")
      bluera_memory_create "$learning" --tags "$tags"
      ((imported++))
    fi
  done <<< "$learnings"

  echo "Imported: $imported, Skipped (duplicates): $skipped"
}
