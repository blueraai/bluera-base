# Language-Specific Release Commands

All commands MUST be prefixed with `__SKILL__=release` to bypass the manual-release hook.

## JavaScript/TypeScript

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

## Python

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

## Rust

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

## Go

Go modules use git tags for versioning:

```bash
# Determine next version based on commits
__SKILL__=release git tag v1.2.3
__SKILL__=release git push --tags
```

For Go modules with major version > 1, update `go.mod` module path.
