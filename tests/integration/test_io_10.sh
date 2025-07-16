#!/bin/bash
source "$(dirname "$0")/test_framework.sh"
describe "I/O Test 10"
it "performs file operations"
# Write test data
echo "test data 10" > "/test_10.txt"
assert_file_exists "/test_10.txt" "File created"
# Read test data
content=$(cat "/test_10.txt")
assert_equals "test data 10" "$content" "File content correct"
