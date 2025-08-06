#!/usr/bin/env bash
source "$(dirname "$0")/../test_framework.sh"
describe "Resource Test 20"
it "should complete quickly"
assert_true "true" "Quick test 20"
