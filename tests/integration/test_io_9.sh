#!/bin/bash
source "$(dirname "$0")/test_framework.sh"
describe "I/O Test 9"
it "performs file operations"
# Write test data
echo "test data 9" > "/test_9.txt"
assert_file_exists "/test_9.txt" "File created"
# Read test data
content=$(cat "/test_9.txt")
assert_equals "test data 9" "$content" "File content correct"
