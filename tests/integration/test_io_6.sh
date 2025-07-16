#!/bin/bash
source "$(dirname "$0")/test_framework.sh"
describe "I/O Test 6"
it "performs file operations"
# Write test data
echo "test data 6" > "/test_6.txt"
assert_file_exists "/test_6.txt" "File created"
# Read test data
content=$(cat "/test_6.txt")
assert_equals "test data 6" "$content" "File content correct"
