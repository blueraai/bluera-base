# Milhouse Options Reference

Complete option reference for the milhouse loop.

## Option Table

| Option | Description | Default |
|--------|-------------|---------|
| `--max-iterations <n>` | Stop after N iterations | unlimited |
| `--promise <text>` | Completion promise text | "TASK COMPLETE" |
| `--inline <prompt>` | Use inline prompt instead of file | - |
| `--gate <cmd>` | Command that must pass before exit (repeatable) | none |
| `--stuck-limit <n>` | Stop after N identical gate failures | 3 |
| `--init-harness` | Create plan.md and activity.md files | false |

## Context Harness

For long-running loops, use `--init-harness` to create tracking files:

```bash
/bluera-base:milhouse-loop task.md --init-harness
```

Creates:

- `.bluera/bluera-base/state/milhouse-plan.md` - Acceptance criteria checklist
- `.bluera/bluera-base/state/milhouse-activity.md` - Per-iteration progress log

Update these files each iteration to maintain context across compactions.

## Session Scoping

Each milhouse loop is tied to the terminal session that started it. If you have multiple Claude Code terminals in the same project, they won't interfere with each other's loops.

## Stopping Early

- **Max iterations**: Use `--max-iterations N` to auto-stop after N iterations
- **Manual cancel**: Run `/bluera-base:cancel-milhouse` to stop immediately
- **Stuck detection**: Triggers after 3 identical gate failures (configurable)
