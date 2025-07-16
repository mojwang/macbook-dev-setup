#!/bin/bash
source "$(dirname "$0")/test_framework.sh"
describe "Concurrent Fail 4"
it "fails concurrently"
# All tests fail at different times
sleep 0.4
assert_false "true" "Concurrent failure 4"
