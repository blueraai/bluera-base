---
name: release
description: Release workflow with conventional commits auto-detection and GitHub Actions monitoring. Use /bluera-base:release to cut releases.
---

# Release Workflow

Standardized release workflow that auto-detects version bump, bumps version, commits, pushes, and monitors CI.

**CRITICAL:** Do NOT push tags directly. Tags should only be created AFTER CI passes. Either:

1. Use auto-release workflow (creates tags after CI passes)
2. Or manually create tag only after verifying CI success

## Hook Bypass (REQUIRED)

A PreToolUse hook blocks manual release commands. To run version/release commands, you MUST prefix with exactly:

```bash
__SKILL__=release <command>
```

**Examples (use these exact formats):**

```bash
__SKILL__=release bun run version:patch
__SKILL__=release npm version minor
__SKILL__=release poetry version patch
__SKILL__=release cargo release patch --execute
```

**DO NOT invent alternative prefixes.** The hook checks for the literal string `__SKILL__=release` at the start of the command. Using any other format (like `RELEASE_SKILL_ACTIVE=1`) will be blocked.

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

## Detect Version Command

**Always detect what the project uses, then use that.** Project scripts may sync multiple files, run hooks, or handle project-specific logic that direct tool calls would bypass.

Run the detection script to find the appropriate version command:

```bash
PLUGIN_PATH="${CLAUDE_PLUGIN_ROOT:-}"
bash "$PLUGIN_PATH/hooks/lib/detect-version-tool.sh" patch  # or minor, major
```

Then execute with the `__SKILL__=release` prefix:

```bash
__SKILL__=release <detected-command>
```

### Detection Priority

1. **Makefile** with `release:` or `version:` targets
2. **package.json** with `version:*` scripts (e.g., `version:patch`)
3. **package.json** with `release:*` scripts
4. **pyproject.toml** with Poetry or Hatch
5. **Cargo.toml** (Rust)
6. **go.mod** (Go)
7. **Fallback:** `npm version patch`

**Why this matters:** The bluera-knowledge bug was caused by using `npm version patch` directly instead of `bun run version:patch`, which would have synced both `package.json` and `.claude-plugin/plugin.json` via `.versionrc.json`.

## Language Reference

See `references/languages.md` for fallback commands when detection doesn't apply.

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
2. **Analyze:** Check commits since last tag, determine bump type (patch/minor/major)
3. **Detect:** Run `detect-version-tool.sh` to find the right command
4. **Bump:** Run detected command with `__SKILL__=release` prefix (NO tag yet)
5. **Push:** Push version bump commit (triggers CI)
6. **Wait:** Poll `gh run list --commit SHA` until ALL workflows complete
7. **Verify workflows:** Compare `.github/workflows/` files vs actual runs - ensure none missing
8. **Tag:** Create and push tag only AFTER CI passes (or let auto-release do it)
9. **Verify release:** `gh release list --limit 1` to confirm published
