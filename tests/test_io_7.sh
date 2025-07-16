#!/bin/bash
source "$(dirname "$0")/test_framework.sh"
describe "I/O Test 7"
it "performs file operations"
# Write test data
echo "test data 7" > "/test_7.txt"
assert_file_exists "/test_7.txt" "File created"
# Read test data
content=$(cat "/test_7.txt")
assert_equals "test data 7" "$content" "File content correct"
