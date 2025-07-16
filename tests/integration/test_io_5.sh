#!/bin/bash
source "$(dirname "$0")/test_framework.sh"
describe "I/O Test 5"
it "performs file operations"
# Write test data
echo "test data 5" > "/test_5.txt"
assert_file_exists "/test_5.txt" "File created"
# Read test data
content=$(cat "/test_5.txt")
assert_equals "test data 5" "$content" "File content correct"
