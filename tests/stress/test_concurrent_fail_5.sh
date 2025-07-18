#!/bin/bash
source "$(dirname "$0")/../test_framework.sh"
describe "Concurrent Fail 5"
it "fails concurrently"
# All tests fail at different times
sleep 0.5
assert_false "true" "Concurrent failure 5"
