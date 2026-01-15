---
name: milhouse
description: Iterative development loop that feeds the same prompt back after each iteration until task completion. Use /milhouse-loop to start.
---

# Milhouse Loop - Iterative Development

## Overview

The milhouse loop is a powerful pattern for iterative development tasks. It works by:

1. Starting with a prompt (from file or inline)
2. Working on the task
3. When you try to exit, the Stop hook intercepts and feeds the SAME PROMPT back
4. You continue iterating, building on previous work visible in files and git history
5. Loop ends when you output the completion promise or hit max iterations

## Starting a Loop

```bash
# From a prompt file
/milhouse-loop .claude/prompts/my-task.md

# With max iterations
/milhouse-loop .claude/prompts/my-task.md --max-iterations 10

# With custom completion promise
/milhouse-loop .claude/prompts/my-task.md --promise "FEATURE COMPLETE"

# Inline prompt (for simple tasks)
/milhouse-loop --inline "Refactor the auth module to use JWT tokens"
```

## Completing the Loop

To signal genuine completion, output this EXACT format on its own line:

```
<promise>TASK COMPLETE</promise>
```

Or with a custom promise:
```
<promise>YOUR_CUSTOM_PROMISE</promise>
```

**STRICT REQUIREMENTS:**
- The promise must appear on its OWN LINE (last non-empty line)
- Do NOT output false promises to escape the loop
- Only output when the task is genuinely complete

## Stopping Early

- **Max iterations**: Use `--max-iterations N` to auto-stop after N iterations
- **Manual cancel**: Run `/cancel-milhouse` to stop immediately

## State File

The loop state is stored in `.claude/milhouse-loop.local.md`:
- Should be gitignored (`.local.md` pattern)
- Contains: iteration count, max iterations, completion promise, prompt content

## Use Cases

1. **Complex refactoring**: Keep iterating until all tests pass
2. **Performance optimization**: Iterate until benchmark targets are met
3. **Bug hunting**: Keep investigating until root cause is found
4. **Feature implementation**: Iterate through design, implement, test cycles

## Example Prompt File

```markdown
# Task: Optimize Database Queries

## Goal
Reduce average query time from 500ms to under 100ms.

## Current State
- Average query time: 500ms
- Slowest queries in: user_analytics.py

## Iteration Steps
1. Profile current performance
2. Identify bottlenecks
3. Implement optimization
4. Measure improvement
5. If target not met, continue iterating

## Completion Criteria
Output <promise>TASK COMPLETE</promise> when average query time < 100ms.
```
