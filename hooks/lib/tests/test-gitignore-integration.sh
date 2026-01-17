#!/usr/bin/env bash
# hooks/lib/tests/test-gitignore-integration.sh
# Tests for gitignore.sh integration in session-setup

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../gitignore.sh"

TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT

# Test counter
PASS_COUNT=0
FAIL_COUNT=0

pass() {
  echo "PASS: $1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
  echo "FAIL: $1"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

test_ensure_patterns_creates_gitignore() {
  export CLAUDE_PROJECT_DIR="$TEST_DIR/new-project"
  mkdir -p "$CLAUDE_PROJECT_DIR"

  gitignore_ensure_patterns || true

  if [[ ! -f "$CLAUDE_PROJECT_DIR/.gitignore" ]]; then
    fail "test_ensure_patterns_creates_gitignore: .gitignore not created"
    return
  fi

  if ! grep -q ".bluera/" "$CLAUDE_PROJECT_DIR/.gitignore"; then
    fail "test_ensure_patterns_creates_gitignore: .bluera/ pattern not found"
    return
  fi

  pass "test_ensure_patterns_creates_gitignore"
}

test_ensure_patterns_appends_to_existing() {
  export CLAUDE_PROJECT_DIR="$TEST_DIR/existing-project"
  mkdir -p "$CLAUDE_PROJECT_DIR"
  echo "node_modules/" > "$CLAUDE_PROJECT_DIR/.gitignore"

  gitignore_ensure_patterns || true

  if ! grep -q "node_modules/" "$CLAUDE_PROJECT_DIR/.gitignore"; then
    fail "test_ensure_patterns_appends_to_existing: existing pattern lost"
    return
  fi

  if ! grep -q ".bluera/" "$CLAUDE_PROJECT_DIR/.gitignore"; then
    fail "test_ensure_patterns_appends_to_existing: .bluera/ pattern not added"
    return
  fi

  pass "test_ensure_patterns_appends_to_existing"
}

test_ensure_patterns_idempotent() {
  export CLAUDE_PROJECT_DIR="$TEST_DIR/idempotent-project"
  mkdir -p "$CLAUDE_PROJECT_DIR"

  gitignore_ensure_patterns || true  # First run adds patterns
  local line_count_before
  line_count_before=$(wc -l < "$CLAUDE_PROJECT_DIR/.gitignore" | tr -d ' ')

  # Run again - should not add duplicates (returns 1 when nothing to add)
  gitignore_ensure_patterns || true
  local line_count_after
  line_count_after=$(wc -l < "$CLAUDE_PROJECT_DIR/.gitignore" | tr -d ' ')

  if [[ "$line_count_before" != "$line_count_after" ]]; then
    fail "test_ensure_patterns_idempotent: patterns added twice ($line_count_before vs $line_count_after)"
    return
  fi

  pass "test_ensure_patterns_idempotent"
}

test_negation_patterns_present() {
  export CLAUDE_PROJECT_DIR="$TEST_DIR/negation-project"
  mkdir -p "$CLAUDE_PROJECT_DIR"

  gitignore_ensure_patterns || true

  # Check for negation patterns
  if ! grep -q "!.bluera/bluera-base/" "$CLAUDE_PROJECT_DIR/.gitignore"; then
    fail "test_negation_patterns_present: negation pattern !.bluera/bluera-base/ not found"
    return
  fi

  pass "test_negation_patterns_present"
}

# Run all tests
echo "=== Running gitignore integration tests ==="
echo ""

test_ensure_patterns_creates_gitignore
test_ensure_patterns_appends_to_existing
test_ensure_patterns_idempotent
test_negation_patterns_present

echo ""
echo "=== Results: $PASS_COUNT passed, $FAIL_COUNT failed ==="

[[ $FAIL_COUNT -eq 0 ]] || exit 1
