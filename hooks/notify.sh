#!/bin/bash
# Cross-platform notification hook for Claude Code
# Supports: macOS (osascript), Linux (notify-send), Windows (powershell)

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

# Title based on notification type
case "$NOTIFICATION_TYPE" in
    permission_prompt)
        TITLE="Claude Code - Permission Required"
        ;;
    idle_prompt)
        TITLE="Claude Code - Waiting"
        ;;
    elicitation_dialog)
        TITLE="Claude Code - Input Needed"
        ;;
    *)
        TITLE="Claude Code"
        ;;
esac

# Platform-specific notification
case "$OSTYPE" in
    darwin*)
        # macOS - use osascript
        osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\" sound name \"Glass\"" 2>/dev/null || true
        ;;
    linux-gnu*|linux*)
        # Linux - try notify-send (common on GNOME/KDE)
        if command -v notify-send &>/dev/null; then
            notify-send "$TITLE" "$MESSAGE" 2>/dev/null || true
        elif command -v kdialog &>/dev/null; then
            kdialog --passivepopup "$MESSAGE" 5 --title "$TITLE" 2>/dev/null || true
        fi
        ;;
    msys*|cygwin*|mingw*)
        # Windows (Git Bash, Cygwin, etc.) - use PowerShell
        powershell.exe -Command "[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); [System.Windows.Forms.MessageBox]::Show('$MESSAGE', '$TITLE')" 2>/dev/null || true
        ;;
    *)
        # Fallback: just beep
        printf '\a'
        ;;
esac

exit 0
