---
name: release
description: Release workflow with conventional commits auto-detection and GitHub Actions monitoring. Use /release to cut releases.
---

# Release Workflow

Standardized release workflow that auto-detects version bump, bumps version, commits, pushes, and monitors CI.

**CRITICAL:** Do NOT push tags directly. Tags should only be created AFTER CI passes. Either:
1. Use auto-release workflow (creates tags after CI passes)
2. Or manually create tag only after verifying CI success

**IMPORTANT:** All release commands MUST be prefixed with `__SKILL__=release` to bypass the manual-release hook.

## Pre-flight Checks

1. Run `git status` - ensure clean working directory
2. If uncommitted changes exist, commit them first
3. Verify you're on the correct branch (usually `main`)

## Auto-Detection Rules

Analyze commits since last tag:

```bash
git log $(git describe --tags --abbrev=0 2>/dev/null || echo "")..HEAD --oneline
```

| Commit Type | Version Bump |
|-------------|--------------|
| `fix:` | patch (0.0.x) |
| `feat:` | minor (0.x.0) |
| `feat!:` or `BREAKING CHANGE:` | major (x.0.0) |
| Other types | patch |

## Language-Specific Commands

See `references/languages.md` for detailed commands by language:
- JavaScript/TypeScript (npm/yarn/pnpm/bun)
- Python (poetry/hatch/bump2version)
- Rust (cargo-release)
- Go (git tags)

## CI Monitoring

After push, monitor until ALL workflows complete:

```bash
gh run list --limit 5
gh release view v<version>
```

**Not complete until:**
- All workflows show `completed` with `success`
- GitHub release is published (if configured)

## Troubleshooting

| Issue | Solution |
|-------|----------|
| CI failed | Fix issue, bump again, re-release |
| Tag exists | `git tag -d vX.Y.Z && git push origin :refs/tags/vX.Y.Z` |
| Hook blocking | Ensure `__SKILL__=release` prefix is present |

## Workflow Summary

1. **Pre-flight:** `git status` - ensure clean working directory
2. **Analyze:** Check commits since last tag, determine bump type
3. **Bump:** Run version command with `__SKILL__=release` prefix (NO tag yet)
4. **Push:** Push version bump commit (triggers CI)
5. **Wait:** `gh run list` until CI passes
6. **Tag:** Create and push tag only AFTER CI passes (or let auto-release do it)
7. **Verify:** `gh release view v<version>`
