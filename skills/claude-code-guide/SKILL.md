---
name: claude-code-guide
description: Use when working on Claude Code plugins, hooks, skills, commands, agents, or MCP. Provides expert guidance and reviews implementations.
argument-hint: "<question or 'review'>"
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
- **`audit`** or **`audit [path] [instructions]`** - Comprehensive audit against checklist
- **`graph`** - Generate dependency graph (delegate to `/bluera-base:claude-code-graph`)
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

### 4. For Graph Mode

Delegate to the specialized graph skill:

```bash
/bluera-base:claude-code-graph [path]
```

Use this when user asks about:

- Plugin structure visualization
- Dependency analysis
- Component relationships
- "What calls what" questions

### 5. For Audit Mode

Parse arguments:

- First arg starting with `/` or `.` or containing `/` → treat as path
- Remaining args → natural language instructions (e.g., "focus on hooks")

Spawn the agent with comprehensive audit:

```yaml
task:
  subagent_type: claude-code-guide
  prompt: |
    Perform a comprehensive Claude Code audit.

    **Target**: $PATH (or current directory if not specified)
    **Specific focus**: $INSTRUCTIONS (or "full audit" if none)

    Use the checklist at skills/claude-code-guide/references/audit-checklist.md

    For each applicable section:
    1. Check current state
    2. Compare against best practices
    3. Note issues with severity (critical/warning/suggestion)
    4. Provide specific fixes

    Search documentation and web for latest recommendations if needed.

    Output format:
    ## Audit Report: [project name]

    ### Summary
    - Critical: N
    - Warnings: N
    - Suggestions: N

    ### Findings
    [Grouped by checklist section, only include sections with findings]

    ### Recommendations
    [Prioritized list of fixes]
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

## Related Skills

| Skill | Use For |
|-------|---------|
| `/bluera-base:claude-code-graph` | Dependency graphs, structure visualization |
| `/bluera-base:claude-code-audit-plugin` | Full plugin audit with fixes |
| `/bluera-base:claude-code-test-plugin` | Validation test suite |

## Constraints

- Always spawn the claude-code-guide agent for detailed work
- Delegate to specialized skills when appropriate (graph, audit, test)
- Cite sources (docs, files, line numbers)
- Provide specific, actionable fixes
- Don't make assumptions - search documentation when unsure
