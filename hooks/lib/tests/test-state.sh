#!/usr/bin/env bash
# hooks/lib/tests/test-state.sh
# Tests for state.sh library

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../state.sh"

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

test_get_state_simple() {
  local file="$TEST_DIR/test-simple.md"
  cat > "$file" << 'EOF'
---
iteration: 5
max_iterations: 10
---
# Content here
EOF

  local val
  val=$(bluera_get_state "$file" "iteration")
  [[ "$val" == "5" ]] || { fail "test_get_state_simple: expected 5, got '$val'"; return; }

  val=$(bluera_get_state "$file" "max_iterations")
  [[ "$val" == "10" ]] || { fail "test_get_state_simple: expected 10, got '$val'"; return; }

  pass "test_get_state_simple"
}

test_get_state_quoted() {
  local file="$TEST_DIR/test-quoted.md"
  cat > "$file" << 'EOF'
---
session_id: "abc123"
completion_promise: "done!"
---
EOF

  local val
  val=$(bluera_get_state "$file" "session_id")
  [[ "$val" == '"abc123"' ]] || { fail "test_get_state_quoted: expected '\"abc123\"', got '$val'"; return; }

  pass "test_get_state_quoted"
}

test_get_state_missing() {
  local file="$TEST_DIR/test-missing.md"
  cat > "$file" << 'EOF'
---
iteration: 5
---
EOF

  local val
  val=$(bluera_get_state "$file" "nonexistent")
  [[ -z "$val" ]] || { fail "test_get_state_missing: expected empty, got '$val'"; return; }

  pass "test_get_state_missing"
}

test_set_state_simple() {
  local file="$TEST_DIR/test-set.md"
  cat > "$file" << 'EOF'
---
iteration: 5
max_iterations: 10
---
# Content
EOF

  bluera_set_state "$file" "iteration" "6"

  local val
  val=$(bluera_get_state "$file" "iteration")
  [[ "$val" == "6" ]] || { fail "test_set_state_simple: expected 6, got '$val'"; return; }

  # Verify max_iterations unchanged
  val=$(bluera_get_state "$file" "max_iterations")
  [[ "$val" == "10" ]] || { fail "test_set_state_simple: max_iterations changed, got '$val'"; return; }

  pass "test_set_state_simple"
}

test_set_state_preserves_content() {
  local file="$TEST_DIR/test-preserve.md"
  cat > "$file" << 'EOF'
---
iteration: 1
---
# Task
This is important content.
EOF

  bluera_set_state "$file" "iteration" "2"

  # Verify content preserved
  if ! grep -q "This is important content" "$file"; then
    fail "test_set_state_preserves_content: content was lost"
    return
  fi

  pass "test_set_state_preserves_content"
}

test_state_exists_true() {
  local file="$TEST_DIR/test-exists.md"
  cat > "$file" << 'EOF'
---
iteration: 1
---
EOF

  if ! bluera_state_exists "$file"; then
    fail "test_state_exists_true: should return true for valid state file"
    return
  fi

  pass "test_state_exists_true"
}

test_state_exists_false_missing() {
  if bluera_state_exists "$TEST_DIR/nonexistent.md"; then
    fail "test_state_exists_false_missing: should return false for missing file"
    return
  fi

  pass "test_state_exists_false_missing"
}

test_state_exists_false_no_frontmatter() {
  local file="$TEST_DIR/test-no-fm.md"
  echo "# Just markdown" > "$file"

  if bluera_state_exists "$file"; then
    fail "test_state_exists_false_no_frontmatter: should return false for file without frontmatter"
    return
  fi

  pass "test_state_exists_false_no_frontmatter"
}

# Run all tests
echo "=== Running state.sh tests ==="
echo ""

test_get_state_simple
test_get_state_quoted
test_get_state_missing
test_set_state_simple
test_set_state_preserves_content
test_state_exists_true
test_state_exists_false_missing
test_state_exists_false_no_frontmatter

echo ""
echo "=== Results: $PASS_COUNT passed, $FAIL_COUNT failed ==="

[[ $FAIL_COUNT -eq 0 ]] || exit 1
