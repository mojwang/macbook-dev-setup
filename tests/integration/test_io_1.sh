#!/usr/bin/env bash
source "$(dirname "$0")/../test_framework.sh"

# Create temporary directory for test
TEST_TMP_DIR=$(mktemp -d)
trap "rm -rf '$TEST_TMP_DIR'" EXIT

describe "I/O Test 1"
it "performs file operations"
# Write test data
echo "test data 1" > "$TEST_TMP_DIR/test_1.txt"
assert_file_exists "$TEST_TMP_DIR/test_1.txt" "File created"
# Read test data
content=$(cat "$TEST_TMP_DIR/test_1.txt")
assert_equals "test data 1" "$content" "File content correct"
