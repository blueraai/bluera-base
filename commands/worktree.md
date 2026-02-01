---
description: Manage Git worktrees for parallel development
argument-hint: [list|add|remove|prune|status] [args]
allowed-tools: Bash, Read, AskUserQuestion
---

# Git Worktree Management

Manage multiple working directories from a single repository for parallel development.

## Subcommands

| Command | Description |
|---------|-------------|
| `/bluera-base:worktree` or `/bluera-base:worktree list` | List all worktrees |
| `/bluera-base:worktree add <branch> [path]` | Create worktree for branch |
| `/bluera-base:worktree remove <path>` | Remove a worktree |
| `/bluera-base:worktree prune` | Clean up stale worktree refs |
| `/bluera-base:worktree status` | Show status of all worktrees |

---

## Use Cases

- **Parallel Development**: Work on feature branch while keeping main clean for reviews
- **Testing**: Test changes in isolation without stashing
- **Building**: Build one version while developing another
- **Hotfixes**: Quick fixes on main without losing feature branch context

---

## Algorithm

### List (default)

Show all worktrees with their HEAD commit and branch:

```bash
git worktree list
```

### Add

Arguments: `<branch> [path]`

1. Validate branch exists or offer to create it
2. Determine path (default: `../<repo>-<branch>`)
3. Create worktree: `git worktree add <path> <branch>`
4. Report created worktree location

**Path conventions**:

- Default: `../<repo-name>-<branch-name>`
- Example: `../bluera-base-feature-xyz`

### Remove

Arguments: `<path>`

1. Verify path is a valid worktree
2. Confirm with user if uncommitted changes exist
3. Remove: `git worktree remove <path>`
4. Optionally force with `--force` if locked

### Prune

Clean up stale worktree references:

```bash
git worktree prune
```

### Status

Show condensed status of all worktrees:

- Branch and ahead/behind counts
- Modified file count
- Highlight worktrees needing attention

---

## Examples

```bash
# List all worktrees
/bluera-base:worktree list

# Create worktree for existing branch
/bluera-base:worktree add feature/new-ui

# Create worktree with custom path
/bluera-base:worktree add feature/new-ui ~/projects/new-ui-worktree

# Remove a worktree
/bluera-base:worktree remove ../bluera-base-feature-new-ui

# Force remove (if locked or has changes)
/bluera-base:worktree remove ../bluera-base-stale --force

# Clean up stale references
/bluera-base:worktree prune

# Show status of all worktrees
/bluera-base:worktree status
```

---

See @bluera-base/skills/worktree/SKILL.md for complete documentation.
