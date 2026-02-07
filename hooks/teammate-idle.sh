#!/bin/bash
# TeammateIdle Hook - Fires when an agent teammate is idle
# Available since Claude Code 2.1.33+
# Use this to coordinate work between agent teammates
set -euo pipefail

INPUT=$(cat 2>/dev/null || true)
[[ -z "$INPUT" ]] && exit 0

# Log idle event for observability (stderr only)
echo "[bluera-base] Agent teammate idle" >&2

exit 0
