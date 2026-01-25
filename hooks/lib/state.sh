#!/usr/bin/env bash
# bluera-base Markdown+YAML State File Management
# Provides functions for reading and updating YAML frontmatter in markdown files

# Parse YAML frontmatter value from markdown file
# Returns the value after "key: " (including quotes if present)
# Returns empty string if key not found
# Usage: val=$(bluera_get_state "$file" "iteration")
bluera_get_state() {
  local file="$1"
  local key="$2"

  if [[ ! -f "$file" ]]; then
    return 0
  fi

  # Extract frontmatter between --- lines and find the key
  # Use || true to avoid exit on grep no-match
  sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$file" | grep "^${key}:" | sed "s/${key}: *//" || true
}

# Update YAML frontmatter value in markdown file
# Only modifies keys within frontmatter (between --- markers), not document body
# Usage: bluera_set_state "$file" "iteration" "6"
bluera_set_state() {
  local file="$1"
  local key="$2"
  local value="$3"
  local temp_file="${file}.tmp.$$"

  # Use awk to only modify within frontmatter bounds
  awk -v key="$key" -v value="$value" '
    /^---$/ { in_frontmatter = !in_frontmatter; print; next }
    in_frontmatter && $0 ~ ("^" key ": ") { print key ": " value; next }
    { print }
  ' "$file" > "$temp_file"
  command mv -f "$temp_file" "$file"
}

# Check if state file exists and has YAML frontmatter
# Usage: if bluera_state_exists "$file"; then ...
bluera_state_exists() {
  local file="$1"
  [[ -f "$file" ]] && head -1 "$file" | grep -q '^---$'
}
