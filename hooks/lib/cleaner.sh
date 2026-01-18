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

# =============================================================================
# CENTRALIZED BACKUP SYSTEM
# All backups go to ~/.claude-backups/TIMESTAMP/
# =============================================================================

CLEANER_BACKUP_ROOT="$HOME/.claude-backups"

# Get the backup root directory
cleaner_backup_root() {
    echo "$CLEANER_BACKUP_ROOT"
}

# Create a new backup directory with timestamp, return its path
cleaner_backup_dir() {
    local timestamp
    timestamp=$(date +%Y-%m-%dT%H-%M-%S)
    local backup_dir="$CLEANER_BACKUP_ROOT/$timestamp"

    mkdir -p "$backup_dir"

    # Update 'latest' symlink
    rm -f "$CLEANER_BACKUP_ROOT/latest"
    ln -sf "$timestamp" "$CLEANER_BACKUP_ROOT/latest"

    echo "$backup_dir"
}

# Create manifest.json in backup directory
# Usage: cleaner_create_manifest <backup_dir> <action> <description>
cleaner_create_manifest() {
    local backup_dir="$1"
    local action="$2"
    local description="${3:-}"

    cat > "$backup_dir/manifest.json" <<EOF
{
  "created": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "action": "$action",
  "description": "$description",
  "hostname": "$(hostname)",
  "user": "$(whoami)",
  "files": []
}
EOF
}

# Add file entry to manifest
# Usage: cleaner_manifest_add_file <backup_dir> <original_path> <backup_name> <size>
cleaner_manifest_add_file() {
    local backup_dir="$1"
    local original_path="$2"
    local backup_name="$3"
    local size="$4"
    local manifest="$backup_dir/manifest.json"

    # Use jq if available, otherwise basic append
    if command -v jq &>/dev/null; then
        local tmp
        tmp=$(mktemp)
        jq --arg path "$original_path" --arg name "$backup_name" --arg size "$size" \
           '.files += [{"original": $path, "backup": $name, "size": ($size | tonumber)}]' \
           "$manifest" > "$tmp" && mv "$tmp" "$manifest"
    fi
}

# Backup a single file to the backup directory
# Usage: cleaner_backup_file <backup_dir> <source_path> [backup_name]
cleaner_backup_file() {
    local backup_dir="$1"
    local source_path="$2"
    local backup_name="${3:-$(basename "$source_path")}"

    if [[ ! -e "$source_path" ]]; then
        return 1
    fi

    local size
    size=$(cleaner_file_size "$source_path")

    cp -p "$source_path" "$backup_dir/$backup_name"
    cleaner_manifest_add_file "$backup_dir" "$source_path" "$backup_name" "$size"

    echo "$backup_dir/$backup_name"
}

# Backup a directory as tarball
# Usage: cleaner_backup_dir_tar <backup_dir> <source_dir> <tarball_name>
cleaner_backup_dir_tar() {
    local backup_dir="$1"
    local source_dir="$2"
    local tarball_name="$3"

    if [[ ! -d "$source_dir" ]]; then
        return 1
    fi

    local size
    size=$(cleaner_dir_size "$source_dir")

    tar -czf "$backup_dir/$tarball_name" -C "$(dirname "$source_dir")" "$(basename "$source_dir")" 2>/dev/null
    cleaner_manifest_add_file "$backup_dir" "$source_dir" "$tarball_name" "$size"

    echo "$backup_dir/$tarball_name"
}

# List all available backups
cleaner_list_backups() {
    local backup_root
    backup_root=$(cleaner_backup_root)

    if [[ ! -d "$backup_root" ]]; then
        echo "No backups found."
        return
    fi

    echo "Available backups in $backup_root:"
    echo ""

    for dir in "$backup_root"/20*; do
        if [[ -d "$dir" && -f "$dir/manifest.json" ]]; then
            local timestamp
            timestamp=$(basename "$dir")
            local action=""
            local description=""

            if command -v jq &>/dev/null; then
                action=$(jq -r '.action // "unknown"' "$dir/manifest.json" 2>/dev/null)
                description=$(jq -r '.description // ""' "$dir/manifest.json" 2>/dev/null)
            fi

            local size
            size=$(cleaner_dir_size "$dir")

            echo "  $timestamp - $action ($(cleaner_format_size "$size"))"
            if [[ -n "$description" ]]; then
                echo "    $description"
            fi
        fi
    done
}

# Restore from a backup
# Usage: cleaner_restore_backup <timestamp>
cleaner_restore_backup() {
    local timestamp="$1"
    local backup_root
    backup_root=$(cleaner_backup_root)
    local backup_dir="$backup_root/$timestamp"

    if [[ ! -d "$backup_dir" ]]; then
        echo "ERROR: Backup not found: $backup_dir"
        return 1
    fi

    if [[ ! -f "$backup_dir/manifest.json" ]]; then
        echo "ERROR: No manifest found in backup"
        return 1
    fi

    echo "Restoring from $backup_dir..."

    # Read manifest and restore files
    if command -v jq &>/dev/null; then
        local files
        files=$(jq -r '.files[] | "\(.original)|\(.backup)"' "$backup_dir/manifest.json" 2>/dev/null)

        while IFS='|' read -r original backup; do
            if [[ -n "$original" && -n "$backup" ]]; then
                local backup_path="$backup_dir/$backup"

                if [[ "$backup" == *.tgz || "$backup" == *.tar.gz ]]; then
                    # Extract tarball to parent of original
                    echo "  Restoring directory: $original"
                    tar -xzf "$backup_path" -C "$(dirname "$original")" 2>/dev/null
                elif [[ -f "$backup_path" ]]; then
                    echo "  Restoring file: $original"
                    cp -p "$backup_path" "$original"
                fi
            fi
        done <<< "$files"
    else
        echo "ERROR: jq required for restore"
        return 1
    fi

    echo "Restore complete."
}

# Legacy backup function (for compatibility)
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
