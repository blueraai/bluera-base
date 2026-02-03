#!/bin/bash
# PreToolUse: Check for secrets in git add/commit
# Phase 1: Static regex check (fast)
# Phase 2: AI check for obfuscated secrets (optional, via config)
# Exit 0 = allow, Exit 2 = block with stderr feedback to Claude

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# DRY: Reuse existing pattern from autolearn.sh
source "$SCRIPT_DIR/lib/autolearn.sh"

# Load config for AI check setting
if [[ -f "$SCRIPT_DIR/lib/config.sh" ]]; then
  source "$SCRIPT_DIR/lib/config.sh"
  AI_SECRETS_CHECK=$(bluera_get_config ".secretsCheck.aiEnabled" "false" 2>/dev/null || echo "false")
else
  AI_SECRETS_CHECK="false"
fi

# Read hook input from stdin
INPUT=$(cat 2>/dev/null || true)
[[ -z "$INPUT" ]] && exit 0

# Parse command - need jq
if ! command -v jq &>/dev/null; then
  exit 0  # Can't parse, allow through
fi

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
[[ -z "$COMMAND" ]] && exit 0

# Only trigger on git add/commit
echo "$COMMAND" | grep -qE '^git[[:space:]]+(add|commit)' || exit 0

# Get staged content
STAGED=$(git diff --cached 2>/dev/null || true)
[[ -z "$STAGED" ]] && exit 0

# Check for escape hatch: # ok: or // ok:
STAGED_NO_ESCAPES=$(echo "$STAGED" | grep -v '# ok:' | grep -v '// ok:' || true)

# Phase 1: Static check for secrets
if echo "$STAGED_NO_ESCAPES" | grep -qiE "$BLUERA_SECRETS_PATTERN"; then
  MATCH=$(echo "$STAGED_NO_ESCAPES" | grep -oiE "$BLUERA_SECRETS_PATTERN" | head -1)
  echo "Blocked: Potential secret in staged changes (matched: $MATCH)" >&2
  echo "Remove the secret or add '# ok: <reason>' comment to bypass" >&2
  exit 2
fi

# Phase 2: AI check for obfuscated secrets (if enabled)
if [[ "$AI_SECRETS_CHECK" == "true" ]] && command -v claude &>/dev/null; then
  # Truncate staged content for AI analysis
  STAGED_TRUNCATED=$(echo "$STAGED" | head -c 4000)

  AI_PROMPT="Analyze this git diff for secrets that might bypass regex detection:
- Base64-encoded credentials
- Hex-encoded API keys
- Environment variable assignments with real values
- Commented-out secrets
- Obfuscated tokens

Diff:
$STAGED_TRUNCATED

Respond ONLY with JSON: {\"suspicious\": true/false, \"reason\": \"...\"}"

  AI_RESPONSE=$(echo "$AI_PROMPT" | timeout 15 claude -p --model haiku 2>/dev/null || echo '{"suspicious": false}')

  if echo "$AI_RESPONSE" | jq -e '.suspicious == true' &>/dev/null; then
    REASON=$(echo "$AI_RESPONSE" | jq -r '.reason // "Suspicious content detected"')
    echo "Blocked: AI detected potential secret - $REASON" >&2
    exit 2
  fi
fi

exit 0
