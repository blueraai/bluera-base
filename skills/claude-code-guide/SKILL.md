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

### 1.5 Ensure Knowledge Stores (one-time)

Before dispatching, check if bluera-knowledge stores are indexed:

1. Try `mcp__plugin_bluera-knowledge_bluera-knowledge__execute` with `command: stores`
2. If **MCP unavailable** (tool not found): print `[claude-code-guide] bluera-knowledge not installed — skipping knowledge store setup. Install for richer results.` and continue
3. If **available**: check if stores `claude-code`, `claude-skills`, `claude-plugins-official` exist in the response
4. If any are missing: run `/bluera-base:bluera-knowledge:sync` to index from `stores.config.json`
5. Skip this step if all stores already exist (idempotent)

### 2. For Questions

Spawn the `claude-code-guide` agent:

```yaml
task:
  subagent_type: claude-code-guide
  prompt: |
    User question: $ARGUMENTS

    IMPORTANT: You MUST search bluera-knowledge stores BEFORE answering.
    Query stores: claude-code, claude-skills, claude-plugins-official, claude-code-docs
    If bluera-knowledge is unavailable, skip silently and use other sources.

    Answer using your knowledge of Claude Code best practices.
    Cite sources.
```

### 3. For Review Mode

Spawn the agent with review instructions:

```yaml
task:
  subagent_type: claude-code-guide
  prompt: |
    IMPORTANT: Search bluera-knowledge stores first (claude-code, claude-skills, claude-plugins-official).

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
    IMPORTANT: Search bluera-knowledge stores first (claude-code, claude-skills, claude-plugins-official).

    Perform a comprehensive Claude Code audit.

    **Target**: $PATH (or current directory if not specified)
    **Specific focus**: $INSTRUCTIONS (or "full audit" if none)

    Use the checklist at skills/claude-code-guide/references/audit-checklist.md

    For each applicable section:
    1. Check current state
    2. Compare against best practices
    3. Note issues with severity (critical/warning/suggestion)
    4. Provide specific fixes

    Search bluera-knowledge and web for latest recommendations if needed.

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

### Settings Hierarchy

Managed > CLI (`--settings`) > Local (`.claude/settings.local.json`) > Project (`.claude/settings.json`) > User (`~/.claude/settings.json`)

Schema: `https://json.schemastore.org/claude-code-settings.json` — see [references/settings.md](references/settings.md)

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
