---
description: Diagnose slow Claude Code startup and guide cleanup
argument-hint: "[scan | fix <action> | backups <list|restore>] [--days N]"
allowed-tools: Bash(python3:*), Bash(du:*), Bash(stat:*), Read, AskUserQuestion
---

# Clean

> ## GLOBAL IMPACT WARNING
>
> **This command modifies `~/.claude` - Claude Code's configuration directory.**
>
> - **AFFECTS ALL PROJECTS** - Changes are global, not project-scoped
> - **CAN BREAK CLAUDE** - Clearing plugin cache kills running plugins mid-session
> - **NOT TESTABLE** - Excluded from `/test-plugin` because it's too dangerous
>
> All backups go to: `~/.claude-backups/`

Diagnose and fix slow Claude Code startup.

## Context

!`du -sh ~/.claude 2>/dev/null || echo "~/.claude not found"`
!`(stat -f%z ~/.claude.json 2>/dev/null || stat -c%s ~/.claude.json 2>/dev/null) | awk '{printf "%.1fKB", $1/1024}' || echo "no .claude.json"`

## Workflow

See @bluera-base/skills/claude-cleaner/SKILL.md for complete workflow.

**Modes:**

- `/clean` - Interactive wizard: scan, show findings, select actions, confirm, execute
- `/clean scan` - Read-only scan, no changes
- `/clean fix <action>` - Single action with preview and confirmation
- `/clean backups list` - List available backups
- `/clean backups restore <timestamp>` - Restore from backup

**Actions:** DELETE-auth-config, DELETE-plugin-cache, DELETE-old-sessions, DELETE-debug-logs, disable-nonessential, set-cleanup-period

## CRITICAL SAFETY RULES

1. **ALWAYS use AskUserQuestion before ANY destructive action**
   - Show exactly what files will be affected with paths and sizes
   - Show where backup will be created
   - Get explicit "Yes, delete" confirmation

2. **NEVER run --confirm without user approval**
   - First run without --confirm to get preview
   - Show preview to user via AskUserQuestion
   - Only run with --confirm AFTER user explicitly confirms

3. **ALWAYS verify backup exists before proceeding**
   - Check backup directory was created
   - Show backup path to user in confirmation

## Workflow Example

```text
User: /clean fix DELETE-plugin-cache

Step 1: Run preview (no --confirm)
  python3 "${CLAUDE_PLUGIN_ROOT}/scripts/cc-cleaner-fix.py" DELETE-plugin-cache

Step 2: Present results to user via AskUserQuestion
  "Delete 12 plugins (2.1 GB)? Backup will be created at ~/.claude-backups/..."
  Options: "Yes, delete" / "No, cancel"

Step 3: Only if user confirms, run with --confirm
  python3 "${CLAUDE_PLUGIN_ROOT}/scripts/cc-cleaner-fix.py" DELETE-plugin-cache --confirm

Step 4: Show results and backup location
```
