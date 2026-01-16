#!/bin/bash
# Auto-Commit Hook (Stop)
# Intercepts session stop to trigger /bluera-base:commit when there are uncommitted changes
# Uses the commit skill for atomic, well-organized commits

set -euo pipefail

cd "${CLAUDE_PROJECT_DIR:-.}"

# Source config library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/config.sh"

# Read hook input
HOOK_INPUT=$(cat)

# Check stop_hook_active to prevent infinite loops
STOP_HOOK_ACTIVE=$(echo "$HOOK_INPUT" | jq -r '.stop_hook_active // false')
if [[ "$STOP_HOOK_ACTIVE" == "true" ]]; then
  exit 0
fi

# Check if auto-commit is enabled (opt-in)
if ! bluera_config_enabled ".autoCommit.enabled"; then
  exit 0
fi

# Check if onStop trigger is enabled
ON_STOP=$(bluera_get_config ".autoCommit.onStop")
ON_STOP="${ON_STOP:-true}"
if [[ "$ON_STOP" != "true" ]]; then
  exit 0
fi

# Check if we're in a git repo
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  exit 0
fi

# Check for changes (staged + unstaged + untracked)
HAS_STAGED=$(git diff --cached --quiet 2>/dev/null && echo "no" || echo "yes")
HAS_UNSTAGED=$(git diff --quiet 2>/dev/null && echo "no" || echo "yes")
HAS_UNTRACKED=$(git ls-files --others --exclude-standard | head -1)

if [[ "$HAS_STAGED" == "no" && "$HAS_UNSTAGED" == "no" && -z "$HAS_UNTRACKED" ]]; then
  # No changes to commit
  exit 0
fi

# Check if we already attempted commit this session (state file)
STATE_DIR="$(bluera_state_dir)"
COMMIT_FLAG="$STATE_DIR/auto-commit-attempted"

if [[ -f "$COMMIT_FLAG" ]]; then
  # Already attempted once, allow exit
  rm -f "$COMMIT_FLAG"
  exit 0
fi

# Mark that we're attempting commit
mkdir -p "$STATE_DIR"
touch "$COMMIT_FLAG"

# Get push setting for instructions
SHOULD_PUSH=$(bluera_get_config ".autoCommit.push")
SHOULD_PUSH="${SHOULD_PUSH:-false}"

# Build instruction message
PUSH_INSTRUCTION=""
if [[ "$SHOULD_PUSH" == "true" ]]; then
  PUSH_INSTRUCTION=" After committing, push the changes."
fi

REASON="[auto-commit] Uncommitted changes detected. Run /bluera-base:commit to create atomic commits.${PUSH_INSTRUCTION}"

# Block stop and inject commit instruction
jq -n --arg reason "$REASON" '{"decision": "block", "reason": $reason}'
