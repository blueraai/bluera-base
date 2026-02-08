# Claude Code Audit Checklist

Comprehensive checklist for auditing Claude Code configurations and plugins.

**Official Documentation:**

- [Claude Code Plugins](https://code.claude.com/docs/en/plugins)
- [Claude Code Hooks](https://code.claude.com/docs/en/hooks)
- [Claude Code Skills](https://code.claude.com/docs/en/skills)
- [Claude Code MCP](https://code.claude.com/docs/en/mcp)
- [CLAUDE.md Memory Files](https://code.claude.com/docs/en/memory)

## 1. Project Configuration

> Reference: [CLAUDE.md Memory Files](https://code.claude.com/docs/en/memory)

### CLAUDE.md Files

- [ ] CLAUDE.md exists at project root
- [ ] Follows progressive disclosure (most important first)
- [ ] No redundant information duplicated from parent CLAUDE.md
- [ ] Includes key commands section
- [ ] No outdated or deprecated instructions

### Rules Directory

- [ ] `.claude/rules/` contains appropriate rules (if needed)
- [ ] Rules are focused and single-purpose
- [ ] No conflicting rules across files
- [ ] Rules follow naming conventions (e.g., `00-base.md`, `anti-patterns.md`)

### Settings

- [ ] `.claude/settings.json` (if exists) is valid JSON
- [ ] No conflicting configurations between files
- [ ] Local overrides (`.local.md`, `settings.local.json`) are gitignored

## 2. Plugin Structure (if applicable)

> Reference: [Claude Code Plugins](https://code.claude.com/docs/en/plugins)

### Manifest

- [ ] `.claude-plugin/plugin.json` in correct location (not nested)
- [ ] Has required fields: `name`, `version`, `description`
- [ ] Only recognized keys: `name`, `version`, `description`, `author`, `repository`, `homepage`, `license`, `keywords`
- [ ] No unrecognized keys (e.g., `bugs`, `categories` cause load failure)
- [ ] Version follows semver

### Directory Layout

- [ ] Skills at `skills/*/SKILL.md` (auto-register as slash commands)
- [ ] No legacy `commands/*.md` wrappers (use skills directly since 2.1.3)
- [ ] Hooks at `hooks/hooks.json` + `hooks/*.sh`
- [ ] Agents at `agents/*.md` (if used)

## 3. Skills (Slash Commands)

Since Claude Code 2.1.3, skills auto-register as slash commands. No separate `commands/` files needed.

> Reference: [Claude Code Skills](https://code.claude.com/docs/en/skills)

### Organization

- [ ] SKILL.md files are lean (<200 lines)
- [ ] Deep content in `references/` subdirectory
- [ ] Progressive disclosure structure
- [ ] Clear "When This Skill Applies" section

### Syntax

- [ ] No deprecated argument syntax (`$ARGUMENTS.0` should be `$ARGUMENTS[0]`)
- [ ] `allowed-tools` uses YAML list syntax, not comma-separated strings
- [ ] `allowed-tools` entries with `*`, `,`, `:` or parens are quoted (e.g., `"Bash(git:*)"`)
- [ ] Workflow sections are clear and actionable
- [ ] Quick reference sections for common patterns

## 5. Hooks

> Reference: [Claude Code Hooks](https://code.claude.com/docs/en/hooks)

### Configuration

- [ ] `hooks.json` has valid structure
- [ ] Matchers use correct regex syntax
- [ ] Event types are valid (SessionStart, UserPromptSubmit, PreToolUse, PermissionRequest, PostToolUse, PostToolUseFailure, Notification, SubagentStart, SubagentStop, Stop, TeammateIdle, TaskCompleted, PreCompact, SessionEnd)
- [ ] TeammateIdle/TaskCompleted hooks registered if agent teams used

### Scripts

- [ ] Scripts use `${CLAUDE_PLUGIN_ROOT}` for paths (not hardcoded)
- [ ] Scripts are executable (`chmod +x`)
- [ ] Exit codes are correct:
  - `0` = allow/success
  - `2` = block with stderr message
  - Other = non-blocking error

### Defensive Patterns

- [ ] Stop hooks check `stop_hook_active` before continuing
- [ ] Defensive stdin: `INPUT=$(cat 2>/dev/null || true)`
- [ ] Setup hooks use `once: true` where appropriate
- [ ] No infinite loops in Stop hooks

## 5a. Agent Teams (if applicable)

> Reference: [Agent Teams](https://code.claude.com/docs/en/agent-teams)

### Setup

- [ ] `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` set in settings.json `env` block
- [ ] `teammateMode` configured (`in-process`, `tmux`, or `auto`)
- [ ] tmux or iTerm2 with `it2` CLI installed if using split-pane mode
- [ ] Split-pane mode NOT used in VS Code terminal, Windows Terminal, or Ghostty

### Hooks

- [ ] TeammateIdle hooks enforce quality gates (exit 2 keeps teammate working)
- [ ] TaskCompleted hooks enforce completion criteria (exit 2 blocks completion)
- [ ] Both registered as `async` in hooks.json (no matcher support)
- [ ] Both use exit-code-only control (no JSON decision support)

### Architecture

- [ ] Agent `memory` frontmatter set where appropriate (`user`, `project`, `local`)
- [ ] Task dependencies defined for sequential work
- [ ] File ownership clear (no two teammates editing same files — last write wins)
- [ ] Plan approval gates used for risky teammate work
- [ ] Tasks sized appropriately (5-6 per teammate for steady throughput)

### Limitations Acknowledged

- [ ] No `/resume` or `/rewind` support for teammates
- [ ] One team per session, no nested teams, fixed lead
- [ ] Spawn prompts include full context (teammates don't inherit lead history)

## 6. Token Efficiency

> Reference: [Claude Code Best Practices](https://code.claude.com/docs/en/best-practices)

### State Management

- [ ] State bus pattern for large data passing
- [ ] `CLAUDE_ENV_FILE` for cross-component state
- [ ] No large inline content dumps in prompts

### Optimization

- [ ] Capsule pattern for reusable reference data
- [ ] Progressive disclosure in skill files
- [ ] Expensive operations cached appropriately

## 7. Security

> Reference: [Claude Code Security](https://code.claude.com/docs/en/security)

### Secrets

- [ ] No secrets in committed files
- [ ] `.env` and credential files are gitignored
- [ ] No API keys or tokens in hooks/scripts

### Git Safety

- [ ] No `--no-verify` patterns allowed
- [ ] No force push patterns in hooks

### Tool Permissions

- [ ] Scoped `allowed-tools` (not permissive wildcards)
- [ ] PreToolUse blocking for dangerous commands
- [ ] No overly permissive Bash patterns

## 8. MCP Configuration (if applicable)

> Reference: [Claude Code MCP](https://code.claude.com/docs/en/mcp)

### Configuration

- [ ] `.mcp.json` is valid JSON
- [ ] Server configurations are complete
- [ ] No hardcoded credentials in MCP config

### Servers

- [ ] Server commands are correct
- [ ] Required environment variables documented
- [ ] Fallback behavior defined

---

## Severity Levels

When reporting findings, use these severity levels:

| Severity | Description |
|----------|-------------|
| **Critical** | Security risk, data loss potential, or blocks functionality |
| **Warning** | Best practice violation, potential issues, tech debt |
| **Suggestion** | Optimization opportunity, style improvement |

---

## Updating This Checklist

This checklist should be updated when:

- New Claude Code features are released
- New anti-patterns are discovered
- Best practices evolve

Use `/bluera-base:claude-code-guide` to research latest recommendations before updating.
