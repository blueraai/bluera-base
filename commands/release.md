---
description: Cut a release using conventional commits auto-detection and CI monitoring
allowed-tools: Bash(git:*), Bash(gh:*), Bash(npm:*), Bash(bun:*), Bash(poetry:*), Bash(cargo:*), Read, Glob
---

# Release

Cut a release and monitor CI/CD.

## Context

!`git fetch --tags -q 2>/dev/null && git describe --tags --abbrev=0 2>/dev/null || echo "No tags yet"`

## Workflow

See @bluera-base/skills/release/SKILL.md for complete workflow.

**Phases:** Analyze commits → Bump version → Push → Monitor CI → Verify release

**Key rule:** Do NOT push tags directly. Tags should only be created AFTER CI passes.
