---
description: Configure Claude Code's terminal status line display
allowed-tools: Bash(git:*), Bash(jq:*), Bash(cat:*), Bash(mkdir:*), Bash(cp:*), Bash(chmod:*), Read, Write, Edit, AskUserQuestion, WebFetch
argument-hint: [show|preset|barista|custom|reset]
---

# Status Line Configuration

Manage Claude Code's status line display at the bottom of your terminal.

## Subcommands

| Command | Description |
|---------|-------------|
| `/statusline` or `/statusline show` | Display current configuration |
| `/statusline preset <name>` | Apply a preset configuration |
| `/statusline barista` | Install/configure Barista (advanced) |
| `/statusline custom` | Interactive custom configuration |
| `/statusline reset` | Reset to Claude Code defaults |

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

```json
{
  "statusLine": "%model% | %context%"
}
```

### Informative

```json
{
  "statusLine": "🤖 %model% | 📊 %context% | 💰 %cost%"
}
```

### Developer

Uses a script showing git branch, project type, and more:

```bash
#!/bin/bash
# ~/.claude/statusline.sh
read -r INPUT
DIR=$(echo "$INPUT" | jq -r '.workspace.current_dir // "unknown"')
MODEL=$(echo "$INPUT" | jq -r '.model.display_name // "Claude"')
CONTEXT=$(echo "$INPUT" | jq -r '.context_window.used_percentage // 0')
BRANCH=$(cd "$DIR" 2>/dev/null && git branch --show-current 2>/dev/null || echo "")

OUTPUT="🤖 $MODEL | 📊 ${CONTEXT}%"
[ -n "$BRANCH" ] && OUTPUT="$OUTPUT | 🌿 $BRANCH"
echo "$OUTPUT"
```

---

## Barista Integration

[Barista](https://github.com/pstuart/Barista) is a full-featured modular status line.

### Features

- **Modules**: context, git, cost, rate limits, battery, docker, and more
- **Themes**: default, minimal, vibrant, monochrome, nerd fonts
- **Modes**: normal, compact, verbose
- **Per-project**: `.barista.conf` overrides

### Quick Install

```bash
git clone https://github.com/pstuart/Barista.git ~/.claude/barista
cd ~/.claude/barista && ./install.sh
```

### Recommended Presets

**Espresso (Minimal)**:
```bash
DISPLAY_MODE="compact"
MODULE_ORDER="directory,context,git,model"
```

**Americano (Developer)**:
```bash
MODULE_DOCKER="true"
MODULE_CPU="true"
MODULE_ORDER="directory,git,docker,cpu,model,cost,rate-limits"
```

---

## Algorithm

### Show (default)

1. Read `~/.claude/settings.json`
2. Extract statusLine configuration
3. Display current type and settings
4. If command-based, show script path and check if exists

### Preset

Arguments: `<preset-name>`

1. Validate preset exists (minimal, informative, developer)
2. For script-based presets:
   - Create `~/.claude/statusline.sh` with template
   - Make executable
3. Update `~/.claude/settings.json`
4. Report changes

### Barista

1. Check if Barista is installed (`~/.claude/barista/`)
2. If not installed:
   - Offer to clone repository
   - Run interactive installer
3. If installed:
   - Show current config
   - Offer to reconfigure

### Custom

Interactive workflow:

1. Ask: Built-in, static text, or script-based?
2. If static: Ask for format string
3. If script: Ask which modules (context, git, cost, etc.)
4. Generate configuration
5. Preview before applying
6. Update settings

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
/statusline show

# Apply minimal preset
/statusline preset minimal

# Apply developer preset (script-based)
/statusline preset developer

# Install Barista
/statusline barista

# Interactive custom setup
/statusline custom

# Reset to defaults
/statusline reset
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

---

## Troubleshooting

### Script not executing

1. Check permissions: `chmod +x ~/.claude/statusline.sh`
2. Verify path in settings.json matches
3. Test manually: `echo '{}' | ~/.claude/statusline.sh`

### Variables not interpolating

Static strings use `%var%` format. Command-based use JSON input.

### Barista issues

See [Barista troubleshooting](https://github.com/pstuart/Barista#troubleshooting).

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
