#!/usr/bin/env bash

# Test parallel test runner edge cases and functionality

# Get script directory
TESTS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ROOT_DIR="$(dirname "$TESTS_DIR")"

# Source test framework
source "$TESTS_DIR/test_framework.sh"

# Source common functions to get validate_test_jobs
if [[ -f "$ROOT_DIR/lib/common.sh" ]]; then
    source "$ROOT_DIR/lib/common.sh"
fi

describe "Parallel Test Runner Edge Cases"

# Test validate_test_jobs function
it "should validate TEST_JOBS input correctly"

# Test with valid values
assert_equals "4" "$(validate_test_jobs 4)" "Valid job count 4"
assert_equals "1" "$(validate_test_jobs 1)" "Valid job count 1"
assert_equals "32" "$(validate_test_jobs 32)" "Valid job count 32"

# Test with invalid values
cpu_count=$(sysctl -n hw.ncpu 2>/dev/null || echo 4)
result=$(validate_test_jobs 0 2>&1)
assert_equals "$cpu_count" "$(echo "$result" | tail -1)" "Zero jobs should use CPU count"
assert_true "[[ \"$result\" == *\"Invalid TEST_JOBS\"* ]]" "Should warn about invalid value"

result=$(validate_test_jobs -1 2>&1)
assert_equals "$cpu_count" "$(echo "$result" | tail -1)" "Negative jobs should use CPU count"

result=$(validate_test_jobs 33 2>&1)
assert_equals "$cpu_count" "$(echo "$result" | tail -1)" "Too many jobs should use CPU count"

result=$(validate_test_jobs "abc" 2>&1)
assert_equals "$cpu_count" "$(echo "$result" | tail -1)" "Non-numeric should use CPU count"

result=$(validate_test_jobs "" 2>&1)
assert_equals "$cpu_count" "$result" "Empty string should use CPU count"

# Test wait_for_job_slot function
it "should handle job slot waiting efficiently"

# Create a test that launches background jobs
test_job_control() {
    local max_jobs=2
    local job_count=0
    
    # Launch several test jobs
    for i in {1..5}; do
        wait_for_job_slot $max_jobs
        (sleep 0.1) &
        ((job_count++))
    done
    
    # All jobs should complete
    wait
    echo "$job_count"
}

result=$(test_job_control)
assert_equals "5" "$result" "Should launch all 5 jobs with max_jobs=2"

# Test suite timeout checking
it "should detect suite timeout correctly"

# Test with a past start time
past_time=$(($(date +%s) - 400))  # 400 seconds ago
if ! check_suite_timeout "$past_time" 300 2>/dev/null; then
    assert_equals "124" "$?" "Should return timeout exit code"
else
    assert_true "false" "Should have detected timeout"
fi

# Test with current time
current_time=$(date +%s)
check_suite_timeout "$current_time" 300
assert_equals "0" "$?" "Should not timeout with current time"

# Test kill_all_test_jobs function
it "should cleanly terminate background jobs"

# Launch some test jobs
(sleep 10) &
pid1=$!
(sleep 10) &
pid2=$!
(sleep 10) &
pid3=$!

# Verify jobs are running
assert_true "kill -0 $pid1 2>/dev/null" "Job 1 should be running"
assert_true "kill -0 $pid2 2>/dev/null" "Job 2 should be running"
assert_true "kill -0 $pid3 2>/dev/null" "Job 3 should be running"

# Kill all jobs
kill_all_test_jobs 2>/dev/null

# Give more time for cleanup (kill_all_test_jobs has internal sleeps)
sleep 3

# Verify jobs are terminated
assert_false "kill -0 $pid1 2>/dev/null" "Job 1 should be terminated"
assert_false "kill -0 $pid2 2>/dev/null" "Job 2 should be terminated"
assert_false "kill -0 $pid3 2>/dev/null" "Job 3 should be terminated"

# Test parallel runner with extreme job counts
it "should handle edge case job counts"

# Create a simple test script
test_script=$(mktemp /tmp/test_script.XXXXXX)
trap "rm -f '$test_script' '$timeout_test'" EXIT
cat > "$test_script" <<'EOF'
#!/bin/bash
echo "Test running"
exit 0
EOF
chmod +x "$test_script"

# Test with TEST_JOBS=0 (should use CPU count)
# Get CPU count for CI environment (should be 3 due to CI limit)
expected_jobs=3
output=$(TEST_JOBS=0 CI=true bash "$TESTS_DIR/run_tests_parallel_simple.sh" 2>&1)
# Should show invalid warning and then use CPU count
assert_true "[[ \"$output\" == *\"Invalid TEST_JOBS value: 0\"* ]]" "TEST_JOBS=0 should show invalid warning"
assert_true "[[ \"$output\" == *\"$expected_jobs parallel jobs\"* ]]" "TEST_JOBS=0 should use CPU count"

# Test with TEST_JOBS=1 (sequential behavior)
output=$(TEST_JOBS=1 bash "$TESTS_DIR/run_tests_parallel_simple.sh" 2>&1 | grep "Running with")
assert_true "[[ \"$output\" == *\"1 parallel jobs\"* ]]" "TEST_JOBS=1 should run sequentially"

# Clean up
rm -f "$test_script"

# Test timeout handling in parallel runners
it "should handle timeouts gracefully"

# Create a test that will timeout
timeout_test=$(mktemp /tmp/test_timeout.XXXXXX)
cat > "$timeout_test" <<'EOF'
#!/bin/bash
source "$(dirname "$0")/test_framework.sh"
describe "Timeout Test"
it "should timeout"
sleep 10  # Will timeout with TEST_TIMEOUT=1
assert_true "true" "Should not reach here"
EOF
chmod +x "$timeout_test"
mv "$timeout_test" "$TESTS_DIR/test_timeout_demo.sh"

# Run with short timeout
output=$(cd "$TESTS_DIR" && TEST_TIMEOUT=1 bash ./run_tests_parallel.sh 2>&1)
assert_true "[[ \"$output\" == *\"timed out\"* || \"$output\" == *\"timeout\"* ]]" "Should show timeout message"

# Clean up
rm -f "$TESTS_DIR/test_timeout_demo.sh"

# Test resource exhaustion handling
it "should handle resource constraints gracefully"

# Create many small test files
for i in {1..20}; do
    cat > "$TESTS_DIR/test_resource_$i.sh" <<EOF
#!/bin/bash
source "\$(dirname "\$0")/test_framework.sh"
describe "Resource Test $i"
it "should complete quickly"
assert_true "true" "Quick test $i"
EOF
    chmod +x "$TESTS_DIR/test_resource_$i.sh"
done

# Run with limited jobs
start_time=$(date +%s)
TEST_JOBS=2 bash "$TESTS_DIR/run_tests_parallel_simple.sh" >/dev/null 2>&1
end_time=$(date +%s)
duration=$((end_time - start_time))

# Should complete reasonably fast even with limited jobs
assert_true "[[ $duration -lt 30 ]]" "Should complete 20 tests in under 30s with 2 jobs"

# Clean up
rm -f "$TESTS_DIR"/test_resource_*.sh

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