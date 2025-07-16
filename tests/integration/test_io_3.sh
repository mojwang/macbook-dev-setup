#!/bin/bash
source "$(dirname "$0")/test_framework.sh"
describe "I/O Test 3"
it "performs file operations"
# Write test data
echo "test data 3" > "/test_3.txt"
assert_file_exists "/test_3.txt" "File created"
# Read test data
content=$(cat "/test_3.txt")
assert_equals "test data 3" "$content" "File content correct"
