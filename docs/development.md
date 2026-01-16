# Development

> Part of [Bluera Base](../README.md) documentation.

## Setup

```bash
git clone https://github.com/blueraai/bluera-base.git
cd bluera-base
```

No build step required - this plugin is pure markdown and shell scripts.

## Dogfooding (Testing Your Development Version)

The easiest way to test the plugin during development is to run Claude Code from the repo root:

```bash
cd /path/to/bluera-base
claude --plugin-dir .
```

This loads the current directory as a plugin. Your commands, hooks, and skills are active immediately.

**From any directory:**

```bash
claude --plugin-dir /path/to/bluera-base
```

| What to test | How |
|--------------|-----|
| Commands (`/bluera-base:release`, `/bluera-base:commit`) | `--plugin-dir .` (restart to pick up changes) |
| Hooks (post-edit, milhouse) | `--plugin-dir .` (restart to pick up changes) |
| Skills | `--plugin-dir .` (restart to pick up changes) |

Changes take effect on Claude Code restart (no reinstall needed).

## Project Structure

```
bluera-base/
├── .claude-plugin/
│   └── plugin.json               # Plugin manifest
├── commands/
│   ├── cancel-milhouse.md        # /bluera-base:cancel-milhouse command
│   ├── claude-md.md              # /bluera-base:claude-md command
│   ├── code-review.md            # /bluera-base:code-review command
│   ├── commit.md                 # /bluera-base:commit command
│   ├── install-rules.md          # /bluera-base:install-rules command
│   ├── milhouse-loop.md          # /bluera-base:milhouse-loop command
│   ├── readme.md                 # /bluera-base:readme command
│   ├── release.md                # /bluera-base:release command
│   └── test-plugin.md            # /bluera-base:test-plugin command
├── hooks/
│   ├── hooks.json                # Hook definitions
│   ├── block-manual-release.sh   # Enforces /bluera-base:release workflow
│   ├── milhouse-setup.sh         # Initializes milhouse loop state
│   ├── milhouse-stop.sh          # Stop hook for milhouse iterations
│   ├── notify.sh                 # Cross-platform notifications
│   ├── post-edit-check.sh        # Multi-language validation hook
│   └── session-setup.sh          # SessionStart dependency check
├── skills/
│   ├── architectural-constraints/
│   │   └── SKILL.md.template     # Template for constraint skills
│   ├── atomic-commits/
│   │   └── SKILL.md              # Commit guidelines
│   ├── claude-md-maintainer/
│   │   ├── SKILL.md              # CLAUDE.md validation skill
│   │   ├── docs/                 # Invariants and heuristics
│   │   └── templates/            # CLAUDE.md templates
│   ├── code-review-repo/
│   │   └── SKILL.md              # Multi-agent review
│   ├── milhouse/
│   │   └── SKILL.md              # Iterative development loop
│   ├── readme-maintainer/
│   │   ├── SKILL.md              # README formatting guidelines
│   │   └── templates/            # Badge and structure templates
│   └── release/
│       └── SKILL.md              # Release workflow
├── includes/
│   └── CLAUDE-BASE.md            # @includeable sections
├── templates/
│   ├── claude/
│   │   └── rules/                # Rule templates for /bluera-base:install-rules
│   ├── CLAUDE.md.template
│   ├── settings.local.json.example
│   └── subdirectory-CLAUDE.md.template
├── docs/
│   ├── usage.md                  # @includes, skills, settings
│   ├── customization.md          # Triggers, hooks, rules, constraints
│   └── development.md            # This file
└── README.md
```
