---
description: Cut a release using conventional commits auto-detection and CI monitoring
allowed-tools: Bash(git:*), Bash(gh:*), Bash(npm:*), Bash(bun:*), Bash(poetry:*), Bash(cargo:*), Read, Glob
---

# Release

Cut a release and monitor CI/CD. See @bluera-base/skills/release/SKILL.md for workflow details.

## Context

!`git fetch --tags -q 2>/dev/null; git describe --tags --abbrev=0 2>/dev/null || echo "No tags yet"`

## Quick Release

Run the appropriate command for your project type:

**JavaScript/TypeScript:**
```bash
__SKILL__=release npm version patch && git push --follow-tags  # Or minor/major
```

**Python (Poetry):**
```bash
__SKILL__=release poetry version patch && git add pyproject.toml && git commit -m "chore: bump version" && git push
```

**Rust:**
```bash
__SKILL__=release cargo release patch --execute  # Requires cargo-release
```

**Go / Other:**
```bash
__SKILL__=release git tag v1.0.0 && git push --tags
```

Auto-detection uses conventional commits: `fix:` → patch, `feat:` → minor, `feat!:`/`BREAKING CHANGE:` → major.

## Monitor

After push, use `gh run list --limit 3` then check status until all workflows complete.
