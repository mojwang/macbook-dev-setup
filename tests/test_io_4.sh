#!/bin/bash
source "$(dirname "$0")/test_framework.sh"
describe "I/O Test 4"
it "performs file operations"
# Write test data
echo "test data 4" > "/test_4.txt"
assert_file_exists "/test_4.txt" "File created"
# Read test data
content=$(cat "/test_4.txt")
assert_equals "test data 4" "$content" "File content correct"
