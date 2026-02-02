---
name: claude-code-guide
description: Use when working on Claude Code plugins, hooks, skills, commands, agents, or MCP. Provides expert guidance and reviews implementations.
allowed-tools: [Read, Glob, Grep, Task]
---

# Claude Code Guide

Expert guidance for Claude Code and plugin development.

## When This Skill Applies

Auto-invoke when:

- Questions about Claude Code features (hooks, skills, commands, agents, MCP)
- Working on files in `hooks/`, `skills/`, `commands/`, `agents/`, `prompts/`
- Creating or modifying `.claude-plugin/plugin.json` or `hooks.json`
- Debugging hook behavior
- "How do I..." questions about Claude Code

## Workflow

### 1. Detect Mode

Parse argument to determine mode:

- **`review`** - Review current plugin against best practices
- **Question** - Answer the question using expert knowledge
- **No argument** - Offer both options

### 2. For Questions

Spawn the `claude-code-guide` agent:

```yaml
task:
  subagent_type: claude-code-guide
  prompt: |
    User question: $ARGUMENTS

    Answer using your knowledge of Claude Code best practices.
    Search documentation if needed. Cite sources.
```

### 3. For Review Mode

Spawn the agent with review instructions:

```yaml
task:
  subagent_type: claude-code-guide
  prompt: |
    Review the current plugin for:
    1. Plugin structure (plugin.json location, directory layout)
    2. Hook implementations (exit codes, defensive stdin, stop_hook_active)
    3. Command/skill frontmatter
    4. Anti-patterns (Bash(*), inline large content, hardcoded paths)
    5. Token efficiency

    Provide specific, actionable fixes for any issues found.
```

## Quick Reference

### Plugin Structure

```text
plugin/
├─ .claude-plugin/plugin.json  # Manifest only
├─ commands/*.md               # Slash commands
├─ skills/*/SKILL.md           # Skills
├─ hooks/hooks.json            # Hook registration
├─ hooks/*.sh                  # Hook scripts
└─ agents/*.md                 # Subagents
```

### Hook Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Allow/success |
| 2 | Block with stderr |
| Other | Non-blocking error |

### Common Fixes

| Issue | Fix |
|-------|-----|
| Hook not firing | Check matcher regex, file permissions, hooks.json syntax |
| Infinite Stop loop | Check `stop_hook_active` before continuing |
| Console hangs | Use `INPUT=$(cat 2>/dev/null \|\| true)` |
| Paths break | Use `${CLAUDE_PLUGIN_ROOT}` |

## Constraints

- Always spawn the claude-code-guide agent for detailed work
- Cite sources (docs, files, line numbers)
- Provide specific, actionable fixes
- Don't make assumptions - search documentation when unsure
