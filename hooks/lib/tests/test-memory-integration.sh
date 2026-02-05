#!/usr/bin/env bash
# Test memory integration features
# Tests: hash function, deduplication, apply-helper, import markers
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Setup test directory BEFORE sourcing libraries
# (ensures bluera_memory_dir uses test HOME, not real ~/.claude)
TEST_HOME=$(mktemp -d)
export HOME="$TEST_HOME"
export CLAUDE_PROJECT_DIR="$TEST_HOME"
trap 'rm -rf "$TEST_HOME"' EXIT

# Now source libraries (they'll use TEST_HOME for paths)
# shellcheck source=../memory.sh
source "$SCRIPT_DIR/../memory.sh"
# shellcheck source=../autolearn.sh
source "$SCRIPT_DIR/../autolearn.sh"

PASS=0 FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "=== Memory Integration Test Suite ==="
echo ""

# Test 1: Cross-platform hash function
test_hash_function() {
  local hash
  hash=$(bluera_memory_content_hash "test content")
  if [[ -n "$hash" && ${#hash} -ge 16 ]]; then
    pass "hash function produces output: $hash"
  else
    fail "hash function (got: '$hash')"
  fi
}

# Test 2: Hash normalization
test_hash_normalization() {
  local hash1 hash2
  hash1=$(bluera_memory_content_hash "Test Content")
  hash2=$(bluera_memory_content_hash "test content")
  if [[ "$hash1" == "$hash2" ]]; then
    pass "hash normalization (case insensitive)"
  else
    fail "hash normalization: '$hash1' != '$hash2'"
  fi
}

# Test 3: Dedup detects same title
test_dedup_same_title() {
  bluera_memory_init
  local id
  id=$(bluera_memory_create "Test Learning Title" --tags test)
  if bluera_memory_is_duplicate "Test Learning Title"; then
    pass "dedup detects same title"
  else
    fail "dedup same title"
  fi
  bluera_memory_delete "$id" >/dev/null 2>&1 || true
}

# Test 4: Dedup detects case-insensitive match
test_dedup_case_insensitive() {
  bluera_memory_init
  local id
  id=$(bluera_memory_create "API Uses snake_case" --tags test)
  if bluera_memory_is_duplicate "api uses snake_case"; then
    pass "dedup case insensitive"
  else
    fail "dedup case insensitive"
  fi
  bluera_memory_delete "$id" >/dev/null 2>&1 || true
}

# Test 5: Dedup allows unique content
test_dedup_allows_unique() {
  bluera_memory_init
  local id
  id=$(bluera_memory_create "First Learning" --tags test)
  if ! bluera_memory_is_duplicate "Completely Different Content"; then
    pass "dedup allows unique content"
  else
    fail "dedup allows unique"
  fi
  bluera_memory_delete "$id" >/dev/null 2>&1 || true
}

# Test 6: Dedup is title-only (same body, different title = NOT duplicate)
test_dedup_title_only() {
  bluera_memory_init
  local id
  id=$(bluera_memory_create "First Title" --tags test)
  # Add identical body to existing memory
  echo -e "\nShared body content here" >> "$(bluera_memory_dir)/$id.md"

  # Different title with same body should NOT be flagged as duplicate
  # (We dedup on TITLE only, not body)
  if ! bluera_memory_is_duplicate "Different Title"; then
    pass "dedup is title-only (same body, different title allowed)"
  else
    fail "dedup incorrectly flagged different title as duplicate"
  fi
  bluera_memory_delete "$id" >/dev/null 2>&1 || true
}

# Test 7: Auto-tagging word boundaries
test_auto_tags_word_boundary() {
  local tags
  tags=$(bluera_memory_auto_tags "Run tests before commit" "manual")
  if echo "$tags" | grep -q "testing"; then
    pass "auto-tags: 'tests' -> 'testing'"
  else
    fail "auto-tags word boundary (got: '$tags')"
  fi
}

# Test 8: Auto-tagging avoids false positives
test_auto_tags_no_false_positive() {
  local tags
  tags=$(bluera_memory_auto_tags "Contest results are in" "manual")
  if ! echo "$tags" | grep -q "testing"; then
    pass "auto-tags: 'contest' != 'test'"
  else
    fail "auto-tags false positive: contest matched test"
  fi
}

# Test 9: Apply-learning helper writes to CLAUDE.local.md
test_apply_helper() {
  cd "$TEST_HOME"
  if bash "$SCRIPT_DIR/../apply-learning.sh" "Test via helper" "fact" "0.5" >/dev/null 2>&1; then
    if grep -q "Test via helper" CLAUDE.local.md 2>/dev/null; then
      pass "apply helper writes learning"
    else
      fail "apply helper write (file missing content)"
    fi
  else
    fail "apply helper execution"
  fi
}

# Test 10: Import markers match autolearn.sh
test_import_markers() {
  if [[ "$BLUERA_LEARN_START" == "<!-- AUTO:bluera-base:learned -->" ]]; then
    if [[ "$BLUERA_LEARN_END" == "<!-- END:bluera-base:learned -->" ]]; then
      pass "import markers match"
    else
      fail "end marker mismatch"
    fi
  else
    fail "start marker mismatch"
  fi
}

# Test 11: Promotion stays off by default
test_promotion_disabled_by_default() {
  bluera_memory_init
  cd "$TEST_HOME"

  # Clear any existing memories
  rm -f "$(bluera_memory_dir)"/*.md 2>/dev/null || true

  # Apply a high-confidence learning (promotion should be skipped)
  bash "$SCRIPT_DIR/../apply-learning.sh" "High confidence test" "fact" "0.95" >/dev/null 2>&1

  # Check no memory was created (promotion disabled by default)
  local count
  shopt -s nullglob
  local mem_files=("$(bluera_memory_dir)"/*.md)
  shopt -u nullglob
  count=${#mem_files[@]}
  if [[ $count -eq 0 ]]; then
    pass "promotion disabled by default"
  else
    fail "promotion should be disabled by default (found $count memories)"
  fi
}

# Test 12: Title hash stored in frontmatter
test_title_hash_in_frontmatter() {
  bluera_memory_init
  local id
  id=$(bluera_memory_create "Hash Test Memory" --tags test)
  local file
  file="$(bluera_memory_dir)/${id}.md"
  if grep -q "title_hash:" "$file"; then
    pass "title_hash in frontmatter"
  else
    fail "title_hash not in frontmatter"
  fi
  bluera_memory_delete "$id" >/dev/null 2>&1 || true
}

# Run all tests
echo "--- Hash Function Tests ---"
test_hash_function
test_hash_normalization

echo ""
echo "--- Deduplication Tests ---"
test_dedup_same_title
test_dedup_case_insensitive
test_dedup_allows_unique
test_dedup_title_only

echo ""
echo "--- Auto-Tagging Tests ---"
test_auto_tags_word_boundary
test_auto_tags_no_false_positive

echo ""
echo "--- Integration Tests ---"
test_apply_helper
test_import_markers
test_promotion_disabled_by_default
test_title_hash_in_frontmatter

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[[ $FAIL -eq 0 ]] || exit 1
