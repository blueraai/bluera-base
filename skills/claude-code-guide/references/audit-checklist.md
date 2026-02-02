# Claude Code Audit Checklist

Comprehensive checklist for auditing Claude Code configurations and plugins.

**Official Documentation:**

- [Claude Code Plugins](https://docs.anthropic.com/en/docs/claude-code/plugins)
- [Claude Code Hooks](https://docs.anthropic.com/en/docs/claude-code/hooks)
- [Claude Code Skills](https://docs.anthropic.com/en/docs/claude-code/skills)
- [Claude Code MCP](https://docs.anthropic.com/en/docs/claude-code/mcp)
- [CLAUDE.md Memory Files](https://docs.anthropic.com/en/docs/claude-code/memory)

## 1. Project Configuration

> Reference: [CLAUDE.md Memory Files](https://docs.anthropic.com/en/docs/claude-code/memory)

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

> Reference: [Claude Code Plugins](https://docs.anthropic.com/en/docs/claude-code/plugins)

### Manifest

- [ ] `.claude-plugin/plugin.json` in correct location (not nested)
- [ ] Has required fields: `name`, `version`, `description`
- [ ] Version follows semver
- [ ] No deprecated fields

### Directory Layout

- [ ] Commands at `commands/*.md` (not nested in `.claude-plugin/`)
- [ ] Skills at `skills/*/SKILL.md`
- [ ] Hooks at `hooks/hooks.json` + `hooks/*.sh`
- [ ] Agents at `agents/*.md` (if used)

## 3. Commands

> Reference: [Claude Code Commands](https://docs.anthropic.com/en/docs/claude-code/plugins#commands)

### Frontmatter

- [ ] All commands have `description` frontmatter
- [ ] `allowed-tools` are explicit (no wildcards like `Bash(*)`)
- [ ] `argument-hint` present where arguments are expected
- [ ] No deprecated frontmatter fields

### Structure

- [ ] Thin command + thick skill pattern used
- [ ] Command body is minimal (references skill)
- [ ] No duplicate logic across commands

## 4. Skills

> Reference: [Claude Code Skills](https://docs.anthropic.com/en/docs/claude-code/skills)

### Organization

- [ ] SKILL.md files are lean (<200 lines)
- [ ] Deep content in `references/` subdirectory
- [ ] Progressive disclosure structure
- [ ] Clear "When This Skill Applies" section

### Syntax

- [ ] No deprecated argument syntax (`$ARGUMENTS.0` should be `$ARGUMENTS[0]`)
- [ ] Workflow sections are clear and actionable
- [ ] Quick reference sections for common patterns

## 5. Hooks

> Reference: [Claude Code Hooks](https://docs.anthropic.com/en/docs/claude-code/hooks)

### Configuration

- [ ] `hooks.json` has valid structure
- [ ] Matchers use correct regex syntax
- [ ] Event types are valid

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

## 6. Token Efficiency

> Reference: [Claude Code Best Practices](https://docs.anthropic.com/en/docs/claude-code/best-practices)

### State Management

- [ ] State bus pattern for large data passing
- [ ] `CLAUDE_ENV_FILE` for cross-component state
- [ ] No large inline content dumps in prompts

### Optimization

- [ ] Capsule pattern for reusable reference data
- [ ] Progressive disclosure in skill files
- [ ] Expensive operations cached appropriately

## 7. Security

> Reference: [Claude Code Security](https://docs.anthropic.com/en/docs/claude-code/security)

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

> Reference: [Claude Code MCP](https://docs.anthropic.com/en/docs/claude-code/mcp)

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
