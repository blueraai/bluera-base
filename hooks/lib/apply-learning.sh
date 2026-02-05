#!/bin/bash
# Apply a learning to CLAUDE.local.md and optionally promote to global memory
# Usage: apply-learning.sh <content> <type> <confidence>
# Called by /bluera-base:learn apply action
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source autolearn library (provides bluera_autolearn_write and promotion)
# shellcheck source=./autolearn.sh
source "$SCRIPT_DIR/autolearn.sh"

# Ensure we're in the project directory
cd "${CLAUDE_PROJECT_DIR:-.}"

content="${1:-}"
type="${2:-fact}"
confidence="${3:-0}"

if [[ -z "$content" ]]; then
    echo "Error: Learning content is required" >&2
    echo "Usage: apply-learning.sh <content> [type] [confidence]" >&2
    exit 1
fi

# Write to CLAUDE.local.md
if ! bluera_autolearn_write "$content"; then
    echo "Failed to write learning" >&2
    exit 1
fi

echo "Applied to CLAUDE.local.md"

# Attempt promotion (silently skips if disabled or below threshold)
bluera_autolearn_promote_to_global "$content" "$type" "$confidence"

exit 0
