# Hook Examples

Practical hook implementations from bluera-base with explanations.

---

## Hook Types Overview

| Hook Event | When It Fires | Common Uses |
|------------|---------------|-------------|
| SessionStart | Session begins | Dependency checks, env setup, context injection |
| PreToolUse | Before tool execution | Block dangerous commands, policy enforcement |
| PostToolUse | After tool execution | Linting, formatting, validation |
| Stop | Before session ends | Loop continuation, cleanup, summaries |
| PreCompact | Before compaction | State preservation |
| Notification | Claude waiting for user | Desktop notifications, alerts |

---

## PreToolUse: Blocking Patterns

Block dangerous or policy-violating commands before execution.

### Example: Block Manual Release Commands

**Purpose**: Force use of `/bluera-base:release` skill instead of manual version bumps.

```bash
#!/bin/bash
# hooks/block-manual-release.sh

# Read tool input from stdin
INPUT=$(cat)

# Extract the command from Bash tool input
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

# If no command, allow
[ -z "$COMMAND" ] && exit 0

# Allow if invoked from /bluera-base:release skill (skill prefix makes it intentional)
if echo "$COMMAND" | grep -qE '^__SKILL__=release '; then
  exit 0
fi

# Block --no-verify on git commit (absolute rule)
if echo "$COMMAND" | grep -qE '\bgit\s+commit\b.*--no-verify'; then
  echo "Blocked: git commit --no-verify is forbidden. Fix pre-commit failures." >&2
  exit 2
fi

# Block manual version/release commands
BLOCK_PATTERNS='(npm|yarn|pnpm|bun)( run)? (version|release)'
BLOCK_PATTERNS="$BLOCK_PATTERNS|git tag v[0-9]"
BLOCK_PATTERNS="$BLOCK_PATTERNS|gh release create"

if echo "$COMMAND" | grep -qE "$BLOCK_PATTERNS"; then
  echo "Manual release commands are blocked. Use /bluera-base:release instead." >&2
  exit 2
fi

exit 0
```

### Hook Registration

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/block-manual-release.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

### Key Patterns

1. **Read stdin JSON**: Hook input comes via stdin
2. **Extract relevant fields**: Use jq to parse tool_input
3. **Exit 0**: Allow the command
4. **Exit 2 + stderr**: Block with message shown to user
5. **Skill prefix check**: Allow trusted skill invocations

---

## PostToolUse: Validation Patterns

Run validation after file edits.

### Example: Smart Post-Edit Validation

**Purpose**: Auto-lint and type-check after Write/Edit operations.

> **Note:** This is a simplified example. The actual bluera-base `post-edit-check.sh` treats lint/typecheck as advisory (non-blocking) and includes rate limiting to avoid running on every edit.

```bash
#!/bin/bash
# hooks/post-edit-check.sh
set -euo pipefail

cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

# Read stdin JSON
INPUT=$(cat || true)
[ -z "$INPUT" ] && exit 0

# Extract tool name and file path
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null || echo "")
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null || echo "")

# Only process Write/Edit tools
case "$TOOL_NAME" in
  Write|Edit) ;;
  *) exit 0 ;;
esac

# Need a file path
[ -z "$FILE_PATH" ] && exit 0

# Skip generated paths
case "$FILE_PATH" in
  dist/*|build/*|node_modules/*|.git/*) exit 0 ;;
esac

# Detect package manager
detect_runner() {
  if [ -f "bun.lockb" ]; then echo "bun"
  elif [ -f "yarn.lock" ]; then echo "yarn"
  elif [ -f "pnpm-lock.yaml" ]; then echo "pnpm"
  else echo "npm"
  fi
}

# Lint JavaScript/TypeScript files
case "$FILE_PATH" in
  *.ts|*.tsx|*.js|*.jsx)
    if [ -f "package.json" ]; then
      RUNNER=$(detect_runner)

      # Invoke project's lint script (no auto-fix - let user control)
      LINT_OUT=$("$RUNNER" run lint --quiet 2>&1 || true)
      if [ -n "$LINT_OUT" ]; then
        echo "$LINT_OUT" >&2
        exit 2
      fi
    fi
    ;;
esac

exit 0
```

### Key Patterns

1. **Tool filtering**: Only run for specific tools (Write/Edit)
2. **Path filtering**: Skip generated/vendor directories
3. **Use project scripts**: Invoke the project's own lint/typecheck scripts
4. **Report errors**: Block if lint errors remain
5. **Rate limiting**: For expensive checks (type checking), use timestamps to avoid running on every edit

---

## Stop Hook: Loop Continuation

Intercept session stop for autonomous iteration.

### Example: Milhouse Loop

**Purpose**: Keep working until completion promise matched and tests pass.

```bash
#!/bin/bash
# hooks/milhouse-stop.sh
set -euo pipefail

# Read hook input
HOOK_INPUT=$(cat)

# Prevent infinite loop - check if stop hook already tried
STOP_HOOK_ACTIVE=$(echo "$HOOK_INPUT" | jq -r '.stop_hook_active // false')
if [[ "$STOP_HOOK_ACTIVE" == "true" ]]; then
  exit 0  # Already tried once, allow exit
fi

# Check for active loop state file
STATE_FILE=".bluera/bluera-base/state/milhouse-loop.md"
if [[ ! -f "$STATE_FILE" ]]; then
  exit 0  # No active loop
fi

# Parse state (YAML frontmatter)
FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$STATE_FILE")
ITERATION=$(echo "$FRONTMATTER" | grep '^iteration:' | sed 's/iteration: *//')
MAX_ITERATIONS=$(echo "$FRONTMATTER" | grep '^max_iterations:' | sed 's/max_iterations: *//')
COMPLETION_PROMISE=$(echo "$FRONTMATTER" | grep '^completion_promise:' | \
  sed 's/completion_promise: *"\(.*\)"/\1/')

# Check max iterations
if [[ $ITERATION -ge $MAX_ITERATIONS ]]; then
  echo "Max iterations ($MAX_ITERATIONS) reached."
  rm "$STATE_FILE"
  exit 0
fi

# Get last assistant output from transcript
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path')
LAST_OUTPUT=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" | tail -1 | \
  jq -r '.message.content | map(select(.type == "text")) | map(.text) | join("\n")')

# Check for completion promise on last line
LAST_LINE=$(echo "$LAST_OUTPUT" | grep -v '^\s*$' | tail -1)
if echo "$LAST_LINE" | grep -qE "<promise>$COMPLETION_PROMISE</promise>"; then
  echo "Completion promise matched."
  rm "$STATE_FILE"
  exit 0
fi

# Not complete - continue loop
NEXT_ITERATION=$((ITERATION + 1))
sed -i '' "s/^iteration: .*/iteration: $NEXT_ITERATION/" "$STATE_FILE"

# Block stop and inject continuation
jq -n --arg reason "Continue working. Iteration $NEXT_ITERATION/$MAX_ITERATIONS" \
  '{"decision": "block", "reason": $reason}'
```

### Key Patterns

1. **stop_hook_active check**: Prevent infinite retry loops
2. **State file check**: Only act if loop is active
3. **Session scoping**: Verify session ID matches
4. **Promise detection**: Check last line, not entire output
5. **JSON output**: `{"decision": "block", "reason": "..."}` to continue
6. **State update**: Increment iteration before continuing

---

## SessionStart: Environment Setup

Initialize dependencies and publish environment variables.

### Example: Session Setup

**Purpose**: Check dependencies and publish state pointers.

```bash
#!/bin/bash
# hooks/session-setup.sh
set -e

PREFIX="[my-plugin]"

# Check required dependency
if ! command -v jq &> /dev/null; then
    # Attempt auto-install on macOS
    if [[ "$OSTYPE" == "darwin"* ]] && command -v brew &> /dev/null; then
        brew install jq &>/dev/null && echo "$PREFIX jq installed" || \
            echo "$PREFIX jq missing. Install: brew install jq"
    else
        echo "$PREFIX jq missing. Install from https://stedolan.github.io/jq/"
    fi
else
    echo "$PREFIX jq ready"
fi

# Ensure hook scripts are executable
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname "$(dirname "$0")")}"
for hook in "$PLUGIN_ROOT"/hooks/*.sh; do
    [[ -f "$hook" ]] && [[ ! -x "$hook" ]] && chmod +x "$hook"
done

# Publish state pointers via CLAUDE_ENV_FILE
if [[ -n "${CLAUDE_ENV_FILE:-}" ]] && [[ -f "$CLAUDE_ENV_FILE" ]]; then
    PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
    {
        echo "export MY_STATE_DIR=\"$PROJECT_DIR/.my-plugin/state\""
        echo "export MY_CONFIG=\"$PROJECT_DIR/.my-plugin/config.json\""
    } >> "$CLAUDE_ENV_FILE"
fi

# Always exit 0 to not block session
exit 0
```

### Key Patterns

1. **Dependency checks**: Verify required tools exist
2. **Auto-install**: Attempt silent install where safe
3. **Executable permissions**: Ensure scripts can run
4. **CLAUDE_ENV_FILE**: Publish pointers for later Bash commands
5. **Always exit 0**: Never block session startup

---

## SessionStart: Context Injection

Inject critical invariants into every session.

```bash
#!/bin/bash
# hooks/inject-invariants.sh

INVARIANTS=$(cat << 'EOF'
Critical project rules:
- Run tests before commit
- Use conventional commit format
- Never skip pre-commit hooks
EOF
)

jq -n --arg ctx "$INVARIANTS" '{
  "hookSpecificOutput": {
    "additionalContext": $ctx
  }
}'
```

---

## Notification Hook: Desktop Alerts

Send notifications when Claude is waiting.

### Example: macOS Notification

```bash
#!/bin/bash
# hooks/notify.sh

# Read notification payload
INPUT=$(cat)
TITLE=$(echo "$INPUT" | jq -r '.title // "Claude Code"')
MESSAGE=$(echo "$INPUT" | jq -r '.message // "Waiting for input"')

# macOS notification
if [[ "$OSTYPE" == "darwin"* ]]; then
    osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\""
fi

exit 0
```

---

## Hook Templates

### Minimal PreToolUse Template

```bash
#!/bin/bash
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[ -z "$COMMAND" ] && exit 0

# Your blocking logic here
if [[ "$COMMAND" == *"dangerous-pattern"* ]]; then
    echo "Blocked: reason here" >&2
    exit 2
fi

exit 0
```

### Minimal PostToolUse Template

```bash
#!/bin/bash
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

# Only process specific tools
[[ "$TOOL_NAME" != "Write" && "$TOOL_NAME" != "Edit" ]] && exit 0

# Your validation logic here

exit 0
```

### Minimal Stop Hook Template

```bash
#!/bin/bash
HOOK_INPUT=$(cat)

# Prevent infinite loops
STOP_HOOK_ACTIVE=$(echo "$HOOK_INPUT" | jq -r '.stop_hook_active // false')
[[ "$STOP_HOOK_ACTIVE" == "true" ]] && exit 0

# Your continuation logic here

# To continue:
jq -n '{"decision": "block", "reason": "Continue..."}'

# To allow exit:
exit 0
```

---

## Common Mistakes

### 1. Not Checking stop_hook_active

```bash
# WRONG - infinite loop risk
if ! task_complete; then
    jq -n '{"decision": "block"}'
fi

# RIGHT
STOP_HOOK_ACTIVE=$(echo "$HOOK_INPUT" | jq -r '.stop_hook_active // false')
if [[ "$STOP_HOOK_ACTIVE" == "true" ]]; then
    exit 0  # Stop hook already tried
fi
```

### 2. Blocking Session Start

```bash
# WRONG - blocks session
command_that_fails || exit 1

# RIGHT - warn but don't block
command_that_fails || echo "Warning: ..." >&2
exit 0
```

### 3. Not Validating JSON

```bash
# WRONG - fails silently on bad JSON
VALUE=$(echo "$INPUT" | jq -r '.field')

# RIGHT - handle parse errors
if ! VALUE=$(echo "$INPUT" | jq -r '.field' 2>&1); then
    echo "Parse error" >&2
    exit 0
fi
```

---

## References

- [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks)
- [Hooks Guide](https://code.claude.com/docs/en/hooks-guide)
- bluera-base source: `hooks/*.sh`
