---
name: learn
description: Manage semantic learnings from session analysis
user-invocable: true
allowed-tools: [Read, Write, Edit, Bash, AskUserQuestion]
---

# Deep Learning Management

Review, apply, or dismiss learnings captured from session analysis.

## How It Works

1. **Session Analysis**: After each session, key events are analyzed by Claude Haiku
2. **Learning Capture**: Project-specific insights are stored in `.bluera/bluera-base/state/pending-learnings.jsonl`
3. **User Review**: You review learnings before they're applied to CLAUDE.local.md
4. **Feedback Loop**: Applied learnings improve future sessions

## Commands

### Show Pending Learnings

Display learnings waiting for review:

```bash
# In your prompt
/bluera-base:learn show
```

### Apply a Learning

Add a learning to CLAUDE.local.md:

```bash
# Apply specific learning by number
/bluera-base:learn apply 1

# Apply all pending learnings
/bluera-base:learn apply all
```

### Dismiss a Learning

Mark a learning as not useful (won't be suggested again):

```bash
/bluera-base:learn dismiss 1
```

### Clear All Pending

Remove all pending learnings:

```bash
/bluera-base:learn clear
```

## Learning Types

| Type | Description | Example |
|------|-------------|---------|
| `correction` | User corrected Claude's approach | "Use `bun run test:e2e` not `bun test` for integration tests" |
| `error` | Error resolution discovered | "vitest.config.ts requires explicit include paths" |
| `fact` | Project-specific fact learned | "The API uses snake_case, not camelCase" |
| `workflow` | Successful workflow pattern | "Always run type-check before build in this repo" |

## Configuration

Enable deep learning:

```bash
/bluera-base:config enable deep-learn
```

Configure model and budget:

```bash
/bluera-base:config set .deepLearn.model haiku    # or sonnet
/bluera-base:config set .deepLearn.maxBudget 0.05 # USD per analysis
```

## Cost

- Haiku micro-analysis: ~$0.001 per session
- Daily usage (10 sessions): ~$0.01/day
- Monthly: ~$0.30

## Implementation

When this skill is invoked:

1. Read pending learnings from `.bluera/bluera-base/state/pending-learnings.jsonl`
2. For `show`: Display learnings with type, content, confidence, and created date
3. For `apply`: Use the autolearn library to write to CLAUDE.local.md, mark as applied
4. For `dismiss`: Remove from pending file
5. For `clear`: Remove all pending learnings

Use the existing `bluera_autolearn_write` function from `hooks/lib/autolearn.sh` for writing learnings.
