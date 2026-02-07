---
name: memory
description: Manage global memories stored in ~/.claude/.bluera/bluera-base/
argument-hint: "[add|get|search|tag|edit|delete] [--limit N] [--tags TAG]"
allowed-tools: [Read, Write, Edit, Bash, AskUserQuestion]
---

# Global Memory Management

Manage cross-project knowledge stored globally at `~/.claude/.bluera/bluera-base/memories/`.

## Dual Scope Architecture

| Scope | Location | Purpose |
|-------|----------|---------|
| **Global memories** | `~/.claude/.bluera/bluera-base/memories/` | Cross-project knowledge, user-wide |
| **Project learnings** | `CLAUDE.local.md` | Project-specific auto-learn |

These systems are **100% independent**. No automatic sync - users explicitly manage each.

## Commands

### List Memories

Display recent memories:

```bash
# Show last 10 memories (default)
/bluera-base:memory

# Show more
/bluera-base:memory --limit 20

# Filter by tag
/bluera-base:memory --tags workflow
```

### Add a Memory

Create a new memory:

```bash
# Simple memory
/bluera-base:memory add "Always run tests before committing"

# With tags
/bluera-base:memory add "Use bun for this project" --tags bun,workflow

# With multiple tags
/bluera-base:memory add "API uses snake_case" --tags api,convention,backend
```

### Get Memory Details

View full content of a memory:

```bash
/bluera-base:memory get abc12345
```

### Search Memories

Find memories by content or tags:

```bash
/bluera-base:memory search "tests"
/bluera-base:memory search "workflow"
```

### Add Tags

Add tags to an existing memory:

```bash
/bluera-base:memory tag abc12345 important security
```

### Edit Memory

Modify a memory's content:

```bash
/bluera-base:memory edit abc12345
```

When editing:

1. Read the current memory file
2. Show content to user with AskUserQuestion
3. User provides new content
4. Update file with atomic write

### Delete Memory

Permanently remove a memory:

```bash
/bluera-base:memory delete abc12345
```

### Import Project Learnings

Move learnings from CLAUDE.local.md to global memory:

```bash
# Preview what would be imported
/bluera-base:memory import --dry-run

# Import all learnings
/bluera-base:memory import
```

Duplicates are detected via content hash and skipped.

**Cross-Project Warning**: Imported memories become visible in ALL projects.
Review carefully before importing project-specific or sensitive learnings.

## Memory Format

Each memory is stored as a markdown file with YAML frontmatter:

```markdown
---
id: "abc12345"
created: "2026-02-04T19:45:00Z"
updated: "2026-02-04T19:45:00Z"
tags:
  - workflow
  - testing
---

# Always run tests before committing

This ensures bugs are caught early.
```

## Tagging Conventions

Tags are free-form but here are suggested categories:

| Category | Example Tags |
|----------|-------------|
| **Type** | `correction`, `error`, `fact`, `workflow`, `preference` |
| **Domain** | `testing`, `git`, `ci`, `build`, `security` |
| **Tool** | `bun`, `npm`, `cargo`, `docker`, `git` |
| **Language** | `typescript`, `python`, `rust`, `bash` |
| **Project** | `bluera-base`, `shellkit` (if project-specific) |

**Rules**: Lowercase, hyphens allowed, max 30 chars, max 10 tags per memory.

## Configuration

Memory system is **disabled by default** (opt-in). To enable:

```bash
/bluera-base:config set .memory.enabled true
```

**Available options:**

| Option | Default | Description |
|--------|---------|-------------|
| `memory.enabled` | `false` | Enable global memory system |
| `memory.surfaceOnStart` | `false` | Show relevant memories at session start |
| `memory.contextBudget` | `500` | Max characters to inject at session start |

**Enable context surfacing:**

```bash
/bluera-base:config set .memory.enabled true
/bluera-base:config set .memory.surfaceOnStart true
```

## Implementation

This skill uses `hooks/lib/memory.sh` for all operations:

```bash
# Source the library
source "${CLAUDE_PLUGIN_ROOT}/hooks/lib/memory.sh"

# Create
id=$(bluera_memory_create "Title" --tags tag1,tag2)

# Read
content=$(bluera_memory_read "$id")

# List
bluera_memory_list --limit 10 --tags workflow

# Search
bluera_memory_search "tests"

# Add tags
bluera_memory_add_tags "$id" tag1 tag2

# Delete
bluera_memory_delete "$id"
```

## P2 Features (Coming Later)

- Session-scoped memories
- Statistics and cleanup
