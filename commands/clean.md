---
description: Diagnose slow Claude Code startup and guide cleanup
argument-hint: "[scan | fix <action>] [--confirm] [--days N]"
allowed-tools: Bash(python3:*), Bash(du:*), Bash(stat:*), Read, AskUserQuestion
---

# Clean

Diagnose and fix slow Claude Code startup.

## Context

!`du -sh ~/.claude 2>/dev/null || echo "~/.claude not found"`
!`stat -f%z ~/.claude.json 2>/dev/null | awk '{printf "%.1fKB", $1/1024}' || echo "no .claude.json"`

## Workflow

See @bluera-base/skills/claude-cleaner/SKILL.md for complete workflow.

**Modes:**

- `/clean` - Interactive diagnosis and guided cleanup (default)
- `/clean scan` - Read-only scan, no changes
- `/clean fix <action>` - Non-interactive single action

**Safety:** Dry-run default. Backups before destructive actions. Double-confirm for data deletion.
