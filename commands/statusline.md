---
description: Configure Claude Code's terminal status line display
allowed-tools: Bash(git:*), Bash(jq:*), Bash(cat:*), Bash(mkdir:*), Read, Write, Edit, AskUserQuestion
argument-hint: [show|preset|custom|reset]
---

# Status Line Configuration

Manage Claude Code's status line display.

## Subcommands

| Command | Description |
|---------|-------------|
| `statusline` or `statusline show` | Display current configuration |
| `statusline preset <name>` | Apply preset (minimal, informative, developer, system) |
| `statusline custom` | Interactive custom configuration |
| `statusline reset` | Reset to Claude Code defaults |

## Workflow

See @bluera-base/skills/statusline/SKILL.md for complete workflow including presets, format strings, and barista integration.
