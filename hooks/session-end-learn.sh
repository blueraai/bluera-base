#!/bin/bash
# Learning Synthesis Hook (Stop)
# Analyzes accumulated session signals and suggests learnings
# Runs alongside milhouse-stop.sh, not instead of it

set -euo pipefail

cd "${CLAUDE_PROJECT_DIR:-.}"

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/config.sh"
source "$SCRIPT_DIR/lib/signals.sh"
source "$SCRIPT_DIR/lib/autolearn.sh"

# Require jq for JSON parsing (optional hook: warn + skip)
bluera_require_jq || exit 0

# Check if auto-learn is enabled (opt-in)
if ! bluera_config_enabled ".autoLearn.enabled"; then
  exit 0
fi

# Read hook input and check for stop_hook_active
INPUT=$(cat 2>/dev/null || true)
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null || echo "false")
if [[ "$STOP_HOOK_ACTIVE" == "true" ]]; then
  exit 0
fi

# Get config values
AUTO_LEARN_MODE=$(bluera_get_config ".autoLearn.mode")
AUTO_LEARN_MODE="${AUTO_LEARN_MODE:-suggest}"
THRESHOLD=$(bluera_get_config ".autoLearn.threshold")
THRESHOLD="${THRESHOLD:-3}"

# Skip if no signals accumulated
SIGNAL_FILE="$(bluera_signals_file)"
if [[ ! -f "$SIGNAL_FILE" ]]; then
  exit 0
fi

# Load signals with validation
SIGNALS=$(bluera_load_signals)
if ! echo "$SIGNALS" | jq -e . >/dev/null 2>&1; then
  echo "[bluera-base] Warning: Corrupted signals file, removing" >&2
  bluera_clear_signals
  exit 0
fi

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
  bluera_clear_signals
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

# If we have suggestions, handle based on mode
if [[ -n "$SUGGESTIONS" ]]; then
  if [[ "$AUTO_LEARN_MODE" == "auto" ]]; then
    # Auto mode: write learnings directly to target file
    applied_count=0
    while IFS= read -r suggestion; do
      [[ -z "$suggestion" ]] && continue
      # Strip leading "- " from suggestion
      suggestion="${suggestion#- }"
      if bluera_autolearn_write "$suggestion"; then
        ((applied_count++)) || true
      fi
    done <<< "$SUGGESTIONS"

    if [[ $applied_count -gt 0 ]]; then
      target_file=$(bluera_autolearn_target_file)
      jq -n --arg msg "[bluera-base] Applied $applied_count learning(s) to $target_file" \
        '{"systemMessage": $msg}'
    fi
  else
    # Suggest mode: show suggestions and command to run
    MSG="[bluera-base] Session patterns detected. Consider adding to CLAUDE.md:${SUGGESTIONS}

Run \`/bluera-base:claude-code-md learn \"<learning>\"\` to add any of these."

    jq -n --arg msg "$MSG" '{
      "systemMessage": $msg
    }'
  fi
fi

# Clean up signal file after synthesis
bluera_clear_signals

exit 0
