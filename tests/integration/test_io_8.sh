#!/bin/bash
source "$(dirname "$0")/test_framework.sh"
describe "I/O Test 8"
it "performs file operations"
# Write test data
echo "test data 8" > "/test_8.txt"
assert_file_exists "/test_8.txt" "File created"
# Read test data
content=$(cat "/test_8.txt")
assert_equals "test data 8" "$content" "File content correct"
