# Advanced Patterns

Architectural patterns for building sophisticated Claude Code plugins.

---

## State Bus + Capsules

A token-efficient pattern for passing data between hooks, commands, and skills.

### The Problem

Naively passing data between Claude Code components means dumping large content (diffs, logs, file contents) into the LLM conversation. This is expensive, noisy, and degrades performance.

### The Solution: Two-Channel Architecture

**In-band channel (small)**: Pass only compact "routing" information through model context:

- File path pointer
- Capsule ID
- Short digest/summary

**Out-of-band channel (large)**: Store real payload outside LLM context:

- Files on disk
- Structured JSON state file
- Model fetches slices only when needed

### Implementation

```bash
# SessionStart hook: initialize state + publish pointer
STATE_DIR="$PROJECT_DIR/.bluera/plugin-name/state"
STATE_FILE="$STATE_DIR/state.json"

mkdir -p "$STATE_DIR"

# Publish pointer for subsequent Bash commands
if [[ -n "${CLAUDE_ENV_FILE:-}" ]]; then
  echo "export MY_STATE_FILE=\"$STATE_FILE\"" >> "$CLAUDE_ENV_FILE"
fi
```

```json
// state.json schema
{
  "schema_version": "1",
  "session": {
    "session_id": "abc123",
    "created_at": "2026-01-16T00:00:00Z"
  },
  "capsules": {
    "cap_001": {
      "type": "git_diff",
      "path": ".bluera/state/capsules/cap_001.diff",
      "summary": "Edited 3 files: src/app.ts, src/utils.ts, tests/app.test.ts",
      "bytes": 12345
    }
  },
  "pointers": {
    "latest_diff": "cap_001"
  }
}
```

### Hydration Commands

Create commands that retrieve small slices:

```md
---
description: Show state bus status
---
## Status
- State file: !`echo "${MY_STATE_FILE:-"(unset)"}"`
- Latest diff: !`jq -r '.pointers.latest_diff // "(none)"' "$MY_STATE_FILE"`
```

> **Note**: The `!`` prefix in command markdown files is intentional—it executes shell commands within the command context. This differs from general markdown where this pattern should be avoided.

---

## Loop Patterns (Milhouse/Ralph Wiggum)

Stop hook interception for autonomous iteration.

### How It Works

1. User starts a loop via command: `/bluera-base:milhouse --inline "Build the feature" --max-iterations 10`
2. Setup script creates state file with prompt, iteration count, completion promise
3. Stop hook intercepts every stop attempt:
   - Check if completion promise matched
   - Run objective gates (tests, lint)
   - If not complete: block stop, increment iteration, inject continuation message
   - If complete (or max iterations): allow exit

### State File Format

```md
---
iteration: 1
max_iterations: 10
completion_promise: "DONE"
session_id: "abc123"
gates:
  - "npm test"
  - "npm run lint"
failure_hashes: []
stuck_limit: 3
---
Build the feature as described in the requirements.
```

### Stop Hook Logic

```bash
# Check if promise matched
LAST_LINE=$(echo "$LAST_OUTPUT" | grep -v '^\s*$' | tail -1)
if echo "$LAST_LINE" | grep -qE '<promise>DONE</promise>'; then
  PROMISE_MATCHED=true
fi

# Run gates if promise matched
if [[ "$PROMISE_MATCHED" == true ]]; then
  for gate in "${GATES[@]}"; do
    if ! bash -c "$gate" 2>&1; then
      # Gate failed - continue loop
      GATES_PASSED=false
      break
    fi
  done
fi

# Allow exit only if promise matched AND all gates passed
if [[ "$PROMISE_MATCHED" == true ]] && [[ "$GATES_PASSED" == true ]]; then
  rm "$STATE_FILE"
  exit 0
fi

# Block and continue
jq -n --arg reason "Continue working..." '{"decision": "block", "reason": $reason}'
```

---

## Objective Gates

Validation commands that must pass before loop exit.

### Purpose

Gates ensure that claiming "done" actually means done - tests pass, linting clean, build succeeds.

### Configuration

```yaml
gates:
  - "npm test"
  - "npm run lint"
  - "npm run build"
```

### Gate Execution

```bash
for gate in "${GATES[@]}"; do
  if ! GATE_OUTPUT=$(bash -c "$gate" 2>&1); then
    GATES_PASSED=false
    GATE_FAILURE_OUTPUT="Gate failed: $gate
$(echo "$GATE_OUTPUT" | tail -20)"
    break
  fi
done
```

### Gate Failure Feedback

When a gate fails, inject targeted feedback:

```bash
REASON="## Gate Failure

$GATE_FAILURE_OUTPUT

---

Continue working. Address the gate failure above."
```

---

## Stuck Detection

Circuit breakers for infinite retry prevention.

### The Problem

Without safeguards, a loop can waste tokens retrying the same failing approach indefinitely.

### Solution: Failure Hash Tracking

Track hashes of failure output. If the same failure repeats N times, stop:

```bash
FAILURE_HASH=$(echo "$GATE_FAILURE_OUTPUT" | md5 -q)

# Count repeated identical hashes
HASH_COUNT=$(echo "$FAILURE_HASHES" | grep -o "\"$FAILURE_HASH\"" | wc -l)

if [[ "$HASH_COUNT" -ge "$STUCK_LIMIT" ]]; then
  echo "Stuck detected: same failure $HASH_COUNT times. Stopping."
  rm "$STATE_FILE"
  exit 0
fi
```

### Configuration

```yaml
stuck_limit: 3  # Stop after 3 identical failures
```

---

## Marker-Based Edits

Safe modification of memory files with plugin-owned regions.

### The Problem

Plugins need to update CLAUDE.md but must not clobber user content.

### Solution: Stable Owned Regions

```md
## User Content
...user's stuff here...

## Auto-managed (plugin)
<!-- AUTO-MANAGED:learned -->
- Run tests before commits
- Use conventional commit format
<!-- END AUTO-MANAGED:learned -->
```

### Rules

1. Plugin ONLY edits between its markers
2. If markers missing, insert at end with notice
3. Enforce size cap (50-120 lines)
4. Dedupe and normalize content

### Implementation

```bash
# Check if marker exists
if ! grep -q "<!-- AUTO-MANAGED:learned -->" CLAUDE.md; then
  # Insert markers at end
  cat >> CLAUDE.md << 'EOF'

## Auto-managed (plugin)
<!-- AUTO-MANAGED:learned -->
<!-- END AUTO-MANAGED:learned -->
EOF
fi

# Edit only between markers
sed -i '' '/<!-- AUTO-MANAGED:learned -->/,/<!-- END AUTO-MANAGED:learned -->/{
  /<!-- AUTO-MANAGED:learned -->/a\
- New learning here
}' CLAUDE.md
```

---

## Compaction Resilience

Strategies to maintain context after `/compact`.

### The Problem

After compaction, Claude may "forget" CLAUDE.md guidance until explicitly re-read.

### Solutions

**1. SessionStart Context Injection**

```bash
# hooks/session-start-inject.sh
CRITICAL_INVARIANTS=$(cat << 'EOF'
Critical project rules:
- Always run tests before commit
- Use conventional commit format
- Never use --no-verify
EOF
)

jq -n --arg ctx "$CRITICAL_INVARIANTS" '{
  "hookSpecificOutput": {
    "additionalContext": $ctx
  }
}'
```

**2. PreCompact Snapshot**

Use `PreCompact` hook to ensure critical state is preserved:

```bash
# Save current state before compaction
cp "$STATE_FILE" "$STATE_FILE.pre-compact"
```

**3. Keep Critical Section Small**

In CLAUDE.md, maintain a tiny "Critical invariants" block (5-15 lines max) that survives compaction better than large documents.

---

## Session Scoping

Isolate loop state per session to prevent cross-terminal bleed.

### The Problem

Multiple Claude Code instances in different terminals can interfere if state isn't session-scoped.

### Solution: Session ID from Transcript Path

```bash
# Derive unique session ID
CURRENT_SESSION=$(echo "$HOOK_INPUT" | jq -r '.transcript_path' | md5 -q)

# Store in state file
if [[ -z "$STORED_SESSION" ]]; then
  sed -i '' "s/^session_id: .*/session_id: \"$CURRENT_SESSION\"/" "$STATE_FILE"
  STORED_SESSION="$CURRENT_SESSION"
fi

# Ignore if mismatch
if [[ "$STORED_SESSION" != "$CURRENT_SESSION" ]]; then
  exit 0  # Different terminal, not our loop
fi
```

---

## Multi-Phase Workflows

Structured development with agent coordination.

### Pattern: Feature Development Phases

```text
1. Research     → Explore agent gathers context
2. Design       → Plan agent proposes approach
3. Implement    → Main thread writes code
4. Validate     → Test runner subagent verifies
5. Document     → Update relevant docs
6. Review       → Code review agent checks quality
7. Commit       → Atomic commits via /bluera-base:commit
```

### Implementation Tips

- Use subagents for noisy phases (research, validation)
- Keep main thread for user-visible work
- Pass results via state bus, not conversation

---

## Confidence-Based Filtering

Scoring and filtering findings with thresholds.

### Use Case

Code review that filters out low-confidence findings:

```bash
# Only show findings with score >= threshold
FINDINGS=$(jq --argjson threshold 80 '
  .findings | map(select(.confidence >= $threshold))
' review-results.json)
```

### Scoring Factors

- Pattern match strength
- Context relevance
- Historical accuracy
- User feedback integration

---

## Token Efficiency Summary

| Pattern | Token Savings | How |
|---------|---------------|-----|
| State Bus + Capsules | 80-90% | Pointers instead of full content |
| Pointer-Based Continuation | 80-90% | Reference state file, not re-inject prompt |
| Progressive Skill Loading | 50-70% | SKILL.md summary + references/ detail |
| Forked Context Commands | 100% | No pollution of main thread |
| Marker-Based Edits | Variable | Small, bounded updates |

---

## References

- [Claude Code Hooks Docs](https://code.claude.com/docs/en/hooks)
- [Claude Code Memory Docs](https://code.claude.com/docs/en/memory)
- bluera-base implementation: `hooks/milhouse-stop.sh`, `hooks/session-setup.sh`
