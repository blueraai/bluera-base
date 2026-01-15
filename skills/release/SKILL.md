---
name: release
description: Release workflow with conventional commits auto-detection and GitHub Actions monitoring. Use /release to cut releases.
---

# Release Workflow

## Overview

This skill provides a standardized release workflow that:
1. Auto-detects version bump from conventional commits
2. Bumps version using language-appropriate tools
3. Commits, tags, and pushes
4. Monitors CI/CD until release is complete

**IMPORTANT:** All release commands MUST be prefixed with `__SKILL__=release` to bypass the manual-release hook.

## Pre-flight Checks

Before running any release command, you MUST:

1. Run `git status` to check for uncommitted changes
2. If there are uncommitted changes:
   - Commit all pending changes first
   - Verify the commit succeeded before proceeding
3. Only proceed with release after working directory is clean
4. Verify you're on the correct branch (usually `main`)

## Auto-Detection Rules

Determine version bump from commit messages since the last tag:

| Commit Type | Version Bump |
|-------------|--------------|
| `fix:` or `fix(scope):` | patch (0.0.x) |
| `feat:` or `feat(scope):` | minor (0.x.0) |
| `feat!:` or `BREAKING CHANGE:` in body | major (x.0.0) |

Other types (`docs:`, `chore:`, `refactor:`, `test:`, `style:`, `ci:`, `build:`, `perf:`) default to patch.

```bash
# Analyze commits since last tag
git log $(git describe --tags --abbrev=0 2>/dev/null || echo "")..HEAD --oneline
```

## Language-Specific Commands

### JavaScript/TypeScript

Detect package manager from lockfile, then use `npm version` (works universally):

```bash
# Auto-detect runner (for scripts), but npm version works everywhere
__SKILL__=release npm version patch  # or minor, major
__SKILL__=release git push --follow-tags
```

If project has custom release scripts in package.json:
```bash
__SKILL__=release <runner> release         # Auto-detect bump
__SKILL__=release <runner> release:patch   # Force patch
__SKILL__=release <runner> release:minor   # Force minor
__SKILL__=release <runner> release:major   # Force major
```

Where `<runner>` is: `bun run`, `yarn`, `pnpm`, or `npm run`.

### Python

**Poetry:**
```bash
__SKILL__=release poetry version patch  # or minor, major
__SKILL__=release git add pyproject.toml
__SKILL__=release git commit -m "chore: bump version to $(poetry version -s)"
__SKILL__=release git tag "v$(poetry version -s)"
__SKILL__=release git push --follow-tags
```

**Hatch:**
```bash
__SKILL__=release hatch version patch  # or minor, major
# Then commit and tag as above
```

**bump2version:**
```bash
__SKILL__=release bump2version patch  # or minor, major
__SKILL__=release git push --follow-tags
```

### Rust

**With cargo-release (recommended):**
```bash
__SKILL__=release cargo release patch --execute  # or minor, major
```

**Manual:**
```bash
# Edit Cargo.toml version field, then:
__SKILL__=release git add Cargo.toml Cargo.lock
__SKILL__=release git commit -m "chore: bump version to X.Y.Z"
__SKILL__=release git tag vX.Y.Z
__SKILL__=release git push --follow-tags
```

### Go

Go modules use git tags for versioning:

```bash
# Determine next version based on commits
__SKILL__=release git tag v1.2.3
__SKILL__=release git push --tags
```

For Go modules with major version > 1, update `go.mod` module path.

## GitHub Actions Monitoring

After push, monitor workflows until ALL complete successfully:

```bash
# Wait for workflows to start, then check status
sleep 15 && gh run list --limit 5

# If still running, re-check
gh run list --limit 5

# Verify release exists
gh release view v<version>
```

**Do NOT consider the release complete until:**
- All workflows show `completed` with `success` status
- The GitHub release is published (if configured)

If any workflow fails:
```bash
gh run view <run-id> --log-failed  # See error details
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| CI failed | Fix issue, bump version again, re-release |
| Tag exists | `git tag -d vX.Y.Z && git push origin :refs/tags/vX.Y.Z` |
| Workflow stuck | `gh run cancel <id>` then re-push |
| Re-run workflow | `gh run rerun <run-id>` |
| Wrong version | Use explicit bump type instead of auto-detect |
| Hook blocking | Ensure `__SKILL__=release` prefix is present |

## Required Workflow Summary

1. **Pre-flight:** `git status` - ensure clean working directory
2. **Analyze:** Check commits since last tag, determine bump type
3. **Bump:** Run language-appropriate version command with `__SKILL__=release` prefix
4. **Push:** Push commits and tags
5. **Monitor:** Check `gh run list` until all workflows complete
6. **Verify:** Confirm release with `gh release view v<version>`
7. **Report:** Show final status to user
