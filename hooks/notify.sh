#!/bin/bash
# Cross-platform notification hook for Claude Code
# Supports: macOS (osascript/terminal-notifier), Linux (notify-send), Windows (PowerShell)

# Read notification info from stdin (optional - hook may not provide JSON)
INPUT=$(cat 2>/dev/null || true)

# Extract notification type and message if JSON provided
if [[ -n "$INPUT" ]]; then
    NOTIFICATION_TYPE=$(echo "$INPUT" | jq -r '.notification_type // "info"' 2>/dev/null || echo "info")
    MESSAGE=$(echo "$INPUT" | jq -r '.message // "Claude needs your input"' 2>/dev/null || echo "Claude needs your input")
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

# Platform-specific notification
case "$OSTYPE" in
    darwin*)
        # macOS - prefer terminal-notifier (supports icons) if available
        if command -v terminal-notifier &>/dev/null && [[ -f "$ICON" ]]; then
            terminal-notifier -title "$TITLE" -message "$MESSAGE" -appIcon "$ICON" -sound Glass 2>/dev/null || true
        else
            # Fallback to osascript (no custom icon support)
            osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\" sound name \"Glass\"" 2>/dev/null || true
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
        powershell.exe -Command "[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > \$null; \$xml = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent(0); \$xml.GetElementsByTagName('text')[0].AppendChild(\$xml.CreateTextNode('$TITLE')) > \$null; \$xml.GetElementsByTagName('text')[1].AppendChild(\$xml.CreateTextNode('$MESSAGE')) > \$null; [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('Claude Code').Show(\$xml)" 2>/dev/null || true
        ;;
    *)
        # Fallback: just beep
        printf '\a'
        ;;
esac

exit 0
