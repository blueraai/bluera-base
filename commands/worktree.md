---
description: Manage Git worktrees for parallel development workflows
allowed-tools: Bash(git:*), Bash(ls:*), Bash(mkdir:*), Bash(rm:*), Read, AskUserQuestion
argument-hint: [list|add|remove|prune|status] [branch] [path]
---

# Git Worktree Management

Manage multiple working directories from a single repository for parallel development.

## Subcommands

| Command | Description |
|---------|-------------|
| `/worktree` or `/worktree list` | List all worktrees |
| `/worktree add <branch> [path]` | Create worktree for branch |
| `/worktree remove <path>` | Remove a worktree |
| `/worktree prune` | Clean up stale worktree refs |
| `/worktree status` | Show status of all worktrees |

---

## Use Cases

**Parallel Development**: Work on feature branch while keeping main clean for reviews
**Testing**: Test changes in isolation without stashing
**Building**: Build one version while developing another
**Hotfixes**: Quick fixes on main without losing feature branch context

---

## Algorithm

### List (default)

```bash
git worktree list
```

Show all worktrees with their HEAD commit and branch.

### Add

Arguments: `<branch> [path]`

1. Validate branch exists or offer to create it
2. Determine path (default: `../<repo>-<branch>`)
3. Create worktree:
   ```bash
   git worktree add <path> <branch>
   ```
4. Report created worktree location

**Path conventions**:
- Default: `../<repo-name>-<branch-name>`
- Example: `../bluera-base-feature-xyz`
- Keeps worktrees adjacent to main repo

### Remove

Arguments: `<path>`

1. Verify path is a valid worktree
2. Confirm with user if uncommitted changes exist
3. Remove worktree:
   ```bash
   git worktree remove <path>
   ```
4. Optionally force with `--force` if locked

### Prune

Clean up stale worktree references (directories no longer exist):

```bash
git worktree prune
```

### Status

Show condensed status of all worktrees:

1. List each worktree
2. Show branch and ahead/behind counts
3. Show modified file count
4. Highlight worktrees needing attention

**Output format**:
```
Worktrees for bluera-base:

  /Users/chris/repos/bluera-base (main)
    main | origin/main +2 | 3 modified

  /Users/chris/repos/bluera-base-feature-auth (feature/auth)
    feature/auth | origin/feature/auth | clean

  /Users/chris/repos/bluera-base-hotfix (hotfix/urgent)
    hotfix/urgent | (no upstream) | 1 modified
```

---

## Interactive Workflows

### Quick Feature Branch Setup

When user runs `/worktree add` without arguments:

1. Ask for branch name
2. Ask whether to create new branch or use existing
3. Suggest path based on conventions
4. Create and report

### Cleanup Workflow

When user runs `/worktree prune`:

1. Show what would be pruned
2. Confirm before pruning
3. Report results

---

## Examples

```bash
# List all worktrees
/worktree list

# Create worktree for existing branch
/worktree add feature/new-ui

# Create worktree with custom path
/worktree add feature/new-ui ~/projects/new-ui-worktree

# Create worktree for new branch (will prompt to create)
/worktree add feature/experiment

# Remove a worktree
/worktree remove ../bluera-base-feature-new-ui

# Force remove (if locked or has changes)
/worktree remove ../bluera-base-stale --force

# Clean up stale references
/worktree prune

# Show status of all worktrees
/worktree status
```

---

## Best Practices

### Naming Conventions

- Use adjacent directories: `../<repo>-<branch>`
- Avoid nested worktrees
- Keep branch names in path for clarity

### Workflow Tips

1. **Main as primary**: Keep main repo on default branch
2. **Worktrees for features**: Create worktrees for longer-lived branches
3. **Clean up**: Remove worktrees when branches are merged
4. **Don't duplicate**: Each branch should have at most one worktree

### Common Pitfalls

- **Don't checkout same branch twice**: Git prevents this
- **Remember to push**: Worktree changes are local until pushed
- **Shared objects**: All worktrees share the same `.git` objects

---

## Implementation Notes

Detect repo name for path defaults:
```bash
REPO_NAME=$(basename "$(git rev-parse --show-toplevel)")
```

Check if branch exists:
```bash
git rev-parse --verify "$BRANCH" 2>/dev/null
```

Get worktree count:
```bash
git worktree list --porcelain | grep -c "^worktree"
```
