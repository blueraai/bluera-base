#!/bin/bash
# Deep Learning Session Analysis Hook (Stop)
# Analyzes session transcripts using Claude CLI to extract meaningful learnings
# Replaces the pattern-matching approach with semantic understanding

set -euo pipefail

# Require CLAUDE_PROJECT_DIR — fallback-to-dot is an anti-pattern
if [[ -z "${CLAUDE_PROJECT_DIR:-}" ]]; then
  echo "[bluera-base] Skipping $(basename "$0"): CLAUDE_PROJECT_DIR not set" >&2
  exit 0
fi
cd "$CLAUDE_PROJECT_DIR"

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/config.sh"

# Require dependencies (optional hook: warn + skip)
bluera_require_jq_optional || exit 0

if ! command -v claude &>/dev/null; then
  echo "[bluera-base] Skipping $(basename "$0"): claude CLI not installed" >&2
  exit 0
fi

# Check if deep learning is enabled (opt-in)
if ! bluera_config_enabled ".deepLearn.enabled"; then
  exit 0
fi

# Get transcript path from hook input
INPUT=$(cat 2>/dev/null || true)

# Check for stop_hook_active to avoid unnecessary work
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null || echo "false")
if [[ "$STOP_HOOK_ACTIVE" == "true" ]]; then
  exit 0
fi

TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty')

if [[ -z "$TRANSCRIPT" ]] || [[ ! -f "$TRANSCRIPT" ]]; then
  exit 0
fi

# Get config values
MODEL=$(bluera_get_config ".deepLearn.model" "haiku")
MAX_BUDGET=$(bluera_get_config ".deepLearn.maxBudget" "0.02")

# Extract learning-relevant events from transcript
# Focus on: user messages (corrections), tool errors (resolutions)
# Note: Content may contain newlines that break JSON output - sanitize with gsub
# Strip control chars (U+0000-U+001F except tab/newline/CR) to prevent jq parse errors
EVENTS=$(tr -d '\000-\010\013\014\016-\037' < "$TRANSCRIPT" | jq -s '
  [.[] | select(
    (.type == "user") or
    (.type == "tool_result" and (
      .is_error == true or
      (.content | type == "string" and test("error|failed|denied|cannot|unable"; "i"))
    ))
  )] |
  # Limit to first 50 events
  .[0:50] |
  # Extract relevant fields and sanitize newlines in content
  map(
    if .type == "user" then
      {type: "user", content: ((.message.content // .content | if type == "array" then map(.text // .content // "") | join(" ") else . end)[0:500] | gsub("\n"; " ") | gsub("\r"; ""))}
    else
      {type: "error", content: ((.content | tostring)[0:300] | gsub("\n"; " ") | gsub("\r"; "")), is_error: .is_error}
    end
  )
' 2>/dev/null)

# Skip if no meaningful events or too short
EVENT_COUNT=$(echo "$EVENTS" | jq 'length')
if [[ "$EVENT_COUNT" -lt 3 ]]; then
  exit 0
fi

# Limit total size
EVENTS=$(echo "$EVENTS" | head -c 30000)

# Get project name for context
PROJECT_NAME=$(basename "$CLAUDE_PROJECT_DIR")

# Read project conventions so learnings don't contradict them
PROJECT_CONTEXT=""
for f in CLAUDE.md CLAUDE.local.md; do
  if [[ -f "$f" ]]; then
    PROJECT_CONTEXT="${PROJECT_CONTEXT}
--- $f ---
$(head -c 2000 "$f")"
  fi
done

# Analyze with Claude
ANALYSIS_PROMPT="Analyze this Claude Code session for actionable, project-specific learnings.

Project: $PROJECT_NAME
${PROJECT_CONTEXT:+
Project conventions (learnings MUST NOT contradict these):
$PROJECT_CONTEXT
}
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

# Run Claude analysis with timeout and budget cap
LEARNINGS=$(echo "$ANALYSIS_PROMPT" | timeout 25 claude -p \
  --model "$MODEL" \
  --max-budget-usd "$MAX_BUDGET" \
  2>/dev/null) || exit 0

# Validate JSON response
if ! echo "$LEARNINGS" | jq -e '.learnings' >/dev/null 2>&1; then
  exit 0
fi

# Filter to high-confidence learnings only
LEARNINGS=$(echo "$LEARNINGS" | jq '{learnings: [.learnings[] | select(.confidence >= 0.7)]}')

# Get learning count
LEARNING_COUNT=$(echo "$LEARNINGS" | jq '.learnings | length')
if [[ "$LEARNING_COUNT" -eq 0 ]]; then
  exit 0
fi

# Store learnings with metadata
STATE_DIR="$(bluera_state_dir)"
mkdir -p "$STATE_DIR"
PENDING_FILE="$STATE_DIR/pending-learnings.jsonl"

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Append each learning with metadata
echo "$LEARNINGS" | jq -c --arg sid "$SESSION_ID" --arg ts "$TIMESTAMP" --arg proj "$PROJECT_NAME" '
  .learnings[] | . + {
    session_id: $sid,
    created_at: $ts,
    project: $proj,
    applied: false
  }
' >> "$PENDING_FILE"

# Output system message
jq -n --arg count "$LEARNING_COUNT" \
  '{"systemMessage": "[bluera-base] Captured \($count) learning(s) from session analysis. Run /bluera-base:learn show to review."}' >&2

exit 0
