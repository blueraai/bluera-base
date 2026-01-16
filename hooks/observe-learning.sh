#!/bin/bash
# Learning Observation Hook (PreToolUse on Bash)
# Tracks recurring commands and patterns for potential learnings
# Signals are accumulated in .bluera/bluera-base/state/session-signals.json
# IMPORTANT: This is opt-in - only runs if autoLearn.enabled is true

set -euo pipefail

# Read hook input
INPUT=$(cat 2>/dev/null || true)

cd "${CLAUDE_PROJECT_DIR:-.}"

# Source config library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/config.sh"

# Check if auto-learn is enabled (opt-in)
if ! bluera_config_enabled ".autoLearn.enabled"; then
  exit 0
fi

# Only process Bash tool calls
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
if [[ "$TOOL_NAME" != "Bash" ]]; then
  exit 0
fi

# Extract command from tool input
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
if [[ -z "$COMMAND" ]]; then
  exit 0
fi

# Skip internal/meta commands
if [[ "$COMMAND" =~ ^(cd|ls|cat|head|tail|echo|pwd|which|type) ]]; then
  exit 0
fi

# Extract the base command (first word, or npm/bun/yarn script name)
BASE_CMD=""
if [[ "$COMMAND" =~ ^(npm|yarn|pnpm|bun)[[:space:]]+(run[[:space:]]+)?([a-zA-Z0-9_:-]+) ]]; then
  # Package manager script: "npm run test" -> "npm:test"
  PM="${BASH_REMATCH[1]}"
  SCRIPT="${BASH_REMATCH[3]}"
  BASE_CMD="${PM}:${SCRIPT}"
elif [[ "$COMMAND" =~ ^(cargo|go|make|pytest|jest|vitest)[[:space:]]+([a-zA-Z0-9_:-]*) ]]; then
  # Build tool command: "cargo test" -> "cargo:test"
  TOOL="${BASH_REMATCH[1]}"
  SUBCMD="${BASH_REMATCH[2]:-run}"
  BASE_CMD="${TOOL}:${SUBCMD}"
elif [[ "$COMMAND" =~ ^(git)[[:space:]]+([a-zA-Z0-9_-]+) ]]; then
  # Git command: "git status" -> "git:status"
  BASE_CMD="git:${BASH_REMATCH[2]}"
else
  # Generic: use first word
  BASE_CMD=$(echo "$COMMAND" | awk '{print $1}')
fi

# Skip if we couldn't extract a meaningful command
if [[ -z "$BASE_CMD" ]] || [[ ${#BASE_CMD} -lt 2 ]]; then
  exit 0
fi

# Ensure state directory exists
bluera_ensure_config_dir

# Signal file path
SIGNAL_FILE="$(bluera_state_dir)/session-signals.json"

# Get current session ID from transcript path (if available)
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')
SESSION_ID=""
if [[ -n "$TRANSCRIPT_PATH" ]]; then
  SESSION_ID=$(echo "$TRANSCRIPT_PATH" | md5 -q 2>/dev/null || echo "$TRANSCRIPT_PATH" | md5sum | cut -d' ' -f1)
fi

# Initialize or read existing signals
if [[ ! -f "$SIGNAL_FILE" ]]; then
  echo '{"commands":{},"session_id":"","started_at":""}' > "$SIGNAL_FILE"
fi

# Read current signals
SIGNALS=$(cat "$SIGNAL_FILE")

# Check if this is a new session (different session_id)
STORED_SESSION=$(echo "$SIGNALS" | jq -r '.session_id // empty')
if [[ -n "$SESSION_ID" ]] && [[ "$STORED_SESSION" != "$SESSION_ID" ]]; then
  # New session - reset signals
  SIGNALS=$(jq -n --arg sid "$SESSION_ID" --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '{
    "commands": {},
    "session_id": $sid,
    "started_at": $ts
  }')
fi

# Increment command count
SIGNALS=$(echo "$SIGNALS" | jq --arg cmd "$BASE_CMD" '
  .commands[$cmd] = ((.commands[$cmd] // 0) + 1)
')

# Write updated signals
echo "$SIGNALS" > "$SIGNAL_FILE"

# Exit successfully (non-blocking)
exit 0
