#!/bin/bash
# Milhouse Loop Setup Script
# Creates state file for iterative development loop

set -euo pipefail

PROMPT_FILE=""
PROMPT_TEXT=""
MAX_ITERATIONS=0
COMPLETION_PROMISE="TASK COMPLETE"
GATES=()
STUCK_LIMIT=3
INIT_HARNESS=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      cat << 'EOF'
Milhouse Loop - Iterative Development Loop

USAGE:
  /milhouse-loop <prompt-file> [OPTIONS]
  /milhouse-loop --inline "Your prompt here" [OPTIONS]

OPTIONS:
  --max-iterations <n>    Maximum iterations (default: unlimited)
  --promise <text>        Completion promise (default: "TASK COMPLETE")
  --inline <prompt>       Use inline prompt instead of file
  --gate <cmd>            Command that must pass before exit (repeatable)
  --stuck-limit <n>       Stop after N identical failures (default: 3, 0=off)
  --init-harness          Create plan.md and activity.md for context hygiene
  -h, --help              Show this help

STOPPING:
  - Output <promise>YOUR_PROMISE</promise> when complete
  - Reach --max-iterations limit
  - Run /cancel-milhouse to stop manually
  - Stuck detection (same failure 3x in a row)

GATES:
  Gates run AFTER the promise matches. All must pass to exit.
  Example: /milhouse-loop task.md --gate "npm test" --gate "npm run lint"

MONITORING:
  # View current iteration:
  grep '^iteration:' .claude/milhouse-loop.local.md

  # View full state:
  head -10 .claude/milhouse-loop.local.md
EOF
      exit 0
      ;;
    --max-iterations)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --max-iterations requires a number argument" >&2
        exit 1
      fi
      if ! [[ "$2" =~ ^[0-9]+$ ]]; then
        echo "Error: --max-iterations must be a positive integer or 0, got: $2" >&2
        exit 1
      fi
      MAX_ITERATIONS="$2"
      shift 2
      ;;
    --promise)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --promise requires a text argument" >&2
        exit 1
      fi
      COMPLETION_PROMISE="$2"
      shift 2
      ;;
    --inline)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --inline requires a prompt argument" >&2
        exit 1
      fi
      PROMPT_TEXT="$2"
      shift 2
      ;;
    --gate)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --gate requires a command argument" >&2
        exit 1
      fi
      GATES+=("$2")
      shift 2
      ;;
    --stuck-limit)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --stuck-limit requires a number argument" >&2
        exit 1
      fi
      if ! [[ "$2" =~ ^[0-9]+$ ]]; then
        echo "Error: --stuck-limit must be a non-negative integer, got: $2" >&2
        exit 1
      fi
      STUCK_LIMIT="$2"
      shift 2
      ;;
    --init-harness)
      INIT_HARNESS=true
      shift
      ;;
    *)
      PROMPT_FILE="$1"
      shift
      ;;
  esac
done

# Get prompt content
if [[ -z "$PROMPT_TEXT" ]]; then
  if [[ -z "$PROMPT_FILE" ]]; then
    echo "Error: Prompt file required. Use --inline or provide file path." >&2
    echo "Usage: /milhouse-loop <prompt-file> [--max-iterations N] [--promise TEXT]" >&2
    exit 1
  fi
  if [[ ! -f "$PROMPT_FILE" ]]; then
    echo "Error: Prompt file not found: $PROMPT_FILE" >&2
    exit 1
  fi
  PROMPT_TEXT=$(cat "$PROMPT_FILE")
fi

# Create state file
mkdir -p .claude

# Build gates YAML array
GATES_YAML=""
if [[ ${#GATES[@]} -gt 0 ]]; then
  GATES_YAML="gates:"
  for gate in "${GATES[@]}"; do
    GATES_YAML="$GATES_YAML
  - \"$gate\""
  done
else
  GATES_YAML="gates: []"
fi

cat > .claude/milhouse-loop.local.md <<EOF
---
active: true
iteration: 1
max_iterations: $MAX_ITERATIONS
completion_promise: "$COMPLETION_PROMISE"
prompt_file: "${PROMPT_FILE:-inline}"
started_at: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
session_id: ""
stuck_limit: $STUCK_LIMIT
failure_hashes: []
$GATES_YAML
---

$PROMPT_TEXT
EOF

# Create harness files if requested
if [[ "$INIT_HARNESS" == true ]]; then
  # Extract first line of prompt as goal summary
  GOAL_SUMMARY=$(echo "$PROMPT_TEXT" | head -1 | sed 's/^#* *//')

  cat > .claude/milhouse-plan.md <<PLANEOF
# Milhouse Plan

## Goal

$GOAL_SUMMARY

## Acceptance Criteria

- [ ] All tests pass
- [ ] Lint clean
- [ ] Task requirements met

## Tasks

1. [ ] Understand current state
2. [ ] Implement changes
3. [ ] Verify with tests
4. [ ] Output completion promise
PLANEOF

  cat > .claude/milhouse-activity.md <<ACTEOF
# Milhouse Activity Log

Track progress across iterations. Update after each iteration.

---

## Iteration 1

**Observed:**
- Starting state

**Changed:**
- (none yet)

**Result:**
- (pending)

**Next:**
- Review task requirements
ACTEOF

  echo "📋 Created .claude/milhouse-plan.md and .claude/milhouse-activity.md"
fi

# Output compact setup message
MAX_DISPLAY=$(if [[ $MAX_ITERATIONS -gt 0 ]]; then echo "$MAX_ITERATIONS"; else echo "unlimited"; fi)
GATES_DISPLAY=$(if [[ ${#GATES[@]} -gt 0 ]]; then echo " | Gates: ${#GATES[@]}"; else echo ""; fi)
echo "🔄 Milhouse: iteration 1/$MAX_DISPLAY$GATES_DISPLAY | Complete: <promise>$COMPLETION_PROMISE</promise>"
echo ""
echo "$PROMPT_TEXT"
