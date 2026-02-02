#!/bin/bash
# Standards Review Hook - validates staged changes against CLAUDE.md conventions
# Runs as PreToolUse on Bash, triggers on git commit commands
#
# Exit codes:
# 0 = allow (not a commit, disabled, or context provided)
# 2 = block with message (only in 'block' mode with violations)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Read hook input from stdin
INPUT=$(cat 2>/dev/null || true)

# Check if jq is available
if ! command -v jq &>/dev/null; then
  exit 0  # Can't parse input, allow
fi

# Extract the command
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
[[ -z "$COMMAND" ]] && exit 0

# Only trigger on git commit commands
if ! echo "$COMMAND" | grep -qE '^git[[:space:]]+commit([[:space:]]|$)'; then
  exit 0
fi

# Check if feature is enabled
# shellcheck source=lib/config.sh
source "$SCRIPT_DIR/lib/config.sh"
if ! bluera_config_enabled ".standardsReview.enabled"; then
  exit 0
fi

# Gather staged files
STAGED_FILES=$(git diff --cached --name-only 2>/dev/null || true)
if [[ -z "$STAGED_FILES" ]]; then
  exit 0  # Nothing staged
fi

# Get staged diff summary
DIFF_STAT=$(git diff --cached --stat 2>/dev/null | head -20 || true)

# Gather relevant CLAUDE.md content
gather_standards() {
  local standards=""
  local seen_dirs=""

  # Root CLAUDE.md
  if [[ -f "CLAUDE.md" ]]; then
    standards+="=== CLAUDE.md ===
"
    standards+=$(cat "CLAUDE.md")
    standards+="
"
  fi

  # All .claude/rules/*.md files
  if [[ -d ".claude/rules" ]]; then
    for rule in .claude/rules/*.md; do
      if [[ -f "$rule" ]]; then
        standards+="
=== $rule ===
"
        standards+=$(cat "$rule")
        standards+="
"
      fi
    done
  fi

  # Subdirectory CLAUDE.md files for staged files
  for file in $STAGED_FILES; do
    dir=$(dirname "$file")
    while [[ "$dir" != "." && "$dir" != "/" ]]; do
      if [[ ! "$seen_dirs" =~ $dir ]]; then
        if [[ -f "$dir/CLAUDE.md" ]]; then
          standards+="
=== $dir/CLAUDE.md ===
"
          standards+=$(cat "$dir/CLAUDE.md")
          standards+="
"
        fi
        seen_dirs+=" $dir"
      fi
      dir=$(dirname "$dir")
    done
  done

  # Truncate if too long (keep first ~100 lines)
  echo "$standards" | head -150
}

STANDARDS=$(gather_standards)

# If no standards found, allow
if [[ -z "$STANDARDS" ]]; then
  exit 0
fi

# Output context for Claude to review
# Using additionalContext to inject review prompt
FILE_LIST=$(echo "$STAGED_FILES" | tr '\n' ', ' | sed 's/,$//')

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "additionalContext": "[STANDARDS REVIEW] Before committing, verify these staged changes comply with project standards.\n\nStaged files: $FILE_LIST\n\nDiff summary:\n$DIFF_STAT\n\nProject standards to check against:\n$STANDARDS\n\nCheck for: anti-patterns (fallback code, deprecated refs), strict typing violations (any/as if enabled), git rule violations. Report only high-confidence issues with file references."
  }
}
EOF
