#!/bin/bash
# Bluera Base Plugin - Session Setup Hook
# Checks dependencies required by bluera-base hooks

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PREFIX="[bluera-base]"

# =====================
# Check jq (required by hooks)
# =====================

if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}${PREFIX} jq is not installed${NC}"
    echo -e "${YELLOW}Some hooks require jq for JSON parsing${NC}"
    echo ""

    # Attempt auto-install based on OS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            echo -e "${YELLOW}${PREFIX} Installing jq via Homebrew...${NC}"
            if brew install jq 2>/dev/null; then
                echo -e "${GREEN}${PREFIX} jq installed ✓${NC}"
            else
                echo -e "${YELLOW}${PREFIX} Auto-install failed. Install manually: brew install jq${NC}"
            fi
        else
            echo -e "${YELLOW}Install manually: brew install jq${NC}"
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if command -v apt-get &> /dev/null; then
            echo -e "${YELLOW}Install manually: sudo apt-get install jq${NC}"
        elif command -v yum &> /dev/null; then
            echo -e "${YELLOW}Install manually: sudo yum install jq${NC}"
        else
            echo -e "${YELLOW}Install jq from: https://stedolan.github.io/jq/download/${NC}"
        fi
    else
        echo -e "${YELLOW}Install jq from: https://stedolan.github.io/jq/download/${NC}"
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
        chmod +x "$hook_file" 2>/dev/null && \
            echo -e "${GREEN}${PREFIX} Fixed permissions: $(basename "$hook_file") ✓${NC}" || \
            echo -e "${YELLOW}${PREFIX} Could not fix permissions: $(basename "$hook_file")${NC}"
    fi
}

# Make sure all hook scripts are executable
for hook in "$PLUGIN_ROOT"/hooks/*.sh; do
    [[ -f "$hook" ]] && check_executable "$hook"
done

# Always exit 0 to not block the session
exit 0
