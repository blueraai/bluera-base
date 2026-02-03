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

## Phase 1: Component Type

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

## Phase 2: Type-Specific Interview

Based on component type, follow the detailed reference:

| Type | Reference |
|------|-----------|
| Command | [references/command-creation.md](references/command-creation.md) |
| Skill | [references/skill-creation.md](references/skill-creation.md) |
| Hook | [references/hook-creation.md](references/hook-creation.md) |
| Agent | [references/agent-creation.md](references/agent-creation.md) |
| Prompt | [references/prompt-creation.md](references/prompt-creation.md) |

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
