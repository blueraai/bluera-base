# Commands Reference

All commands are invoked with `/bluera-base:<command>`.

## Quick Reference

| Command | Description |
|---------|-------------|
| `audit-plugin` | Audit a Claude Code plugin against best practices |
| `analyze-config` | Analyze .claude/** for overlap with bluera-base |
| `cancel-milhouse` | Cancel active milhouse loop |
| `claude-md` | Audit and maintain CLAUDE.md files |
| `clean` | Diagnose slow Claude Code startup |
| `code-review` | Multi-agent codebase review |
| `commit` | Create atomic commits with doc awareness |
| `config` | Manage plugin configuration |
| `dry` | Detect duplicate code using jscpd |
| `explain` | Explain plugin functionality |
| `harden-repo` | Set up linters, formatters, hooks |
| `help` | Show plugin features and usage |
| `init` | Initialize project with bluera-base |
| `install-rules` | Install rule templates to .claude/rules/ |
| `milhouse-loop` | Start iterative development loop |
| `readme` | Maintain README.md formatting |
| `release` | Cut release with conventional commits |
| `statusline` | Configure terminal status line |
| `test-plugin` | Run plugin validation test suite |
| `todo` | Manage project TODO tasks |
| `worktree` | Manage git worktrees |
| `learn` | Manage semantic learnings from session analysis |
| `large-file-refactor` | Break apart files that exceed token limits |

## By Category

### Project Setup

| Command | Description |
|---------|-------------|
| `init` | Initialize project with bluera-base conventions |
| `harden-repo` | Set up git hooks, linters, formatters |
| `install-rules` | Add development rules to .claude/rules/ |

### Code Quality

| Command | Description |
|---------|-------------|
| `code-review` | Multi-agent review for bugs and CLAUDE.md compliance |
| `audit-plugin` | Validate plugin against best practices |
| `test-plugin` | Run comprehensive plugin test suite |
| `dry` | Detect duplicate code |
| `clean` | Diagnose startup performance |
| `large-file-refactor` | Break apart files that exceed token limits |

### Documentation

| Command | Description |
|---------|-------------|
| `claude-md` | Audit and maintain CLAUDE.md files |
| `readme` | Format README.md with tables, diagrams, badges |
| `analyze-config` | Analyze .claude configs for cleanup |

### Version Control

| Command | Description |
|---------|-------------|
| `commit` | Atomic commits with README/CLAUDE.md awareness |
| `worktree` | Manage git worktrees for parallel work |
| `release` | Automated release with conventional commits |

### Configuration

| Command | Description |
|---------|-------------|
| `config` | Manage plugin settings (enable/disable features) |
| `statusline` | Configure terminal status line display |
| `learn` | Manage semantic learnings from session analysis |
| `help` | Show features and usage |
| `explain` | Explain all plugin functionality |
| `todo` | Manage project TODO tasks |

### Iterative Development

| Command | Description |
|---------|-------------|
| `milhouse-loop` | Start iterative development loop |
| `cancel-milhouse` | Stop active milhouse loop |

## See Also

- [Configuration](configuration.md) - Config system reference
- [Skills](skills.md) - Skill documentation
- [Hooks](hooks.md) - Hook behavior
