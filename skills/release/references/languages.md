# Language-Specific Release Commands

**IMPORTANT:** Always run `detect-version-tool.sh` first. These are fallback commands for when detection doesn't apply or for manual override.

All commands MUST be prefixed with `__SKILL__=release` to bypass the manual-release hook.

## Detection First

```bash
PLUGIN_PATH="${CLAUDE_PLUGIN_ROOT:-}"
COMMAND=$(bash "$PLUGIN_PATH/hooks/lib/detect-version-tool.sh" patch)
__SKILL__=release $COMMAND
```

---

## Fallback Commands

Use these only when detection returns a comment (`# ...`) or fails.

### JavaScript/TypeScript

**If project has `version:*` or `release:*` scripts** (detection will find these):

```bash
__SKILL__=release bun run version:patch   # bun.lock/bun.lockb
__SKILL__=release npm run version:patch   # package-lock.json
__SKILL__=release yarn version:patch      # yarn.lock
__SKILL__=release pnpm version:patch      # pnpm-lock.yaml
```

**Bare fallback** (no custom scripts):

```bash
__SKILL__=release npm version patch
```

### Python

**Poetry:**

```bash
__SKILL__=release poetry version patch
```

**Hatch:**

```bash
__SKILL__=release hatch version patch
```

### Rust

**With cargo-release:**

```bash
__SKILL__=release cargo release patch --execute
```

**Manual** (no cargo-release):

```bash
# Edit Cargo.toml version field, then:
__SKILL__=release git add Cargo.toml Cargo.lock
__SKILL__=release git commit -m "chore: bump version"
```

### Go

Go uses git tags for versioning:

```bash
__SKILL__=release git tag v1.2.3
__SKILL__=release git push --tags
```

For major version > 1, also update `go.mod` module path.

---

## Why Detection Matters

Project scripts (`version:patch`, `release:patch`) may:

- Sync multiple version files (`.versionrc.json`)
- Run prerelease hooks
- Generate changelogs
- Handle monorepo versioning

Direct tool calls (`npm version`, `poetry version`) bypass all of this.
