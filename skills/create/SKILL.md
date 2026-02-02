---
name: create
description: Create plugin components (commands, skills, hooks, agents, prompts) interactively
allowed-tools: [Read, Write, Edit, Glob, Grep, AskUserQuestion, Bash, Task]
---

# Create Plugin Component

Scaffold plugin components through iterative interviews. Works with any Claude Code plugin.

## Expert Consultation

**Always consult the `claude-code-guide` agent** when:

- Designing hook logic (exit codes, matchers, event types)
- Choosing between component types (skill vs agent vs hook)
- Validating generated content against best practices
- User asks questions about Claude Code features

```yaml
task:
  subagent_type: claude-code-guide
  prompt: |
    User is creating a <component_type> named <name>.

    Validate this design against Claude Code best practices:
    - <design details>

    Flag any anti-patterns or suggest improvements.
```

## Context

!`ls .claude-plugin/plugin.json 2>/dev/null && echo "Plugin detected" || echo "No plugin detected - will create in current directory"`

## Plugin Root Detection

Detect the target plugin directory:

1. If `$CLAUDE_PLUGIN_ROOT` set, use it
2. If `.claude-plugin/plugin.json` exists, use current directory
3. Otherwise, ask user for target path or create new plugin structure

## Workflow

### Phase 1: Component Type

Parse argument if provided (`/create command`, `/create skill`, etc.).

If no argument or argument not recognized:

```yaml
question: "What type of component do you want to create?"
header: "Component"
options:
  - label: "Command"
    description: "Slash command entry point (/plugin:name)"
  - label: "Skill"
    description: "Reusable workflow or knowledge"
  - label: "Hook"
    description: "Event-driven automation script"
  - label: "Agent"
    description: "Autonomous subagent definition"
  - label: "Prompt"
    description: "MCP prompt template with arguments"
multiSelect: false
```

### Phase 2: Type-Specific Interview

Based on component type, gather required information.

---

## Command Creation

### Interview

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

### Generate Command

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

### Output

- Write `commands/<name>.md`
- If thin command, also create `skills/<name>/SKILL.md`

---

## Skill Creation

### Interview

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

### Generate Skill

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

### Output

- Create `skills/<name>/` directory
- Write `skills/<name>/SKILL.md`

---

## Hook Creation

### Interview

1. **Name** (required): kebab-case identifier for the hook script

2. **Event type**:

```yaml
question: "When should this hook run?"
header: "Event"
options:
  - label: "PreToolUse"
    description: "Before a tool executes (can block)"
  - label: "PostToolUse"
    description: "After a tool succeeds"
  - label: "Stop"
    description: "When Claude finishes responding"
  - label: "SessionStart"
    description: "When session begins/resumes"
multiSelect: false
```

If "Other" selected, show full event list: PreToolUse, PostToolUse, PostToolUseFailure, Stop, SessionStart, SessionEnd, Notification, SubagentStart, SubagentStop, PreCompact, PermissionRequest, UserPromptSubmit.

1. **Matcher pattern** (for tool events):

If PreToolUse/PostToolUse/PermissionRequest selected:

```yaml
question: "Which tools should trigger this hook?"
header: "Matcher"
options:
  - label: "Bash"
    description: "Shell command execution"
  - label: "Edit|Write"
    description: "File modifications"
  - label: "All tools (*)"
    description: "Every tool invocation"
  - label: "Custom pattern"
    description: "Regex pattern (e.g., mcp__.*)"
multiSelect: false
```

1. **Hook type**:

```yaml
question: "How should this hook work?"
header: "Type"
options:
  - label: "Command (Recommended)"
    description: "Shell script that reads JSON stdin"
  - label: "Prompt"
    description: "LLM evaluates with single-turn response"
  - label: "Agent"
    description: "LLM agent with tool access for verification"
multiSelect: false
```

1. **For command type - Async?**:

```yaml
question: "Should this hook run in the background?"
header: "Async"
options:
  - label: "Sync (Recommended)"
    description: "Blocks until complete, can control outcome"
  - label: "Async"
    description: "Runs in background, cannot block"
multiSelect: false
```

1. **Timeout** (seconds): Default 30 for prompt, 60 for agent, 600 for command

2. **Status message** (optional): Shown while hook runs

### Generate Hook

**For command type:**

Create shell script `hooks/<name>.sh`:

```bash
#!/bin/bash
# <description>
# Event: <event>
# Matcher: <matcher>

set -euo pipefail

# Read hook input (defensive pattern)
INPUT=$(cat 2>/dev/null || true)

# Extract relevant fields
# For PreToolUse: tool_name, tool_input
# For Stop: stop_hook_active, transcript_path
# See hooks reference for full schemas

# Example: extract command from Bash tool
# COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Main logic
# Exit 0 = allow, Exit 2 = block with stderr message

exit 0
```

**For prompt type:**

Add to hooks.json:

```json
{
  "type": "prompt",
  "prompt": "<user-provided prompt>. Context: $ARGUMENTS",
  "model": "haiku",
  "timeout": 30
}
```

**For agent type:**

Add to hooks.json:

```json
{
  "type": "agent",
  "prompt": "<user-provided prompt>. $ARGUMENTS",
  "model": "haiku",
  "timeout": 60
}
```

### Update hooks.json

Read existing `hooks/hooks.json`, add new entry under appropriate event:

```json
{
  "hooks": {
    "<event>": [
      {
        "matcher": "<matcher>",
        "hooks": [<hook config>]
      }
    ]
  }
}
```

### Output

- For command type: Write `hooks/<name>.sh` and make executable
- Update `hooks/hooks.json` with registration
- Show hook input/output schema for the selected event

---

## Agent Creation

### Interview

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

### Generate Agent

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

### Output

- Create `agents/` directory if needed
- Write `agents/<name>.md`

---

## Prompt Creation (MCP)

### Interview

1. **Name** (required): Unique identifier (kebab-case)

2. **Title** (optional): Human-readable display name

3. **Description** (optional): What this prompt does

4. **Arguments**: Interview for each argument

```yaml
question: "Does this prompt need arguments?"
header: "Arguments"
options:
  - label: "Yes"
    description: "Prompt takes input parameters"
  - label: "No"
    description: "Static prompt with no parameters"
multiSelect: false
```

If yes, for each argument:

- Name (identifier)
- Description (what it's for)
- Required (yes/no)

1. **Prompt content**: The actual prompt template

### Generate Prompt

```markdown
---
name: <name>
title: <title if provided>
description: <description if provided>
arguments:
  - name: <arg1>
    description: <arg1 description>
    required: <true|false>
---

# <Title or Name>

<Prompt content with {{argument}} placeholders>
```

### Output

- Create `prompts/` directory if needed
- Write `prompts/<name>.md`

---

## Phase 3: Expert Review & Confirmation

**For hooks**: Before showing preview, consult claude-code-guide to validate:

- Exit code usage (0=allow, 2=block)
- Defensive stdin pattern
- stop_hook_active check for Stop hooks
- Proper use of ${CLAUDE_PLUGIN_ROOT}

Before writing files, show preview:

```text
## Component Preview

**Type**: <type>
**Name**: <name>
**Files to create**:
- <file 1>
- <file 2>

### Content Preview

<show generated content>

Proceed with creation?
```

```yaml
question: "Create this component?"
header: "Confirm"
options:
  - label: "Yes, create it"
    description: "Write files and complete setup"
  - label: "Edit first"
    description: "Make changes before creating"
  - label: "Cancel"
    description: "Don't create anything"
multiSelect: false
```

## Phase 4: Write Files

1. Create necessary directories
2. Write component files
3. For hooks: update hooks.json
4. For command hooks: make script executable

## Constraints

- **Consult claude-code-guide**: For hooks and complex components, spawn the expert agent to validate design
- **Detect plugin root**: Use `$CLAUDE_PLUGIN_ROOT` or `.claude-plugin/plugin.json`
- **Safe file creation**: Never overwrite without asking
- **Valid names**: Enforce kebab-case for all names
- **Executable hooks**: `chmod +x` for shell scripts
- **hooks.json merge**: Preserve existing hooks when adding new ones
- **Best practices**: Use defensive stdin pattern, proper exit codes, ${CLAUDE_PLUGIN_ROOT} paths
