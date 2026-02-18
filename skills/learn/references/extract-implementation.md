# Extract Implementation

Implementation details for `/bluera-base:learn extract` command.

## Overview

The extract command manually triggers session analysis on the current session's transcript.

## Step-by-Step Implementation

### 1. Check Prerequisites

```bash
# Check deep-learn enabled
ENABLED=$(cat .bluera/bluera-base/config.json 2>/dev/null | jq -r '.deepLearn.enabled // false')
if [[ "$ENABLED" != "true" ]]; then
  echo "Deep-learn not enabled. Run: /bluera-base:settings enable deep-learn"
  exit 0
fi

# Check claude CLI
if ! command -v claude &>/dev/null; then
  echo "Claude CLI not installed"
  exit 1
fi
```

### 2. Find Current Session Transcript

```bash
# Build project ID (same as Claude Code does)
PROJECT_ID=$(echo "$PWD" | sed 's|/|-|g')
TRANSCRIPT_DIR="$HOME/.claude/projects/$PROJECT_ID"

# Get most recent transcript
TRANSCRIPT=$(ls -t "$TRANSCRIPT_DIR"/*.jsonl 2>/dev/null | head -1)

if [[ -z "$TRANSCRIPT" ]] || [[ ! -f "$TRANSCRIPT" ]]; then
  echo "No session transcript found"
  exit 0
fi

echo "Analyzing: $(basename "$TRANSCRIPT")"
```

### 3. Extract Events (Match hook logic exactly)

```bash
# Extract user messages and errors - MUST match session-end-analyze.sh
# Strip control chars (U+0000-U+001F except tab/newline/CR) to prevent jq parse errors
EVENTS=$(tr -d '\000-\010\013\014\016-\037' < "$TRANSCRIPT" | jq -s '
  [.[] | select(
    (.type == "user") or
    (.type == "tool_result" and (
      .is_error == true or
      (.content | type == "string" and test("error|failed|denied|cannot|unable"; "i"))
    ))
  )] |
  .[0:50] |
  map(
    if .type == "user" then
      {type: "user", content: ((.message.content // .content | if type == "array" then map(.text // .content // "") | join(" ") else . end)[0:500] | gsub("\n"; " ") | gsub("\r"; ""))}
    else
      {type: "error", content: ((.content | tostring)[0:300] | gsub("\n"; " ") | gsub("\r"; "")), is_error: .is_error}
    end
  )
' 2>/dev/null)

# Check event count
EVENT_COUNT=$(echo "$EVENTS" | jq 'length' 2>/dev/null || echo "0")
if [[ "${EVENT_COUNT:-0}" -lt 3 ]]; then
  echo "Not enough events for analysis (found $EVENT_COUNT, need ≥3)"
  exit 0
fi

echo "Found $EVENT_COUNT events to analyze"
```

### 4. Run Analysis (with proper timeout)

```bash
PROJECT_NAME=$(basename "$PWD")
MODEL=$(cat .bluera/bluera-base/config.json 2>/dev/null | jq -r '.deepLearn.model // "haiku"')
MAX_BUDGET=$(cat .bluera/bluera-base/config.json 2>/dev/null | jq -r '.deepLearn.maxBudget // "0.02"')

ANALYSIS_PROMPT="Analyze this Claude Code session for actionable, project-specific learnings.

Project: $PROJECT_NAME

Session events (user messages and errors):
$EVENTS

Extract learnings in this exact JSON format:
{\"learnings\": [{\"type\": \"correction|error|fact|workflow\", \"content\": \"specific actionable text\", \"confidence\": 0.0-1.0}]}

Rules:
- Only project-specific insights, NOT generic best practices
- Skip obvious advice like \"run tests\" or \"check status\"
- Focus on user corrections (\"No, use X instead of Y\")
- Focus on error resolutions (what fixed the error)
- Each learning must be actionable and specific to this project
- Maximum 5 learnings
- Minimum confidence 0.7

If no meaningful learnings found, return: {\"learnings\": []}"

# Use 120s timeout for interactive use (vs 25s for background hook)
echo "Running analysis with Claude $MODEL (up to 2 minutes)..."
LEARNINGS=$(echo "$ANALYSIS_PROMPT" | timeout 120 claude -p \
  --model "$MODEL" \
  --max-budget-usd "$MAX_BUDGET" \
  2>/dev/null) || {
    echo "Analysis timed out or failed"
    exit 1
  }
```

### 5. Validate and Store Results

```bash
# Validate JSON
if ! echo "$LEARNINGS" | jq -e '.learnings' >/dev/null 2>&1; then
  echo "Invalid response from Claude"
  exit 1
fi

# Filter high-confidence
LEARNINGS=$(echo "$LEARNINGS" | jq '{learnings: [.learnings[] | select(.confidence >= 0.7)]}')
LEARNING_COUNT=$(echo "$LEARNINGS" | jq '.learnings | length')

if [[ "$LEARNING_COUNT" -eq 0 ]]; then
  echo "No high-confidence learnings extracted"
  exit 0
fi

# Store
STATE_DIR=".bluera/bluera-base/state"
mkdir -p "$STATE_DIR"
PENDING_FILE="$STATE_DIR/pending-learnings.jsonl"
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

echo "$LEARNINGS" | jq -c --arg ts "$TIMESTAMP" --arg proj "$PROJECT_NAME" '
  .learnings[] | {
    type: .type,
    learning: .content,
    confidence: .confidence,
    source: "manual-extract",
    created: $ts,
    project: $proj
  }
' >> "$PENDING_FILE"

echo "Extracted $LEARNING_COUNT learning(s). Run /bluera-base:learn show to review."
```

## Key Differences from Hook

| Aspect | Hook (session-end-analyze.sh) | Manual Extract |
|--------|-------------------------------|----------------|
| Trigger | Automatic on session end | User-initiated |
| Timeout | 25 seconds | 120 seconds |
| Transcript | Provided via hook input | Found by project path |
| Output | System message | Console output |

## Common Issues

| Issue | Cause | Fix |
|-------|-------|-----|
| "Not enough events" | Session too short | Need ≥3 user messages or errors |
| Timeout | Slow model startup | Use 120s timeout, pipe input |
| Invalid JSON | Model response malformed | Validate with jq -e before storing |
| Wrong transcript | Multiple sessions | Uses most recent .jsonl by mtime |
