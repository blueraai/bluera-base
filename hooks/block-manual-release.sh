#!/bin/bash
# Block manual release commands - must use /release skill
# Supports: JavaScript/TypeScript, Python, Rust, Go
#
# Exit codes:
# 0 = allow (not a release command)
# 2 = block with message (manual release attempt)

# Read tool input from stdin
INPUT=$(cat)

# Extract the command from Bash tool input
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

# If no command, allow
[ -z "$COMMAND" ] && exit 0

# Allow if invoked from /release skill (prefix makes it awkward to type manually)
if echo "$COMMAND" | grep -qE '^__SKILL__=release '; then
  exit 0
fi

# Block --no-verify on git commit (CLAUDE-BASE.md rule: absolute zero exceptions)
# This is a hard block regardless of /release skill prefix
if echo "$COMMAND" | grep -qE '(^|[^a-zA-Z])git[[:space:]]+commit([^a-zA-Z]|[[:space:]]).*(--no-verify|-n([[:space:]]|$))'; then
  echo "Blocked: git commit --no-verify/-n is forbidden. Fix pre-commit failures; do not bypass." >&2
  exit 2
fi

# Block patterns for manual release commands across languages

# JavaScript/TypeScript: npm version, yarn version, pnpm version, bun version, release scripts
JS_PATTERNS='(npm|yarn|pnpm|bun)( run)? (version|release)(:|$| )'

# Python: poetry version, hatch version, bump2version
PY_PATTERNS='(poetry|hatch) version|bump2version'

# Rust: cargo release
RUST_PATTERNS='cargo release'

# Go/Generic: direct git tag creation for versions
GIT_PATTERNS='git tag .*v[0-9]|gh release create'

if echo "$COMMAND" | grep -qE "($JS_PATTERNS)|($PY_PATTERNS)|($RUST_PATTERNS)|($GIT_PATTERNS)"; then
  echo "Manual release commands are blocked. Use /bluera-base:release instead." >&2
  exit 2
fi

exit 0
