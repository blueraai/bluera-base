#!/bin/bash
# bluera-base Gitignore Management Library
# Provides intelligent, non-destructive gitignore updates with negation pattern support

# Required patterns for bluera-base
# Order matters: ignore .bluera/, then allow specific subdirs and files
BLUERA_GITIGNORE_PATTERNS=(
  "# Bluera plugins - shared config committed, local/state ignored"
  ".bluera/"
  "!.bluera/bluera-base/"
  "!.bluera/bluera-knowledge/"
  ".bluera/bluera-base/*"
  ".bluera/bluera-knowledge/*"
  "!.bluera/bluera-base/config.json"
  "!.bluera/bluera-base/TODO.txt"
  "!.bluera/bluera-knowledge/stores.config.json"
  "# Claude Code local files (not committed)"
  "*.local.md"
)

# Check if a pattern exists in gitignore
# Usage: if gitignore_has_pattern ".bluera/"; then ...
gitignore_has_pattern() {
  local pattern="$1"
  local gitignore="${CLAUDE_PROJECT_DIR:-.}/.gitignore"

  if [[ ! -f "$gitignore" ]]; then
    return 1
  fi

  # Check for exact pattern match
  grep -qFx "$pattern" "$gitignore" 2>/dev/null
}

# Get missing patterns that need to be added
# Usage: missing=$(gitignore_missing_patterns)
gitignore_missing_patterns() {
  local missing=()

  for pattern in "${BLUERA_GITIGNORE_PATTERNS[@]}"; do
    # Skip comments when checking (but include them in output)
    if [[ "$pattern" =~ ^# ]]; then
      # Only add comment if the next non-comment pattern is missing
      continue
    fi

    if ! gitignore_has_pattern "$pattern"; then
      missing+=("$pattern")
    fi
  done

  # If we have missing patterns, include the header comment
  if [[ ${#missing[@]} -gt 0 ]]; then
    # Check if header comment is missing
    if ! grep -q "^# Bluera plugins" "${CLAUDE_PROJECT_DIR:-.}/.gitignore" 2>/dev/null; then
      echo "# Bluera plugins - shared config committed, local/state ignored"
    fi
    printf '%s\n' "${missing[@]}"
  fi
}

# Ensure all required patterns exist in gitignore
# Usage: gitignore_ensure_patterns
# Returns: 0 on success (patterns added or already exist), 1 on error
gitignore_ensure_patterns() {
  local gitignore="${CLAUDE_PROJECT_DIR:-.}/.gitignore"
  local missing

  missing=$(gitignore_missing_patterns)

  if [[ -z "$missing" ]]; then
    return 0  # All patterns already exist - success
  fi

  # Create gitignore if it doesn't exist
  if [[ ! -f "$gitignore" ]]; then
    echo "$missing" > "$gitignore"
    return 0
  fi

  # Append missing patterns with a newline separator
  {
    echo ""  # Ensure we start on a new line
    echo "$missing"
  } >> "$gitignore"

  return 0
}

# Show current gitignore status for bluera patterns
# Usage: gitignore_status
gitignore_status() {
  local gitignore="${CLAUDE_PROJECT_DIR:-.}/.gitignore"

  echo "Gitignore status for bluera-base patterns:"
  echo ""

  for pattern in "${BLUERA_GITIGNORE_PATTERNS[@]}"; do
    # Skip comments
    if [[ "$pattern" =~ ^# ]]; then
      continue
    fi

    if gitignore_has_pattern "$pattern"; then
      echo "  [x] $pattern"
    else
      echo "  [ ] $pattern (missing)"
    fi
  done
}
