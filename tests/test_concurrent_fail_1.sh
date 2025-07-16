#!/bin/bash
source "$(dirname "$0")/test_framework.sh"
describe "Concurrent Fail 1"
it "fails concurrently"
# All tests fail at different times
sleep 0.1
assert_false "true" "Concurrent failure 1"
