# Development

> Part of [Bluera Base](../README.md) documentation.

## Setup

```bash
git clone https://github.com/blueraai/bluera-base.git
cd bluera-base
```

No build step required - this plugin is pure markdown, shell scripts, and Python utilities.

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

```text
bluera-base/
├── .claude-plugin/
│   └── plugin.json               # Plugin manifest
├── assets/
│   └── claude.png                # Plugin icon/assets
├── commands/
│   ├── analyze-config.md         # /bluera-base:analyze-config command
│   ├── audit-plugin.md           # /bluera-base:audit-plugin command
│   ├── cancel-milhouse.md        # /bluera-base:cancel-milhouse command
│   ├── claude-md.md              # /bluera-base:claude-md command
│   ├── clean.md                  # /bluera-base:clean command
│   ├── code-review.md            # /bluera-base:code-review command
│   ├── commit.md                 # /bluera-base:commit command
│   ├── config.md                 # /bluera-base:config command
│   ├── dry.md                    # /bluera-base:dry command
│   ├── explain.md                # /bluera-base:explain command
│   ├── harden-repo.md            # /bluera-base:harden-repo command
│   ├── help.md                   # /bluera-base:help command
│   ├── init.md                   # /bluera-base:init command
│   ├── install-rules.md          # /bluera-base:install-rules command
│   ├── milhouse-loop.md          # /bluera-base:milhouse-loop command
│   ├── readme.md                 # /bluera-base:readme command
│   ├── release.md                # /bluera-base:release command
│   ├── statusline.md             # /bluera-base:statusline command
│   ├── test-plugin.md            # /bluera-base:test-plugin command
│   ├── todo.md                   # /bluera-base:todo command
│   └── worktree.md               # /bluera-base:worktree command
├── hooks/
│   ├── hooks.json                # Hook definitions
│   ├── lib/                      # Shared hook libraries
│   │   └── tests/                # Shell script tests
│   ├── auto-commit.sh            # Stop hook for auto-commit
│   ├── block-manual-release.sh   # Enforces /bluera-base:release workflow
│   ├── dry-scan.sh               # Stop hook for duplication scan
│   ├── milhouse-setup.sh         # Initializes milhouse loop state
│   ├── milhouse-stop.sh          # Stop hook for milhouse iterations
│   ├── notify.sh                 # Cross-platform notifications
│   ├── observe-learning.sh       # PreToolUse hook for auto-learn
│   ├── post-edit-check.sh        # Multi-language validation hook
│   ├── pre-compact.sh            # PreCompact hook for state preservation
│   ├── session-end-learn.sh      # Stop hook for learning consolidation
│   ├── session-setup.sh          # SessionStart dependency check
│   └── session-start-inject.sh   # SessionStart context injection
├── scripts/
│   ├── cc-cleaner-fix.py         # Claude Code cleaner fix script
│   └── cc-cleaner-scan.py        # Claude Code cleaner scan script
├── skills/
│   ├── architectural-constraints/
│   │   └── SKILL.md.template     # Template for project-specific constraints
│   ├── auto-learn/
│   │   └── SKILL.md              # Automatic learning from sessions
│   ├── atomic-commits/
│   │   └── SKILL.md              # Commit guidelines
│   ├── claude-cleaner/
│   │   └── SKILL.md              # Diagnose slow startup
│   ├── claude-md-maintainer/
│   │   ├── SKILL.md              # CLAUDE.md validation skill
│   │   ├── docs/                 # Invariants and heuristics
│   │   └── templates/            # CLAUDE.md templates
│   ├── code-review-repo/
│   │   └── SKILL.md              # Multi-agent review
│   ├── dry-refactor/
│   │   └── SKILL.md              # DRY refactoring guidance
│   ├── large-file-refactor/
│   │   └── SKILL.md              # Large file splitting guidance
│   ├── milhouse/
│   │   └── SKILL.md              # Iterative development loop
│   ├── readme-maintainer/
│   │   ├── SKILL.md              # README formatting guidelines
│   │   └── templates/            # Badge and structure templates
│   ├── release/
│   │   └── SKILL.md              # Release workflow
│   ├── repo-hardening/
│   │   └── SKILL.md              # Repo hardening best practices
│   └── statusline/
│       └── SKILL.md              # Status line configuration
├── includes/
│   └── CLAUDE-BASE.md            # @includeable sections
├── templates/
│   ├── claude/
│   │   └── rules/                # Rule templates for /bluera-base:install-rules
│   ├── repo-hardening/           # Templates for /bluera-base:harden-repo
│   ├── bluera-base-config.json   # Default config template
│   ├── CLAUDE.md.template
│   ├── critical-invariants.md    # Template for compaction-resilient rules
│   ├── jscpd.json.template       # Duplicate detection config
│   ├── settings.local.json.example
│   └── subdirectory-CLAUDE.md.template
├── docs/
│   ├── advanced-patterns.md              # Advanced usage patterns
│   ├── bluera-base-claude-md-maintainer-spec.md  # CLAUDE.md maintainer spec
│   ├── bluera-base-plugin-audit-spec.md  # Plugin audit spec
│   ├── claude-code-best-practices.md     # Best practices guide
│   ├── command-patterns.md               # Command design patterns
│   ├── customization.md                  # Triggers, hooks, rules, constraints
│   ├── development.md                    # This file
│   ├── hook-examples.md                  # Hook implementation examples
│   ├── hooks.md                          # Hook reference
│   ├── skills.md                         # Skill reference
│   ├── troubleshooting.md                # Troubleshooting guide
│   └── usage.md                          # @includes, skills, settings
└── README.md
```
