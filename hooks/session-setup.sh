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
    # Attempt silent auto-install based on platform
    if [[ "$OSTYPE" == "darwin"* ]] && command -v brew &> /dev/null; then
        brew install jq &>/dev/null && echo -e "${GREEN}${PREFIX} jq installed ✓${NC}" || \
            echo -e "${YELLOW}${PREFIX} jq missing. Install: brew install jq${NC}"
    elif command -v apt-get &> /dev/null; then
        sudo apt-get install -y jq &>/dev/null && echo -e "${GREEN}${PREFIX} jq installed ✓${NC}" || \
            echo -e "${YELLOW}${PREFIX} jq missing. Install: sudo apt-get install jq${NC}"
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm jq &>/dev/null && echo -e "${GREEN}${PREFIX} jq installed ✓${NC}" || \
            echo -e "${YELLOW}${PREFIX} jq missing. Install: sudo pacman -S jq${NC}"
    else
        echo -e "${YELLOW}${PREFIX} jq missing. Install: https://stedolan.github.io/jq/download/${NC}"
    fi
else
    echo -e "${GREEN}${PREFIX} jq ready ✓${NC}"
fi

# =====================
# Ensure .gitignore has bluera-base patterns
# =====================

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname "$(dirname "$0")")}"
source "${PLUGIN_ROOT}/hooks/lib/gitignore.sh"
gitignore_ensure_patterns

# =====================
# Verify hooks are executable
# =====================

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

# =====================
# Publish state/config pointers via CLAUDE_ENV_FILE
# This allows Bash commands to access these paths without manual discovery
# Note: Known issues exist where CLAUDE_ENV_FILE may be empty/missing
# =====================

if [[ -n "${CLAUDE_ENV_FILE:-}" ]] && [[ -f "$CLAUDE_ENV_FILE" ]]; then
    # Determine project directory (prefer CLAUDE_PROJECT_DIR, fallback to pwd)
    PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

    # State and config paths
    STATE_DIR="$PROJECT_DIR/.bluera/bluera-base/state"
    CONFIG_FILE="$PROJECT_DIR/.bluera/bluera-base/config.json"

    # Remove existing BLUERA_ exports to prevent accumulation across sessions
    if grep -q '^export BLUERA_' "$CLAUDE_ENV_FILE" 2>/dev/null; then
        grep -v '^export BLUERA_' "$CLAUDE_ENV_FILE" > "${CLAUDE_ENV_FILE}.tmp" && \
            mv "${CLAUDE_ENV_FILE}.tmp" "$CLAUDE_ENV_FILE"
    fi

    # Write environment exports (available to subsequent Bash tool calls)
    {
        echo "export BLUERA_STATE_DIR=\"$STATE_DIR\""
        echo "export BLUERA_CONFIG=\"$CONFIG_FILE\""
        echo "export BLUERA_PROJECT_DIR=\"$PROJECT_DIR\""
    } >> "$CLAUDE_ENV_FILE"
fi

# Always exit 0 to not block the session
exit 0
