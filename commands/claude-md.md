---
description: Audit + maintain CLAUDE.md memory files (validate, update, create where helpful)
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(find:*), Bash(git:*), Bash(ls:*), Bash(wc:*), Bash(head:*), Bash(tail:*), AskUserQuestion
---

# CLAUDE.md Maintainer

Audit and maintain `CLAUDE.md` files in this repository. See @bluera-base/skills/claude-md-maintainer/SKILL.md for the algorithm.

## Two-Phase Workflow

### Phase 1: Plan (no writes)

1. Find all memory files and rules
2. Validate against invariants
3. Identify module roots for potential CLAUDE.md
4. Output proposed plan with exact changes

### Phase 2: Apply (after confirmation)

Ask user to confirm before making any writes:

```
question: "Apply the proposed changes to CLAUDE.md files?"
header: "Confirm"
options:
  - label: "Yes, apply all"
    description: "Create and update all proposed files"
  - label: "Apply updates only"
    description: "Update existing files but don't create new ones"
  - label: "No, abort"
    description: "Don't make any changes"
```

## Excluded Directories

Skip these during discovery:
- `.git/`, `node_modules/`, `.venv/`, `dist/`, `build/`, `out/`, `target/`, `vendor/`, `.idea/`, `.vscode/`

## Memory File Locations

Standard locations (check all):
- `./CLAUDE.md` - Root project memory
- `./.claude/CLAUDE.md` - Alternative root location
- `./CLAUDE.local.md` - Personal notes (gitignored)
- `**/CLAUDE.md` - Module-specific memory
- `.claude/rules/**/*.md` - Topic-specific rules

## Output

After each phase, report:
1. Files found (paths)
2. Files to create (paths)
3. Files to update (paths + change summary)
4. Follow-ups (items requiring human decision)
