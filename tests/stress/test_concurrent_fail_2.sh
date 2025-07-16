#!/bin/bash
source "$(dirname "$0")/test_framework.sh"
describe "Concurrent Fail 2"
it "fails concurrently"
# All tests fail at different times
sleep 0.2
assert_false "true" "Concurrent failure 2"
