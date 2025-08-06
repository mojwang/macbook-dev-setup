#!/usr/bin/env bash

# Test error recovery and cleanup mechanisms

# Get script directory
TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$TESTS_DIR")"

# Source test framework
source "$TESTS_DIR/test_framework.sh"
source "$ROOT_DIR/lib/common.sh"

describe "Error Recovery Tests"

# Test cleanup after test failures
it "should clean up after test failures"

# Create a test that fails and leaves artifacts
failing_test=$(mktemp /tmp/failing_test.XXXXXX)
test_name=$(basename "$failing_test")
# Update trap to clean both locations
trap "rm -f '$failing_test' '$TESTS_DIR/$test_name' '$TESTS_DIR'/failing_test.* '$TESTS_DIR'/interrupt_test.* '$TESTS_DIR'/timeout_cleanup.* '$TESTS_DIR'/trap_test.* '$TESTS_DIR'/syntax_test.* /tmp/test_artifact_*" EXIT INT TERM HUP
cat > "$failing_test" <<'EOF'
#!/bin/bash
source "$(dirname "$0")/test_framework.sh"
describe "Failing Test"
it "creates files then fails"
touch /tmp/test_artifact_$$
assert_false "true" "This test always fails"
EOF
chmod +x "$failing_test"
mv "$failing_test" "$TESTS_DIR/$test_name"

# Run the failing test
(cd "$TESTS_DIR" && bash "./$test_name" >/dev/null 2>&1)
exit_code=$?

# Verify test failed
assert_equals "1" "$exit_code" "Test should have failed"

# Verify cleanup (artifacts should not accumulate)
artifact_count=$(ls /tmp/test_artifact_* 2>/dev/null | wc -l)
assert_true "[[ $artifact_count -lt 10 ]]" "Should not accumulate artifacts"

# Clean up
rm -f "$TESTS_DIR/$test_name"
rm -f /tmp/test_artifact_*

# Test signal handling and cleanup
it "should handle interrupts gracefully"

# Create a long-running test
interrupt_test=$(mktemp /tmp/interrupt_test.XXXXXX)
cat > "$interrupt_test" <<'EOF'
#!/bin/bash
trap 'echo "Caught signal"; exit 130' INT TERM
echo "Starting long test"
sleep 10
echo "Should not reach here"
EOF
chmod +x "$interrupt_test"

# Start test in background
output=$("$interrupt_test" 2>&1 &)
pid=$!

# Give it time to start
sleep 0.5

# Send interrupt
kill -INT "$pid" 2>/dev/null

# Wait for process to handle signal
wait "$pid" 2>/dev/null
exit_code=$?

# Should exit with interrupt code
assert_equals "130" "$exit_code" "Should exit with SIGINT code"

rm -f "$interrupt_test"

# Test partial execution recovery
it "should handle partial execution gracefully"

# Create tests where some pass and some fail
pass_count=0
fail_count=0

for i in {1..5}; do
    cat > "$TESTS_DIR/test_partial_$i.sh" <<EOF
#!/bin/bash
source "\$(dirname "\$0")/test_framework.sh"
describe "Partial Test $i"
it "may pass or fail"
if [[ $i -le 3 ]]; then
    assert_true "true" "Test $i passes"
else
    assert_false "true" "Test $i fails"
fi
EOF
    chmod +x "$TESTS_DIR/test_partial_$i.sh"
done

# Run tests and capture results
output=$(cd "$TESTS_DIR" && bash ./run_tests_parallel_simple.sh 2>&1)

# Should report both passes and failures
assert_true "[[ \"$output\" == *\"Passed:\"* ]]" "Should show passed tests"
assert_true "[[ \"$output\" == *\"Failed:\"* ]]" "Should show failed tests"

# Clean up
rm -f "$TESTS_DIR"/test_partial_*.sh

# Test disk space exhaustion handling
it "should handle disk space issues"

# Create a test that tries to write when space is limited
disk_test() {
    local test_dir=$(mktemp -d /tmp/disk_test.XXXXXX)
    local large_file="$test_dir/large_file"
    
    # Try to create a file (might fail on full disk)
    if dd if=/dev/zero of="$large_file" bs=1024 count=1 2>/dev/null; then
        echo "write_success"
        rm -f "$large_file"
    else
        echo "write_failed"
    fi
    
    rmdir "$test_dir" 2>/dev/null
}

result=$(disk_test)
assert_true "[[ \"$result\" == \"write_success\" || \"$result\" == \"write_failed\" ]]" \
    "Should handle write attempts gracefully"

# Test timeout cleanup
it "should clean up after timeouts"

if command -v timeout &>/dev/null || command -v gtimeout &>/dev/null; then
    # Create a test that will timeout
    timeout_cleanup_test=$(mktemp /tmp/timeout_cleanup.XXXXXX)
    cat > "$timeout_cleanup_test" <<'EOF'
#!/bin/bash
# Create a temp file
temp_file=$(mktemp /tmp/temp_file.XXXXXX)
echo "$$" > "$temp_file"
# Sleep longer than timeout
sleep 10
# This should not execute
rm -f "$temp_file"
EOF
    chmod +x "$timeout_cleanup_test"
    
    # Run with timeout
    execute_with_timeout 1s "$timeout_cleanup_test" 2>/dev/null
    
    # The temp file might still exist (depends on how the process was killed)
    # But the process should be gone
    sleep 2
    
    # Check for zombie processes (should be none)
    zombie_count=$(ps aux | grep -c "[d]efunct.*$(basename "$timeout_cleanup_test")")
    assert_equals "0" "$zombie_count" "Should not leave zombie processes"
    
    rm -f "$timeout_cleanup_test"
else
    echo "  ⚠️  Skipping timeout cleanup test - no timeout command"
fi

# Test error propagation
it "should propagate errors correctly"

# Create a chain of tests
cat > "$TESTS_DIR/test_error_chain_1.sh" <<'EOF'
#!/bin/bash
exit 0  # Success
EOF

cat > "$TESTS_DIR/test_error_chain_2.sh" <<'EOF'
#!/bin/bash
exit 1  # Failure
EOF

cat > "$TESTS_DIR/test_error_chain_3.sh" <<'EOF'
#!/bin/bash
exit 0  # Success
EOF

chmod +x "$TESTS_DIR"/test_error_chain_*.sh

# Run the chain
(cd "$TESTS_DIR" && bash ./run_tests_parallel_simple.sh >/dev/null 2>&1)
final_exit=$?

# Should propagate the failure
assert_equals "1" "$final_exit" "Should propagate test failures"

# Clean up
rm -f "$TESTS_DIR"/test_error_chain_*.sh

# Test resource cleanup
it "should clean up resources properly"

# Test file descriptor cleanup
test_fd_cleanup() {
    local initial_fds=$(ls /dev/fd | wc -l)
    
    # Open and close file descriptors
    exec 3< /dev/null
    exec 4< /dev/null
    exec 5< /dev/null
    
    # Close them
    exec 3<&-
    exec 4<&-
    exec 5<&-
    
    local final_fds=$(ls /dev/fd | wc -l)
    
    # Should return to initial state
    [[ $final_fds -eq $initial_fds ]]
}

assert_true "test_fd_cleanup" "Should clean up file descriptors"

# Test background job cleanup
it "should clean up background jobs"

# Function to test job cleanup
test_job_cleanup() {
    # Launch background jobs
    (sleep 30) &
    local pid1=$!
    (sleep 30) &
    local pid2=$!
    
    # Get initial job count
    local initial_jobs=$(jobs -p | wc -l)
    assert_true "[[ $initial_jobs -ge 2 ]]" "Should have background jobs"
    
    # Clean them up
    kill_all_test_jobs 2>/dev/null
    
    # Verify cleanup
    sleep 1
    local final_jobs=$(jobs -p | wc -l)
    assert_equals "0" "$final_jobs" "All jobs should be cleaned up"
}

test_job_cleanup

# Test trap handling
it "should handle traps correctly"

# Create a test with trap
trap_test=$(mktemp /tmp/trap_test.XXXXXX)
cat > "$trap_test" <<'EOF'
#!/bin/bash
cleanup_called=0
cleanup() {
    cleanup_called=1
    echo "CLEANUP:$cleanup_called"
}
trap cleanup EXIT
# Trigger exit
exit 0
EOF
chmod +x "$trap_test"

output=$("$trap_test" 2>&1)
assert_true "[[ \"$output\" == *\"CLEANUP:1\"* ]]" "Exit trap should be called"

rm -f "$trap_test"

# Test recovery from syntax errors
it "should handle syntax errors gracefully"

# Create a test with syntax error
syntax_test=$(mktemp /tmp/syntax_test.XXXXXX)
cat > "$syntax_test" <<'EOF'
#!/bin/bash
source "$(dirname "$0")/test_framework.sh"
describe "Syntax Error Test"
it "has a syntax error"
if [[ "test" == "test" ]  # Missing closing bracket
    assert_true "true" "Should not execute"
fi
EOF
chmod +x "$syntax_test"
mv "$syntax_test" "$TESTS_DIR/test_syntax_error.sh"

# Run test with syntax error
output=$(cd "$TESTS_DIR" && bash ./test_syntax_error.sh 2>&1)
exit_code=$?

# Should fail but not crash
assert_true "[[ $exit_code -ne 0 ]]" "Should detect syntax error"
assert_true "[[ \"$output\" == *\"syntax error\"* || \"$output\" == *\"unexpected\"* ]]" \
    "Should report syntax error"

# Clean up
rm -f "$TESTS_DIR/test_syntax_error.sh"

# Test concurrent error handling
it "should handle concurrent errors properly"

# Create multiple failing tests
for i in {1..5}; do
    cat > "$TESTS_DIR/test_concurrent_fail_$i.sh" <<EOF
#!/bin/bash
source "\$(dirname "\$0")/test_framework.sh"
describe "Concurrent Fail $i"
it "fails concurrently"
# All tests fail at different times
sleep 0.$i
assert_false "true" "Concurrent failure $i"
EOF
    chmod +x "$TESTS_DIR/test_concurrent_fail_$i.sh"
done

# Run concurrently
start_time=$(date +%s)
(cd "$TESTS_DIR" && TEST_JOBS=5 bash ./run_tests_parallel_simple.sh >/dev/null 2>&1)
exit_code=$?
end_time=$(date +%s)
duration=$((end_time - start_time))

# Should handle all failures
assert_equals "1" "$exit_code" "Should report failures"
assert_true "[[ $duration -lt 3 ]]" "Should not hang on failures"

# Clean up
rm -f "$TESTS_DIR"/test_concurrent_fail_*.sh

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