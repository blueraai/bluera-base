---
description: Cut a release using conventional commits auto-detection and CI monitoring
allowed-tools: Bash(git:*), Bash(gh:*), Bash(npm:*), Bash(bun:*), Bash(poetry:*), Bash(cargo:*), Read, Glob
---

# Release

Cut a release and monitor CI/CD. See @bluera-base/skills/release/SKILL.md for workflow details.

## Context

!`git fetch --tags -q 2>/dev/null; git describe --tags --abbrev=0 2>/dev/null || echo "No tags yet"`

## Workflow

**IMPORTANT:** Do NOT push tags directly. Tags should only be created AFTER CI passes.

### Safe Release Pattern (Recommended)

1. **Analyze commits** to determine version bump:
   ```bash
   git fetch --tags -q
   git log $(git describe --tags --abbrev=0)..HEAD --oneline
   ```
   - `fix:` commits → patch (0.0.x)
   - `feat:` commits → minor (0.x.0)
   - `feat!:` or `BREAKING CHANGE:` → major (x.0.0)

2. **Bump version** (creates commit, NO tag):
   ```bash
   # JavaScript/TypeScript (with commit-and-tag-version)
   __SKILL__=release npx commit-and-tag-version --release-as patch --skip.tag

   # Python (Poetry)
   __SKILL__=release poetry version patch && git add pyproject.toml && git commit -m "chore(release): $(poetry version -s)"

   # Manual
   # Edit version files, then: git commit -m "chore(release): X.Y.Z"
   ```

3. **Push commit** (triggers CI):
   ```bash
   git push
   ```

4. **Wait for CI to pass**, then create tag:
   ```bash
   gh run list --limit 3  # Wait for success
   VERSION=$(jq -r .version package.json)  # Or read from your version file
   git tag "v$VERSION" && git push origin "v$VERSION"
   ```

### If Project Has auto-release.yml

Projects with auto-release workflow (like bluera-base) automatically create tags after CI passes. Just push the version bump commit:

```bash
__SKILL__=release bun run release:patch  # Bumps, commits, pushes (no tag)
# CI runs → auto-release creates tag → release workflow publishes
```

## Monitor

After push, poll until all workflows pass:

```bash
# Quick status check (silent unless issues)
gh run list --limit 5 --json status,conclusion -q '.[] | select(.status != "completed" or .conclusion != "success")' | grep -q . && echo "PENDING" || echo "ALL PASSED"

# On failure, inspect with verbose output
gh run list --limit 5
gh run view <run-id>
```

Verify release published: `gh release list --limit 1`
