---
description: "Create atomic, well-organized commits"
allowed-tools: ["Bash(git *)", "Read(*)", "Grep(*)"]
---
# Commit

## Context (auto-loaded)

!`git status --short && echo "---" && git diff --stat && echo "---UNTRACKED---" && git ls-files --others --exclude-standard`

---

⛔ **STOP: You MUST complete Steps 1-2 before ANY git commit command.**

---

## Step 1: Analyze Changes (MANDATORY)

Review the diff output above. You MUST produce this analysis table:

| File | Change Type | Purpose |
|------|-------------|---------|
| (fill each file from diff) | add/modify/delete | (describe what changed) |

**DO NOT proceed until this table is complete.**

## Step 2: Documentation Check (MANDATORY)

For files that affect users (new features, changed behavior, new commands):

| File | User-Facing? | README/CLAUDE.md Update Needed? |
|------|--------------|--------------------------------|
| (each file) | Yes/No | Yes/No |

**If any "Yes" in last column:** Update documentation BEFORE committing.

## Step 3: Group and Commit

Only after producing BOTH tables above, create atomic commits:

```bash
git add <files-for-group-1>
git commit -m "<type>(<scope>): <description>

Co-Authored-By: Claude <noreply@anthropic.com>"
```

**Grouping rules** (see @bluera-base/skills/atomic-commits/SKILL.md):
- One logical change per commit
- README/CLAUDE.md changes with the feature they document
- Config changes separate from code changes

## Required Output Format

Your response MUST include this report:

```
## Commit Report
✓ Analyzed: X files
✓ Doc check: [no updates needed | updated README.md | updated CLAUDE.md]
✓ Commits:
  - <hash> <type>: <message>
✓ Status: [clean | X files remaining]
```

## Safety

- Never use `--no-verify`
- Never force push
- Never amend commits from other sessions
- If hooks fail, fix issues and retry
