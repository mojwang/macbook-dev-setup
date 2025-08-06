#!/usr/bin/env bash
source "$(dirname "$0")/../test_framework.sh"

# Create temporary directory for test
TEST_TMP_DIR=$(mktemp -d)
trap "rm -rf '$TEST_TMP_DIR'" EXIT

describe "I/O Test 6"
it "performs file operations"
# Write test data
echo "test data 6" > "$TEST_TMP_DIR/test_6.txt"
assert_file_exists "$TEST_TMP_DIR/test_6.txt" "File created"
# Read test data
content=$(cat "$TEST_TMP_DIR/test_6.txt")
assert_equals "test data 6" "$content" "File content correct"
