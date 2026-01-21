#!/bin/bash
# Session Start - Critical Invariants Injection
# Injects critical invariants into context via additionalContext
# This helps maintain guidance across /compact operations

set -euo pipefail

cd "${CLAUDE_PROJECT_DIR:-.}"

# Check for critical invariants file
INVARIANTS_FILE=".claude/critical-invariants.md"

if [[ ! -f "$INVARIANTS_FILE" ]]; then
  # No invariants file - exit silently
  exit 0
fi

# Check jq availability
if ! command -v jq &>/dev/null; then
  echo "[bluera-base] Warning: jq not available, skipping context injection" >&2
  exit 0
fi

# Read invariants content
CONTENT=$(cat "$INVARIANTS_FILE")

# Validate size (max 15 lines / ~1000 chars to avoid context bloat)
LINE_COUNT=$(echo "$CONTENT" | wc -l | tr -d ' ')
if [[ "$LINE_COUNT" -gt 20 ]]; then
  echo "[bluera-base] Warning: critical-invariants.md exceeds 20 lines ($LINE_COUNT). Consider trimming." >&2
fi

# Output JSON with additionalContext for Claude Code to inject
jq -n --arg ctx "$CONTENT" '{
  "hookSpecificOutput": {
    "additionalContext": $ctx
  }
}'

exit 0
