#!/bin/bash
# Milhouse Loop Setup Script
# Creates state file for iterative development loop

set -euo pipefail

PROMPT_FILE=""
PROMPT_TEXT=""
MAX_ITERATIONS=0
COMPLETION_PROMISE="TASK COMPLETE"

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
  -h, --help              Show this help

STOPPING:
  - Output <promise>YOUR_PROMISE</promise> when complete
  - Reach --max-iterations limit
  - Run /cancel-milhouse to stop manually

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

cat > .claude/milhouse-loop.local.md <<EOF
---
active: true
iteration: 1
max_iterations: $MAX_ITERATIONS
completion_promise: "$COMPLETION_PROMISE"
prompt_file: "${PROMPT_FILE:-inline}"
started_at: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
---

$PROMPT_TEXT
EOF

# Output compact setup message
MAX_DISPLAY=$(if [[ $MAX_ITERATIONS -gt 0 ]]; then echo "$MAX_ITERATIONS"; else echo "unlimited"; fi)
echo "🔄 Milhouse: iteration 1/$MAX_DISPLAY | Complete: <promise>$COMPLETION_PROMISE</promise>"
echo ""
echo "$PROMPT_TEXT"
