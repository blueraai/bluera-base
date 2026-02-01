---
description: Manage semantic learnings from session analysis
argument-hint: [show|apply|dismiss|clear]
allowed-tools: Read, Write, Edit, Bash(jq:*), Bash(cat:*), Bash(wc:*), AskUserQuestion
---

# Deep Learning Management

Review, apply, or dismiss learnings captured from session analysis.

## Subcommands

| Command | Description |
|---------|-------------|
| `/bluera-base:learn` or `/bluera-base:learn show` | Display pending learnings |
| `/bluera-base:learn apply <n>` | Apply learning #n to CLAUDE.local.md |
| `/bluera-base:learn apply all` | Apply all pending learnings |
| `/bluera-base:learn dismiss <n>` | Mark learning #n as not useful |
| `/bluera-base:learn clear` | Remove all pending learnings |

---

## How It Works

1. **Session Analysis**: After each session, key events are analyzed by Claude Haiku
2. **Learning Capture**: Project-specific insights are stored in `.bluera/bluera-base/state/pending-learnings.jsonl`
3. **User Review**: You review learnings before they're applied to CLAUDE.local.md
4. **Feedback Loop**: Applied learnings improve future sessions

---

## Algorithm

### Show (default)

1. Read pending learnings from `.bluera/bluera-base/state/pending-learnings.jsonl`
2. Display learnings with type, content, confidence, and created date
3. Show total count and recommended actions

### Apply

Arguments: `<n>` or `all`

1. Load the specified learning(s) from pending file
2. Use `bluera_autolearn_write` to write to CLAUDE.local.md
3. Mark learning as applied (remove from pending)
4. Report what was added

### Dismiss

Arguments: `<n>`

1. Load the specified learning
2. Remove from pending file
3. Report dismissal

### Clear

1. Remove all entries from pending-learnings.jsonl
2. Report count of cleared learnings

---

## Learning Types

| Type | Description | Example |
|------|-------------|---------|
| `correction` | User corrected Claude's approach | "Use `bun run test:e2e` not `bun test`" |
| `error` | Error resolution discovered | "vitest.config.ts requires explicit include paths" |
| `fact` | Project-specific fact learned | "The API uses snake_case, not camelCase" |
| `workflow` | Successful workflow pattern | "Always run type-check before build" |

---

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

---

## Examples

```bash
# Show pending learnings
/bluera-base:learn show

# Apply specific learning by number
/bluera-base:learn apply 1

# Apply all pending learnings
/bluera-base:learn apply all

# Dismiss a learning (won't be suggested again)
/bluera-base:learn dismiss 2

# Clear all pending learnings
/bluera-base:learn clear
```

---

See @bluera-base/skills/learn/SKILL.md for complete documentation.
