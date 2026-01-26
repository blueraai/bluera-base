#!/bin/bash
# Cross-platform notification hook for Claude Code
# Supports: macOS (osascript/terminal-notifier), Linux (notify-send), Windows (PowerShell)

# Source config library to check if notifications are enabled
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Require jq for config parsing - skip config check if missing (use default: enabled)
if command -v jq &>/dev/null && [[ -f "$SCRIPT_DIR/lib/config.sh" ]]; then
  source "$SCRIPT_DIR/lib/config.sh"
  # Check if notifications are enabled (default: true)
  if ! bluera_config_enabled ".notifications.enabled"; then
    exit 0
  fi
fi

# Read notification info from stdin (optional - hook may not provide JSON)
INPUT=$(cat 2>/dev/null || true)

# Extract notification type and message if JSON provided
if [[ -n "$INPUT" ]]; then
    # Require jq for JSON parsing
    if command -v jq &>/dev/null; then
        NOTIFICATION_TYPE=$(echo "$INPUT" | jq -r '.notification_type // "info"' 2>/dev/null || echo "info")
        MESSAGE=$(echo "$INPUT" | jq -r '.message // "Claude needs your input"' 2>/dev/null || echo "Claude needs your input")
    else
        # Without jq, use defaults
        NOTIFICATION_TYPE="info"
        MESSAGE="Claude needs your input"
    fi
else
    NOTIFICATION_TYPE="info"
    MESSAGE="Claude needs your input"
fi

# Project name from environment
PROJECT_NAME=$(basename "${CLAUDE_PROJECT_DIR:-$PWD}")

# Title based on notification type (includes project name)
case "$NOTIFICATION_TYPE" in
    permission_prompt)
        TITLE="$PROJECT_NAME - Permission Required"
        ;;
    idle_prompt)
        TITLE="$PROJECT_NAME - Waiting"
        ;;
    elicitation_dialog)
        TITLE="$PROJECT_NAME - Input Needed"
        ;;
    *)
        TITLE="$PROJECT_NAME"
        ;;
esac

# Icon path (optional - for platforms that support it)
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname "$0")/..}"
ICON="$PLUGIN_ROOT/assets/claude.png"

# Escape quotes for shell embedding (prevents injection and broken notifications)
escape_for_applescript() {
    local str="$1"
    str="${str//\\/\\\\}"      # escape backslashes first
    str="${str//\"/\\\"}"      # escape double quotes
    echo "$str"
}

escape_for_powershell() {
    local str="$1"
    str="${str//\'/\'\'}"      # escape single quotes by doubling
    echo "$str"
}

# Platform-specific notification
case "$OSTYPE" in
    darwin*)
        # macOS - prefer terminal-notifier (supports icons) if available
        if command -v terminal-notifier &>/dev/null && [[ -f "$ICON" ]]; then
            terminal-notifier -title "$TITLE" -message "$MESSAGE" -appIcon "$ICON" -sound Glass 2>/dev/null || true
        else
            # Fallback to osascript (no custom icon support)
            ESCAPED_TITLE=$(escape_for_applescript "$TITLE")
            ESCAPED_MESSAGE=$(escape_for_applescript "$MESSAGE")
            osascript -e "display notification \"$ESCAPED_MESSAGE\" with title \"$ESCAPED_TITLE\" sound name \"Glass\"" 2>/dev/null || true
        fi
        ;;
    linux-gnu*|linux*)
        # Linux - use notify-send with icon if available
        if command -v notify-send &>/dev/null; then
            if [[ -f "$ICON" ]]; then
                notify-send -i "$ICON" "$TITLE" "$MESSAGE" 2>/dev/null || true
            else
                notify-send "$TITLE" "$MESSAGE" 2>/dev/null || true
            fi
        elif command -v kdialog &>/dev/null; then
            kdialog --passivepopup "$MESSAGE" 5 --title "$TITLE" 2>/dev/null || true
        fi
        ;;
    msys*|cygwin*|mingw*)
        # Windows (Git Bash, Cygwin, etc.) - use PowerShell toast notification
        ESCAPED_TITLE=$(escape_for_powershell "$TITLE")
        ESCAPED_MESSAGE=$(escape_for_powershell "$MESSAGE")
        powershell.exe -Command "[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > \$null; \$xml = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent(0); \$xml.GetElementsByTagName('text')[0].AppendChild(\$xml.CreateTextNode('$ESCAPED_TITLE')) > \$null; \$xml.GetElementsByTagName('text')[1].AppendChild(\$xml.CreateTextNode('$ESCAPED_MESSAGE')) > \$null; [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('Claude Code').Show(\$xml)" 2>/dev/null || true
        ;;
    *)
        # Fallback: just beep
        printf '\a'
        ;;
esac

exit 0
