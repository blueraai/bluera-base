# Agent Creation

Full template and rules for creating agent components.

## Interview

1. **Name** (required): kebab-case identifier

2. **Description** (required): What this agent does

3. **Model**:

```yaml
question: "Which model should this agent use?"
header: "Model"
options:
  - label: "haiku (Recommended)"
    description: "Fast, cost-effective for simple tasks"
  - label: "sonnet"
    description: "Balanced for complex tasks"
  - label: "opus"
    description: "Maximum capability"
multiSelect: false
```

1. **Allowed tools**:

```yaml
question: "What tools should this agent have access to?"
header: "Tools"
options:
  - label: "Read-only (Recommended)"
    description: "Read, Glob, Grep - safe exploration"
  - label: "Read + Write"
    description: "Read, Glob, Grep, Write, Edit"
  - label: "Full access"
    description: "All tools including Bash"
  - label: "Custom"
    description: "Specify your own tool list"
multiSelect: false
```

1. **Skills to preload** (optional): Skills the agent should have loaded

## Generate Agent

```markdown
---
name: <name>
description: <description>
model: <model>
allowed-tools: [<tools>]
skills: [<skills if any>]
---

# <Name>

<description>

## Instructions

<agent-specific instructions>

## Constraints

- <constraint 1>
- <constraint 2>
```

## Output

- Create `agents/` directory if needed
- Write `agents/<name>.md`

## Subagent Types

When using the Task tool to spawn agents, use `subagent_type`:

| Type | Purpose |
|------|---------|
| `Explore` | Fast codebase exploration |
| `Plan` | Implementation planning |
| `Bash` | Command execution |
| `general-purpose` | Complex multi-step tasks |
| Custom agent name | Your defined agents |
