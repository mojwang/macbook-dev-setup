#!/bin/bash
source "$(dirname "$0")/test_framework.sh"
describe "I/O Test 2"
it "performs file operations"
# Write test data
echo "test data 2" > "/test_2.txt"
assert_file_exists "/test_2.txt" "File created"
# Read test data
content=$(cat "/test_2.txt")
assert_equals "test data 2" "$content" "File content correct"
