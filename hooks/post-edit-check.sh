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

  # If git tracked, check only added lines
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if git ls-files --error-unmatch "$file" >/dev/null 2>&1; then
      local ADDED
      ADDED=$(git diff -U0 -- "$file" 2>/dev/null | grep -E '^\+' | grep -vE '^\+\+\+' || true)
      if echo "$ADDED" | grep -Eiq "$ANTI_RE"; then
        echo "Anti-pattern detected in added lines ($file): fallback/deprecated/legacy/backward compatibility" >&2
        echo "$ADDED" | grep -Ei "$ANTI_RE" | head -10 >&2
        return 2
      fi
      return 0
    fi
  fi

  # Untracked or non-git: scan full file
  if grep -Eiq "$ANTI_RE" "$file"; then
    echo "Anti-pattern detected in file ($file): fallback/deprecated/legacy/backward compatibility" >&2
    grep -Ein "$ANTI_RE" "$file" | head -10 >&2
    return 2
  fi

  return 0
}

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

exit 0
