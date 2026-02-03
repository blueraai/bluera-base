# Hook Creation

Full template and rules for creating hook components.

## Interview

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

## Generate Hook

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

## Update hooks.json

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

## Output

- For command type: Write `hooks/<name>.sh` and make executable
- Update `hooks/hooks.json` with registration
- Show hook input/output schema for the selected event

## Hook Input Schemas

### PreToolUse / PostToolUse

```json
{
  "tool_name": "Bash",
  "tool_input": {
    "command": "git status"
  }
}
```

### Stop

```json
{
  "stop_hook_active": false,
  "transcript_path": "/path/to/transcript.jsonl",
  "session_id": "abc123"
}
```

### SessionStart

```json
{
  "session_id": "abc123",
  "project_path": "/path/to/project"
}
```

### Notification

```json
{
  "type": "user",
  "message": "Notification text"
}
```
