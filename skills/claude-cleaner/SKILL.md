---
trigger: slow startup, claude slow, cleanup, cleaner, ~/.claude size, plugin cache, disk space
---

# Claude Code Cleaner

Diagnose and fix slow Claude Code startup caused by accumulated configuration files.

## When to Use

- Claude Code takes a long time to start
- Disk space is low due to `~/.claude` growth
- Performance degrades over time
- Error messages about Grove timeout or PowerShell

## Commands

| Command | Purpose |
|---------|---------|
| `/bluera-base:clean` | Interactive diagnosis and guided cleanup |
| `/bluera-base:clean-scan` | Read-only scan (no changes) |
| `/bluera-base:clean-fix <action>` | Non-interactive single action |

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

### WSL PowerShell Issues

**Symptoms**: Repeated PowerShell calls in debug logs (WSL only)

**Cause**: Cross-environment detection issues

**Fix**: Environment-specific configuration needed

## Risk Levels

| Level | Meaning | Example Actions |
|-------|---------|-----------------|
| **SAFE** | No risk of data loss | clear-plugin-cache, set-cleanup-period |
| **CAUTION** | May change behavior | disable-nonessential |
| **DESTRUCTIVE** | Can delete data | prune-sessions, reset-claude-json |

## Safety Guarantees

1. **Dry-run default**: Preview changes before applying
2. **Timestamped backups**: Created before destructive actions
3. **Rollback commands**: Provided for reversing changes
4. **Double confirmation**: Required for destructive actions

## Typical Sizes

| Path | Normal | Concerning | Critical |
|------|--------|------------|----------|
| `~/.claude` total | <1GB | >5GB | >20GB |
| `~/.claude.json` | <100KB | >5MB | >100MB |
| `plugins/cache` | <100MB | >1GB | >10GB |
| `projects/` | <500MB | >2GB | >10GB |

## Related GitHub Issues

- Plugin cache regression causing 29GB+ accumulation
- Session cleanup not running on schedule
- Authentication history bloat in .claude.json
- Grove service timeout on startup

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
