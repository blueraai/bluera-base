#!/usr/bin/env bash
# =============================================================================
# Detect Version Tool
# Detects project's version tool and outputs the command to use
# Usage: detect-version-tool.sh [patch|minor|major]
# =============================================================================

set -euo pipefail

BUMP_TYPE="${1:-patch}"

# Validate bump type
case "$BUMP_TYPE" in
  patch|minor|major) ;;
  *)
    echo "Usage: detect-version-tool.sh [patch|minor|major]" >&2
    exit 1
    ;;
esac

# Detect JS package manager runner
detect_runner() {
  if [ -f bun.lockb ] || [ -f bun.lock ]; then echo "bun run"
  elif [ -f pnpm-lock.yaml ]; then echo "pnpm"
  elif [ -f yarn.lock ]; then echo "yarn"
  else echo "npm run"
  fi
}

# 1. Makefile with release/version targets (universal)
if [ -f Makefile ]; then
  # Check for hyphenated targets (common pattern: release-patch, release-minor, etc.)
  if grep -q "^release-$BUMP_TYPE:" Makefile 2>/dev/null; then
    echo "make release-$BUMP_TYPE"
    exit 0
  elif grep -q "^version-$BUMP_TYPE:" Makefile 2>/dev/null; then
    echo "make version-$BUMP_TYPE"
    exit 0
  # Check for release target with BUMP/VERSION variable
  elif grep -q "^release:" Makefile 2>/dev/null && grep -qE "BUMP|VERSION" Makefile 2>/dev/null; then
    echo "make release BUMP=$BUMP_TYPE"
    exit 0
  fi
fi

# 2. package.json with version:* scripts (JS/TS)
if [ -f package.json ] && grep -q "\"version:$BUMP_TYPE\"" package.json 2>/dev/null; then
  echo "$(detect_runner) version:$BUMP_TYPE"
  exit 0
fi

# 3. package.json with release:* scripts (JS/TS)
if [ -f package.json ] && grep -q "\"release:$BUMP_TYPE\"" package.json 2>/dev/null; then
  echo "$(detect_runner) release:$BUMP_TYPE"
  exit 0
fi

# 4. pyproject.toml with Poetry (Python)
if [ -f pyproject.toml ] && grep -q '\[tool.poetry\]' pyproject.toml 2>/dev/null; then
  echo "poetry version $BUMP_TYPE"
  exit 0
fi

# 5. pyproject.toml with Hatch (Python)
if [ -f pyproject.toml ] && grep -q '\[tool.hatch\]' pyproject.toml 2>/dev/null; then
  echo "hatch version $BUMP_TYPE"
  exit 0
fi

# 6. Cargo.toml (Rust)
if [ -f Cargo.toml ]; then
  if command -v cargo-release &>/dev/null; then
    echo "cargo release $BUMP_TYPE --execute"
  else
    echo "# Rust: edit Cargo.toml version, then: git add Cargo.toml && git commit -m 'chore: bump version'"
  fi
  exit 0
fi

# 7. go.mod (Go) - tag-based versioning
if [ -f go.mod ]; then
  echo "# Go: determine next version and run: git tag vX.Y.Z"
  exit 0
fi

# 8. Fallback: npm version (if package.json exists)
if [ -f package.json ]; then
  echo "npm version $BUMP_TYPE"
  exit 0
fi

# No version tool detected
echo "# No version tool detected"
exit 1
