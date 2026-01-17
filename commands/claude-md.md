---
description: Audit and maintain CLAUDE.md memory files
argument-hint: <audit|init|learn> [options]
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(git:*), Bash(ls:*), AskUserQuestion
---

# CLAUDE.md Maintainer

Audit and maintain `CLAUDE.md` files in this repository.

## Subcommands

| Command | Description |
|---------|-------------|
| `claude-md` or `claude-md audit` | Validate existing CLAUDE.md files |
| `claude-md init` | Create new CLAUDE.md via auto-detection + interview |
| `claude-md learn "<text>"` | Add a learning to auto-managed section |

## Workflow

See @bluera-base/skills/claude-md-maintainer/SKILL.md for complete workflow including validation rules and templates.
