# Milhouse Internals

Technical details about how the milhouse loop works.

## State File

The loop state is stored in `.bluera/bluera-base/state/milhouse-loop.md`:

- Automatically gitignored via `.bluera/` pattern (with config.json excepted)
- Contains: iteration, max_iterations, completion_promise, session_id, gates, failure_hashes
- Full prompt text stored in file body (after `---` frontmatter)

### State File Format

```markdown
---
iteration: 3
max_iterations: 20
completion_promise: "TASK COMPLETE"
session_id: "abc123"
gates:
  - "npm test"
  - "npm run lint"
failure_hashes: []
---

# Original Prompt

Your full prompt text here...
```

## Token-Efficient Continuation

The milhouse hook uses pointer-based continuation to minimize token usage:

- **On each iteration**, the hook injects a short continuation message, NOT the full prompt
- The model continues based on conversation context and file state
- The full prompt remains in the state file and can be re-read if needed

This design saves ~80-90% of tokens compared to re-injecting the full prompt each iteration.

### Continuation Message Format

```text
Continue working on the milhouse task. Review your previous work visible in files and git history.
State: .bluera/bluera-base/state/milhouse-loop.md
```

If you need to refresh on the original task, read the state file directly.

## Hook Chain

1. **milhouse-setup.sh** (SessionStart) - Initializes state file from command args
2. **milhouse-stop.sh** (Stop) - Intercepts completion, runs gates, re-prompts

## Files

| Path | Purpose |
|------|---------|
| `.bluera/bluera-base/state/milhouse-loop.md` | Loop state + original prompt |
| `.bluera/bluera-base/state/milhouse-plan.md` | Optional: acceptance criteria (with --init-harness) |
| `.bluera/bluera-base/state/milhouse-activity.md` | Optional: iteration log (with --init-harness) |
