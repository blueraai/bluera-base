---
description: Apply a specific cleanup action non-interactively
argument-hint: "<action> [--confirm] [--days N]"
allowed-tools: Bash(python3:*), Bash(cp:*), Bash(mv:*), Bash(rm:*), Bash(tar:*), Read
---

# Claude Code Cleaner - Fix

Apply a specific cleanup action without interactive prompts.

## What This Command Does

1. Executes a single cleanup action
2. Default: dry-run mode (shows what would happen)
3. With `--confirm`: actually executes the action
4. Creates timestamped backups before destructive operations

## Usage

```bash
# Dry-run (preview only)
/bluera-base:clean-fix clear-plugin-cache
/bluera-base:clean-fix prune-sessions --days 30

# Actually execute
/bluera-base:clean-fix clear-plugin-cache --confirm
/bluera-base:clean-fix prune-sessions --days 30 --confirm
```

## Available Actions

| Action | Safety | Description |
|--------|--------|-------------|
| `clear-plugin-cache` | SAFE | Remove plugin cache (regenerates on startup) |
| `set-cleanup-period` | SAFE | Set auto-cleanup period in settings.json |
| `prune-debug-logs` | SAFE | Delete old debug log files |
| `prune-sessions` | DESTRUCTIVE | Delete old session files (creates backup first) |
| `reset-claude-json` | DESTRUCTIVE | Backup and move aside ~/.claude.json |
| `disable-nonessential` | CAUTION | Set CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1 |

## Instructions

Run the fix script from the plugin directory:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/cc-cleaner-fix.py" $ARGUMENTS
```

**IMPORTANT**:

- Always run without `--confirm` first to preview changes
- For DESTRUCTIVE actions, warn the user about data loss
- Report the backup location and rollback command if provided

## Safety Levels

| Level | Meaning |
|-------|---------|
| **SAFE** | No risk of data loss, fully reversible |
| **CAUTION** | May change behavior, review before applying |
| **DESTRUCTIVE** | Can delete data, backup created automatically |

## Examples

### Clear plugin cache (29GB+ common issue)

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/cc-cleaner-fix.py" clear-plugin-cache --confirm --verbose
```

### Prune old sessions (older than 30 days)

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/cc-cleaner-fix.py" prune-sessions --days 30 --confirm --verbose
```

### Set automatic cleanup period

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/cc-cleaner-fix.py" set-cleanup-period --days 7 --confirm
```
