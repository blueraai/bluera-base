---
description: Configure Claude Code's terminal status line display
allowed-tools: Bash(git:*), Bash(jq:*), Bash(cat:*), Bash(mkdir:*), Bash(cp:*), Bash(chmod:*), Read, Write, Edit, AskUserQuestion, WebFetch
argument-hint: [show|preset|custom|reset]
---

# Status Line Configuration

Manage Claude Code's status line display at the bottom of your terminal.

## Subcommands

| Command | Description |
|---------|-------------|
| `/bluera-base:statusline` or `/bluera-base:statusline show` | Display current configuration |
| `/bluera-base:statusline preset <name>` | Apply a preset (minimal, informative, developer, system) |
| `/bluera-base:statusline custom` | Interactive custom configuration |
| `/bluera-base:statusline reset` | Reset to Claude Code defaults |

---

## Status Line Types

Claude Code supports three status line types:

### 1. Built-in (default)

```json
{
  "statusLine": "default"
}
```

Shows model, context %, and basic info.

### 2. Custom Static

```json
{
  "statusLine": "🔵 Claude | %model% | %context%"
}
```

Custom text with variable interpolation.

### 3. Command-based

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

Script receives JSON input, outputs status text.

---

## Presets

### Minimal

Static string - lightweight, no script needed.

```json
{
  "statusLine": "%model% | %context%"
}
```

### Informative

Static string with cost display.

```json
{
  "statusLine": "🤖 %model% | 📊 %context% | 💰 %cost%"
}
```

### Developer

Script-based with git integration, project detection, and context awareness.

Theme: `default` | Modules: `directory,model,context,git,project,cost`

### System

Script-based with system monitoring (CPU, memory, docker).

Theme: `default` | Modules: `directory,model,context,git,cpu,memory,docker`

---

## Themes

Five themes available for script-based status lines:

| Theme | Description | Example Status |
|-------|-------------|----------------|
| `default` | Standard emoji | 🟢🟡🔴 📁 📊 🌿 |
| `minimal` | Geometric shapes | ◦○● → ⎇ |
| `vibrant` | Bold emoji | 💚💛❤️ 📂 🎯 🔀 |
| `monochrome` | ASCII only | `[OK][~~][!!]` DIR: CTX: |
| `nerd` | Nerd Font glyphs |    |

---

## Available Modules

### Core Modules

| Module | Description |
|--------|-------------|
| `directory` | Current directory name |
| `model` | Claude model display name |
| `context` | Context window usage with status indicator |
| `git` | Branch name and dirty/staged status |
| `cost` | Session cost in USD |
| `rate-limits` | 5h/7d API usage via OAuth |
| `project` | Project type detection (Rust, Go, Python, Node, etc.) |
| `lines-changed` | Lines added/removed (via git diff) |

### System Modules

| Module | Description |
|--------|-------------|
| `battery` | Battery % with charging indicator (macOS) |
| `cpu` | CPU usage percentage |
| `memory` | RAM usage percentage |
| `docker` | Running container count |

### Extra Modules

| Module | Description |
|--------|-------------|
| `time` | Current time/date |
| `cca-status` | Claude Code Anywhere status |

---

## Display Modes

| Mode | Description |
|------|-------------|
| `normal` | Standard display with all elements |
| `compact` | Shortened output, fewer separators |
| `verbose` | Full detail with progress bars |

---

## Algorithm

### Show (default)

1. Read `~/.claude/settings.json`
2. Extract statusLine configuration
3. Display current type and settings
4. If command-based, show script path and check if exists

### Preset

Arguments: `<preset-name>` (minimal, informative, developer, system)

1. Validate preset exists
2. For script-based presets (developer, system):
   - Read skill for module implementations
   - Generate `~/.claude/statusline.sh` with selected theme and modules
   - Make executable
3. For static presets (minimal, informative):
   - Set static string directly
4. Update `~/.claude/settings.json`
5. Report changes

### Custom

Interactive workflow:

1. Ask: Built-in, static text, or script-based?
2. If static: Ask for format string
3. If script:
   a. Select theme (default, minimal, vibrant, monochrome, nerd)
   b. Select modules (multi-select from available list)
   c. Select display mode (normal, compact, verbose)
4. Generate configuration
5. If existing script has custom sections, preserve them
6. Preview before applying
7. Update settings

### Reset

1. Remove custom script if exists
2. Set statusLine to "default"
3. Confirm changes

---

## Available Variables

For static status lines:

| Variable | Description |
|----------|-------------|
| `%model%` | Current Claude model |
| `%context%` | Context usage percentage |
| `%cost%` | Session cost (USD) |

For command-based, input JSON includes:

```json
{
  "workspace": {
    "current_dir": "/path/to/project"
  },
  "model": {
    "display_name": "Claude Opus 4.5",
    "model_id": "claude-opus-4-5-20251101"
  },
  "context_window": {
    "context_window_size": 200000,
    "used_percentage": 45,
    "remaining_percentage": 55,
    "current_usage": { "input_tokens": 90000 }
  },
  "total_cost_usd": 2.50
}
```

---

## Examples

```bash
# Show current config
/bluera-base:statusline show

# Apply minimal preset (static)
/bluera-base:statusline preset minimal

# Apply developer preset (script-based)
/bluera-base:statusline preset developer

# Apply system monitoring preset
/bluera-base:statusline preset system

# Interactive custom setup
/bluera-base:statusline custom

# Reset to defaults
/bluera-base:statusline reset
```

---

## Script Template

For custom scripts, use this template:

```bash
#!/bin/bash
# Claude Code Status Line Script
# Receives JSON on stdin, outputs status text

set -e
read -r INPUT

# Extract fields
MODEL=$(echo "$INPUT" | jq -r '.model.display_name // "Claude"')
CONTEXT=$(echo "$INPUT" | jq -r '.context_window.used_percentage // 0')
COST=$(echo "$INPUT" | jq -r '.total_cost_usd // 0')
DIR=$(echo "$INPUT" | jq -r '.workspace.current_dir // ""')

# Status indicator
if (( CONTEXT > 75 )); then
  STATUS="🔴"
elif (( CONTEXT > 50 )); then
  STATUS="🟡"
else
  STATUS="🟢"
fi

# Git branch (optional)
BRANCH=""
if [ -n "$DIR" ]; then
  BRANCH=$(cd "$DIR" 2>/dev/null && git branch --show-current 2>/dev/null || true)
fi

# Build output
OUTPUT="🤖 $MODEL | 📊 ${CONTEXT}%${STATUS}"
[ -n "$BRANCH" ] && OUTPUT="$OUTPUT | 🌿 $BRANCH"
[ "$COST" != "0" ] && OUTPUT="$OUTPUT | 💰 \$${COST}"

echo "$OUTPUT"
```

See `skills/statusline/SKILL.md` for complete module implementations and theme definitions.

---

## Troubleshooting

### Script not executing

1. Check permissions: `chmod +x ~/.claude/statusline.sh`
2. Verify path in settings.json matches
3. Test manually: `echo '{}' | ~/.claude/statusline.sh`

### Variables not interpolating

Static strings use `%var%` format. Command-based use JSON input.

### Custom sections lost

When regenerating scripts, the command preserves sections marked with boundary comments:

```bash
# --- custom ---
# Your custom code here
# --- end custom ---
```

---

## Related Settings

```json
{
  "showTurnDuration": false,
  "CLAUDE_CODE_SHELL_PREFIX": "..."
}
```

- `showTurnDuration`: Show/hide "Cooked for X" messages
- `CLAUDE_CODE_SHELL_PREFIX`: Wrap shell commands (affects status)
