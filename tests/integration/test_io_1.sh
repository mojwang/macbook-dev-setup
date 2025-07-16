#!/bin/bash
source "$(dirname "$0")/test_framework.sh"
describe "I/O Test 1"
it "performs file operations"
# Write test data
echo "test data 1" > "/test_1.txt"
assert_file_exists "/test_1.txt" "File created"
# Read test data
content=$(cat "/test_1.txt")
assert_equals "test data 1" "$content" "File content correct"
