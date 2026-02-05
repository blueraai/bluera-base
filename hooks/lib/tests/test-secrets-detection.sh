#!/usr/bin/env bash
# hooks/lib/tests/test-secrets-detection.sh
# Tests for secrets detection patterns used in check-git-secrets.sh
# No jq dependency - uses grep only for pattern matching

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source autolearn.sh to get BLUERA_SECRETS_PATTERN
source "$SCRIPT_DIR/../autolearn.sh"

TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT

# Test counters
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

# =============================================================================
# Helper Functions (mirror check-git-secrets.sh behavior)
# =============================================================================

# Simulate real pipeline: strip escape hatches + placeholders, then match pattern
# Returns 0 if content would be blocked, 1 otherwise
would_be_blocked() {
  local content="$1"
  local filtered
  # Strip lines with escape hatches (like the real hook does)
  filtered=$(echo "$content" | grep -vE '(# ok:|// ok:|<!-- ok:)' || true)
  # Strip placeholder patterns (like the real hook does)
  filtered=$(echo "$filtered" | \
    grep -vi 'your_.*_here' | \
    grep -vi 'placeholder' | \
    grep -vi 'example' || true)
  # Check if remaining content matches pattern (case insensitive)
  echo "$filtered" | grep -qiE "$BLUERA_SECRETS_PATTERN"
}

# Check if content has an escape hatch
has_escape_hatch() {
  echo "$1" | grep -qE '(# ok:|// ok:|<!-- ok:)'
}

# =============================================================================
# TRUE POSITIVES - These patterns MUST be blocked
# =============================================================================

test_blocks_api_key_underscore() {
  would_be_blocked 'api_key = "sk-abc123def456"' || { fail "api_key with underscore"; return; }
  pass "api_key with underscore"
}

test_blocks_api_key_hyphen() {
  would_be_blocked 'api-key = "sk-abc123"' || { fail "api-key with hyphen"; return; }
  pass "api-key with hyphen"
}

test_blocks_apikey_no_separator() {
  would_be_blocked 'apikey="secret123"' || { fail "apikey no separator"; return; }
  pass "apikey no separator"
}

test_blocks_token_assignment() {
  would_be_blocked 'token = "ghp_xxxx"' || { fail "token assignment at start"; return; }
  pass "token assignment at start"
}

test_blocks_auth_token_assignment() {
  would_be_blocked 'auth_token = "bearer123"' || { fail "_token assignment"; return; }
  pass "_token assignment"
}

test_blocks_github_token() {
  would_be_blocked 'GITHUB_TOKEN=ghp_xxxxxxxxxxxx' || { fail "GITHUB_TOKEN"; return; }
  pass "GITHUB_TOKEN"
}

test_blocks_anthropic_api_key() {
  would_be_blocked 'ANTHROPIC_API_KEY=sk-ant-xxxxx' || { fail "ANTHROPIC_API_KEY"; return; }
  pass "ANTHROPIC_API_KEY"
}

test_blocks_openai_api_key() {
  would_be_blocked 'OPENAI_API_KEY=sk-xxxxx' || { fail "OPENAI_API_KEY"; return; }
  pass "OPENAI_API_KEY"
}

test_blocks_aws_access_key() {
  would_be_blocked 'AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI' || { fail "AWS_SECRET_ACCESS_KEY"; return; }
  pass "AWS_SECRET_ACCESS_KEY"
}

test_blocks_password_literal() {
  would_be_blocked 'password: admin123' || { fail "password literal"; return; }
  pass "password literal"
}

test_blocks_secret_key() {
  would_be_blocked 'secret_key = "abc123"' || { fail "secret_key"; return; }
  pass "secret_key"
}

test_blocks_secretkey_no_separator() {
  would_be_blocked 'secretkey="value"' || { fail "secretkey no separator"; return; }
  pass "secretkey no separator"
}

test_blocks_pem_rsa() {
  would_be_blocked '-----BEGIN RSA PRIVATE KEY-----' || { fail "PEM RSA header"; return; }
  pass "PEM RSA header"
}

test_blocks_pem_generic() {
  would_be_blocked '-----BEGIN PRIVATE KEY-----' || { fail "PEM generic header"; return; }
  pass "PEM generic header"
}

test_blocks_private_key() {
  would_be_blocked 'private_key = "..."' || { fail "private_key"; return; }
  pass "private_key"
}

test_blocks_credential() {
  would_be_blocked 'credential: xyz123' || { fail "credential"; return; }
  pass "credential"
}

test_blocks_hf_token() {
  would_be_blocked 'HF_TOKEN=hf_xxxxxxxxxxxx' || { fail "HF_TOKEN"; return; }
  pass "HF_TOKEN"
}

# =============================================================================
# FALSE POSITIVES - These patterns must NOT be blocked
# =============================================================================

test_allows_max_tokens() {
  ! would_be_blocked 'max_tokens = 100' || { fail "max_tokens should be allowed"; return; }
  pass "max_tokens allowed"
}

test_allows_token_type() {
  ! would_be_blocked 'token_type: "Bearer"' || { fail "token_type should be allowed"; return; }
  pass "token_type allowed"
}

test_allows_tokenizer() {
  ! would_be_blocked 'tokenizer = BertTokenizer.from_pretrained()' || { fail "tokenizer should be allowed"; return; }
  pass "tokenizer allowed"
}

test_allows_token_path() {
  ! would_be_blocked 'tokenPath: "./config/tokens.json"' || { fail "tokenPath should be allowed"; return; }
  pass "tokenPath allowed"
}

test_allows_token_limit() {
  ! would_be_blocked 'token_limit: 4096' || { fail "token_limit should be allowed"; return; }
  pass "token_limit allowed"
}

test_allows_file_path_with_secrets() {
  ! would_be_blocked 'config_path = "./secrets/config.json"' || { fail "file path with secrets should be allowed"; return; }
  pass "file path with secrets allowed"
}

test_allows_url_with_secret() {
  ! would_be_blocked 'url = "https://api.example.com/secret/endpoint"' || { fail "URL with secret should be allowed"; return; }
  pass "URL with secret allowed"
}

# Note: The pattern matches api_key/apikey/api-key anywhere in the string
# Variable references and placeholders containing these DO match
# The real hook has additional placeholder filtering not tested here

test_allows_key_without_api_prefix() {
  # 'key' alone without api prefix doesn't match
  ! would_be_blocked 'encryption_key_id = 123' || { fail "key without api prefix should be allowed"; return; }
  pass "key without api prefix allowed"
}

test_allows_api_key_method_call() {
  # Method names like get_pinecone_api_key() should not trigger
  ! would_be_blocked 'result = app_state.get_pinecone_api_key()' || { fail "api_key method call should be allowed"; return; }
  pass "api_key method call allowed"
}

test_allows_token_in_middle_of_word() {
  # 'tokens' as part of larger word without assignment context
  ! would_be_blocked 'total_tokens: 100' || { fail "tokens in word should be allowed"; return; }
  pass "tokens in word allowed"
}

# =============================================================================
# ESCAPE HATCHES - Must bypass detection
# =============================================================================

test_escape_bash_ok() {
  local content='api_key = "sk-secret123" # ok: demo credentials'
  has_escape_hatch "$content" || { fail "bash # ok: not detected"; return; }
  ! would_be_blocked "$content" || { fail "bash # ok: didn't bypass"; return; }
  pass "bash # ok: bypass"
}

test_escape_js_ok() {
  local content='const token = "secret" // ok: testing only'
  has_escape_hatch "$content" || { fail "js // ok: not detected"; return; }
  ! would_be_blocked "$content" || { fail "js // ok: didn't bypass"; return; }
  pass "js // ok: bypass"
}

test_escape_html_ok() {
  local content='password = "test123" <!-- ok: documentation example -->'
  has_escape_hatch "$content" || { fail "html <!-- ok: not detected"; return; }
  ! would_be_blocked "$content" || { fail "html <!-- ok: didn't bypass"; return; }
  pass "html <!-- ok: bypass"
}

test_escape_ok_colon_variations() {
  # Test that ok: (with colon) is required, not just "ok"
  local content_with_colon='api_key = "secret" # ok: valid'
  local content_without_colon='api_key = "secret" # ok this is not valid'
  ! would_be_blocked "$content_with_colon" || { fail "ok: with colon should bypass"; return; }
  would_be_blocked "$content_without_colon" || { fail "ok without colon should block"; return; }
  pass "ok: colon required"
}

# =============================================================================
# PLACEHOLDER FILTERS - Must be allowed (mirrors check-git-secrets.sh)
# =============================================================================

test_allows_your_key_here() {
  ! would_be_blocked 'api_key = "your_api_key_here"' || { fail "your_*_here should be allowed"; return; }
  pass "your_*_here placeholder allowed"
}

test_allows_placeholder_value() {
  ! would_be_blocked 'token = "placeholder_token_value"' || { fail "placeholder should be allowed"; return; }
  pass "placeholder value allowed"
}

test_allows_example_secret() {
  ! would_be_blocked 'secret_key = "example_key_12345"' || { fail "example should be allowed"; return; }
  pass "example value allowed"
}

test_added_line_pattern() {
  # The hook extracts lines starting with + from git diff
  # Verify pattern still matches when content has + prefix
  would_be_blocked '+api_key = "sk-secret123"' || { fail "+line pattern should match"; return; }
  pass "+line pattern matches"
}

# =============================================================================
# EDGE CASES
# =============================================================================

test_case_insensitive() {
  would_be_blocked 'PASSWORD = "admin"' || { fail "uppercase PASSWORD"; return; }
  would_be_blocked 'Password = "admin"' || { fail "mixed case Password"; return; }
  pass "case insensitive matching"
}

test_whitespace_variations() {
  would_be_blocked 'api_key  =  "value"' || { fail "multiple spaces"; return; }
  would_be_blocked 'token	=	"value"' || { fail "tabs"; return; }
  pass "whitespace variations"
}

test_multiline_escape() {
  # Escape hatch only applies to its own line
  local content=$'api_key = "secret"\ntoken = "value" # ok: this is ok'
  # First line should still be blocked
  local first_line
  first_line=$(echo "$content" | head -1)
  would_be_blocked "$first_line" || { fail "first line should still block"; return; }
  pass "multiline escape applies per-line"
}

# =============================================================================
# RUN ALL TESTS
# =============================================================================

echo "=== Secrets Detection Test Suite ==="
echo ""

echo "--- True Positives (must block) ---"
test_blocks_api_key_underscore
test_blocks_api_key_hyphen
test_blocks_apikey_no_separator
test_blocks_token_assignment
test_blocks_auth_token_assignment
test_blocks_github_token
test_blocks_anthropic_api_key
test_blocks_openai_api_key
test_blocks_aws_access_key
test_blocks_password_literal
test_blocks_secret_key
test_blocks_secretkey_no_separator
test_blocks_pem_rsa
test_blocks_pem_generic
test_blocks_private_key
test_blocks_credential
test_blocks_hf_token

echo ""
echo "--- False Positives (must allow) ---"
test_allows_max_tokens
test_allows_token_type
test_allows_tokenizer
test_allows_token_path
test_allows_token_limit
test_allows_file_path_with_secrets
test_allows_url_with_secret
test_allows_key_without_api_prefix
test_allows_token_in_middle_of_word
test_allows_api_key_method_call

echo ""
echo "--- Escape Hatches (must bypass) ---"
test_escape_bash_ok
test_escape_js_ok
test_escape_html_ok
test_escape_ok_colon_variations

echo ""
echo "--- Placeholder Filters (must allow) ---"
test_allows_your_key_here
test_allows_placeholder_value
test_allows_example_secret
test_added_line_pattern

echo ""
echo "--- Edge Cases ---"
test_case_insensitive
test_whitespace_variations
test_multiline_escape

echo ""
echo "=== Results: $PASS_COUNT passed, $FAIL_COUNT failed ==="
[[ $FAIL_COUNT -eq 0 ]] || exit 1
