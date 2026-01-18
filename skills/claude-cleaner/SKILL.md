---
name: claude-cleaner
description: Diagnose slow Claude Code startup and guide cleanup. Use /bluera-base:clean to run.
---

# Claude Code Cleaner

Diagnose and fix slow Claude Code startup caused by accumulated configuration files.

## ⛔ DANGER ZONE - READ THIS FIRST

**This command modifies `~/.claude` - Claude Code's own brain.**

### Why This Is Dangerous

| Risk | Consequence |
|------|-------------|
| **Kills running plugins** | Clearing cache invalidates all cached plugins MID-SESSION. Hooks stop working immediately. |
| **Global scope** | Changes affect EVERY project, not just the current one |
| **Can corrupt config** | Bad writes to settings.json or .claude.json can break Claude entirely |
| **No undo** | Some actions are irreversible without restoring from backup |

### EXCLUDED FROM TEST-PLUGIN

**DO NOT** test this command via `/test-plugin`. It is explicitly excluded because:

- Running it automatically could destroy the session running the tests
- There's no safe way to test "delete 30GB of files" in CI

### Mandatory Safety Protocol

1. **NEVER** run `--confirm` without explicit user approval via AskUserQuestion
2. **ALWAYS** run `scan` or dry-run first to preview changes
3. **ALWAYS** show the user what will be deleted/modified before doing it
4. **ALWAYS** report backup location and rollback instructions after destructive actions

## When to Use

- Claude Code takes a long time to start
- Disk space is low due to `~/.claude` growth
- Performance degrades over time
- Error messages about Grove timeout or PowerShell

## Modes

| Mode | Purpose |
|------|---------|
| `/clean` | Interactive diagnosis and guided cleanup (default) |
| `/clean scan` | Read-only scan, no changes |
| `/clean fix <action>` | Non-interactive single action |

## Interactive Workflow (`/clean`)

### Step 1: Before Snapshot

Record initial sizes for comparison:

```bash
du -sk ~/.claude 2>/dev/null | awk '{print $1 * 1024}'
stat -f%z ~/.claude.json 2>/dev/null || echo 0
```

### Step 2: Run Scan

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/cc-cleaner-scan.py" --json
```

Parse the JSON output to get findings and recommended actions.

### Step 3: Display Results

Show the user:

- Total `~/.claude` size
- `~/.claude.json` size
- Findings table with risk levels
- Recommended actions

### Step 4: Present Options

Use AskUserQuestion to let user select which actions to take based on findings.

### Step 5: Execute Selected Actions

For SAFE actions:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/cc-cleaner-fix.py" <action> --confirm --verbose
```

For DESTRUCTIVE actions, require second confirmation via AskUserQuestion.

### Step 6: After Snapshot

Record final sizes and report the difference (before → after, saved X MB).

## Scan Mode (`/clean scan`)

Read-only scan that makes no changes:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/cc-cleaner-scan.py" $ARGUMENTS
```

If issues found, suggest `/clean` for interactive cleanup or `/clean fix <action>` for specific fixes.

## Fix Mode (`/clean fix <action>`)

Non-interactive single action:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/cc-cleaner-fix.py" <action> $ARGUMENTS
```

### Available Actions

| Action | Safety | Description |
|--------|--------|-------------|
| `clear-plugin-cache` | SAFE | Remove plugin cache (regenerates on startup) |
| `set-cleanup-period` | SAFE | Set auto-cleanup period in settings.json |
| `prune-debug-logs` | SAFE | Delete old debug log files |
| `prune-sessions` | DESTRUCTIVE | Delete old session files (creates backup first) |
| `reset-claude-json` | DESTRUCTIVE | Backup and move aside ~/.claude.json |
| `disable-nonessential` | CAUTION | Set CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1 |

## Common Issues

### Plugin Cache Regression (29GB+ common)

**Symptoms**: Massive `~/.claude/plugins/cache` directory

**Cause**: Plugin cache not being cleaned up properly

**Fix**: `clear-plugin-cache` - cache regenerates on next startup

### Projects Directory Bloat

**Symptoms**: Large `~/.claude/projects` with thousands of files

**Cause**: Session files accumulate over time

**Fix**:

- `set-cleanup-period --days 7` - auto-delete old sessions
- `prune-sessions --days 30` - manual cleanup

### Large ~/.claude.json

**Symptoms**: `~/.claude.json` grows to MB/GB

**Cause**: Authentication history accumulates

**Fix**: `reset-claude-json` - backup and reset (requires re-auth)

### Grove Timeout Errors

**Symptoms**: Debug logs show "Grove notice config" timeout

**Cause**: Network configuration issues with Grove service

**Fix**: `disable-nonessential` - disable non-essential network traffic

## Risk Levels

| Level | Meaning | Example Actions |
|-------|---------|-----------------|
| **SAFE** | No risk of data loss | clear-plugin-cache, set-cleanup-period |
| **CAUTION** | May change behavior | disable-nonessential |
| **DESTRUCTIVE** | Can delete data | prune-sessions, reset-claude-json |

## Safety Guarantees

1. **Dry-run default**: Preview changes before applying (`--confirm` required)
2. **Timestamped backups**: Created before destructive actions
3. **Rollback commands**: Provided for reversing changes
4. **Double confirmation**: Required for destructive actions in interactive mode

## Typical Sizes

| Path | Normal | Concerning | Critical |
|------|--------|------------|----------|
| `~/.claude` total | <1GB | >5GB | >20GB |
| `~/.claude.json` | <100KB | >5MB | >100MB |
| `plugins/cache` | <100MB | >1GB | >10GB |
| `projects/` | <500MB | >2GB | >10GB |

## Technical Details

### File Locations

```text
~/.claude/                    # Main config directory
├── settings.json             # User settings
├── plugins/cache/            # Plugin cache (safe to delete)
├── projects/                 # Session files per project
├── debug/                    # Debug logs
└── CLAUDE.md                 # User's global memory file

~/.claude.json                # Authentication & history
```

### Environment Variables

- `CLAUDE_CONFIG_DIR`: Override `~/.claude` location
- `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`: Disable telemetry

### Cross-Platform Notes

- **macOS**: Uses `stat -f%z` for file sizes
- **Linux**: Uses `stat -c%s` for file sizes
- **WSL**: Linux tools with Windows filesystem
