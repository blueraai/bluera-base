#!/bin/bash
# TaskCompleted Hook - Fires when a delegated agent task completes
# Available since Claude Code 2.1.33+
# Use this to aggregate results or trigger follow-up actions
set -euo pipefail

INPUT=$(cat 2>/dev/null || true)
[[ -z "$INPUT" ]] && exit 0

# Log completion for observability (stderr only)
echo "[bluera-base] Agent task completed" >&2

exit 0
