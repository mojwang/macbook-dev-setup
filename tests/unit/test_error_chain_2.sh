#!/usr/bin/env bash
# Test error chain - failure case
source "$(dirname "$0")/../test_framework.sh"

describe "Error Chain Test 2"
it "should fail"
assert_false "true" "This test should fail"
exit 1