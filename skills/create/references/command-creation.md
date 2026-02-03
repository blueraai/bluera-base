# Command Creation

Full template and rules for creating command components.

## Interview

1. **Name** (required): kebab-case identifier

```yaml
question: "What should this command be called?"
header: "Name"
options:
  - label: "deploy"
    description: "Example: /plugin:deploy"
  - label: "validate"
    description: "Example: /plugin:validate"
  - label: "sync"
    description: "Example: /plugin:sync"
multiSelect: false
```

If "Other" selected, user provides custom name.

1. **Description** (required): One-line description shown in `/` menu

2. **Create associated skill?**

```yaml
question: "Should this command have an associated skill?"
header: "Skill"
options:
  - label: "Yes, create skill (Recommended)"
    description: "Thin command + full skill in skills/<name>/SKILL.md"
  - label: "No, inline content"
    description: "All content in the command file itself"
multiSelect: false
```

1. **Allowed tools** (if inline):

```yaml
question: "What tools should this command be able to use?"
header: "Tools"
options:
  - label: "Read-only (Recommended for most)"
    description: "Read, Glob, Grep"
  - label: "Read + Write"
    description: "Read, Glob, Grep, Write, Edit"
  - label: "Full access"
    description: "Read, Write, Edit, Bash, Glob, Grep"
  - label: "Custom"
    description: "Specify your own tool list"
multiSelect: false
```

## Generate Command

**If thin command (with skill):**

```markdown
---
description: <description>
argument-hint: <hint if any>
allowed-tools: Read, Write, Edit, Glob, Grep, AskUserQuestion
---

See skills/<name>/SKILL.md
```

Then create the skill (proceed to Skill Creation).

**If inline command:**

```markdown
---
description: <description>
argument-hint: <hint if any>
allowed-tools: <selected tools>
---

# <Name>

<description>

## Workflow

<!-- User defines workflow here -->
```

## Output

- Write `commands/<name>.md`
- If thin command, also create `skills/<name>/SKILL.md`
