# Auto-Detection Rules

How the release skill detects what kind of version bump to apply.

## Analyze Commits

Check commits since last tag:

```bash
# If tags exist:
git log $(git describe --tags --abbrev=0)..HEAD --oneline
# If no tags yet:
git log --oneline
```

## Commit Type to Version Bump

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

## Detection Priority

1. **Makefile** with `release-*` or `version-*` targets (e.g., `release-patch:`)
2. **package.json** with `version:*` scripts (e.g., `version:patch`)
3. **package.json** with `release:*` scripts
4. **pyproject.toml** with Poetry or Hatch
5. **Cargo.toml** (Rust)
6. **go.mod** (Go)
7. **Fallback:** `npm version patch`

## Why This Matters

The bluera-knowledge bug was caused by using `npm version patch` directly instead of `bun run version:patch`, which would have synced both `package.json` and `.claude-plugin/plugin.json` via `.versionrc.json`.

Always use the detected command to respect project-specific version sync configurations.
