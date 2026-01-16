#!/bin/bash
# PreCompact Hook - Compaction Warning
# Runs before context compaction to ensure critical invariants are preserved

set -euo pipefail

cd "${CLAUDE_PROJECT_DIR:-.}"

INVARIANTS_FILE=".claude/critical-invariants.md"

# Check if invariants file exists
if [[ ! -f "$INVARIANTS_FILE" ]]; then
  # Suggest creating one if CLAUDE.md exists
  if [[ -f "CLAUDE.md" ]] || [[ -f ".claude/CLAUDE.md" ]]; then
    echo "[bluera-base] Tip: Create .claude/critical-invariants.md with your must-follow rules (5-15 lines)." >&2
    echo "             These will be re-injected after compaction to prevent drift." >&2
  fi
  exit 0
fi

# Validate invariants aren't empty
if [[ ! -s "$INVARIANTS_FILE" ]]; then
  echo "[bluera-base] Warning: .claude/critical-invariants.md is empty." >&2
  exit 0
fi

# Read and validate size
LINE_COUNT=$(wc -l < "$INVARIANTS_FILE" | tr -d ' ')
CHAR_COUNT=$(wc -c < "$INVARIANTS_FILE" | tr -d ' ')

if [[ "$LINE_COUNT" -gt 20 ]]; then
  echo "[bluera-base] Warning: critical-invariants.md is $LINE_COUNT lines (recommended: 5-15)." >&2
  echo "             Large invariants reduce compaction effectiveness." >&2
fi

if [[ "$CHAR_COUNT" -gt 1500 ]]; then
  echo "[bluera-base] Warning: critical-invariants.md is ${CHAR_COUNT} chars (recommended: < 1000)." >&2
fi

# Output confirmation that invariants will be preserved
echo "[bluera-base] Critical invariants ($LINE_COUNT lines) will be re-injected after compaction." >&2

exit 0
