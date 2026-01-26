#!/bin/bash
# Smart post-edit validation hook
# Language-independent: invokes project's own lint/typecheck scripts
#
# Per-file checks: anti-patterns, lint suppression, strict typing (on edited file)
# Project-wide checks: lint/typecheck (rate-limited to once per 30s)

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
  if [ -f "bun.lockb" ] || [ -f "bun.lock" ]; then echo "bun"
  elif [ -f "yarn.lock" ]; then echo "yarn"
  elif [ -f "pnpm-lock.yaml" ]; then echo "pnpm"
  else echo "npm"
  fi
}

# Check if project has lint configured
has_lint_script() {
  if [ -f "package.json" ] && grep -Eq '"lint"[[:space:]]*:' package.json 2>/dev/null; then
    return 0
  elif [ -f "Makefile" ] && grep -Eq '^lint[[:space:]]*:' Makefile 2>/dev/null; then
    return 0
  elif [ -f "pyproject.toml" ] && grep -Eq '\[tool\.(ruff|pylint)\]' pyproject.toml 2>/dev/null; then
    return 0
  elif [ -f "Cargo.toml" ]; then
    # Rust projects use cargo clippy by convention
    return 0
  fi
  return 1
}

# Check if project has typecheck configured
has_typecheck_script() {
  if [ -f "package.json" ] && grep -Eq '"typecheck"|"type-check"|"tsc"' package.json 2>/dev/null; then
    return 0
  elif [ -f "tsconfig.json" ]; then
    return 0
  elif [ -f "Makefile" ] && grep -Eq '^(typecheck|type-check)[[:space:]]*:' Makefile 2>/dev/null; then
    return 0
  elif [ -f "pyproject.toml" ] && grep -Eq '\[tool\.(mypy|pyright)\]' pyproject.toml 2>/dev/null; then
    return 0
  fi
  return 1
}

# === Project Script Invocation (rate-limited) ===

run_project_lint() {
  has_lint_script || return 0

  # Rate limit: only run if last check was > 30 seconds ago (scoped per project)
  local PROJECT_HASH
  PROJECT_HASH=$(echo "${CLAUDE_PROJECT_DIR:-$(pwd)}" | (md5sum 2>/dev/null || md5) | grep -oE '[a-f0-9]{8}' | head -1)
  local RATE_FILE="${TMPDIR:-/tmp}/bluera-lint-${PROJECT_HASH}"
  local NOW LAST
  NOW=$(date +%s)
  LAST=0
  [ -f "$RATE_FILE" ] && LAST=$(cat "$RATE_FILE" 2>/dev/null || echo 0)
  [ $((NOW - LAST)) -le 30 ] && return 0
  echo "$NOW" > "$RATE_FILE"

  local runner
  runner=$(detect_js_runner)

  if [ -f "package.json" ]; then
    $runner run lint --quiet 2>/dev/null || true
  elif [ -f "Makefile" ] && grep -Eq '^lint[[:space:]]*:' Makefile; then
    make lint 2>/dev/null || true
  elif [ -f "Cargo.toml" ] && command -v cargo &>/dev/null; then
    cargo clippy --quiet --message-format=short 2>&1 | grep -E "^error" | head -10 >&2 || true
  elif [ -f "pyproject.toml" ]; then
    local lint_ran=false
    if command -v poetry &>/dev/null && grep -q '\[tool.poetry\]' pyproject.toml; then
      if poetry run lint 2>/dev/null; then
        lint_ran=true
      fi
    fi
    # Fallback to ruff if poetry lint didn't run or failed
    if [ "$lint_ran" = "false" ] && command -v ruff &>/dev/null; then
      ruff check . --quiet 2>/dev/null || true
    fi
  fi
}

run_project_typecheck() {
  has_typecheck_script || return 0

  # Rate limit: only run if last check was > 30 seconds ago (scoped per project)
  local PROJECT_HASH
  PROJECT_HASH=$(echo "${CLAUDE_PROJECT_DIR:-$(pwd)}" | (md5sum 2>/dev/null || md5) | grep -oE '[a-f0-9]{8}' | head -1)
  local RATE_FILE="${TMPDIR:-/tmp}/bluera-typecheck-${PROJECT_HASH}"
  local NOW LAST
  NOW=$(date +%s)
  LAST=0
  [ -f "$RATE_FILE" ] && LAST=$(cat "$RATE_FILE" 2>/dev/null || echo 0)
  [ $((NOW - LAST)) -le 30 ] && return 0
  echo "$NOW" > "$RATE_FILE"

  local runner
  runner=$(detect_js_runner)

  if [ -f "package.json" ]; then
    # Try common script names
    $runner run typecheck --quiet 2>/dev/null || \
    $runner run type-check --quiet 2>/dev/null || \
    $runner run tsc --quiet 2>/dev/null || true
  elif [ -f "tsconfig.json" ] && [ -f "node_modules/.bin/tsc" ]; then
    node_modules/.bin/tsc --noEmit --pretty false 2>&1 | head -20 >&2 || true
  elif [ -f "Makefile" ]; then
    # Support both typecheck and type-check targets (with optional space before colon)
    if grep -Eq '^typecheck[[:space:]]*:' Makefile; then
      make typecheck 2>/dev/null || true
    elif grep -Eq '^type-check[[:space:]]*:' Makefile; then
      make type-check 2>/dev/null || true
    fi
  elif [ -f "Cargo.toml" ] && command -v cargo &>/dev/null; then
    cargo check --quiet --message-format=short 2>&1 | grep -E "^error" | head -10 >&2 || true
  elif [ -f "pyproject.toml" ]; then
    if command -v mypy &>/dev/null; then
      mypy . --no-error-summary 2>&1 | grep -v "^Success" | head -10 >&2 || true
    fi
  fi
}

# === Anti-pattern Check (single file, no deps) ===

check_anti_patterns_file() {
  local file="$1"

  # Only check text-like source files
  case "$file" in
    *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs|*.py|*.pyi|*.rs|*.go) ;;
    *) return 0 ;;
  esac

  # File must exist
  [ -f "$file" ] || return 0

  local ANTI_RE='(^|[^a-zA-Z])(fallback|deprecated|backward compatibility|legacy)([^a-zA-Z]|$)'

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

# === Lint Suppression Check (config files, no deps) ===

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
      # Check for disabling markdown rules: "MD___": false (JSON) or MD___: false (YAML)
      if echo "$ADDED" | grep -E '("MD[0-9]+"|MD[0-9]+)[[:space:]]*:[[:space:]]*false' | grep -v '// ok:' | grep -v '# ok:' | grep -q .; then
        echo "Lint suppression detected ($file): disabling markdownlint rules" >&2
        echo "Fix the markdown issues instead of disabling rules." >&2
        echo "$ADDED" | grep -E '("MD[0-9]+"|MD[0-9]+)[[:space:]]*:[[:space:]]*false' | head -5 >&2
        return 2
      fi
      ;;
    .eslintrc*|eslint.config.*)
      # Check for disabling eslint rules: "off", 'off', 0, or array forms ["off"], ['off'], [0]
      if echo "$ADDED" | grep -E ":[[:space:]]*(\"off\"|'off'|0|\[\"off\"\]|\['off'\]|\[0\])[[:space:]]*[,}\]]" | grep -v '// ok:' | grep -q .; then
        echo "Lint suppression detected ($file): disabling ESLint rules" >&2
        echo "Fix the code issues instead of disabling rules." >&2
        echo "$ADDED" | grep -E ":[[:space:]]*(\"off\"|'off'|0)" | head -5 >&2
        return 2
      fi
      ;;
    pyproject.toml|.ruff.toml|ruff.toml)
      # Check for ignore patterns in ruff config (including extend-ignore and per-file-ignores)
      if echo "$ADDED" | grep -E '(extend-ignore|per-file-ignores|ignore)[[:space:]]*=' | grep -v '# ok:' | grep -q .; then
        echo "Lint suppression detected ($file): adding ruff ignore patterns" >&2
        echo "Fix the Python issues instead of ignoring rules." >&2
        echo "$ADDED" | grep -E '(extend-)?ignore[[:space:]]*=' | head -5 >&2
        return 2
      fi
      ;;
    .pylintrc)
      # Check for disable additions
      if echo "$ADDED" | grep -E 'disable[[:space:]]*=' | grep -v '# ok:' | grep -q .; then
        echo "Lint suppression detected ($file): disabling pylint rules" >&2
        echo "Fix the Python issues instead of disabling rules." >&2
        echo "$ADDED" | grep -E 'disable[[:space:]]*=' | head -5 >&2
        return 2
      fi
      ;;
  esac

  return 0
}

# === Strict Typing Check (single file, no deps) ===

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

      # 'any' type (but not 'company' or 'many' etc)
      if echo "$CONTENT" | grep -E ':[[:space:]]*any([^a-zA-Z]|$)|<any>|as[[:space:]]+any([^a-zA-Z]|$)' | grep -v '// ok:' | grep -q .; then
        echo "Strict typing violation ($file): 'any' type is forbidden" >&2
        echo "$CONTENT" | grep -En ':[[:space:]]*any([^a-zA-Z]|$)|<any>|as[[:space:]]+any([^a-zA-Z]|$)' | grep -v '// ok:' | head -5 >&2
        return 2
      fi

      # Unsafe 'as' type casts (but allow 'as const')
      # Match uppercase types and lowercase TS primitives (string, number, boolean, unknown, etc.)
      if echo "$CONTENT" | grep -E '(^|[^a-zA-Z])as[[:space:]]+(string|number|boolean|unknown|never|null|undefined|object|symbol|bigint|[A-Z])' | grep -v 'as const' | grep -v '// ok:' | grep -q .; then
        echo "Strict typing violation ($file): unsafe 'as' cast is forbidden (use type guards)" >&2
        echo "$CONTENT" | grep -En '(^|[^a-zA-Z])as[[:space:]]+(string|number|boolean|unknown|never|null|undefined|object|symbol|bigint|[A-Z])' | grep -v 'as const' | grep -v '// ok:' | head -5 >&2
        return 2
      fi

      # @ts-ignore without explanation (must have 10+ chars after it)
      # Escape hatch: add "// ok:" on same line
      if echo "$CONTENT" | grep '@ts-ignore' | grep -v '// ok:' | grep -v -E '@ts-ignore[[:space:]]+.{10,}' | grep -q .; then
        echo "Strict typing violation ($file): @ts-ignore requires 10+ char explanation" >&2
        echo "$CONTENT" | grep -En '@ts-ignore' | grep -v '// ok:' | grep -v -E '@ts-ignore[[:space:]]+.{10,}' | head -5 >&2
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

      # type: ignore without error code [code]
      # Escape hatch: add "# ok:" on same line
      if echo "$CONTENT" | grep -E '#[[:space:]]*type:[[:space:]]*ignore' | grep -v '# ok:' | grep -v -E '#[[:space:]]*type:[[:space:]]*ignore\[' | grep -q .; then
        echo "Strict typing violation ($file): 'type: ignore' requires error code [code]" >&2
        echo "$CONTENT" | grep -En '#[[:space:]]*type:[[:space:]]*ignore' | grep -v '# ok:' | grep -v -E '#[[:space:]]*type:[[:space:]]*ignore\[' | head -5 >&2
        return 2
      fi

      # Any type usage (from typing import Any, or : Any)
      if echo "$CONTENT" | grep -E '(^|[^a-zA-Z])Any([^a-zA-Z]|$)' | grep -v '# ok:' | grep -q .; then
        echo "Strict typing violation ($file): 'Any' type is forbidden (use specific types or generics)" >&2
        echo "$CONTENT" | grep -En '(^|[^a-zA-Z])Any([^a-zA-Z]|$)' | grep -v '# ok:' | head -5 >&2
        return 2
      fi

      # cast() is usually a code smell
      if echo "$CONTENT" | grep -E '(^|[^a-zA-Z])cast[[:space:]]*\(' | grep -v '# ok:' | grep -q .; then
        echo "Strict typing violation ($file): cast() is forbidden (use type guards or fix types)" >&2
        echo "$CONTENT" | grep -En '(^|[^a-zA-Z])cast[[:space:]]*\(' | head -5 >&2
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

# Anti-pattern check (all source files, no deps)
check_anti_patterns_file "$FILE_PATH" || exit $?

# Lint suppression check (config files, no deps)
check_lint_suppression_file "$FILE_PATH" || exit $?

# Strict typing check (opt-in via config, no deps)
if [ "$STRICT_TYPING_ENABLED" = "true" ]; then
  check_strict_typing_file "$FILE_PATH" || exit $?
fi

# Project lint/typecheck (rate-limited, uses project scripts)
run_project_lint
run_project_typecheck

exit 0
