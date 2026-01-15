#!/bin/bash
# Milhouse Loop Stop Hook
# Prevents session exit when a milhouse-loop is active
# Feeds the prompt back as input to continue the loop

set -euo pipefail

# Read hook input from stdin (advanced stop hook API)
HOOK_INPUT=$(cat)

# Check if milhouse-loop is active
STATE_FILE=".claude/milhouse-loop.local.md"

if [[ ! -f "$STATE_FILE" ]]; then
  # No active loop - allow exit
  exit 0
fi

# Parse markdown frontmatter (YAML between ---) and extract values
FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$STATE_FILE")
ITERATION=$(echo "$FRONTMATTER" | grep '^iteration:' | sed 's/iteration: *//')
MAX_ITERATIONS=$(echo "$FRONTMATTER" | grep '^max_iterations:' | sed 's/max_iterations: *//')
COMPLETION_PROMISE=$(echo "$FRONTMATTER" | grep '^completion_promise:' | sed 's/completion_promise: *"\(.*\)"/\1/')

# Validate numeric fields before arithmetic operations
if [[ ! "$ITERATION" =~ ^[0-9]+$ ]]; then
  echo "⚠️  Milhouse loop: State file corrupted" >&2
  echo "   File: $STATE_FILE" >&2
  echo "   Problem: 'iteration' field is not a valid number (got: '$ITERATION')" >&2
  echo "   Milhouse loop is stopping. Run /milhouse-loop again to start fresh." >&2
  rm "$STATE_FILE"
  exit 0
fi

if [[ ! "$MAX_ITERATIONS" =~ ^[0-9]+$ ]]; then
  echo "⚠️  Milhouse loop: State file corrupted" >&2
  echo "   File: $STATE_FILE" >&2
  echo "   Problem: 'max_iterations' field is not a valid number (got: '$MAX_ITERATIONS')" >&2
  echo "   Milhouse loop is stopping. Run /milhouse-loop again to start fresh." >&2
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

if [[ ! -f "$TRANSCRIPT_PATH" ]]; then
  echo "⚠️  Milhouse loop: Transcript file not found" >&2
  echo "   Expected: $TRANSCRIPT_PATH" >&2
  echo "   Milhouse loop is stopping." >&2
  rm "$STATE_FILE"
  exit 0
fi

# Read last assistant message from transcript (JSONL format - one JSON per line)
if ! grep -q '"role":"assistant"' "$TRANSCRIPT_PATH"; then
  echo "⚠️  Milhouse loop: No assistant messages found in transcript" >&2
  echo "   Milhouse loop is stopping." >&2
  rm "$STATE_FILE"
  exit 0
fi

# Extract last assistant message
LAST_LINE=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" | tail -1)
if [[ -z "$LAST_LINE" ]]; then
  echo "⚠️  Milhouse loop: Failed to extract last assistant message" >&2
  echo "   Milhouse loop is stopping." >&2
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
  echo "⚠️  Milhouse loop: Failed to parse assistant message JSON" >&2
  echo "   Error: $LAST_OUTPUT" >&2
  echo "   Milhouse loop is stopping." >&2
  rm "$STATE_FILE"
  exit 0
fi

if [[ -z "$LAST_OUTPUT" ]]; then
  echo "⚠️  Milhouse loop: Assistant message contained no text content" >&2
  echo "   Milhouse loop is stopping." >&2
  rm "$STATE_FILE"
  exit 0
fi

# Check for completion promise
# Must appear on the LAST non-empty line (prevents false triggers from examples/docs)
# This ensures the promise is a deliberate completion signal, not part of an explanation
LAST_CONTENT_LINE=$(echo "$LAST_OUTPUT" | grep -v '^\s*$' | tail -1)
PROMISE_TEXT=""
if echo "$LAST_CONTENT_LINE" | grep -qE '^\s*<promise>.*</promise>\s*$'; then
  PROMISE_TEXT=$(echo "$LAST_CONTENT_LINE" | sed 's/.*<promise>\(.*\)<\/promise>.*/\1/')
fi

# Use = for literal string comparison
if [[ -n "$PROMISE_TEXT" ]] && [[ "$PROMISE_TEXT" = "$COMPLETION_PROMISE" ]]; then
  echo "✅ Milhouse loop: Detected completion promise on its own line"
  echo "   Task complete!"
  rm "$STATE_FILE"
  exit 0
fi

# Not complete - continue loop with SAME PROMPT
NEXT_ITERATION=$((ITERATION + 1))

# Read prompt from state file (after second ---)
PROMPT_TEXT=$(awk '/^---$/{i++; next} i>=2' "$STATE_FILE")

if [[ -z "$PROMPT_TEXT" ]]; then
  echo "⚠️  Milhouse loop: Could not read prompt from state file" >&2
  echo "   Milhouse loop is stopping." >&2
  rm "$STATE_FILE"
  exit 0
fi

# Update iteration in state file
TEMP_FILE="${STATE_FILE}.tmp.$$"
sed "s/^iteration: .*/iteration: $NEXT_ITERATION/" "$STATE_FILE" > "$TEMP_FILE"
mv "$TEMP_FILE" "$STATE_FILE"

# Build system message
SYSTEM_MSG="🔄 Milhouse iteration $NEXT_ITERATION | To complete: <promise>$COMPLETION_PROMISE</promise>"

# Output JSON to block the stop and feed prompt back
jq -n \
  --arg prompt "$PROMPT_TEXT" \
  --arg msg "$SYSTEM_MSG" \
  '{
    "decision": "block",
    "reason": $prompt,
    "systemMessage": $msg
  }'

exit 0
