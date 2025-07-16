#!/bin/bash

# Test input validation across the codebase

# Get script directory
TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$TESTS_DIR")"

# Source test framework
source "$TESTS_DIR/test_framework.sh"
source "$ROOT_DIR/lib/common.sh"

describe "Input Validation Tests"

# Test TEST_JOBS validation
it "should validate TEST_JOBS environment variable"

# Test valid numeric values
assert_equals "1" "$(validate_test_jobs 1)" "Should accept 1"
assert_equals "4" "$(validate_test_jobs 4)" "Should accept 4"
assert_equals "8" "$(validate_test_jobs 8)" "Should accept 8"
assert_equals "16" "$(validate_test_jobs 16)" "Should accept 16"
assert_equals "32" "$(validate_test_jobs 32)" "Should accept 32"

# Test boundary values
cpu_count=$(sysctl -n hw.ncpu 2>/dev/null || echo 4)
assert_equals "$cpu_count" "$(validate_test_jobs 0 2>&1 | tail -1)" "Should reject 0"
assert_equals "$cpu_count" "$(validate_test_jobs 33 2>&1 | tail -1)" "Should reject >32"
assert_equals "$cpu_count" "$(validate_test_jobs -1 2>&1 | tail -1)" "Should reject negative"
assert_equals "$cpu_count" "$(validate_test_jobs -999 2>&1 | tail -1)" "Should reject large negative"

# Test non-numeric inputs
assert_equals "$cpu_count" "$(validate_test_jobs "abc" 2>&1 | tail -1)" "Should reject alphabetic"
assert_equals "$cpu_count" "$(validate_test_jobs "12.5" 2>&1 | tail -1)" "Should reject decimal"
assert_equals "$cpu_count" "$(validate_test_jobs "10x" 2>&1 | tail -1)" "Should reject mixed"
assert_equals "$cpu_count" "$(validate_test_jobs " " 2>&1 | tail -1)" "Should reject whitespace"
assert_equals "$cpu_count" "$(validate_test_jobs "\$PATH" 2>&1 | tail -1)" "Should reject variables"

# Test empty and null inputs
assert_equals "$cpu_count" "$(validate_test_jobs "" 2>&1)" "Should handle empty string"
assert_equals "$cpu_count" "$(validate_test_jobs 2>&1)" "Should handle no argument"

# Test command injection attempts
it "should prevent command injection in TEST_JOBS"

# Try various injection attempts
result=$(validate_test_jobs "4; echo hacked" 2>&1)
assert_false "[[ \"$result\" == *\"hacked\"* ]]" "Should not execute injected command"

result=$(validate_test_jobs "4 && echo hacked" 2>&1)
assert_false "[[ \"$result\" == *\"hacked\"* ]]" "Should not execute && command"

result=$(validate_test_jobs "\$(echo 4)" 2>&1)
assert_equals "$cpu_count" "$(echo "$result" | tail -1)" "Should not evaluate command substitution"

result=$(validate_test_jobs "\`echo 4\`" 2>&1)
assert_equals "$cpu_count" "$(echo "$result" | tail -1)" "Should not evaluate backticks"

# Test environment variable validation in parallel runners
it "should validate other environment variables"

# Test SUITE_TIMEOUT validation
test_suite_timeout() {
    local timeout="${SUITE_TIMEOUT:-300}"
    if [[ "$timeout" =~ ^[0-9]+$ ]] && (( timeout > 0 && timeout <= 3600 )); then
        echo "valid"
    else
        echo "invalid"
    fi
}

SUITE_TIMEOUT=300 assert_equals "valid" "$(test_suite_timeout)" "Valid timeout 300"
SUITE_TIMEOUT=3600 assert_equals "valid" "$(test_suite_timeout)" "Valid timeout 3600"
SUITE_TIMEOUT=0 assert_equals "invalid" "$(test_suite_timeout)" "Invalid timeout 0"
SUITE_TIMEOUT=3601 assert_equals "invalid" "$(test_suite_timeout)" "Invalid timeout >3600"
SUITE_TIMEOUT="abc" assert_equals "invalid" "$(test_suite_timeout)" "Invalid non-numeric"

# Test SEQUENTIAL_TIME_ESTIMATE validation
test_time_estimate() {
    local estimate="${SEQUENTIAL_TIME_ESTIMATE:-38}"
    if [[ "$estimate" =~ ^[0-9]+$ ]] && (( estimate > 0 )); then
        echo "$estimate"
    else
        echo "38"  # Default
    fi
}

SEQUENTIAL_TIME_ESTIMATE=50 assert_equals "50" "$(test_time_estimate)" "Valid estimate"
SEQUENTIAL_TIME_ESTIMATE=0 assert_equals "38" "$(test_time_estimate)" "Invalid 0 uses default"
SEQUENTIAL_TIME_ESTIMATE="bad" assert_equals "38" "$(test_time_estimate)" "Invalid string uses default"

# Test path validation
it "should validate file paths safely"

# Test paths with special characters
test_path_validation() {
    local path="$1"
    # Simple validation: no command substitution or dangerous chars
    if [[ "$path" =~ [\$\`\;] ]]; then
        echo "invalid"
    else
        echo "valid"
    fi
}

assert_equals "valid" "$(test_path_validation "/normal/path")" "Normal path"
assert_equals "valid" "$(test_path_validation "/path with spaces")" "Path with spaces"
assert_equals "invalid" "$(test_path_validation "/path;\$command")" "Path with command"
assert_equals "invalid" "$(test_path_validation "/path\`cmd\`")" "Path with backticks"
assert_equals "invalid" "$(test_path_validation "/\$(whoami)/path")" "Path with substitution"

# Test timeout duration validation
it "should validate timeout durations"

test_timeout_validation() {
    local duration="$1"
    # Validate format: number followed by optional s/m/h
    if [[ "$duration" =~ ^[0-9]+[smh]?$ ]]; then
        echo "valid"
    else
        echo "invalid"
    fi
}

assert_equals "valid" "$(test_timeout_validation "5s")" "Valid seconds"
assert_equals "valid" "$(test_timeout_validation "10m")" "Valid minutes"
assert_equals "valid" "$(test_timeout_validation "1h")" "Valid hours"
assert_equals "valid" "$(test_timeout_validation "30")" "Valid no unit"
assert_equals "invalid" "$(test_timeout_validation "5.5s")" "Invalid decimal"
assert_equals "invalid" "$(test_timeout_validation "abc")" "Invalid non-numeric"
assert_equals "invalid" "$(test_timeout_validation "-5s")" "Invalid negative"

# Test malformed input handling
it "should handle malformed inputs gracefully"

# Test with very long inputs
long_input=$(printf 'a%.0s' {1..1000})
result=$(validate_test_jobs "$long_input" 2>&1 | tail -1)
assert_equals "$cpu_count" "$result" "Should handle very long input"

# Test with special characters
special_chars='!@#$%^&*()_+-={}[]|\\:";'\''<>?,./'
result=$(validate_test_jobs "$special_chars" 2>&1 | tail -1)
assert_equals "$cpu_count" "$result" "Should handle special characters"

# Test with newlines and tabs
multiline="4\necho hacked"
result=$(validate_test_jobs "$multiline" 2>&1 | tail -1)
assert_equals "$cpu_count" "$result" "Should handle newlines"

# Test error recovery
it "should recover from validation errors"

# Create a test that triggers multiple validation errors
error_count=0
for invalid in "abc" "-1" "999" "1.5" "; echo" ""; do
    result=$(validate_test_jobs "$invalid" 2>&1)
    if [[ "$result" == *"Invalid TEST_JOBS"* ]] || [[ "$(echo "$result" | tail -1)" == "$cpu_count" ]]; then
        ((error_count++))
    fi
done
assert_equals "6" "$error_count" "Should handle all 6 invalid inputs"

# Test validation in actual usage
it "should work correctly in parallel runners"

# Create a simple test file
test_file=$(mktemp /tmp/test_validation.XXXXXX)
trap "rm -f '$test_file'" EXIT
cat > "$test_file" <<'EOF'
#!/bin/bash
source "$(dirname "$0")/test_framework.sh"
describe "Validation Test"
it "passes"
assert_true "true" "Always passes"
EOF
chmod +x "$test_file"
mv "$test_file" "$TESTS_DIR/test_validation_demo.sh"

# Run with various TEST_JOBS values
for jobs in "abc" "0" "-1" "999"; do
    output=$(cd "$TESTS_DIR" && TEST_JOBS="$jobs" bash ./run_tests_parallel_simple.sh 2>&1)
    assert_true "[[ \"$output\" == *\"Invalid TEST_JOBS\"* || \"$output\" == *\"$cpu_count parallel jobs\"* ]]" \
        "Should handle TEST_JOBS=$jobs gracefully"
done

# Clean up
rm -f "$TESTS_DIR/test_validation_demo.sh"

# Summary
echo -e "\n${BLUE}Test Summary${NC}"
echo "============"
echo "Total tests: $TEST_COUNT"
echo "Passed: $PASSED_COUNT"
echo "Failed: $FAILED_COUNT"

if [[ $FAILED_COUNT -eq 0 ]]; then
    exit 0
else
    exit 1
fi