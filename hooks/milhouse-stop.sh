#!/bin/bash
# Milhouse Loop Stop Hook
# Prevents session exit when a milhouse-loop is active
# Feeds the prompt back as input to continue the loop

set -euo pipefail

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/config.sh"
source "$SCRIPT_DIR/lib/state.sh"

# Require jq for JSON parsing (optional hook: warn + skip)
bluera_require_jq_optional || exit 0

# Read hook input from stdin (advanced stop hook API)
HOOK_INPUT=$(cat 2>/dev/null || true)

# Check if stop hook already triggered continuation - prevent infinite loop
# See: https://code.claude.com/docs/en/hooks (stop_hook_active field)
STOP_HOOK_ACTIVE=$(echo "$HOOK_INPUT" | jq -r '.stop_hook_active // false')
if [[ "$STOP_HOOK_ACTIVE" == "true" ]]; then
  exit 0
fi

# Check if milhouse-loop is active
STATE_FILE="$(bluera_state_dir)/milhouse-loop.md"

if [[ ! -f "$STATE_FILE" ]]; then
  # No active loop - allow exit
  exit 0
fi

# Parse markdown frontmatter values using state library
ITERATION=$(bluera_get_state "$STATE_FILE" "iteration")
MAX_ITERATIONS=$(bluera_get_state "$STATE_FILE" "max_iterations")
COMPLETION_PROMISE=$(bluera_get_state "$STATE_FILE" "completion_promise")
COMPLETION_PROMISE="${COMPLETION_PROMISE#\"}"  # Strip leading quote
COMPLETION_PROMISE="${COMPLETION_PROMISE%\"}"  # Strip trailing quote
STORED_SESSION=$(bluera_get_state "$STATE_FILE" "session_id")
STORED_SESSION="${STORED_SESSION#\"}"  # Strip leading quote
STORED_SESSION="${STORED_SESSION%\"}"  # Strip trailing quote
STUCK_LIMIT=$(bluera_get_state "$STATE_FILE" "stuck_limit")
STUCK_LIMIT="${STUCK_LIMIT:-3}"

# Parse frontmatter for gates array (complex YAML, keep manual parsing)
FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$STATE_FILE")

# Parse gates from YAML (lines starting with "  - " after "gates:")
GATES=()
IN_GATES=false
while IFS= read -r line; do
  if [[ "$line" =~ ^gates: ]]; then
    IN_GATES=true
    # Check for inline empty array
    if [[ "$line" =~ ^\s*gates:\s*\[\] ]]; then
      IN_GATES=false
    fi
  elif [[ "$IN_GATES" == true ]]; then
    if [[ "$line" =~ ^[[:space:]]+-[[:space:]]+(.*) ]]; then
      GATE_CMD="${BASH_REMATCH[1]}"
      # Strip quotes
      GATE_CMD="${GATE_CMD#\"}"
      GATE_CMD="${GATE_CMD%\"}"
      GATES+=("$GATE_CMD")
    elif [[ ! "$line" =~ ^[[:space:]] ]]; then
      IN_GATES=false
    fi
  fi
done <<< "$FRONTMATTER"

# Parse failure_hashes (simple array on one line)
FAILURE_HASHES=$(bluera_get_state "$STATE_FILE" "failure_hashes")

# Session scoping: derive current session ID from transcript path
CURRENT_SESSION=$(echo "$HOOK_INPUT" | jq -r '.transcript_path' | md5 -q 2>/dev/null || echo "$HOOK_INPUT" | jq -r '.transcript_path' | md5sum | cut -d' ' -f1)

# If no stored session, capture it (first stop hook for this loop)
if [[ -z "$STORED_SESSION" ]]; then
  bluera_set_state "$STATE_FILE" "session_id" "\"$CURRENT_SESSION\""
  STORED_SESSION="$CURRENT_SESSION"
fi

# Session mismatch = different terminal, ignore this state file
if [[ "$STORED_SESSION" != "$CURRENT_SESSION" ]]; then
  exit 0
fi

# Validate numeric fields before arithmetic operations
if [[ ! "$ITERATION" =~ ^[0-9]+$ ]]; then
  echo "⚠️  Milhouse: iteration invalid ('$ITERATION'). Run /bluera-base:milhouse-loop again." >&2
  rm "$STATE_FILE"
  exit 0
fi

if [[ ! "$MAX_ITERATIONS" =~ ^[0-9]+$ ]]; then
  echo "⚠️  Milhouse: max_iterations invalid ('$MAX_ITERATIONS'). Run /bluera-base:milhouse-loop again." >&2
  rm "$STATE_FILE"
  exit 0
fi

# Check if max iterations reached
if [[ $MAX_ITERATIONS -gt 0 ]] && [[ $ITERATION -ge $MAX_ITERATIONS ]]; then
  echo "🛑 Milhouse loop: Max iterations ($MAX_ITERATIONS) reached."
  rm "$STATE_FILE"
  exit 0
fi

# Get transcript path from hook input
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path')

# Validate transcript_path is not null/empty (jq returns "null" for missing keys)
if [[ -z "$TRANSCRIPT_PATH" ]] || [[ "$TRANSCRIPT_PATH" == "null" ]]; then
  echo "⚠️  Milhouse: transcript_path missing or invalid. State preserved." >&2
  exit 0  # Exit WITHOUT deleting state - may be transient issue
fi

if [[ ! -f "$TRANSCRIPT_PATH" ]]; then
  echo "⚠️  Milhouse: transcript not found ($TRANSCRIPT_PATH). Stopping." >&2
  rm "$STATE_FILE"
  exit 0
fi

# Read last assistant message from transcript (JSONL format - one JSON per line)
# Use jq for robust parsing (handles whitespace variations in JSON)
if ! jq -e 'select(.role == "assistant")' "$TRANSCRIPT_PATH" >/dev/null 2>&1; then
  echo "⚠️  Milhouse: no assistant messages in transcript. Stopping." >&2
  rm "$STATE_FILE"
  exit 0
fi

# Extract last assistant message using jq (JSONL: -s slurps all lines into array)
LAST_LINE=$(jq -s '[.[] | select(.role == "assistant")] | last' "$TRANSCRIPT_PATH" 2>/dev/null)
if [[ -z "$LAST_LINE" ]] || [[ "$LAST_LINE" == "null" ]]; then
  echo "⚠️  Milhouse: failed to extract assistant message. Stopping." >&2
  rm "$STATE_FILE"
  exit 0
fi

# Parse JSON with error handling
if ! LAST_OUTPUT=$(echo "$LAST_LINE" | jq -r '
  .message.content |
  map(select(.type == "text")) |
  map(.text) |
  join("\n")
' 2>&1); then
  echo "⚠️  Milhouse: JSON parse failed. Stopping." >&2
  rm "$STATE_FILE"
  exit 0
fi

if [[ -z "$LAST_OUTPUT" ]]; then
  echo "⚠️  Milhouse: no text in assistant message. Stopping." >&2
  rm "$STATE_FILE"
  exit 0
fi

# Check for completion promise
# Must appear on the LAST non-empty line (prevents false triggers from examples/docs)
# This ensures the promise is a deliberate completion signal, not part of an explanation
LAST_CONTENT_LINE=$(echo "$LAST_OUTPUT" | grep -v '^[[:space:]]*$' | tail -1)
PROMISE_TEXT=""
if echo "$LAST_CONTENT_LINE" | grep -qE '^\s*<promise>.*</promise>\s*$'; then
  PROMISE_TEXT=$(echo "$LAST_CONTENT_LINE" | sed 's/.*<promise>\(.*\)<\/promise>.*/\1/')
fi

# Use = for literal string comparison
PROMISE_MATCHED=false
if [[ -n "$PROMISE_TEXT" ]] && [[ "$PROMISE_TEXT" = "$COMPLETION_PROMISE" ]]; then
  PROMISE_MATCHED=true
fi

# If promise matched, run gates (if any)
GATES_PASSED=true
GATE_FAILURE_OUTPUT=""
if [[ "$PROMISE_MATCHED" == true ]] && [[ ${#GATES[@]} -gt 0 ]]; then
  for gate in "${GATES[@]}"; do
    if ! GATE_OUTPUT=$(bash -c "$gate" 2>&1); then
      GATES_PASSED=false
      GATE_FAILURE_OUTPUT="Gate failed: $gate
$(echo "$GATE_OUTPUT" | tail -20)"
      break
    fi
  done
fi

# If promise matched and all gates passed, allow exit
if [[ "$PROMISE_MATCHED" == true ]] && [[ "$GATES_PASSED" == true ]]; then
  echo "✅ Milhouse complete."
  rm "$STATE_FILE"
  exit 0
fi

# Gate failure: track hash for stuck detection
if [[ "$PROMISE_MATCHED" == true ]] && [[ "$GATES_PASSED" == false ]]; then
  FAILURE_HASH=$(echo "$GATE_FAILURE_OUTPUT" | md5 -q 2>/dev/null || echo "$GATE_FAILURE_OUTPUT" | md5sum | cut -d' ' -f1)

  # Update failure_hashes in state file (append new hash)
  if [[ "$FAILURE_HASHES" == "[]" ]]; then
    NEW_HASHES="[\"$FAILURE_HASH\"]"
  else
    # Strip brackets, append new hash
    EXISTING="${FAILURE_HASHES#[}"
    EXISTING="${EXISTING%]}"
    if [[ -z "$EXISTING" ]]; then
      NEW_HASHES="[\"$FAILURE_HASH\"]"
    else
      NEW_HASHES="[$EXISTING, \"$FAILURE_HASH\"]"
    fi
  fi

  # Check for stuck (last N hashes must be identical, not just total count)
  if [[ "$STUCK_LIMIT" -gt 0 ]]; then
    # Extract last STUCK_LIMIT hashes and check if all are identical
    LAST_N_HASHES=$(echo "$NEW_HASHES" | jq -r ".[-$STUCK_LIMIT:]")
    TOTAL_COUNT=$(echo "$LAST_N_HASHES" | jq 'length')
    UNIQUE_COUNT=$(echo "$LAST_N_HASHES" | jq 'unique | length')

    if [[ "$TOTAL_COUNT" -ge "$STUCK_LIMIT" ]] && [[ "$UNIQUE_COUNT" -eq 1 ]]; then
      echo "🛑 Milhouse: stuck detected (same failure $STUCK_LIMIT consecutive times). Stopping."
      echo "Last failure: $GATE_FAILURE_OUTPUT" | head -5
      rm "$STATE_FILE"
      exit 0
    fi
  fi

  # Update state file with new failure hash
  bluera_set_state "$STATE_FILE" "failure_hashes" "$NEW_HASHES"
fi

# Not complete - continue loop
NEXT_ITERATION=$((ITERATION + 1))

# Update iteration in state file
bluera_set_state "$STATE_FILE" "iteration" "$NEXT_ITERATION"

# Build iteration display
if [[ $MAX_ITERATIONS -gt 0 ]]; then
  ITER_DISPLAY="$NEXT_ITERATION/$MAX_ITERATIONS"
else
  ITER_DISPLAY="$NEXT_ITERATION"
fi

# Build reason (pointer-based, not full prompt injection)
# Token optimization: The model has conversation context and can read state file if needed
if [[ -n "$GATE_FAILURE_OUTPUT" ]]; then
  SYSTEM_MSG="🔄 Milhouse iteration $ITER_DISPLAY | Gate failed - fix and retry | Complete: <promise>$COMPLETION_PROMISE</promise>"
  REASON="## Gate Failure

$GATE_FAILURE_OUTPUT

---

Continue working on the milhouse task. Review your previous work and address the gate failure above.
State: $STATE_FILE"
else
  SYSTEM_MSG="🔄 Milhouse iteration $ITER_DISPLAY | To complete: <promise>$COMPLETION_PROMISE</promise>"
  REASON="Continue working on the milhouse task. Review your previous work visible in files and git history.
State: $STATE_FILE"
fi

# Output JSON to block the stop and continue iteration
# Note: reason contains continuation message, NOT full prompt (saves ~80% tokens per iteration)
jq -n \
  --arg reason "$REASON" \
  --arg msg "$SYSTEM_MSG" \
  '{
    "decision": "block",
    "reason": $reason,
    "systemMessage": $msg
  }'

exit 0
