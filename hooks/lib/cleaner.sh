#!/usr/bin/env bash
# Claude Code Cleaner - Bash Library
#
# Cross-platform utilities for *nix/macOS/WSL
#
# Usage:
#   source "${CLAUDE_PLUGIN_ROOT}/hooks/lib/cleaner.sh"
#   size=$(cleaner_file_size "/path/to/file")

set -euo pipefail

# Resolve ~/.claude or $CLAUDE_CONFIG_DIR
cleaner_claude_dir() {
    if [[ -n "${CLAUDE_CONFIG_DIR:-}" ]]; then
        echo "$CLAUDE_CONFIG_DIR"
    else
        echo "$HOME/.claude"
    fi
}

# Detect WSL environment
cleaner_is_wsl() {
    if [[ -f /proc/version ]]; then
        grep -qi microsoft /proc/version 2>/dev/null && return 0
    fi
    return 1
}

# Detect OS type
cleaner_os_type() {
    case "$(uname -s)" in
        Darwin) echo "macos" ;;
        Linux)
            if cleaner_is_wsl; then
                echo "wsl"
            else
                echo "linux"
            fi
            ;;
        MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
        *) echo "unknown" ;;
    esac
}

# Get file size in bytes (cross-platform)
cleaner_file_size() {
    local path="$1"

    if [[ ! -e "$path" ]]; then
        echo 0
        return
    fi

    case "$(uname -s)" in
        Darwin)
            # macOS: stat -f%z
            stat -f%z "$path" 2>/dev/null || echo 0
            ;;
        *)
            # Linux/WSL: stat -c%s
            stat -c%s "$path" 2>/dev/null || echo 0
            ;;
    esac
}

# Get directory size in bytes (cross-platform)
cleaner_dir_size() {
    local path="$1"

    if [[ ! -d "$path" ]]; then
        echo 0
        return
    fi

    case "$(uname -s)" in
        Darwin)
            # macOS: du -sk outputs KB, convert to bytes
            du -sk "$path" 2>/dev/null | awk '{print $1 * 1024}'
            ;;
        *)
            # Linux/WSL: du -sb outputs bytes directly
            du -sb "$path" 2>/dev/null | awk '{print $1}'
            ;;
    esac
}

# Format bytes as human-readable string
cleaner_format_size() {
    local bytes="$1"

    if (( bytes >= 1073741824 )); then
        awk "BEGIN {printf \"%.1fGB\", $bytes / 1073741824}"
    elif (( bytes >= 1048576 )); then
        awk "BEGIN {printf \"%.1fMB\", $bytes / 1048576}"
    elif (( bytes >= 1024 )); then
        awk "BEGIN {printf \"%.1fKB\", $bytes / 1024}"
    else
        echo "${bytes}B"
    fi
}

# Create timestamped backup with preserved permissions
cleaner_backup() {
    local path="$1"
    local timestamp
    timestamp=$(date +%Y%m%d%H%M%S)
    local backup_path="${path}.bak.${timestamp}"

    if [[ -e "$path" ]]; then
        cp -p "$path" "$backup_path"
        echo "$backup_path"
    fi
}

# Take a snapshot of key sizes for before/after comparison
# Returns JSON-like output
cleaner_snapshot() {
    local claude_dir
    claude_dir=$(cleaner_claude_dir)

    local claude_json="$HOME/.claude.json"
    local claude_json_size=0
    local claude_dir_size=0

    if [[ -f "$claude_json" ]]; then
        claude_json_size=$(cleaner_file_size "$claude_json")
    fi

    if [[ -d "$claude_dir" ]]; then
        claude_dir_size=$(cleaner_dir_size "$claude_dir")
    fi

    cat <<EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "claude_json_size": $claude_json_size,
  "claude_dir_size": $claude_dir_size,
  "claude_json_size_human": "$(cleaner_format_size "$claude_json_size")",
  "claude_dir_size_human": "$(cleaner_format_size "$claude_dir_size")"
}
EOF
}

# Compare two snapshots and report difference
cleaner_compare_snapshots() {
    local before_dir_size="$1"
    local after_dir_size="$2"

    local diff=$((before_dir_size - after_dir_size))

    if (( diff > 0 )); then
        echo "Saved: $(cleaner_format_size "$diff")"
    elif (( diff < 0 )); then
        echo "Added: $(cleaner_format_size "${diff#-}")"
    else
        echo "No change"
    fi
}
