#!/bin/bash
# Learning Synthesis Hook (Stop)
# Analyzes accumulated session signals and suggests learnings
# Runs alongside milhouse-stop.sh, not instead of it

set -euo pipefail

cd "${CLAUDE_PROJECT_DIR:-.}"

# Source config library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/config.sh"

# Check if auto-learn is enabled (opt-in)
if ! bluera_config_enabled ".autoLearn.enabled"; then
  exit 0
fi

# Get config values
AUTO_LEARN_MODE=$(bluera_get_config ".autoLearn.mode")
AUTO_LEARN_MODE="${AUTO_LEARN_MODE:-suggest}"
THRESHOLD=$(bluera_get_config ".autoLearn.threshold")
THRESHOLD="${THRESHOLD:-3}"

# Signal file path
SIGNAL_FILE="$(bluera_state_dir)/session-signals.json"

# Skip if no signals accumulated
if [[ ! -f "$SIGNAL_FILE" ]]; then
  exit 0
fi

# Read signals
SIGNALS=$(cat "$SIGNAL_FILE")

# Check if we have any commands tracked
CMD_COUNT=$(echo "$SIGNALS" | jq '.commands | length')
if [[ "$CMD_COUNT" -eq 0 ]]; then
  exit 0
fi

# Find commands with count >= threshold
FREQUENT_CMDS=$(echo "$SIGNALS" | jq -r --argjson threshold "$THRESHOLD" '
  .commands | to_entries | map(select(.value >= $threshold)) |
  sort_by(-.value) |
  .[0:5] |
  map("\(.key) (×\(.value))") |
  join(", ")
')

# Skip if no frequent commands
if [[ -z "$FREQUENT_CMDS" ]] || [[ "$FREQUENT_CMDS" == "null" ]]; then
  # Clean up signal file
  rm -f "$SIGNAL_FILE"
  exit 0
fi

# Generate learning suggestions based on patterns
SUGGESTIONS=""

# Analyze command patterns
while IFS= read -r line; do
  CMD=$(echo "$line" | jq -r '.key')
  # COUNT available for future use: COUNT=$(echo "$line" | jq -r '.value')

  case "$CMD" in
    npm:test|bun:test|yarn:test|pnpm:test|cargo:test|go:test|pytest:*|jest:*|vitest:*)
      SUGGESTIONS="${SUGGESTIONS}\n- Run tests frequently during development"
      ;;
    npm:lint|bun:lint|yarn:lint|pnpm:lint|cargo:clippy)
      SUGGESTIONS="${SUGGESTIONS}\n- Run linter before committing"
      ;;
    npm:build|bun:build|yarn:build|pnpm:build|cargo:build|go:build|make:*)
      SUGGESTIONS="${SUGGESTIONS}\n- Build verification is part of workflow"
      ;;
    git:status|git:diff)
      SUGGESTIONS="${SUGGESTIONS}\n- Check git status before commits"
      ;;
  esac
done < <(echo "$SIGNALS" | jq -c --argjson threshold "$THRESHOLD" '.commands | to_entries | map(select(.value >= $threshold))[]')

# Dedupe suggestions
SUGGESTIONS=$(echo -e "$SUGGESTIONS" | sort -u | grep -v '^$' || true)

# If we have suggestions, output them
if [[ -n "$SUGGESTIONS" ]]; then
  # Format as systemMessage for user visibility
  MSG="[bluera-base] Session patterns detected. Consider adding to CLAUDE.md:${SUGGESTIONS}

Run \`/claude-md learn \"<learning>\"\` to add any of these."

  jq -n --arg msg "$MSG" '{
    "systemMessage": $msg
  }'
fi

# Clean up signal file after synthesis
rm -f "$SIGNAL_FILE"

exit 0
