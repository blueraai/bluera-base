---
name: release
description: Release workflow with conventional commits auto-detection and GitHub Actions monitoring. Use /bluera-base:release to cut releases.
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
# If tags exist:
git log $(git describe --tags --abbrev=0)..HEAD --oneline
# If no tags yet:
git log --oneline
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

After push, **verify ALL workflows triggered and succeeded**.

### Monitor All Workflows

```bash
COMMIT_SHA=$(git rev-parse HEAD)

# Silent wait for completion
while gh run list --commit "$COMMIT_SHA" --json status -q '[.[] | select(.status == "completed")] | length < (. | length)' | grep -q true; do sleep 10; done

# Show failures only (empty = all passed)
gh run list --commit "$COMMIT_SHA" --json name,conclusion -q '.[] | select(.conclusion == "success" | not) | "\(.name): \(.conclusion)"'

# Verify workflow count: expected vs actual
EXPECTED=$(ls .github/workflows/*.yml 2>/dev/null | wc -l | tr -d ' ')
ACTUAL=$(gh run list --commit "$COMMIT_SHA" --json name -q 'length')
[ "$EXPECTED" -ne "$ACTUAL" ] && echo "WARNING: Expected $EXPECTED workflows, got $ACTUAL"
```

### Verify Release

```bash
gh release view "v$VERSION" --json tagName -q .tagName 2>/dev/null && echo "OK" || echo "NOT FOUND"
```

**Release is NOT complete until:**

- All workflows for this commit show `success`
- Workflow count matches expected (none failed to trigger)
- GitHub release exists with correct version

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
5. **Wait:** Poll `gh run list --commit SHA` until ALL workflows complete
6. **Verify workflows:** Compare `.github/workflows/` files vs actual runs - ensure none missing
7. **Tag:** Create and push tag only AFTER CI passes (or let auto-release do it)
8. **Verify release:** `gh release list --limit 1` to confirm published
