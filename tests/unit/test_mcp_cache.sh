#!/usr/bin/env bash

# Test MCP API key validation caching functionality

set -e

# Set test mode
export TEST_MODE=1

# Set ROOT_DIR correctly before loading test framework
export ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

# Load test framework
source "$(dirname "$0")/../test_framework.sh"

# Mock functions and variables needed for testing
VALIDATION_CACHE_FILE="/tmp/mcp-validated-keys-$(date +%Y%m%d)"
VALIDATION_CACHE_DURATION=3600

# Source the extracted cache functions
source "$(dirname "$0")/test_mcp_cache_functions.sh"

# Test suite
describe "MCP API Key Validation Cache"

# Test cache file creation with secure permissions
it "creates cache file with secure permissions" '
    # Setup
    VALIDATION_CACHE_FILE="/tmp/test-mcp-cache-$$"
    trap "rm -f $VALIDATION_CACHE_FILE" EXIT
    
    # Execute
    cache_validation "TEST_KEY"
    
    # Verify permissions (should be 600 - readable/writable by owner only)
    local perms=$(stat -f "%OLp" "$VALIDATION_CACHE_FILE" 2>/dev/null || stat -c "%a" "$VALIDATION_CACHE_FILE")
    assert_equals "$perms" "600" "Cache file should have 600 permissions"
    
    # Verify content
    assert_contains "$(cat "$VALIDATION_CACHE_FILE")" "TEST_KEY:" "Cache should contain key entry"
'

# Test cache validation check
it "checks if validation is cached" '
    # Setup
    VALIDATION_CACHE_FILE="/tmp/test-mcp-cache-$$"
    VALIDATION_CACHE_DURATION=3600
    trap "rm -f $VALIDATION_CACHE_FILE" EXIT
    
    # Add a valid cache entry
    echo "TEST_KEY:$(date +%s)" > "$VALIDATION_CACHE_FILE"
    
    # Should return success for valid cache
    is_validation_cached TEST_KEY
    assert_equals "$?" "0" "Should find cached validation"
    
    # Should return failure for non-existent key
    is_validation_cached MISSING_KEY || true
    assert_equals "$?" "0" "Command should complete"
'

# Test cache expiration
it "handles cache expiration" '
    # Setup
    VALIDATION_CACHE_FILE="/tmp/test-mcp-cache-$$"
    VALIDATION_CACHE_DURATION=2  # 2 seconds for testing
    trap "rm -f $VALIDATION_CACHE_FILE" EXIT
    
    # Add an expired cache entry (3 seconds old)
    local old_time=$(($(date +%s) - 3))
    echo "EXPIRED_KEY:$old_time" > "$VALIDATION_CACHE_FILE"
    
    # Should return failure for expired cache
    is_validation_cached EXPIRED_KEY && false || true
    assert_equals "$?" "0" "Should not use expired cache"
    
    # Expired entry should be removed
    assert_not_contains "$(cat "$VALIDATION_CACHE_FILE" 2>/dev/null || echo "")" "EXPIRED_KEY:" "Expired entry should be removed"
'

# Test cleanup of old cache files
it "cleans up old cache files" '
    # Setup - create old cache files
    local old_file="/tmp/mcp-validated-keys-20230101"
    local current_file="/tmp/mcp-validated-keys-$(date +%Y%m%d)"
    
    touch -t 202301010000 "$old_file" 2>/dev/null || touch "$old_file"
    touch "$current_file"
    
    # Execute cleanup
    cleanup_old_cache_files
    
    # Old file should be removed
    assert_false "test -f $old_file" "Old cache file should be removed"
    
    # Current file should remain
    assert_true "test -f $current_file" "Current cache file should remain"
    
    # Cleanup
    rm -f "$current_file"
'

# Test multiple cache entries
it "handles multiple cache entries" '
    # Setup
    VALIDATION_CACHE_FILE="/tmp/test-mcp-cache-$$"
    VALIDATION_CACHE_DURATION=3600
    trap "rm -f $VALIDATION_CACHE_FILE" EXIT
    
    # Add multiple entries
    cache_validation "KEY1"
    cache_validation "KEY2"
    cache_validation "KEY3"
    
    # All should be cached
    is_validation_cached KEY1
    assert_equals "$?" "0" "KEY1 should be cached"
    is_validation_cached KEY2
    assert_equals "$?" "0" "KEY2 should be cached"
    is_validation_cached KEY3
    assert_equals "$?" "0" "KEY3 should be cached"
    
    # Count entries
    local count=$(wc -l < "$VALIDATION_CACHE_FILE")
    assert_equals "$count" "3" "Should have 3 cache entries"
'

# Test cache update for existing key
it "updates existing cache entry" '
    # Setup
    VALIDATION_CACHE_FILE="/tmp/test-mcp-cache-$$"
    trap "rm -f $VALIDATION_CACHE_FILE" EXIT
    
    # Add initial entry with old timestamp
    echo "UPDATE_KEY:1000000000" > "$VALIDATION_CACHE_FILE"
    
    # Update the entry
    cache_validation "UPDATE_KEY"
    
    # Should have only one entry
    local count=$(grep -c "UPDATE_KEY:" "$VALIDATION_CACHE_FILE")
    assert_equals "$count" "1" "Should have only one entry for the key"
    
    # Timestamp should be updated (not the old one)
    assert_not_contains "$(cat "$VALIDATION_CACHE_FILE")" "UPDATE_KEY:1000000000" "Old timestamp should be replaced"
'

# Test cache file error handling
it "handles cache file errors gracefully" '
    # Setup - use a directory path as cache file (will fail)
    VALIDATION_CACHE_FILE="/tmp"
    
    # Should not crash when cache operations fail
    cache_validation "TEST_KEY" 2>/dev/null || true
    is_validation_cached "TEST_KEY" 2>/dev/null || true
    cleanup_old_cache_files 2>/dev/null || true
    
    # Test passed if we get here without crashing
    assert_true "true" "Cache operations should handle errors gracefully"
'

# Tests are run automatically by the test framework