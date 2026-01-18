---
description: Configure Claude Code's terminal status line display
allowed-tools: Bash(git:*), Bash(jq:*), Bash(cat:*), Bash(mkdir:*), Read, Write, Edit, AskUserQuestion
argument-hint: "[show|preset [name]|custom|reset]"
---

# Status Line Configuration

Manage Claude Code's status line display.

## Subcommands

| Command | Description |
|---------|-------------|
| `statusline` or `statusline show` | Display current configuration |
| `statusline preset` | Preview all presets, let user select |
| `statusline preset <name>` | Apply preset directly (minimal, informative, developer, system, bluera) |
| `statusline custom` | Interactive custom configuration |
| `statusline reset` | Reset to Claude Code defaults |

## Workflow

See @bluera-base/skills/statusline/SKILL.md for complete workflow.

**Preset mode:**

- `statusline preset` (no name) → Show preview table of all presets, use AskUserQuestion to select
- `statusline preset <name>` → Apply the named preset directly by copying the ready-to-use script
