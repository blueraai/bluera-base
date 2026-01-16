#!/bin/bash
# Bluera Base Plugin - Session Setup Hook
# Checks dependencies required by bluera-base hooks

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PREFIX="[bluera-base]"

# =====================
# Check jq (required by hooks)
# =====================

if ! command -v jq &> /dev/null; then
    # Attempt silent auto-install on macOS
    if [[ "$OSTYPE" == "darwin"* ]] && command -v brew &> /dev/null; then
        brew install jq &>/dev/null && echo -e "${GREEN}${PREFIX} jq installed ✓${NC}" || \
            echo -e "${YELLOW}${PREFIX} jq missing. Install: brew install jq${NC}"
    else
        echo -e "${YELLOW}${PREFIX} jq missing. Install: https://stedolan.github.io/jq/download/${NC}"
    fi
else
    echo -e "${GREEN}${PREFIX} jq ready ✓${NC}"
fi

# =====================
# Verify hooks are executable
# =====================

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname "$(dirname "$0")")}"

check_executable() {
    local hook_file="$1"
    if [[ -f "$hook_file" ]] && [[ ! -x "$hook_file" ]]; then
        chmod +x "$hook_file" 2>/dev/null || \
            echo -e "${YELLOW}${PREFIX} chmod failed: $(basename "$hook_file")${NC}"
    fi
}

# Make sure all hook scripts are executable
for hook in "$PLUGIN_ROOT"/hooks/*.sh; do
    [[ -f "$hook" ]] && check_executable "$hook"
done

# Always exit 0 to not block the session
exit 0
