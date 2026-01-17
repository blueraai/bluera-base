#!/usr/bin/env bash
# hooks/lib/tests/test-signals.sh
# Tests for signals.sh library

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../config.sh"
source "$SCRIPT_DIR/../signals.sh"

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

test_signals_file_path() {
  export BLUERA_STATE_DIR="$TEST_DIR"

  local file
  file=$(bluera_signals_file)
  [[ "$file" == "$TEST_DIR/session-signals.json" ]] || { fail "test_signals_file_path: expected $TEST_DIR/session-signals.json, got $file"; return; }
  pass "test_signals_file_path"
}

test_init_signals() {
  export BLUERA_STATE_DIR="$TEST_DIR"
  bluera_init_signals "test-session-123"

  local file="$TEST_DIR/session-signals.json"
  [[ -f "$file" ]] || { fail "test_init_signals: signals file not created"; return; }

  local session_id
  session_id=$(jq -r '.session_id' "$file")
  [[ "$session_id" == "test-session-123" ]] || { fail "test_init_signals: session_id mismatch, got $session_id"; return; }

  local started_at
  started_at=$(jq -r '.started_at' "$file")
  [[ -n "$started_at" ]] || { fail "test_init_signals: started_at empty"; return; }

  pass "test_init_signals"
}

test_load_signals_empty() {
  export BLUERA_STATE_DIR="$TEST_DIR/empty"
  mkdir -p "$TEST_DIR/empty"

  local signals
  signals=$(bluera_load_signals)

  local session_id
  session_id=$(echo "$signals" | jq -r '.session_id')
  [[ "$session_id" == "" ]] || { fail "test_load_signals_empty: expected empty session_id, got $session_id"; return; }

  pass "test_load_signals_empty"
}

test_increment_signal() {
  export BLUERA_STATE_DIR="$TEST_DIR/inc"
  mkdir -p "$TEST_DIR/inc"
  bluera_init_signals "test-session"

  bluera_increment_signal "git status"
  bluera_increment_signal "git status"
  bluera_increment_signal "git diff"

  local count
  count=$(bluera_get_signal_count "git status")
  [[ "$count" == "2" ]] || { fail "test_increment_signal: expected 2, got $count"; return; }

  count=$(bluera_get_signal_count "git diff")
  [[ "$count" == "1" ]] || { fail "test_increment_signal: expected 1, got $count"; return; }

  pass "test_increment_signal"
}

test_get_signal_count_missing() {
  export BLUERA_STATE_DIR="$TEST_DIR/missing"
  mkdir -p "$TEST_DIR/missing"
  bluera_init_signals "test-session"

  local count
  count=$(bluera_get_signal_count "nonexistent")
  [[ "$count" == "0" ]] || { fail "test_get_signal_count_missing: expected 0, got $count"; return; }

  pass "test_get_signal_count_missing"
}

test_signals_session_id() {
  export BLUERA_STATE_DIR="$TEST_DIR/sid"
  mkdir -p "$TEST_DIR/sid"
  bluera_init_signals "my-session-456"

  local sid
  sid=$(bluera_signals_session_id)
  [[ "$sid" == "my-session-456" ]] || { fail "test_signals_session_id: expected my-session-456, got $sid"; return; }

  pass "test_signals_session_id"
}

# Run all tests
echo "=== Running signals.sh tests ==="
echo ""

test_signals_file_path
test_init_signals
test_load_signals_empty
test_increment_signal
test_get_signal_count_missing
test_signals_session_id

echo ""
echo "=== Results: $PASS_COUNT passed, $FAIL_COUNT failed ==="

[[ $FAIL_COUNT -eq 0 ]] || exit 1
