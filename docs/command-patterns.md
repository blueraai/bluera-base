# Command Patterns

Pattern guide for creating slash commands in bluera-base plugins.

## Thin Command / Heavy SKILL Pattern

Commands should be **thin** (~20-30 lines) with details in the SKILL.md.

> **Exception:** Some commands use `context: fork` and are intentionally self-contained (100+ lines). These include `config`, `init`, and `analyze-config` which run in isolated contexts and need all instructions inline. When using `context: fork`, the command cannot reference external SKILL.md files.

### Command Structure

```yaml
---
description: Brief one-line description
argument-hint: "[optional args]"
allowed-tools: Tool1, Tool2, Bash(cmd:*)
---

# Command Name

One-line purpose.

## Context

!`shell command for context`

## Workflow

See @bluera-base/skills/<skill-name>/SKILL.md for complete workflow.

**Phases:** Phase1 → Phase2 → Phase3

**Key rules:** Brief safety or behavior notes
```

### What Goes Where

| Content | Location |
|---------|----------|
| Frontmatter (description, tools) | Command |
| One-line purpose | Command |
| Context shell commands (`!` prefix) | Command |
| Workflow reference | Command |
| Phase summary | Command |
| Key safety rules (1-2 lines) | Command |
| Detailed instructions | SKILL.md |
| Step-by-step workflow | SKILL.md |
| Examples and code blocks | SKILL.md |
| Tables and reference data | SKILL.md |

### SKILL.md Frontmatter

```yaml
---
name: skill-name
description: Full description. Use /bluera-base:command to run.
---
```

## Examples

**Good** (thin command - commit.md):

```markdown
---
description: Create atomic commits
allowed-tools: Bash(git:*), Read
---

# Commit

Create atomic commits.

## Context

!`git status -s | head -10`

## Workflow

See @bluera-base/skills/atomic-commits/SKILL.md for criteria.

**Phases:** Analyze → Check docs → Group → Commit

**Safety:** Never --no-verify. Never amend pushed commits.
```

**Bad** (heavy command):

```markdown
---
description: Create atomic commits
---

# Commit

## Step 1: Analyze Changes
Run git status...

## Step 2: Check Documentation
Look for README changes...

[100+ lines of instructions]
```

## Subcommands via Arguments

Use `argument-hint` for subcommands instead of separate command files:

```yaml
argument-hint: "[scan | fix <action>] [--confirm]"
```

This enables:

- `/command` - default mode
- `/command scan` - scan subcommand
- `/command fix action` - fix subcommand with arg
