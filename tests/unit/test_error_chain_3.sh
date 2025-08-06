#!/usr/bin/env bash
# Test error chain - mixed case
source "$(dirname "$0")/../test_framework.sh"

describe "Error Chain Test 3"
it "should have mixed results"
assert_true "true" "First assertion passes"
assert_false "false" "Second assertion passes"
assert_equals "foo" "bar" "Third assertion fails"
exit 0