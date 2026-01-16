---
description: Show bluera-base plugin features and usage
allowed-tools: Read
argument-hint: [commands|skills|hooks|config|all]
---

# bluera-base Help

Comprehensive guide to all bluera-base features.

## Subcommands

| Command | Description |
|---------|-------------|
| `/help` or `/help all` | Show all features |
| `/help commands` | List all slash commands |
| `/help skills` | List all skills |
| `/help hooks` | Explain automatic hooks |
| `/help config` | Show configuration options |

---

## Algorithm

### Show All (default)

Display the complete feature reference below.

### Commands

Show only the Commands section.

### Skills

Show only the Skills section.

### Hooks

Show only the Hooks section.

### Config

Show only the Configuration section.

---

## Quick Start

```bash
# Initialize config for your project
/config init

# Create atomic commits with conventional format
/commit

# Start iterative development loop
/milhouse-loop "implement feature X"

# Review code for issues
/code-review

# Cut a release
/release
```

---

## Commands (17 total)

### Development & Iteration

| Command | Description |
|---------|-------------|
| `/commit` | Create atomic commits with conventional format |
| `/code-review` | Review codebase for bugs and CLAUDE.md compliance |
| `/release` | Cut releases with conventional commits auto-detection |
| `/milhouse-loop` | Start iterative development loop |
| `/cancel-milhouse` | Cancel active milhouse loop |

### Project Setup

| Command | Description |
|---------|-------------|
| `/config` | Manage plugin configuration |
| `/harden-repo` | Set up git hooks, linters, formatters |
| `/install-rules` | Install rule templates to `.claude/rules/` |

### Documentation

| Command | Description |
|---------|-------------|
| `/claude-md` | Audit and maintain CLAUDE.md files |
| `/readme` | Maintain README.md files |

### Analysis & Quality

| Command | Description |
|---------|-------------|
| `/analyze-config` | Analyze repo's `.claude/**` for overlap |
| `/audit-plugin` | Audit a Claude Code plugin against best practices |
| `/dry` | Detect duplicate code with jscpd |

### Git & Workflows

| Command | Description |
|---------|-------------|
| `/worktree` | Manage git worktrees for parallel development |
| `/statusline` | Configure Claude Code terminal status line |
| `/test-plugin` | Run plugin validation test suite |

### Help

| Command | Description |
|---------|-------------|
| `/help` | Show this help (you are here) |

---

## Skills (9 total)

Skills provide specialized guidance and workflows. Reference them with `@skill-name`.

| Skill | Description |
|-------|-------------|
| `@atomic-commits` | Atomic commit creation with grouping rules |
| `@code-review-repo` | Multi-agent code review patterns |
| `@release` | Release workflow with CI monitoring |
| `@milhouse` | Iterative development loop guidance |
| `@claude-md-maintainer` | CLAUDE.md structure and validation |
| `@readme-maintainer` | README.md formatting and structure |
| `@repo-hardening` | Security and quality tool setup |
| `@large-file-refactor` | Breaking apart files that exceed token limits |
| `@dry-refactor` | DRY refactoring patterns by language |

---

## Hooks (10 total)

Hooks run automatically on specific events. No action required.

### Session Lifecycle

| Hook | Event | Description |
|------|-------|-------------|
| `session-setup.sh` | SessionStart | Initialize state directory, verify tools |
| `session-start-inject.sh` | SessionStart | Inject context into session |
| `pre-compact.sh` | PreCompact | Preserve state before context compaction |
| `session-end-learn.sh` | Stop | Process learning observations |

### Tool Validation

| Hook | Event | Description |
|------|-------|-------------|
| `block-manual-release.sh` | PreToolUse:Bash | Block manual version bumps (use /release) |
| `post-edit-check.sh` | PostToolUse:Write\|Edit | Validate file changes |
| `observe-learning.sh` | PostToolUse:Bash | Track commands for learning |

### Notifications

| Hook | Event | Description |
|------|-------|-------------|
| `notify.sh` | Notification | Send desktop notifications |

### Automation

| Hook | Event | Description |
|------|-------|-------------|
| `milhouse-stop.sh` | Stop | Continue milhouse loop if active |
| `dry-scan.sh` | Stop | Run DRY scan if enabled |

---

## Configuration

Manage settings with `/config`. Config stored in `.bluera/bluera-base/`.

### Quick Enable/Disable

```bash
/config enable auto-learn      # Track commands for learning
/config enable notifications   # Desktop notifications
/config enable auto-commit     # Auto-commit on session stop
/config enable auto-push       # Push after auto-commit
/config enable dry-check       # Enable DRY detection
/config enable dry-auto        # Auto-scan on session stop
```

### Config Schema

```json
{
  "version": 1,
  "autoLearn": {
    "enabled": false,
    "mode": "suggest",
    "threshold": 3,
    "target": "local"
  },
  "milhouse": {
    "defaultMaxIterations": 0,
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
    "threshold": 5,
    "minTokens": 70,
    "minLines": 5
  }
}
```

### Config Files

| File | Purpose |
|------|---------|
| `config.json` | Team-shareable (committed) |
| `config.local.json` | Personal overrides (gitignored) |
| `state/` | Runtime state (gitignored) |

---

## Supported Languages

bluera-base works with any language Claude Code supports. Language-specific features:

| Feature | Languages |
|---------|-----------|
| DRY detection | 150+ via jscpd |
| Refactor patterns | JS/TS, Python, Rust, Go |
| Commit conventions | All |
| Code review | All |

---

## Getting Help

- `/help <topic>` - Specific topic help
- `@skill-name` - Reference skill documentation
- `/config status` - Debug configuration issues
- GitHub: https://github.com/anthropics/bluera-base
