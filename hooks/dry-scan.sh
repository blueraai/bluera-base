#!/usr/bin/env bash
# =============================================================================
# DRY Scan Stop Hook
# Runs jscpd duplication scan if enabled in config
# =============================================================================

set -euo pipefail

# Require jq for JSON parsing
if ! command -v jq &>/dev/null; then
  exit 0  # Skip gracefully if jq missing
fi

HOOK_INPUT=$(cat 2>/dev/null || true)
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# Source config library
if [[ -n "$PLUGIN_ROOT" ]] && [[ -f "$PLUGIN_ROOT/hooks/lib/config.sh" ]]; then
  # shellcheck source=lib/config.sh
  source "$PLUGIN_ROOT/hooks/lib/config.sh"
else
  # Config library not available, skip
  exit 0
fi

# Check if dry check is enabled
if ! bluera_config_enabled ".dryCheck.enabled"; then
  exit 0
fi

# Check if auto-scan on stop is enabled
if ! bluera_config_enabled ".dryCheck.onStop"; then
  exit 0
fi

# Check stop_hook_active to prevent infinite loops
STOP_HOOK_ACTIVE=$(echo "$HOOK_INPUT" | jq -r '.stop_hook_active // false')
if [[ "$STOP_HOOK_ACTIVE" == "true" ]]; then
  exit 0
fi

# Find jscpd (local only - no npx to avoid hanging downloads)
if command -v jscpd &>/dev/null; then
  JSCPD="jscpd"
elif [[ -f "node_modules/.bin/jscpd" ]]; then
  JSCPD="node_modules/.bin/jscpd"
else
  echo "[bluera-base] DRY scan skipped: jscpd not found (install with: npm install -g jscpd)" >&2
  exit 0
fi

# Get config values with defaults
MIN_TOKENS=$(bluera_get_config ".dryCheck.minTokens" "70")
MIN_LINES=$(bluera_get_config ".dryCheck.minLines" "5")

# Ensure output directory
STATE_DIR="$(bluera_state_dir)"
mkdir -p "$STATE_DIR"

cd "$PROJECT_DIR" || exit 0

echo "[bluera-base] Running DRY scan..." >&2

# Run jscpd scan
$JSCPD . \
  --min-tokens "$MIN_TOKENS" \
  --min-lines "$MIN_LINES" \
  --gitignore \
  --ignore "**/node_modules/**,**/dist/**,**/build/**,**/target/**,**/.git/**,**/vendor/**,**/__pycache__/**" \
  --reporters json \
  --output "$STATE_DIR" \
  --silent 2>/dev/null || true

# Check if report was generated
REPORT_JSON="$STATE_DIR/jscpd-report.json"
if [[ ! -f "$REPORT_JSON" ]]; then
  echo "[bluera-base] DRY scan completed (no report generated)" >&2
  exit 0
fi

# Parse results and generate summary
CLONE_COUNT=$(jq -r '.statistics.clones // 0' "$REPORT_JSON" 2>/dev/null || echo "0")
DUP_LINES=$(jq -r '.statistics.duplicatedLines // 0' "$REPORT_JSON" 2>/dev/null || echo "0")
DUP_PERCENT=$(jq -r '.statistics.percentage // 0' "$REPORT_JSON" 2>/dev/null || echo "0")

# Generate markdown report
REPORT_MD="$STATE_DIR/dry-report.md"
{
  echo "# DRY Report"
  echo ""
  echo "**Project**: $PROJECT_DIR"
  echo "**Scanned**: $(date '+%Y-%m-%d %H:%M:%S')"
  echo "**Engine**: jscpd"
  echo ""
  echo "## Summary"
  echo ""
  echo "| Metric | Value |"
  echo "|--------|-------|"
  echo "| Duplicates found | $CLONE_COUNT |"
  echo "| Duplicate lines | $DUP_LINES |"
  echo "| Duplication % | ${DUP_PERCENT}% |"
  echo ""

  if [[ "$CLONE_COUNT" -gt 0 ]]; then
    echo "## Top Duplicates"
    echo ""
    # Extract top 5 duplicates
    jq -r '.duplicates[:5] | to_entries[] | "### \(.key + 1). [\(.value.tokens // "?") tokens, \(.value.lines // "?") lines]\n\n| File | Lines |\n|------|-------|\n\(.value.firstFile.name // "?") | \(.value.firstFile.start // "?")-\(.value.firstFile.end // "?") |\n| \(.value.secondFile.name // "?") | \(.value.secondFile.start // "?")-\(.value.secondFile.end // "?") |\n\n**Language**: \(.value.format // "unknown")\n"' "$REPORT_JSON" 2>/dev/null || echo "(Could not parse duplicates)"
    echo ""
  fi

  echo "## Next Steps"
  echo ""
  echo "- Run \`/dry report\` to see full details"
  echo "- Use @dry-refactor skill for refactoring guidance"
  echo "- Create \`.jscpd.json\` to customize thresholds"
} > "$REPORT_MD"

if [[ "$CLONE_COUNT" -gt 0 ]]; then
  echo "[bluera-base] DRY scan found $CLONE_COUNT duplicates ($DUP_LINES lines, ${DUP_PERCENT}%). See: $REPORT_MD" >&2
else
  echo "[bluera-base] DRY scan completed: no duplicates found" >&2
fi

exit 0
