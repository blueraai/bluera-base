#!/bin/bash
# Remind Claude about pending checklist items at session start
set -euo pipefail

cd "${CLAUDE_PROJECT_DIR:-.}"
CHECKLIST=".bluera/bluera-base/checklist.md"

# Exit silently if no checklist exists
[[ ! -f "$CHECKLIST" ]] && exit 0

# Require jq for JSON output
command -v jq &>/dev/null || exit 0

# Count unchecked items (lines starting with [ ])
UNCHECKED=$(grep -c '^\[ \]' "$CHECKLIST" 2>/dev/null || echo "0")

# Exit silently if no pending items
[[ "$UNCHECKED" -eq 0 ]] && exit 0

CONTENT=$(cat "$CHECKLIST")

jq -n --arg ctx "[CHECKLIST] $UNCHECKED items pending:

$CONTENT" '{
  "hookSpecificOutput": {
    "additionalContext": $ctx
  }
}'
