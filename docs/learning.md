# Learning System

Bluera Base has two complementary learning systems that capture project-specific insights and incorporate them back into Claude's context for future sessions.

## Overview

```mermaid
flowchart TB
    subgraph Observation["1. Observation"]
        A[observe-learning.sh]
        B[session-end-analyze.sh]
    end

    subgraph Storage["2. Storage"]
        C[session-signals.json]
        D[pending-learnings.jsonl]
    end

    subgraph Synthesis["3. Synthesis"]
        E[session-end-learn.sh]
        F[/learn command]
    end

    subgraph Incorporation["4. Incorporation"]
        G[CLAUDE.local.md]
        H[CLAUDE.md]
    end

    subgraph Usage["5. Usage"]
        I[Claude Context]
    end

    A -->|track commands| C
    B -->|AI analysis| D
    C --> E
    D --> F
    E -->|auto mode| G
    E -->|suggest mode| F
    F -->|apply| G
    F -->|apply --shared| H
    G -->|session start| I
    H -->|session start| I

    style Observation fill:#6366f1,color:#fff
    style Storage fill:#f59e0b,color:#fff
    style Synthesis fill:#8b5cf6,color:#fff
    style Incorporation fill:#16a34a,color:#fff
    style Usage fill:#0891b2,color:#fff
```

## Auto-Learn (Pattern-Based)

Tracks recurring commands during sessions and generates learnings automatically.

### Flow

1. **Observation** (`observe-learning.sh` - PreToolUse on Bash)
   - Tracks commands: `npm:test`, `git:status`, `cargo:build`, etc.
   - Writes to `.bluera/bluera-base/state/session-signals.json`

2. **Synthesis** (`session-end-learn.sh` - Stop hook)
   - Analyzes commands that occurred ≥ threshold times (default: 3)
   - Generates suggestions: "Run tests frequently during development"

3. **Incorporation** (based on mode)
   - **`suggest` mode** (default): Shows suggestions, run `/learn apply` manually
   - **`auto` mode**: Writes directly to target CLAUDE.md file

### Configuration

```bash
# Enable auto-learn
/bluera-base:config enable auto-learn

# Set mode
/bluera-base:config set .autoLearn.mode auto     # or "suggest"

# Set threshold (occurrences before suggesting)
/bluera-base:config set .autoLearn.threshold 3

# Set target file
/bluera-base:config set .autoLearn.target local  # or "shared"
```

| Setting | Options | Default | Description |
|---------|---------|---------|-------------|
| `mode` | `suggest`, `auto` | `suggest` | Show suggestions vs auto-write |
| `threshold` | number | `3` | Occurrences before acting |
| `target` | `local`, `shared` | `local` | CLAUDE.local.md vs CLAUDE.md |

---

## Deep-Learn (AI-Powered)

Semantic analysis of session transcripts to extract meaningful, project-specific insights.

### Flow

1. **Observation** (`session-end-analyze.sh` - Stop hook)
   - Extracts key events from session transcript (user messages, errors)
   - Sends to Claude Haiku for semantic analysis (~$0.001)
   - Stores learnings in `.bluera/bluera-base/state/pending-learnings.jsonl`

2. **Review** (`/bluera-base:learn` command)
   - `show` - View pending learnings with type, confidence, date
   - `apply N` - Apply specific learning
   - `apply all` - Apply all learnings
   - `dismiss N` - Mark as not useful
   - `clear` - Remove all pending
   - `extract` - Manually trigger analysis on current session

3. **Incorporation**
   - Applied learnings are written to CLAUDE.local.md (or CLAUDE.md)

### Learning Types

| Type | Description | Example |
|------|-------------|---------|
| `correction` | User corrected Claude's approach | "Use `bun run test:e2e` not `bun test`" |
| `error` | Error resolution discovered | "vitest.config.ts requires explicit include paths" |
| `fact` | Project-specific fact | "The API uses snake_case, not camelCase" |
| `workflow` | Successful workflow pattern | "Always run type-check before build" |

### Configuration

```bash
# Enable deep learning
/bluera-base:config enable deep-learn

# Configure model
/bluera-base:config set .deepLearn.model haiku    # or "sonnet"

# Set budget limit per analysis
/bluera-base:config set .deepLearn.maxBudget 0.05
```

### Cost

- Per session: ~$0.001 (Haiku)
- Daily (10 sessions): ~$0.01
- Monthly: ~$0.30

---

## Where Learnings Are Stored

### Target Files

| Target | File | Git Status | Use Case |
|--------|------|------------|----------|
| `local` (default) | `CLAUDE.local.md` | Gitignored | Personal preferences, machine-specific |
| `shared` | `CLAUDE.md` | Committed | Team-wide conventions |

### Marker Region

Learnings are written to a dedicated section with markers:

```markdown
## Auto-Learned (bluera-base)
<!-- AUTO:bluera-base:learned -->
- Check git status before commits
- Run tests before pushing
- Uses conventional commits with hook enforcement
<!-- END:bluera-base:learned -->
```

**Safeguards:**

- Maximum 50 learnings (prevents bloat)
- Duplicate detection (normalized comparison)
- Secrets pattern blocking (API keys, tokens, etc.)

---

## How Claude Uses Learnings

Since learnings are written to `CLAUDE.local.md` or `CLAUDE.md`, they become part of Claude's context through the standard CLAUDE.md hierarchy:

```text
Session starts
    ↓
Claude Code loads CLAUDE.md hierarchy:
  - ~/CLAUDE.md (global)
  - ./CLAUDE.md (project)
  - ./CLAUDE.local.md (personal)
  - ./.claude/rules/*.md (rules)
    ↓
Learnings in <!-- AUTO:bluera-base:learned --> section
are visible to Claude as project instructions
    ↓
Claude applies learnings to future work
```

---

## Example Learnings

After using bluera-base for a while, your CLAUDE.local.md might contain:

```markdown
## Auto-Learned (bluera-base)
<!-- AUTO:bluera-base:learned -->
- Check git status before commits
- Run tests before pushing to main
- Use bun instead of npm for this project
- The API requires authentication headers on all endpoints
- Database migrations must be run with `bun run db:migrate`
<!-- END:bluera-base:learned -->
```

These learnings persist across sessions and help Claude:

- Follow your established patterns
- Avoid repeating mistakes
- Understand project-specific conventions

---

## Troubleshooting

### Learnings not appearing

1. Check auto-learn is enabled: `/bluera-base:config status`
2. Verify target file exists and has markers
3. Check `.bluera/bluera-base/state/session-signals.json` for tracked commands

### Too many learnings

1. Review with `/bluera-base:learn show`
2. Dismiss irrelevant ones: `/bluera-base:learn dismiss N`
3. Clear all and start fresh: `/bluera-base:learn clear`

### Deep-learn not working

1. Requires `claude` CLI installed
2. Check deep-learn is enabled: `/bluera-base:config enable deep-learn`
3. Verify API access for Claude CLI

---

## See Also

- [Configuration](configuration.md) - Feature toggles and config schema
- [Hooks](hooks.md) - Hook details for observe-learning and session-end-learn
- [Skills](skills.md) - auto-learn and learn skill documentation
