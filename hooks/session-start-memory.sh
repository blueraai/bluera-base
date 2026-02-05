#!/bin/bash
# Session Start - Global Memory Surfacing (opt-in)
# Surfaces relevant global memories based on project context
# Requires: memory.enabled=true AND memory.surfaceOnStart=true
set -euo pipefail

cd "${CLAUDE_PROJECT_DIR:-.}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=./lib/config.sh
source "$SCRIPT_DIR/lib/config.sh"
# shellcheck source=./lib/memory.sh
source "$SCRIPT_DIR/lib/memory.sh"

# Optional hook - skip gracefully if jq missing
bluera_require_jq_optional || exit 0

# Check if memory system is enabled (opt-in, default false)
mem_enabled=$(bluera_get_config ".memory.enabled" "false")
[[ "$mem_enabled" != "true" ]] && exit 0

# Check if surfacing is enabled (also opt-in, default false)
surface_enabled=$(bluera_get_config ".memory.surfaceOnStart" "false")
[[ "$surface_enabled" != "true" ]] && exit 0

# Detect project tags for matching (all lowercase for consistency with auto-tagging)
detect_project_tags() {
  local tags=""
  [[ -f "package.json" ]] && tags="$tags typescript javascript node"
  [[ -f "Cargo.toml" ]] && tags="$tags rust cargo"
  [[ -f "pyproject.toml" || -f "setup.py" ]] && tags="$tags python"
  [[ -f "go.mod" ]] && tags="$tags go golang"
  [[ -f "*.csproj" ]] 2>/dev/null && tags="$tags csharp dotnet"
  tags="$tags $(basename "$PWD")"
  # Lowercase all tags to match auto-tagging output
  echo "$tags" | tr '[:upper:]' '[:lower:]' | tr ' ' '\n' | grep -v '^$' | sort -u | xargs
}

PROJECT_TAGS=$(detect_project_tags)
BUDGET=$(bluera_get_config ".memory.contextBudget" "500")

# Get memory directory
MEM_DIR=$(bluera_memory_dir)
[[ ! -d "$MEM_DIR" ]] && exit 0

# Check if any memory files exist
shopt -s nullglob
mem_files=("$MEM_DIR"/*.md)
shopt -u nullglob
[[ ${#mem_files[@]} -eq 0 ]] && exit 0

# Track seen files to prevent duplicates across tags
declare -A SEEN_FILES
CONTEXT=""
TOTAL_LEN=0

# Read files directly instead of parsing bluera_memory_list output
for tag in $PROJECT_TAGS; do
  [[ $TOTAL_LEN -ge $BUDGET ]] && break

  # Find memories with matching tag by reading frontmatter directly
  for file in "$MEM_DIR"/*.md; do
    [[ -f "$file" ]] || continue
    [[ $TOTAL_LEN -ge $BUDGET ]] && break

    # Skip if already processed
    [[ -n "${SEEN_FILES[$file]:-}" ]] && continue

    # Check if file has this tag in frontmatter (case-insensitive, fixed string)
    if ! grep -Fi "  - $tag" "$file" >/dev/null 2>&1; then
      continue
    fi

    SEEN_FILES[$file]=1

    # Extract title (first H1 heading after frontmatter)
    title=$(grep '^# ' "$file" | head -1 | sed 's/^# //')
    [[ -z "$title" ]] && continue

    # Extract body preview (first 100 chars after title)
    body=$(sed -n '/^# /,/^$/p' "$file" | tail -n +2 | head -2 | tr '\n' ' ' | cut -c1-100)

    entry="- **$title**: $body
"
    entry_len=${#entry}

    if [[ $((TOTAL_LEN + entry_len)) -gt $BUDGET ]]; then
      break 2
    fi

    CONTEXT="$CONTEXT$entry"
    TOTAL_LEN=$((TOTAL_LEN + entry_len))
  done
done

# Output for injection if we have content
if [[ -n "$CONTEXT" ]]; then
  jq -n --arg ctx "## Relevant Global Memories

$CONTEXT" '{"hookSpecificOutput":{"additionalContext":$ctx}}'
fi

exit 0
