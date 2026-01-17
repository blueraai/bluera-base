---
description: Create atomic commits grouped by logical features with README.md and CLAUDE.md awareness.
allowed-tools: Bash(git:*), Read, Glob, Grep
---

# Commit

Create atomic, well-organized commits.

## Context

!`git status -s | head -10`
!`git log --oneline -5`

## Workflow

See @bluera-base/skills/atomic-commits/SKILL.md for documentation check criteria and grouping rules.

**Phases:** Analyze changes → Check docs → Group logically → Commit each group → Report

**Safety:** Never force push. Never use `--no-verify`. Never amend other sessions' commits.
