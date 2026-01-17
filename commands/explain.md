---
description: Explain all bluera-base plugin functionality in human-readable format
allowed-tools: Read
argument-hint: [overview|commands|skills|hooks|config|philosophy]
---

# bluera-base Explained

Technical documentation of bluera-base plugin internals.

## Subcommands

- `/bluera-base:explain` or `/bluera-base:explain all` - Show everything
- `/bluera-base:explain overview` - Plugin structure and architecture
- `/bluera-base:explain commands` - Command system internals
- `/bluera-base:explain skills` - Skill loading mechanism
- `/bluera-base:explain hooks` - Hook events and execution
- `/bluera-base:explain config` - Configuration system
- `/bluera-base:explain philosophy` - Design principles

---

## Algorithm

**Present the documentation below to the user.** This is a documentation command - output the content directly, don't just acknowledge it.

### Show All (default)

Present all sections: Overview, How It Works, Commands, Skills, Hooks, Configuration, and Philosophy.

### Overview

Present only the Overview section.

### Commands

Present only the Commands Explained section.

### Skills

Present only the Skills Explained section.

### Hooks

Present only the Hooks Explained section.

### Config

Present only the Configuration Explained section.

### Philosophy

Present only the Philosophy Explained section.

---

## Overview

### Plugin Structure

```text
.claude-plugin/
├── plugin.json          # Manifest: name, version, description
commands/                # Slash commands (*.md files)
skills/                  # Skill directories (*/SKILL.md)
hooks/
├── hooks.json           # Hook registration
├── *.sh                 # Hook scripts
└── lib/                 # Shared bash libraries
templates/               # Rule and config templates
includes/                # @includeable content (CLAUDE-BASE.md)
```

### Manifest (`plugin.json`)

```json
{
  "name": "bluera-base",
  "version": "0.10.0",
  "description": "Shared development conventions...",
  "author": { "name": "Bluera" },
  "repository": "https://github.com/blueraai/bluera-base"
}
```

### Environment Variables

| Variable | Description |
|----------|-------------|
| `CLAUDE_PLUGIN_ROOT` | Absolute path to plugin directory |
| `CLAUDE_PROJECT_DIR` | User's project directory |

---

## How It Works

### Session Lifecycle

```text
SessionStart
├── session-setup.sh      # Create .bluera/bluera-base/state/, check jq
└── session-start-inject.sh  # Inject saved context

PreToolUse (Bash)
├── block-manual-release.sh  # Block npm version, git tag
└── observe-learning.sh      # Track commands (if auto-learn)

PostToolUse (Write|Edit)
└── post-edit-check.sh       # Scan for anti-patterns

Notification
└── notify.sh                # Desktop notifications

PreCompact
└── pre-compact.sh           # Preserve state before compaction

Stop
├── milhouse-stop.sh         # Continue loop if active
├── session-end-learn.sh     # Process observations
├── dry-scan.sh              # DRY scan (if enabled)
└── auto-commit.sh           # Commit changes (if enabled)
```

### Hook Execution Flow

1. Claude Code emits event (e.g., `PreToolUse`)
2. `hooks.json` matches event type and tool matcher
3. Script receives JSON on stdin: `{"tool_input": {...}}`
4. Script exits: `0` = allow, `2` = block with message
5. Stdout/stderr shown to Claude as hook feedback

### State Directory

```text
.bluera/bluera-base/
├── config.json           # Team config (committed)
├── config.local.json     # Personal overrides (gitignored)
├── TODO.txt              # Project tasks (committed)
└── state/                # Runtime state (gitignored)
    ├── milhouse-loop.md  # Active loop: iteration, prompt
    ├── session-signals.json  # Learning observations
    ├── dry-report.md     # Last DRY scan results
    └── jscpd-report.json # Raw jscpd output
```

---

## Commands Explained

### Command File Structure

Commands are markdown files in `commands/` with YAML frontmatter:

```yaml
---
description: Short description for command list
allowed-tools: Read, Write, Bash(git:*, npm:*)
argument-hint: [subcommand] [--flag]
hide-from-slash-command-tool: true  # Optional: hide from /commands
---
```

### Tool Scoping

`allowed-tools` restricts what Claude can use during command execution:

```yaml
# Allow specific tools
allowed-tools: Read, Write, Edit, Glob, Grep

# Scope Bash to specific commands
allowed-tools: Bash(git:*, gh:*, npm:*)

# Scope to specific script
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/hooks/script.sh:*)
```

### Command Categories

**Setup**: `config`, `install-rules`, `harden-repo`
**Development**: `commit`, `milhouse-loop`, `cancel-milhouse`, `todo`
**Quality**: `code-review`, `dry`, `audit-plugin`, `analyze-config`
**Documentation**: `claude-md`, `readme`
**Release**: `release`
**Git**: `worktree`, `statusline`
**Meta**: `help`, `explain`, `test-plugin`

### Command Execution

1. User types `/bluera-base:command`
2. Claude Code loads `commands/command.md`
3. Frontmatter parsed: tools scoped, description shown
4. Markdown body injected into Claude's context
5. Claude follows the Algorithm section instructions

---

## Skills Explained

### Skill File Structure

Skills live in `skills/<name>/SKILL.md` with frontmatter:

```yaml
---
name: skill-name
description: What this skill provides
version: 1.0.0
user-invocable: false  # true = can be invoked directly
---
```

### Skill Loading

Skills are loaded via `@skill-name` reference or automatically by commands:

```markdown
See @bluera-base/skills/atomic-commits/SKILL.md for workflow details.
```

Claude Code resolves the path and injects SKILL.md content.

### Available Skills

| Skill | Path | User-Invocable |
|-------|------|----------------|
| `atomic-commits` | `skills/atomic-commits/SKILL.md` | No |
| `code-review-repo` | `skills/code-review-repo/SKILL.md` | No |
| `release` | `skills/release/SKILL.md` | No |
| `milhouse` | `skills/milhouse/SKILL.md` | No |
| `claude-md-maintainer` | `skills/claude-md-maintainer/SKILL.md` | No |
| `readme-maintainer` | `skills/readme-maintainer/SKILL.md` | No |
| `repo-hardening` | `skills/repo-hardening/SKILL.md` | No |
| `large-file-refactor` | `skills/large-file-refactor/SKILL.md` | **Yes** |
| `dry-refactor` | `skills/dry-refactor/SKILL.md` | No |
| `statusline` | `skills/statusline/SKILL.md` | No |

---

## Hooks Explained

### Hook Registration (`hooks.json`)

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "command": "${CLAUDE_PLUGIN_ROOT}/hooks/block-manual-release.sh", "timeout": 5000 }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          { "command": "${CLAUDE_PLUGIN_ROOT}/hooks/post-edit-check.sh", "timeout": 60000 }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": ".*",
        "hooks": [
          { "command": "${CLAUDE_PLUGIN_ROOT}/hooks/auto-commit.sh", "timeout": 30000 }
        ]
      }
    ]
  }
}
```

### Event Types

| Event | When | Stdin JSON |
|-------|------|------------|
| `SessionStart` | Session begins | `{}` |
| `PreToolUse` | Before tool execution | `{"tool_input": {...}}` |
| `PostToolUse` | After tool execution | `{"tool_input": {...}, "tool_output": {...}}` |
| `Stop` | Session ends | `{"transcript_path": "..."}` |
| `PreCompact` | Before context compaction | `{}` |
| `Notification` | Permission/idle prompt | `{"type": "permission_prompt"}` |

### Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success / Allow |
| `2` | Block with message (stdout shown to Claude) |
| Other | Error (logged but doesn't block) |

### Hook Scripts

| Script | Event | Matcher | Purpose |
|--------|-------|---------|---------|
| `session-setup.sh` | SessionStart | `.*` | Init state dir, check jq |
| `session-start-inject.sh` | SessionStart | `.*` | Inject context |
| `pre-compact.sh` | PreCompact | `.*` | Preserve state |
| `block-manual-release.sh` | PreToolUse | `Bash` | Block `npm version`, `git tag` |
| `observe-learning.sh` | PreToolUse | `Bash` | Track commands |
| `post-edit-check.sh` | PostToolUse | `Write\|Edit` | Detect anti-patterns |
| `notify.sh` | Notification | `permission_prompt\|...` | Desktop notifications |
| `milhouse-stop.sh` | Stop | `.*` | Continue loop |
| `session-end-learn.sh` | Stop | `.*` | Process learnings |
| `dry-scan.sh` | Stop | `.*` | DRY scan |
| `auto-commit.sh` | Stop | `.*` | Auto-commit |

### Shared Libraries (`hooks/lib/`)

```bash
source "${PLUGIN_PATH}/hooks/lib/config.sh"  # load_config, get_config
source "${PLUGIN_PATH}/hooks/lib/state.sh"   # get_state, set_state
source "${PLUGIN_PATH}/hooks/lib/signals.sh" # emit_signal, get_signals
```

---

## Configuration Explained

### Config Loading Order

```text
defaults (hardcoded)
    ↓ merge
config.json (team, committed)
    ↓ merge
config.local.json (personal, gitignored)
    ↓
final config
```

### Config Schema

```json
{
  "version": 1,
  "autoLearn": {
    "enabled": false,
    "mode": "suggest",      // "suggest" | "auto"
    "threshold": 3,         // occurrences before suggesting
    "target": "local"       // "local" | "project"
  },
  "milhouse": {
    "defaultMaxIterations": 0,  // 0 = unlimited
    "defaultStuckLimit": 3,
    "defaultGates": []
  },
  "notifications": {
    "enabled": true
  },
  "autoCommit": {
    "enabled": false,
    "onStop": true,
    "push": false,
    "remote": "origin"
  },
  "dryCheck": {
    "enabled": false,
    "onStop": false,
    "threshold": 5,      // min tokens to report
    "minTokens": 70,
    "minLines": 5
  },
  "strictTyping": {
    "enabled": false
  }
}
```

### Feature Flags

| Feature | Config Path | Default | Effect |
|---------|-------------|---------|--------|
| `notifications` | `.notifications.enabled` | `true` | Desktop notifications |
| `auto-learn` | `.autoLearn.enabled` | `false` | Track command patterns |
| `auto-commit` | `.autoCommit.enabled` | `false` | Commit on session stop |
| `auto-push` | `.autoCommit.push` | `false` | Push after auto-commit |
| `dry-check` | `.dryCheck.enabled` | `false` | Enable DRY detection |
| `dry-auto` | `.dryCheck.onStop` | `false` | Scan on session stop |
| `strict-typing` | `.strictTyping.enabled` | `false` | Block `any`/`as`/`ignore` |

### Config Commands

```bash
/bluera-base:config init      # Create config.json with defaults
/bluera-base:config show      # Display current config
/bluera-base:config status    # Debug: show load order, merged result
/bluera-base:config enable <feature>   # Set feature.enabled = true
/bluera-base:config disable <feature>  # Set feature.enabled = false
/bluera-base:config set <path> <value> # Set arbitrary JSON path
/bluera-base:config reset     # Delete config files
```

---

## Philosophy Explained

### Fail Fast

Exit code 2 blocks operations. Errors throw immediately. No silent failures.

```bash
# Hook blocking pattern
if [[ "$cmd" =~ npm\ version ]]; then
  echo "Use /bluera-base:release instead"
  exit 2  # Block
fi
exit 0  # Allow
```

### No Fallbacks

post-edit-check.sh scans staged changes for forbidden patterns:

```bash
FORBIDDEN_PATTERNS="fallback|graceful.?degrad|backward.?compat|legacy.?support"
if git diff --cached | grep -qiE "$FORBIDDEN_PATTERNS"; then
  echo "Anti-pattern detected"
  exit 2
fi
```

### Strict Typing

When `strict-typing` enabled, post-edit-check.sh also scans for:

```bash
# TypeScript
": any" | "as " | "@ts-ignore" | "@ts-nocheck"

# Python
"Any" | "cast(" | "# type: ignore"
```

### Atomic Commits

`/bluera-base:commit` groups changes by logical unit, uses conventional format:

```text
type(scope): description

- feat: new feature (minor bump)
- fix: bug fix (patch bump)
- feat!: breaking change (major bump)
```

### Clean Code

No commented code, no deprecated references, no unused exports. If it's in the codebase, it runs.

---

## Internals

### Milhouse Loop State

`.bluera/bluera-base/state/milhouse-loop.md`:

```yaml
---
iteration: 3
max_iterations: 10
stuck_count: 0
stuck_limit: 3
completion_promise: "All tests pass"
gate_command: "npm test"
---

Original prompt content here...
```

`milhouse-stop.sh` reads this on Stop, increments iteration, and outputs the prompt to continue.

### Learning Signals

`.bluera/bluera-base/state/session-signals.json`:

```json
{
  "commands": {
    "npm test": { "count": 5, "contexts": ["after edit", "before commit"] },
    "git status": { "count": 12, "contexts": ["checking state"] }
  },
  "patterns": []
}
```

`session-end-learn.sh` processes this to suggest CLAUDE.md updates.

### DRY Report

`.bluera/bluera-base/state/dry-report.md`:

```markdown
## DRY Scan Results

**Duplicates found**: 3
**Total duplicate lines**: 45

### Top Duplicates

1. `src/utils.ts:10-25` ↔ `src/helpers.ts:5-20` (15 lines)
...
```

Generated by `dry-scan.sh` using jscpd JSON output.
