---
description: Claude Code Cleaner - diagnose slow startup and guide cleanup
argument-hint: "[--verbose] [--dry-run]"
allowed-tools: Bash(python3:*), Bash(ls:*), Bash(stat:*), Bash(du:*), Bash(find:*), Bash(cp:*), Bash(mv:*), Bash(rm:*), Bash(tar:*), Bash(uname:*), Read, Write, Edit, AskUserQuestion
---

# Claude Code Cleaner

Interactive diagnosis and cleanup of Claude Code configuration files.

## What This Command Does

1. **Before snapshot**: Record total size of `~/.claude` and `~/.claude.json`
2. **Scan**: Detect issues that cause slow startup
3. **Display**: Show findings ranked by risk level
4. **Guide**: Present cleanup options via AskUserQuestion
5. **Execute**: Apply selected fixes (with confirmation for destructive actions)
6. **After snapshot**: Report size change (saved X MB)

## Instructions

### Step 1: Before Snapshot

Record initial sizes for comparison:

```bash
# Get ~/.claude total size
du -sk ~/.claude 2>/dev/null | awk '{print $1 * 1024}'

# Get ~/.claude.json size (if exists)
stat -f%z ~/.claude.json 2>/dev/null || echo 0
```

Store these values for the "after" comparison.

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

Use AskUserQuestion to let user select which actions to take:

```text
Which cleanup actions would you like to perform?

Options based on findings:
- Clear plugin cache (SAFE) - frees X GB
- Prune old sessions (DESTRUCTIVE) - frees X MB
- Set auto-cleanup period (SAFE)
- Skip / Exit
```

### Step 5: Execute Selected Actions

For SAFE actions:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/cc-cleaner-fix.py" <action> --confirm --verbose
```

For DESTRUCTIVE actions, require second confirmation via AskUserQuestion:

- Explain what will be deleted
- Mention backup will be created
- Only proceed with explicit "Yes" confirmation

### Step 6: After Snapshot

Record final sizes:

```bash
du -sk ~/.claude 2>/dev/null | awk '{print $1 * 1024}'
stat -f%z ~/.claude.json 2>/dev/null || echo 0
```

Report the difference:

```text
Cleanup complete!
Before: 32.8 GB
After:  3.0 GB
Saved:  29.8 GB
```

## Safety Rules

1. **Always preview first** - Show what will happen before executing
2. **Backup destructive actions** - Backups are created automatically
3. **Double-confirm destructive** - Use AskUserQuestion twice for DESTRUCTIVE actions
4. **Report rollback command** - Tell user how to undo if needed

## Known Issues Reference

This cleaner addresses issues from:

- Plugin cache regression (29GB+ common)
- Old session file accumulation
- Large ~/.claude.json (auth history bloat)
- WSL PowerShell detection issues
- Grove timeout configuration errors

## Example Session

```text
$ /bluera-base:clean

Claude Code Cleaner
===================

Scanning ~/.claude...

Total size: 32.8 GB
~/.claude.json: 108 KB

Findings:
┌─────────┬────────────────────────────────────────────┐
│ HIGH    │ Plugin cache: 29.8 GB (1.3M files)         │
│ HIGH    │ Projects dir: 2.1 GB (14K files)           │
└─────────┴────────────────────────────────────────────┘

[AskUserQuestion: Select cleanup actions]

Executing: clear-plugin-cache...
✓ Cleared 29.8 GB from plugin cache

Cleanup complete!
Before: 32.8 GB
After:  3.0 GB
Saved:  29.8 GB
```
