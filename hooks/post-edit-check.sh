#!/bin/bash
# Smart post-edit validation hook
# Supports: JavaScript/TypeScript, Python, Rust, Go
# Auto-detects package manager for JS/TS projects

cd "$CLAUDE_PROJECT_DIR" || exit 0

# === Detection Functions ===

detect_js_runner() {
  if [ -f "bun.lockb" ]; then echo "bun"
  elif [ -f "yarn.lock" ]; then echo "yarn"
  elif [ -f "pnpm-lock.yaml" ]; then echo "pnpm"
  else echo "npx"  # fallback for npm or no lockfile
  fi
}

# === Language-Specific Checks ===

check_javascript() {
  local MODIFIED
  MODIFIED=$(git diff --name-only HEAD 2>/dev/null | grep -E '\.(ts|tsx|js|jsx|mjs|cjs)$' || true)
  [ -z "$MODIFIED" ] && return 0

  local RUNNER
  RUNNER=$(detect_js_runner)

  # Auto-fix lint (only if eslint is available)
  if [ -f "node_modules/.bin/eslint" ] || command -v eslint &>/dev/null; then
    echo "$MODIFIED" | xargs "$RUNNER" eslint --fix --quiet 2>/dev/null || true

    # Check for remaining lint errors
    local LINT_OUT
    LINT_OUT=$(echo "$MODIFIED" | xargs "$RUNNER" eslint --quiet 2>&1)
    if [ -n "$LINT_OUT" ]; then
      echo "$LINT_OUT" >&2
      return 2
    fi
  fi

  # Type check (only if tsconfig exists)
  if [ -f "tsconfig.json" ]; then
    local TYPE_OUT
    TYPE_OUT=$("$RUNNER" tsc --noEmit --pretty false 2>&1)
    if [ -n "$TYPE_OUT" ]; then
      echo "$TYPE_OUT" | head -20 >&2
      return 2
    fi
  fi

  return 0
}

check_python() {
  local MODIFIED
  MODIFIED=$(git diff --name-only HEAD 2>/dev/null | grep -E '\.pyi?$' || true)
  [ -z "$MODIFIED" ] && return 0

  # Prefer ruff (fast), fallback to flake8
  if command -v ruff &>/dev/null; then
    echo "$MODIFIED" | xargs ruff check --fix --quiet 2>/dev/null || true

    local LINT_OUT
    LINT_OUT=$(echo "$MODIFIED" | xargs ruff check 2>&1)
    if [ -n "$LINT_OUT" ]; then
      echo "$LINT_OUT" >&2
      return 2
    fi
  elif command -v flake8 &>/dev/null; then
    local LINT_OUT
    LINT_OUT=$(echo "$MODIFIED" | xargs flake8 2>&1)
    if [ -n "$LINT_OUT" ]; then
      echo "$LINT_OUT" >&2
      return 2
    fi
  fi

  # Type check with mypy (only if pyproject.toml or mypy.ini exists)
  if command -v mypy &>/dev/null; then
    if [ -f "pyproject.toml" ] || [ -f "mypy.ini" ] || [ -f "setup.cfg" ]; then
      local TYPE_OUT
      TYPE_OUT=$(echo "$MODIFIED" | xargs mypy --no-error-summary 2>&1 | grep -v "^Success" || true)
      if [ -n "$TYPE_OUT" ]; then
        echo "$TYPE_OUT" | head -20 >&2
        return 2
      fi
    fi
  fi

  return 0
}

check_rust() {
  local MODIFIED
  MODIFIED=$(git diff --name-only HEAD 2>/dev/null | grep -E '\.rs$' || true)
  [ -z "$MODIFIED" ] && return 0

  if ! command -v cargo &>/dev/null; then
    return 0
  fi

  # Auto-format first (like zark does)
  cargo fmt --quiet 2>/dev/null || true

  # cargo clippy for linting (warnings as errors for strict mode)
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

  return 0
}

check_go() {
  local MODIFIED
  MODIFIED=$(git diff --name-only HEAD 2>/dev/null | grep -E '\.go$' || true)
  [ -z "$MODIFIED" ] && return 0

  # golangci-lint if available (comprehensive), otherwise go vet (basic)
  if command -v golangci-lint &>/dev/null; then
    local LINT_OUT
    LINT_OUT=$(golangci-lint run --new-from-rev=HEAD --out-format=line-number 2>&1 || true)
    if [ -n "$LINT_OUT" ]; then
      echo "$LINT_OUT" | head -20 >&2
      return 2
    fi
  elif command -v go &>/dev/null; then
    local LINT_OUT
    LINT_OUT=$(go vet ./... 2>&1 || true)
    if [ -n "$LINT_OUT" ]; then
      echo "$LINT_OUT" | head -20 >&2
      return 2
    fi
  fi

  return 0
}

# === Anti-pattern Check (all languages) ===

check_anti_patterns() {
  # Build file patterns array based on what's in the project
  local -a PATTERNS=()

  [ -f "package.json" ] && PATTERNS+=('*.ts' '*.tsx' '*.js' '*.jsx')
  { [ -f "pyproject.toml" ] || [ -f "requirements.txt" ] || [ -f "setup.py" ]; } && PATTERNS+=('*.py')
  [ -f "Cargo.toml" ] && PATTERNS+=('*.rs')
  [ -f "go.mod" ] && PATTERNS+=('*.go')

  [ ${#PATTERNS[@]} -eq 0 ] && return 0

  # Check for anti-patterns in added lines only
  # Note: relies on proper .gitignore (dist/, node_modules/, etc. should be ignored)
  local ANTI
  ANTI=$(git diff -- "${PATTERNS[@]}" 2>/dev/null | \
    grep -E '\b(fallback|deprecated|backward compatibility|legacy)\b' | \
    grep -v '^-' | grep -E '^\+' || true)

  if [ -n "$ANTI" ]; then
    echo 'Anti-pattern detected (fallback/deprecated/backward compatibility/legacy). Review CLAUDE.md.' >&2
    echo "$ANTI" >&2
    return 2
  fi

  return 0
}

# === Main ===

# Run checks for all detected languages (supports multi-language projects)
EXIT_CODE=0

# JavaScript/TypeScript
if [ -f "package.json" ]; then
  check_javascript || EXIT_CODE=$?
  [ $EXIT_CODE -ne 0 ] && exit $EXIT_CODE
fi

# Python
if [ -f "pyproject.toml" ] || [ -f "requirements.txt" ] || [ -f "setup.py" ]; then
  check_python || EXIT_CODE=$?
  [ $EXIT_CODE -ne 0 ] && exit $EXIT_CODE
fi

# Rust
if [ -f "Cargo.toml" ]; then
  check_rust || EXIT_CODE=$?
  [ $EXIT_CODE -ne 0 ] && exit $EXIT_CODE
fi

# Go
if [ -f "go.mod" ]; then
  check_go || EXIT_CODE=$?
  [ $EXIT_CODE -ne 0 ] && exit $EXIT_CODE
fi

# Anti-pattern check (runs for all languages)
check_anti_patterns || exit $?

exit 0
