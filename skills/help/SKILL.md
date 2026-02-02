---
name: help
description: Show bluera-base plugin features and usage
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion]
---

# bluera-base Help

Comprehensive guide to all bluera-base features.

## Subcommands

| Command | Description |
|---------|-------------|
| `/bluera-base:help` or `/bluera-base:help all` | Show all features |
| `/bluera-base:help commands` | List all slash commands |
| `/bluera-base:help skills` | List all skills |
| `/bluera-base:help hooks` | Explain automatic hooks |
| `/bluera-base:help config` | Show configuration options |

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
/bluera-base:config init

# Create atomic commits with conventional format
/bluera-base:commit

# Start iterative development loop
/bluera-base:milhouse-loop --inline "implement feature X"

# Review code for issues
/bluera-base:code-review

# Cut a release
/bluera-base:release
```

---

## Commands (23 total)

### Development & Iteration

| Command | Description |
|---------|-------------|
| `/bluera-base:commit` | Create atomic commits with conventional format |
| `/bluera-base:code-review` | Review codebase for bugs and CLAUDE.md compliance |
| `/bluera-base:release` | Cut releases with conventional commits auto-detection |
| `/bluera-base:milhouse-loop` | Start iterative development loop |
| `/bluera-base:cancel-milhouse` | Cancel active milhouse loop |
| `/bluera-base:todo` | Manage project TODO tasks (show, add, complete) |
| `/bluera-base:learn` | Manage semantic learnings from session analysis |

### Project Setup

| Command | Description |
|---------|-------------|
| `/bluera-base:config` | Manage plugin configuration |
| `/bluera-base:harden-repo` | Set up git hooks, linters, formatters |
| `/bluera-base:init` | Initialize a project with bluera-base conventions |
| `/bluera-base:install-rules` | Install rule templates to `.claude/rules/` |

### Documentation

| Command | Description |
|---------|-------------|
| `/bluera-base:claude-md` | Audit and maintain CLAUDE.md files |
| `/bluera-base:readme` | Maintain README.md files |

### Analysis & Quality

| Command | Description |
|---------|-------------|
| `/bluera-base:analyze-config` | Analyze repo's `.claude/**` for overlap |
| `/bluera-base:audit-plugin` | Audit a Claude Code plugin against best practices |
| `/bluera-base:clean` | Diagnose slow Claude Code startup and guide cleanup |
| `/bluera-base:dry` | Detect duplicate code with jscpd |
| `/bluera-base:large-file-refactor` | Break apart files exceeding token limits |

### Git & Workflows

| Command | Description |
|---------|-------------|
| `/bluera-base:worktree` | Manage git worktrees for parallel development |
| `/bluera-base:statusline` | Configure Claude Code terminal status line |
| `/bluera-base:test-plugin` | Run plugin validation test suite |

### Help

| Command | Description |
|---------|-------------|
| `/bluera-base:explain` | Explain all bluera-base plugin functionality |
| `/bluera-base:help` | Show this help (you are here) |

---

## Skills (24 total)

Skills provide specialized guidance and workflows. Reference them with `@skill-name`.

| Skill | Description |
|-------|-------------|
| `@analyze-config` | Analyze .claude/** overlap with bluera-base |
| `@atomic-commits` | Atomic commit creation with grouping rules |
| `@audit-plugin` | Audit plugins against best practices |
| `@auto-learn` | Automatic learning from session patterns |
| `@claude-cleaner` | Diagnose slow startup and guide cleanup |
| `@claude-md-maintainer` | CLAUDE.md structure and validation |
| `@code-review-repo` | Multi-agent code review patterns |
| `@config` | Plugin configuration management |
| `@dry` | Duplicate code detection with jscpd |
| `@dry-refactor` | DRY refactoring patterns by language |
| `@explain` | Plugin functionality documentation |
| `@help` | Plugin features reference |
| `@init` | Project initialization with conventions |
| `@install-rules` | Rule template installation |
| `@large-file-refactor` | Breaking apart files exceeding token limits |
| `@learn` | Deep learning management |
| `@milhouse` | Iterative development loop guidance |
| `@readme-maintainer` | README.md formatting and structure |
| `@release` | Release workflow with CI monitoring |
| `@repo-hardening` | Security and quality tool setup |
| `@statusline` | Status line configuration with presets |
| `@test-plugin` | Plugin validation test suite |
| `@todo` | Project TODO task management |
| `@worktree` | Git worktree management |

---

## Hooks (12 total)

Hooks run automatically on specific events. No action required.

### Session Lifecycle

| Hook | Event | Description |
|------|-------|-------------|
| `session-setup.sh` | SessionStart | Check jq, fix hook permissions, update .gitignore |
| `session-start-inject.sh` | SessionStart | Inject context into session |
| `pre-compact.sh` | PreCompact | Preserve state before context compaction |
| `session-end-learn.sh` | Stop | Process learning observations |
| `session-end-analyze.sh` | Stop | Deep learning session analysis |

### Tool Validation

| Hook | Event | Description |
|------|-------|-------------|
| `block-manual-release.sh` | PreToolUse:Bash | Block manual version bumps (use /bluera-base:release) |
| `post-edit-check.sh` | PostToolUse:Write\|Edit | Validate file changes |
| `observe-learning.sh` | PreToolUse:Bash | Track commands for learning |
| `standards-review.sh` | PreToolUse:Bash | Review code against CLAUDE.md standards |

### Notifications

| Hook | Event | Description |
|------|-------|-------------|
| `notify.sh` | Notification | Send desktop notifications |

### Automation

| Hook | Event | Description |
|------|-------|-------------|
| `auto-commit.sh` | Stop | Prompt to commit if uncommitted changes (opt-in) |
| `milhouse-stop.sh` | Stop | Continue milhouse loop if active |
| `dry-scan.sh` | Stop | Run DRY scan if enabled |

---

## Configuration

Manage settings with `/bluera-base:config`. Config stored in `.bluera/bluera-base/`.

### Quick Enable/Disable

```bash
/bluera-base:config enable auto-learn      # Track commands for learning
/bluera-base:config enable notifications   # Desktop notifications
/bluera-base:config enable auto-commit     # Auto-commit on session stop
/bluera-base:config enable auto-push       # Add push instruction to prompt
/bluera-base:config enable dry-check       # Enable DRY detection
/bluera-base:config enable dry-auto        # Auto-scan on session stop
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
  },
  "strictTyping": {
    "enabled": false
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

- `/bluera-base:help <topic>` - Specific topic help
- `@skill-name` - Reference skill documentation
- `/bluera-base:config status` - Debug configuration issues
- GitHub: <https://github.com/blueraai/bluera-base>
