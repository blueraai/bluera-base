#!/bin/bash
# Block manual release commands - must use /release skill
# Supports: JavaScript/TypeScript, Python, Rust, Go
#
# Exit codes:
# 0 = allow (not a release command)
# 2 = block with message (manual release attempt)

# Read tool input from stdin
INPUT=$(cat 2>/dev/null || true)

# jq unavailable: fail closed for security
# This hook protects against accidental releases - better to block than allow bypass
if ! command -v jq &>/dev/null; then
  # Extended pattern matching when jq unavailable
  RELEASE_KEYWORDS='npm publish|yarn publish|npm version|yarn version|pnpm publish|pnpm version|bun publish|bun version|cargo release|cargo publish|poetry publish|poetry version|hatch publish|hatch version|bump2version|gh release|git tag.*[v]?[0-9]|release|--no-verify'
  if echo "$INPUT" | grep -qEi "$RELEASE_KEYWORDS"; then
    echo "Blocked: jq required for release protection. Install jq or use __SKILL__=release prefix." >&2
    exit 2
  fi
  # Allow non-release commands but warn strongly
  # Note: This is a security-sensitive hook - install jq for full protection
  exit 0
fi

# Extract the command from Bash tool input
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

# If no command, allow
[ -z "$COMMAND" ] && exit 0

# Allow if invoked from /release skill (prefix makes it awkward to type manually)
if echo "$COMMAND" | grep -qE '^__SKILL__=release '; then
  exit 0
fi

# Allow test suite to invoke hook tests without live hook interference
# Usage: __BLUERA_TEST__=block-release <actual command to test>
if echo "$COMMAND" | grep -qE '^__BLUERA_TEST__='; then
  exit 0
fi

# Block --no-verify on git commit (CLAUDE-BASE.md rule: absolute zero exceptions)
# This is a hard block regardless of /release skill prefix
if echo "$COMMAND" | grep -qE '(^|[^a-zA-Z])git[[:space:]]+commit([^a-zA-Z]|[[:space:]]).*(--no-verify|-n([[:space:]]|$))'; then
  echo "Blocked: git commit --no-verify/-n is forbidden. Fix pre-commit failures; do not bypass." >&2
  exit 2
fi

# Block patterns for manual release commands across languages

# JavaScript/TypeScript: npm version, yarn version, pnpm version, bun version, release scripts, publish
JS_PATTERNS='(npm|yarn|pnpm|bun)( run)? (version|release|publish)(:|$| )'

# Python: poetry version, hatch version, bump2version, poetry publish
PY_PATTERNS='(poetry|hatch) (version|publish)|bump2version'

# Rust: cargo release, cargo publish
RUST_PATTERNS='cargo (release|publish)'

# Go/Generic: direct git tag creation for versions
GIT_PATTERNS='git tag .*[v]?[0-9]|gh release create'

if echo "$COMMAND" | grep -qE "($JS_PATTERNS)|($PY_PATTERNS)|($RUST_PATTERNS)|($GIT_PATTERNS)"; then
  echo "Manual release commands are blocked. Use /bluera-base:release instead." >&2
  exit 2
fi

exit 0
