---
name: claude-code-disk
description: View disk usage and clean up ~/.claude/ storage. Use /bluera-base:claude-code-disk to run.
---

# Claude Code Disk

View disk usage and clean up `~/.claude/` storage. Shows a visual breakdown by default; use `--clean` for interactive cleanup wizard.

## GLOBAL IMPACT WARNING

**This command modifies `~/.claude` - Claude Code's configuration directory.**

| Risk | Consequence |
|------|-------------|
| **Kills running plugins** | Clearing cache invalidates all cached plugins MID-SESSION |
| **Global scope** | Changes affect EVERY project, not just the current one |
| **Can corrupt config** | Bad writes to settings.json can break Claude entirely |

### EXCLUDED FROM TEST-PLUGIN

This command is excluded from automated testing because it modifies `~/.claude`.

## Command Syntax

```text
/disk [--clean] [--json] [--days N] [--confirm]
      [--include <action>] [--exclude <action>]
      [--backups] [--restore <timestamp>]
```

| Flag | Description |
|------|-------------|
| (no flags) | Show disk usage chart (default) |
| `--clean` | Interactive cleanup wizard |
| `--json` | Output JSON for scripting |
| `--days N` | Set age threshold for old sessions/logs (default: 30) |
| `--confirm` | Skip confirmation prompts (use with `--clean`) |
| `--include <action>` | Clean only specific action(s) |
| `--exclude <action>` | Skip specific action(s) |
| `--backups` | List available backups |
| `--restore <ts>` | Restore from backup timestamp |

## Default: Disk Usage Chart

Running `/disk` without arguments shows:

```text
~/.claude/ Disk Usage (20.1 GB)
══════════════════════════════════════════════════════════════

plugins/cache     ████████████████████████████████████  19.0 GB (95%)
  └─ bluera-knowledge (29 versions)                    18.9 GB
  └─ bluera-base (12 versions)                           43 MB
  └─ other                                               10 MB

projects/         ██                                     755 MB (4%)
  └─ active (17 dirs)                                   755 MB
  └─ orphaned (0 dirs)                                    0 MB

other/            ░                                      350 MB (2%)
  └─ telemetry, debug, cache, plans, tasks

══════════════════════════════════════════════════════════════
Recommendations:
  • DELETE-old-plugin-versions: Keep only latest, free ~18 GB
  • Run `/disk --clean` for interactive cleanup
```

### Implementation

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/cc-disk-scan.py"
```

Parse output and present the chart to the user. If `--json` flag is present:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/cc-disk-scan.py" --json
```

## Available Actions

| Action | Safety | Description |
|--------|--------|-------------|
| `DELETE-cache-dirs` | SAFE | Clear debug, shell-snapshots, paste-cache, todos, session-env |
| `DELETE-debug-logs` | SAFE | Delete debug log files older than N days |
| `set-cleanup-period` | SAFE | Set auto-cleanup period in settings.json |
| `DELETE-old-plugin-versions` | CAUTION | Keep only latest version of each plugin |
| `DELETE-plugin-cache` | CAUTION | Remove all plugin cache (plugins re-download) |
| `disable-nonessential` | CAUTION | Set CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1 |
| `DELETE-orphaned-projects` | DESTRUCTIVE | Remove project data for paths that no longer exist |
| `DELETE-old-sessions` | DESTRUCTIVE | Delete session files older than N days |
| `DELETE-auth-config` | DESTRUCTIVE | Backup and disable ~/.claude.json (requires re-login) |

### Risk Levels

| Level | Meaning |
|-------|---------|
| **SAFE** | No risk of data loss, directories recreated empty |
| **CAUTION** | May affect running session (plugins break mid-session) |
| **DESTRUCTIVE** | Deletes user data (creates backup first) |

## Interactive Cleanup (`--clean`)

### Step 1: Run Scan

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/cc-disk-scan.py" --json
```

### Step 2: Show Findings and Ask User

Use `AskUserQuestion` with `multiSelect: true`:

```text
Header: "Select Cleanup"
Question: "Which items do you want to clean? (Backups created for destructive actions)"
Options:
  - "DELETE-cache-dirs (5.4 MB) - shell-snapshots, paste-cache, etc."
  - "DELETE-debug-logs (714 MB) - logs older than 14 days"
  - "DELETE-old-plugin-versions (18.9 GB) - keep only latest versions"
  - "DELETE-orphaned-projects (2.8 GB) - 36 dirs for paths that don't exist"
  - "DELETE-old-sessions (1.4 GB) - sessions older than 30 days"
```

### Step 3: Preview Selected Actions

For each selected action, run preview:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/cc-disk-fix.py" <action> --json
```

Show user the files that will be affected, sizes, and backup location.

### Step 4: Final Confirmation

Use `AskUserQuestion`:

```text
Header: "Confirm"
Question: "Delete 22.4 GB across 3 actions? Backup will be created first."
Options:
  - "Yes, backup and delete"
  - "No, cancel"
```

### Step 5: Execute

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/cc-disk-fix.py" <action> --confirm --json
```

Report: files deleted, size freed, backup path, restore command.

## Specific Action (`--include`)

To clean specific items without the wizard:

```bash
# Preview
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/cc-disk-fix.py" DELETE-cache-dirs --json

# Show preview to user via AskUserQuestion, then execute:
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/cc-disk-fix.py" DELETE-cache-dirs --confirm --json
```

If `--confirm` flag was passed to `/disk`, skip the AskUserQuestion.

## Backup Management

All destructive operations create timestamped backups in `~/.claude-backups/`:

```text
~/.claude-backups/
├── 2026-02-04T18-30-00/
│   ├── manifest.json          # What was backed up
│   ├── projects.tgz           # If sessions were cleaned
│   └── deleted-plugins.json   # List of removed plugins
├── latest -> 2026-02-04T18-30-00/
```

### List Backups (`--backups`)

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/cc-disk-fix.py" list-backups --json
```

### Restore (`--restore`)

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/cc-disk-fix.py" restore-backup --timestamp <ts>
```

## Cache Directories

These directories are safe to delete and will be recreated empty:

| Directory | Purpose |
|-----------|---------|
| `~/.claude/debug/` | Debug logs |
| `~/.claude/shell-snapshots/` | Shell state snapshots |
| `~/.claude/paste-cache/` | Clipboard cache |
| `~/.claude/todos/` | Task lists |
| `~/.claude/session-env/` | Session environment |

## Orphaned Projects Detection

Project directories are named like `-Users-chris-repos-foo`. The script converts this back to a path (`/Users/chris/repos/foo`) and checks if that path still exists. If not, the project is orphaned.

## Old Plugin Versions Detection

Plugin cache structure: `~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/`

The script keeps only the highest semver version per plugin and marks older versions for deletion.

## Typical Sizes

| Path | Normal | Concerning | Critical |
|------|--------|------------|----------|
| `~/.claude` total | <1GB | >5GB | >20GB |
| `plugins/cache` | <100MB | >1GB | >10GB |
| `projects/` | <500MB | >2GB | >10GB |
| `~/.claude.json` | <100KB | >5MB | >100MB |

## File Locations

```text
~/.claude/                    # Main config directory
├── settings.json             # User settings
├── plugins/cache/            # Plugin cache (safe to delete)
├── projects/                 # Session files per project
├── debug/                    # Debug logs
├── shell-snapshots/          # Shell state
├── paste-cache/              # Clipboard cache
├── todos/                    # Task lists
├── session-env/              # Session environment
└── CLAUDE.md                 # User's global memory file

~/.claude.json                # Authentication & history

~/.claude-backups/            # Centralized backup location
```

## Environment Variables

- `CLAUDE_CONFIG_DIR`: Override `~/.claude` location
- `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`: Disable telemetry
