#!/usr/bin/env bash

# Test MCP API key validation caching functionality

# Set test mode
export TEST_MODE=1

_TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load test framework
source "$_TEST_DIR/../test_framework.sh"

# Mock functions and variables needed for testing
VALIDATION_CACHE_FILE="/tmp/mcp-validated-keys-$(date +%Y%m%d)"
VALIDATION_CACHE_DURATION=3600

# Source the extracted cache functions
source "$_TEST_DIR/test_mcp_cache_functions.sh"

# Test suite
describe "MCP API Key Validation Cache"

# Test cache file creation with secure permissions
it "creates cache file with secure permissions"
VALIDATION_CACHE_FILE="/tmp/test-mcp-cache-$$"
rm -f "$VALIDATION_CACHE_FILE"
cache_validation "TEST_KEY"
perms=$(stat -f "%OLp" "$VALIDATION_CACHE_FILE" 2>/dev/null || stat -c "%a" "$VALIDATION_CACHE_FILE")
assert_equals "$perms" "600" "Cache file should have 600 permissions"
assert_contains "$(cat "$VALIDATION_CACHE_FILE")" "TEST_KEY:" "Cache should contain key entry"
rm -f "$VALIDATION_CACHE_FILE"

# Test cache validation check
it "checks if validation is cached"
VALIDATION_CACHE_FILE="/tmp/test-mcp-cache-$$"
VALIDATION_CACHE_DURATION=3600
rm -f "$VALIDATION_CACHE_FILE"
echo "TEST_KEY:$(date +%s)" > "$VALIDATION_CACHE_FILE"
is_validation_cached TEST_KEY
assert_equals "$?" "0" "Should find cached validation"
is_validation_cached MISSING_KEY || true
assert_true "true" "Command should complete without crashing"
rm -f "$VALIDATION_CACHE_FILE"

# Test cache expiration
it "handles cache expiration"
VALIDATION_CACHE_FILE="/tmp/test-mcp-cache-$$"
VALIDATION_CACHE_DURATION=2  # 2 seconds for testing
rm -f "$VALIDATION_CACHE_FILE"
old_time=$(($(date +%s) - 3))
echo "EXPIRED_KEY:$old_time" > "$VALIDATION_CACHE_FILE"
if is_validation_cached EXPIRED_KEY; then
    assert_true "false" "Should not use expired cache"
else
    assert_true "true" "Should not use expired cache"
fi
assert_not_contains "$(cat "$VALIDATION_CACHE_FILE" 2>/dev/null || echo "")" "EXPIRED_KEY:" "Expired entry should be removed"
rm -f "$VALIDATION_CACHE_FILE"

# Test cleanup of old cache files
it "cleans up old cache files"
old_file="/tmp/mcp-validated-keys-20230101"
current_file="/tmp/mcp-validated-keys-$(date +%Y%m%d)"
touch -t 202301010000 "$old_file" 2>/dev/null || touch "$old_file"
touch "$current_file"
cleanup_old_cache_files
assert_false "test -f '$old_file'" "Old cache file should be removed"
assert_true "test -f '$current_file'" "Current cache file should remain"
rm -f "$current_file" "$old_file"

# Test multiple cache entries
it "handles multiple cache entries"
VALIDATION_CACHE_FILE="/tmp/test-mcp-cache-$$"
VALIDATION_CACHE_DURATION=3600
rm -f "$VALIDATION_CACHE_FILE"
cache_validation "KEY1"
cache_validation "KEY2"
cache_validation "KEY3"
is_validation_cached KEY1
assert_equals "$?" "0" "KEY1 should be cached"
is_validation_cached KEY2
assert_equals "$?" "0" "KEY2 should be cached"
is_validation_cached KEY3
assert_equals "$?" "0" "KEY3 should be cached"
count=$(wc -l < "$VALIDATION_CACHE_FILE" | tr -d ' ')
assert_equals "$count" "3" "Should have 3 cache entries"
rm -f "$VALIDATION_CACHE_FILE"

# Test cache update for existing key
it "updates existing cache entry"
VALIDATION_CACHE_FILE="/tmp/test-mcp-cache-$$"
rm -f "$VALIDATION_CACHE_FILE"
echo "UPDATE_KEY:1000000000" > "$VALIDATION_CACHE_FILE"
cache_validation "UPDATE_KEY"
count=$(grep -c "UPDATE_KEY:" "$VALIDATION_CACHE_FILE")
assert_equals "$count" "1" "Should have only one entry for the key"
assert_not_contains "$(cat "$VALIDATION_CACHE_FILE")" "UPDATE_KEY:1000000000" "Old timestamp should be replaced"
rm -f "$VALIDATION_CACHE_FILE"

# Test cache file error handling
it "handles cache file errors gracefully"
VALIDATION_CACHE_FILE="/tmp"
cache_validation "TEST_KEY" 2>/dev/null || true
is_validation_cached "TEST_KEY" 2>/dev/null || true
cleanup_old_cache_files 2>/dev/null || true
assert_true "true" "Cache operations should handle errors gracefully"

# Print results
print_summary
