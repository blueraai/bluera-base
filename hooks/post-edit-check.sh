#!/bin/bash
# Smart post-edit validation hook
# Supports: JavaScript/TypeScript, Python, Rust, Go
# Auto-detects package manager for JS/TS projects
#
# Reads stdin JSON to get the exact file edited, then validates just that file.
# This fixes issues with git diff missing untracked files and glob patterns not matching subdirs.

set -euo pipefail

cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

# === Read stdin JSON ===

INPUT=$(cat || true)
[ -z "$INPUT" ] && exit 0

# Extract tool name and file path
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null || echo "")
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null || echo "")

# Only process Write/Edit tools
case "$TOOL_NAME" in
  Write|Edit) ;;
  *) exit 0 ;;
esac

# Need a file path to continue
[ -z "$FILE_PATH" ] && exit 0

# Normalize to repo-relative path
if [[ "$FILE_PATH" == /* ]]; then
  FILE_PATH="${FILE_PATH#"${CLAUDE_PROJECT_DIR:-$(pwd)}/"}"
fi

# === Skip generated/vendor paths ===

case "$FILE_PATH" in
  dist/*|build/*|out/*|target/*|node_modules/*|.venv/*|__pycache__/*|vendor/*|.git/*)
    exit 0
    ;;
esac

# === Detection Functions ===

detect_js_runner() {
  if [ -f "bun.lockb" ]; then echo "bun"
  elif [ -f "yarn.lock" ]; then echo "yarn"
  elif [ -f "pnpm-lock.yaml" ]; then echo "pnpm"
  else echo "npx"
  fi
}

# === Language-Specific Checks (single file) ===

check_javascript_file() {
  local file="$1"
  local RUNNER
  RUNNER=$(detect_js_runner)

  # Auto-fix lint (only if eslint is available)
  if [ -f "node_modules/.bin/eslint" ] || command -v eslint &>/dev/null; then
    "$RUNNER" eslint --fix --quiet "$file" 2>/dev/null || true

    # Check for remaining lint errors
    local LINT_OUT
    LINT_OUT=$("$RUNNER" eslint --quiet "$file" 2>&1 || true)
    if [ -n "$LINT_OUT" ]; then
      echo "$LINT_OUT" >&2
      return 2
    fi
  fi

  # Type check (project-wide, rate-limited to avoid slowdown)
  # Only run if last check was > 30 seconds ago
  if [ -f "tsconfig.json" ]; then
    local RATE_FILE="${TMPDIR:-/tmp}/bluera-tsc-last-run"
    local NOW
    NOW=$(date +%s)
    local LAST=0
    [ -f "$RATE_FILE" ] && LAST=$(cat "$RATE_FILE" 2>/dev/null || echo 0)

    if [ $((NOW - LAST)) -gt 30 ]; then
      echo "$NOW" > "$RATE_FILE"
      local TYPE_OUT
      TYPE_OUT=$("$RUNNER" tsc --noEmit --pretty false 2>&1 || true)
      if [ -n "$TYPE_OUT" ]; then
        echo "$TYPE_OUT" | head -20 >&2
        return 2
      fi
    fi
  fi

  return 0
}

check_python_file() {
  local file="$1"

  # Prefer ruff (fast)
  if command -v ruff &>/dev/null; then
    ruff check --fix --quiet "$file" 2>/dev/null || true

    local LINT_OUT
    LINT_OUT=$(ruff check "$file" 2>&1 || true)
    if [ -n "$LINT_OUT" ]; then
      echo "$LINT_OUT" >&2
      return 2
    fi
  elif command -v flake8 &>/dev/null; then
    local LINT_OUT
    LINT_OUT=$(flake8 "$file" 2>&1 || true)
    if [ -n "$LINT_OUT" ]; then
      echo "$LINT_OUT" >&2
      return 2
    fi
  fi

  # Type check with mypy (rate-limited)
  if command -v mypy &>/dev/null; then
    if [ -f "pyproject.toml" ] || [ -f "mypy.ini" ] || [ -f "setup.cfg" ]; then
      local RATE_FILE="${TMPDIR:-/tmp}/bluera-mypy-last-run"
      local NOW
      NOW=$(date +%s)
      local LAST=0
      [ -f "$RATE_FILE" ] && LAST=$(cat "$RATE_FILE" 2>/dev/null || echo 0)

      if [ $((NOW - LAST)) -gt 30 ]; then
        echo "$NOW" > "$RATE_FILE"
        local TYPE_OUT
        TYPE_OUT=$(mypy --no-error-summary "$file" 2>&1 | grep -v "^Success" || true)
        if [ -n "$TYPE_OUT" ]; then
          echo "$TYPE_OUT" | head -20 >&2
          return 2
        fi
      fi
    fi
  fi

  return 0
}

check_rust_file() {
  local file="$1"

  if ! command -v cargo &>/dev/null; then
    return 0
  fi

  # Auto-format the specific file
  rustfmt --quiet "$file" 2>/dev/null || true

  # Cargo checks are project-wide (rate-limited)
  local RATE_FILE="${TMPDIR:-/tmp}/bluera-cargo-last-run"
  local NOW
  NOW=$(date +%s)
  local LAST=0
  [ -f "$RATE_FILE" ] && LAST=$(cat "$RATE_FILE" 2>/dev/null || echo 0)

  if [ $((NOW - LAST)) -gt 30 ]; then
    echo "$NOW" > "$RATE_FILE"

    # cargo clippy for linting
    local LINT_OUT
    LINT_OUT=$(cargo clippy --quiet --message-format=short 2>&1 | grep -E "^(error|warning)" || true)
    if echo "$LINT_OUT" | grep -q "^error"; then
      echo "$LINT_OUT" | head -20 >&2
      return 2
    fi

    # cargo check for compile errors
    local CHECK_OUT
    CHECK_OUT=$(cargo check --quiet --message-format=short 2>&1 | grep -E "^error" || true)
    if [ -n "$CHECK_OUT" ]; then
      echo "$CHECK_OUT" | head -20 >&2
      return 2
    fi
  fi

  return 0
}

check_go_file() {
  local file="$1"

  # Format the specific file
  if command -v gofmt &>/dev/null; then
    gofmt -w "$file" 2>/dev/null || true
  fi

  # Linting (rate-limited)
  local RATE_FILE="${TMPDIR:-/tmp}/bluera-go-last-run"
  local NOW
  NOW=$(date +%s)
  local LAST=0
  [ -f "$RATE_FILE" ] && LAST=$(cat "$RATE_FILE" 2>/dev/null || echo 0)

  if [ $((NOW - LAST)) -gt 30 ]; then
    echo "$NOW" > "$RATE_FILE"

    if command -v golangci-lint &>/dev/null; then
      local LINT_OUT
      LINT_OUT=$(golangci-lint run --out-format=line-number "$file" 2>&1 || true)
      if [ -n "$LINT_OUT" ]; then
        echo "$LINT_OUT" | head -20 >&2
        return 2
      fi
    elif command -v go &>/dev/null; then
      local LINT_OUT
      LINT_OUT=$(go vet "$file" 2>&1 || true)
      if [ -n "$LINT_OUT" ]; then
        echo "$LINT_OUT" | head -20 >&2
        return 2
      fi
    fi
  fi

  return 0
}

# === Anti-pattern Check (single file) ===

check_anti_patterns_file() {
  local file="$1"

  # Only check text-like source files
  case "$file" in
    *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs|*.py|*.pyi|*.rs|*.go) ;;
    *) return 0 ;;
  esac

  # File must exist
  [ -f "$file" ] || return 0

  local ANTI_RE='\b(fallback|deprecated|backward compatibility|legacy)\b'

  # Get content to check (added lines for tracked files, full file otherwise)
  local CONTENT=""
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if git ls-files --error-unmatch "$file" >/dev/null 2>&1; then
      CONTENT=$(git diff -U0 -- "$file" 2>/dev/null | grep -E '^\+' | grep -vE '^\+\+\+' || true)
    fi
  fi
  [ -z "$CONTENT" ] && CONTENT=$(cat "$file")

  # Check general anti-patterns
  if echo "$CONTENT" | grep -Eiq "$ANTI_RE"; then
    echo "Anti-pattern detected ($file): fallback/deprecated/legacy/backward compatibility" >&2
    echo "$CONTENT" | grep -Ei "$ANTI_RE" | head -10 >&2
    return 2
  fi

  return 0
}

# === Lint Suppression Check (config files) ===

check_lint_suppression_file() {
  local file="$1"

  # Only check lint config files
  case "$file" in
    .markdownlint*|.eslintrc*|eslint.config.*|.pylintrc|pyproject.toml|.ruff.toml|ruff.toml) ;;
    *) return 0 ;;
  esac

  # File must exist
  [ -f "$file" ] || return 0

  # Only check added lines (new suppressions)
  local ADDED=""
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if git ls-files --error-unmatch "$file" >/dev/null 2>&1; then
      ADDED=$(git diff -U0 -- "$file" 2>/dev/null | grep -E '^\+' | grep -vE '^\+\+\+' || true)
    fi
  fi

  # Skip if no added lines (only check new suppressions)
  [ -z "$ADDED" ] && return 0

  case "$file" in
    .markdownlint*)
      # Check for disabling markdown rules: "MD___": false
      if echo "$ADDED" | grep -E '"MD[0-9]+"\s*:\s*false' | grep -v '// ok:' | grep -q .; then
        echo "Lint suppression detected ($file): disabling markdownlint rules" >&2
        echo "Fix the markdown issues instead of disabling rules." >&2
        echo "$ADDED" | grep -E '"MD[0-9]+"\s*:\s*false' | head -5 >&2
        return 2
      fi
      ;;
    .eslintrc*|eslint.config.*)
      # Check for disabling eslint rules: "off" or 0
      if echo "$ADDED" | grep -E ':\s*("off"|0)\s*[,}]' | grep -v '// ok:' | grep -q .; then
        echo "Lint suppression detected ($file): disabling ESLint rules" >&2
        echo "Fix the code issues instead of disabling rules." >&2
        echo "$ADDED" | grep -E ':\s*("off"|0)' | head -5 >&2
        return 2
      fi
      ;;
    pyproject.toml|.ruff.toml|ruff.toml)
      # Check for ignore patterns in ruff config
      if echo "$ADDED" | grep -E 'ignore\s*=' | grep -v '# ok:' | grep -q .; then
        echo "Lint suppression detected ($file): adding ruff ignore patterns" >&2
        echo "Fix the Python issues instead of ignoring rules." >&2
        echo "$ADDED" | grep -E 'ignore\s*=' | head -5 >&2
        return 2
      fi
      ;;
    .pylintrc)
      # Check for disable additions
      if echo "$ADDED" | grep -E 'disable\s*=' | grep -v '# ok:' | grep -q .; then
        echo "Lint suppression detected ($file): disabling pylint rules" >&2
        echo "Fix the Python issues instead of disabling rules." >&2
        echo "$ADDED" | grep -E 'disable\s*=' | head -5 >&2
        return 2
      fi
      ;;
  esac

  return 0
}

# === Strict Typing Check (single file) ===

check_strict_typing_file() {
  local file="$1"

  # File must exist
  [ -f "$file" ] || return 0

  # Get content to check (added lines for tracked files, full file otherwise)
  local CONTENT=""
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if git ls-files --error-unmatch "$file" >/dev/null 2>&1; then
      CONTENT=$(git diff -U0 -- "$file" 2>/dev/null | grep -E '^\+' | grep -vE '^\+\+\+' || true)
    fi
  fi
  [ -z "$CONTENT" ] && CONTENT=$(cat "$file")

  case "$file" in
    *.ts|*.tsx)
      # TypeScript strict typing violations
      # Check for: any type, as casts, @ts-ignore, @ts-expect-error without reason

      # 'any' type (but not 'company' or 'many' etc)
      if echo "$CONTENT" | grep -E ':\s*any\b|<any>|as\s+any\b' | grep -v '// ok:' | grep -q .; then
        echo "Strict typing violation ($file): 'any' type is forbidden" >&2
        echo "$CONTENT" | grep -En ':\s*any\b|<any>|as\s+any\b' | grep -v '// ok:' | head -5 >&2
        return 2
      fi

      # Unsafe 'as' type casts (but allow 'as const')
      if echo "$CONTENT" | grep -E '\bas\s+[A-Z]' | grep -v 'as const' | grep -v '// ok:' | grep -q .; then
        echo "Strict typing violation ($file): unsafe 'as' cast is forbidden (use type guards)" >&2
        echo "$CONTENT" | grep -En '\bas\s+[A-Z]' | grep -v 'as const' | grep -v '// ok:' | head -5 >&2
        return 2
      fi

      # @ts-ignore without explanation
      if echo "$CONTENT" | grep -E '@ts-ignore(?!\s+.{10,})' | grep -q .; then
        echo "Strict typing violation ($file): @ts-ignore requires explanation" >&2
        echo "$CONTENT" | grep -En '@ts-ignore' | head -5 >&2
        return 2
      fi

      # @ts-nocheck is always forbidden
      if echo "$CONTENT" | grep -q '@ts-nocheck'; then
        echo "Strict typing violation ($file): @ts-nocheck is forbidden" >&2
        return 2
      fi
      ;;

    *.js|*.jsx|*.mjs|*.cjs)
      # JavaScript - check for @ts-ignore in JS files (indicates type issues being suppressed)
      if echo "$CONTENT" | grep -q '@ts-ignore\|@ts-nocheck'; then
        echo "Strict typing violation ($file): TypeScript ignores in JS files indicate type issues" >&2
        return 2
      fi
      ;;

    *.py|*.pyi)
      # Python strict typing violations

      # type: ignore without code
      if echo "$CONTENT" | grep -E '#\s*type:\s*ignore(?!\[)' | grep -q .; then
        echo "Strict typing violation ($file): 'type: ignore' requires error code [code]" >&2
        echo "$CONTENT" | grep -En '#\s*type:\s*ignore' | head -5 >&2
        return 2
      fi

      # Any type usage (from typing import Any, or : Any)
      if echo "$CONTENT" | grep -E '\bAny\b' | grep -v '# ok:' | grep -q .; then
        echo "Strict typing violation ($file): 'Any' type is forbidden (use specific types or generics)" >&2
        echo "$CONTENT" | grep -En '\bAny\b' | grep -v '# ok:' | head -5 >&2
        return 2
      fi

      # cast() is usually a code smell
      if echo "$CONTENT" | grep -E '\bcast\s*\(' | grep -v '# ok:' | grep -q .; then
        echo "Strict typing violation ($file): cast() is forbidden (use type guards or fix types)" >&2
        echo "$CONTENT" | grep -En '\bcast\s*\(' | head -5 >&2
        return 2
      fi
      ;;

    # Rust and Go are already strictly typed by the compiler
  esac

  return 0
}

# === Config Check ===

# Source config library for feature flags
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/lib/config.sh" ]; then
  source "$SCRIPT_DIR/lib/config.sh"
  STRICT_TYPING_ENABLED=$(bluera_get_config ".strictTyping.enabled" 2>/dev/null || echo "false")
else
  STRICT_TYPING_ENABLED="false"
fi

# === Main ===

EXIT_CODE=0

# Dispatch based on file extension
case "$FILE_PATH" in
  *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs)
    if [ -f "package.json" ]; then
      check_javascript_file "$FILE_PATH" || EXIT_CODE=$?
    fi
    ;;
  *.py|*.pyi)
    if [ -f "pyproject.toml" ] || [ -f "requirements.txt" ] || [ -f "setup.py" ]; then
      check_python_file "$FILE_PATH" || EXIT_CODE=$?
    fi
    ;;
  *.rs)
    if [ -f "Cargo.toml" ]; then
      check_rust_file "$FILE_PATH" || EXIT_CODE=$?
    fi
    ;;
  *.go)
    if [ -f "go.mod" ]; then
      check_go_file "$FILE_PATH" || EXIT_CODE=$?
    fi
    ;;
esac

[ $EXIT_CODE -ne 0 ] && exit $EXIT_CODE

# Anti-pattern check (all source files)
check_anti_patterns_file "$FILE_PATH" || exit $?

# Lint suppression check (config files) - prevents disabling lint rules instead of fixing code
check_lint_suppression_file "$FILE_PATH" || exit $?

# Strict typing check (opt-in via config)
if [ "$STRICT_TYPING_ENABLED" = "true" ]; then
  check_strict_typing_file "$FILE_PATH" || exit $?
fi

exit 0
