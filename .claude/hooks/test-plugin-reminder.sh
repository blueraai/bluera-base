#!/usr/bin/env bash
# Stop hook: Remind to run/update test-plugin if plugin files changed
set -euo pipefail

cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

# Check for changes to plugin files (modified, added, deleted)
PLUGIN_CHANGES=$(git diff --name-only HEAD 2>/dev/null | grep -E '^(hooks/|commands/|skills/)' || true)
STAGED_CHANGES=$(git diff --cached --name-only 2>/dev/null | grep -E '^(hooks/|commands/|skills/)' || true)

# Check for untracked new files in plugin directories
NEW_FILES=$(git ls-files --others --exclude-standard 2>/dev/null | grep -E '^(hooks/|commands/|skills/)' || true)

# Check for deleted files
DELETED_FILES=$(git diff --name-only --diff-filter=D HEAD 2>/dev/null | grep -E '^(hooks/|commands/|skills/)' || true)

if [[ -n "$NEW_FILES" || -n "$DELETED_FILES" ]]; then
  echo "[bluera-base] Plugin files added/removed. Update commands/test-plugin.md if needed, then run /bluera-base:claude-code-test-plugin"
elif [[ -n "$PLUGIN_CHANGES" || -n "$STAGED_CHANGES" ]]; then
  echo "[bluera-base] Plugin files modified. Consider running /bluera-base:claude-code-test-plugin"
fi

exit 0
