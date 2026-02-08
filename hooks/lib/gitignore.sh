#!/bin/bash
# bluera-base Gitignore Management Library
# Provides intelligent, non-destructive gitignore updates with negation pattern support

# Required patterns for bluera-base
# Order matters: ignore .bluera/, then allow specific subdirs and files
BLUERA_GITIGNORE_PATTERNS=(
  "# Bluera plugins - shared config committed, local/state ignored"
  ".bluera/"
  "!.bluera/bluera-base/"
  ".bluera/bluera-base/*"
  "!.bluera/bluera-base/config.json"
  "!.bluera/bluera-base/TODO.txt"
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
  local pending_comment=""

  for pattern in "${BLUERA_GITIGNORE_PATTERNS[@]}"; do
    # Track comments to include before missing patterns
    if [[ "$pattern" =~ ^# ]]; then
      pending_comment="$pattern"
      continue
    fi

    if ! gitignore_has_pattern "$pattern"; then
      # Include pending comment if any
      if [[ -n "$pending_comment" ]]; then
        missing+=("$pending_comment")
        pending_comment=""
      fi
      missing+=("$pattern")
    else
      # Pattern exists, clear pending comment
      pending_comment=""
    fi
  done

  # Output missing patterns (comments are already inline)
  if [[ ${#missing[@]} -gt 0 ]]; then
    printf '%s\n' "${missing[@]}"
  fi
}

# Ensure all required patterns exist in gitignore
# Usage: gitignore_ensure_patterns
# Returns: 0 on success (patterns added or already exist), 1 on error
gitignore_ensure_patterns() {
  local gitignore="${CLAUDE_PROJECT_DIR:-.}/.gitignore"
  local marker="# Bluera plugins - shared config committed"
  local missing

  # Idempotency check: if marker comment exists, assume already configured
  # This prevents duplicate appends even if individual patterns differ slightly
  if [[ -f "$gitignore" ]] && grep -qF "$marker" "$gitignore" 2>/dev/null; then
    return 0  # Already configured - skip
  fi

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
