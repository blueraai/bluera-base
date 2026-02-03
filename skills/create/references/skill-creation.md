# Skill Creation

Full template and rules for creating skill components.

## Interview

1. **Name** (required): kebab-case identifier

2. **Description** (required): Full description of what the skill does

3. **Invocation type**:

```yaml
question: "How should this skill be invoked?"
header: "Invocation"
options:
  - label: "User-invocable (Recommended)"
    description: "User triggers with /plugin:name"
  - label: "Model-invocable"
    description: "Claude can load automatically when relevant"
  - label: "Both"
    description: "User or Claude can invoke"
multiSelect: false
```

1. **Allowed tools**:

```yaml
question: "What tools should this skill use?"
header: "Tools"
options:
  - label: "Read-only"
    description: "Read, Glob, Grep"
  - label: "Read + Write (Recommended)"
    description: "Read, Glob, Grep, Write, Edit"
  - label: "Full access"
    description: "Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion"
  - label: "Custom"
    description: "Specify your own tool list"
multiSelect: false
```

1. **Workflow phases**: Interview for key steps (use brainstorming approach)

## Generate Skill

```markdown
---
name: <name>
description: <description>
allowed-tools: [<tools>]
disable-model-invocation: <true if user-only>
---

# <Name>

<description>

## Context

!`<context command if needed>`

## Workflow

### Phase 1: <First Phase>

<instructions>

### Phase 2: <Second Phase>

<instructions>

## Constraints

- <constraint 1>
- <constraint 2>
```

## Output

- Create `skills/<name>/` directory
- Write `skills/<name>/SKILL.md`
