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

### Extract Learnings Now

Manually trigger deep-learn analysis on the current session:

```bash
/bluera-base:learn extract
```

**How it works:**

1. Find current session transcript: most recent `.jsonl` in `~/.claude/projects/<project-id>/`
2. Extract user messages and errors (same jq query as session-end-analyze.sh)
3. Send to Claude Haiku for analysis (~$0.001)
4. Write learnings to `.bluera/bluera-base/state/pending-learnings.jsonl`
5. Show count of learnings captured

**Requirements:**

- `deep-learn` must be enabled
- `claude` CLI must be installed
- Session must have ≥3 meaningful events (user messages or errors)

**Implementation:** See [references/extract-implementation.md](references/extract-implementation.md) for full bash implementation.

**Key points:**

- Use 120s timeout (vs 25s for background hook) - claude CLI can be slow to start
- Pipe prompt via stdin: `echo "$PROMPT" | timeout 120 claude -p --model haiku`
- Use exact same jq query as `hooks/session-end-analyze.sh` for event extraction
- Validate JSON response with `jq -e '.learnings'` before storing

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
6. For `extract`: Follow [references/extract-implementation.md](references/extract-implementation.md)

Use the existing `bluera_autolearn_write` function from `hooks/lib/autolearn.sh` for writing learnings.

## References

- [extract-implementation.md](references/extract-implementation.md) - Full bash implementation for manual extraction
