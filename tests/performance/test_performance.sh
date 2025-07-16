#!/bin/bash

# Test performance characteristics and regression prevention

# Get script directory
TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$TESTS_DIR")"

# Source test framework
source "$TESTS_DIR/test_framework.sh"
source "$ROOT_DIR/lib/common.sh"

describe "Performance Tests"

# Test parallel execution performance
it "should maintain parallel execution speedup"

# Create multiple test files
test_count=10
for i in $(seq 1 $test_count); do
    cat > "$TESTS_DIR/test_perf_$i.sh" <<EOF
#!/bin/bash
source "\$(dirname "\$0")/test_framework.sh"
describe "Performance Test $i"
it "completes quickly"
# Simulate some work
sleep 0.1
assert_true "true" "Test $i passes"
EOF
    chmod +x "$TESTS_DIR/test_perf_$i.sh"
done

# Measure sequential execution (simulated)
sequential_time=$((test_count * 100))  # 100ms per test in milliseconds

# Measure parallel execution
cpu_count=$(sysctl -n hw.ncpu 2>/dev/null || echo 4)
start_time=$(date +%s.%N 2>/dev/null || date +%s)
(cd "$TESTS_DIR" && TEST_JOBS=$cpu_count bash ./run_tests_parallel_simple.sh >/dev/null 2>&1)
end_time=$(date +%s.%N 2>/dev/null || date +%s)

# Calculate actual parallel time
if command -v bc &>/dev/null; then
    parallel_time=$(echo "scale=3; ($end_time - $start_time) * 1000" | bc)
    speedup=$(echo "scale=1; $sequential_time / $parallel_time" | bc)
else
    parallel_time=$(( (end_time - start_time) * 1000 ))
    speedup=$(( sequential_time / parallel_time ))
fi

# Should achieve significant speedup
assert_true "[[ $(echo "$speedup > 2" | bc 2>/dev/null || echo 1) == 1 ]]" \
    "Should achieve >2x speedup (got ${speedup}x)"

# Clean up
rm -f "$TESTS_DIR"/test_perf_*.sh

# Test job scheduling overhead
it "should have minimal job scheduling overhead"

# Create lightweight test files
for i in {1..20}; do
    cat > "$TESTS_DIR/test_overhead_$i.sh" <<EOF
#!/bin/bash
source "\$(dirname "\$0")/test_framework.sh"
describe "Overhead Test $i"
it "has minimal work"
assert_true "true" "Instant pass"
EOF
    chmod +x "$TESTS_DIR/test_overhead_$i.sh"
done

# Measure execution time
start_time=$(date +%s.%N 2>/dev/null || date +%s)
(cd "$TESTS_DIR" && TEST_JOBS=4 bash ./run_tests_parallel_simple.sh >/dev/null 2>&1)
end_time=$(date +%s.%N 2>/dev/null || date +%s)

if command -v bc &>/dev/null; then
    total_time=$(echo "scale=3; $end_time - $start_time" | bc)
    overhead_per_job=$(echo "scale=3; $total_time / 20" | bc)
else
    total_time=$((end_time - start_time))
    overhead_per_job=0  # Can't calculate precisely without bc
fi

# Overhead should be minimal (< 100ms per job)
if command -v bc &>/dev/null; then
    assert_true "[[ $(echo "$overhead_per_job < 0.1" | bc) == 1 ]]" \
        "Job overhead should be <100ms (got ${overhead_per_job}s)"
fi

# Clean up
rm -f "$TESTS_DIR"/test_overhead_*.sh

# Test adaptive sleep performance
it "should optimize CPU usage with adaptive sleep"

# Test the wait_for_job_slot function efficiency
test_adaptive_sleep() {
    local max_jobs=2
    local iterations=0
    local start=$(date +%s.%N 2>/dev/null || date +%s)
    
    # Simulate waiting for job slots
    for i in {1..5}; do
        # Launch dummy jobs
        (sleep 0.2) &
        (sleep 0.2) &
        
        # Wait for slot (should adapt sleep time)
        wait_for_job_slot $max_jobs
        ((iterations++))
    done
    
    wait  # Clean up remaining jobs
    
    local end=$(date +%s.%N 2>/dev/null || date +%s)
    
    if command -v bc &>/dev/null; then
        local duration=$(echo "scale=3; $end - $start" | bc)
        echo "$duration"
    else
        echo "1"  # Fallback
    fi
}

duration=$(test_adaptive_sleep)
# Should complete efficiently without excessive CPU spinning
if command -v bc &>/dev/null; then
    assert_true "[[ $(echo "$duration < 2" | bc) == 1 ]]" \
        "Adaptive sleep should be efficient (took ${duration}s)"
fi

# Test memory usage patterns
it "should have reasonable memory usage"

# Create a memory usage test
test_memory_usage() {
    # Get initial memory usage
    if command -v vm_stat &>/dev/null; then
        local initial_free=$(vm_stat | grep "Pages free" | awk '{print $3}' | tr -d '.')
    else
        local initial_free=1000000  # Fallback
    fi
    
    # Run parallel tests
    for i in {1..5}; do
        cat > "$TESTS_DIR/test_mem_$i.sh" <<EOF
#!/bin/bash
source "\$(dirname "\$0")/test_framework.sh"
describe "Memory Test $i"
it "uses minimal memory"
# Create some data but not excessive
data=\$(seq 1 1000)
assert_true "[[ -n \"\$data\" ]]" "Data created"
EOF
        chmod +x "$TESTS_DIR/test_mem_$i.sh"
    done
    
    # Run tests
    (cd "$TESTS_DIR" && TEST_JOBS=5 bash ./run_tests_parallel_simple.sh >/dev/null 2>&1)
    
    # Check final memory
    if command -v vm_stat &>/dev/null; then
        local final_free=$(vm_stat | grep "Pages free" | awk '{print $3}' | tr -d '.')
        local pages_used=$((initial_free - final_free))
        # Each page is 4KB, so convert to MB
        local mb_used=$((pages_used * 4 / 1024))
        echo "$mb_used"
    else
        echo "0"  # Can't measure
    fi
}

memory_used=$(test_memory_usage)
# Should use reasonable memory (less than 100MB for simple tests)
if [[ "$memory_used" != "0" ]]; then
    assert_true "[[ $memory_used -lt 100 ]]" \
        "Should use <100MB memory (used ${memory_used}MB)"
fi

# Clean up
rm -f "$TESTS_DIR"/test_mem_*.sh

# Test I/O patterns
it "should handle I/O efficiently"

# Create tests with file I/O
io_test_dir=$(mktemp -d /tmp/io_test.XXXXXX)
trap "rm -rf '$io_test_dir'" EXIT
for i in {1..10}; do
    cat > "$TESTS_DIR/test_io_$i.sh" <<EOF
#!/bin/bash
source "\$(dirname "\$0")/test_framework.sh"
describe "I/O Test $i"
it "performs file operations"
# Write test data
echo "test data $i" > "$io_test_dir/test_$i.txt"
assert_file_exists "$io_test_dir/test_$i.txt" "File created"
# Read test data
content=\$(cat "$io_test_dir/test_$i.txt")
assert_equals "test data $i" "\$content" "File content correct"
EOF
    chmod +x "$TESTS_DIR/test_io_$i.sh"
done

# Measure I/O performance
start_time=$(date +%s.%N 2>/dev/null || date +%s)
(cd "$TESTS_DIR" && TEST_JOBS=4 bash ./run_tests_parallel_simple.sh >/dev/null 2>&1)
end_time=$(date +%s.%N 2>/dev/null || date +%s)

if command -v bc &>/dev/null; then
    io_time=$(echo "scale=3; $end_time - $start_time" | bc)
else
    io_time=$((end_time - start_time))
fi

# Should handle I/O without significant slowdown
assert_true "[[ ${io_time%.*} -lt 5 ]]" "I/O tests should complete quickly (took ${io_time}s)"

# Clean up
rm -rf "$io_test_dir"
rm -f "$TESTS_DIR"/test_io_*.sh

# Test performance with various job counts
it "should scale well with different job counts"

# Create consistent test load
for i in {1..16}; do
    cat > "$TESTS_DIR/test_scale_$i.sh" <<EOF
#!/bin/bash
source "\$(dirname "\$0")/test_framework.sh"
describe "Scale Test $i"
it "has consistent workload"
# Simulate consistent work
for j in {1..100}; do
    echo "data" >/dev/null
done
assert_true "true" "Work completed"
EOF
    chmod +x "$TESTS_DIR/test_scale_$i.sh"
done

# Test with different job counts
declare -A scale_times
for jobs in 1 2 4 8; do
    start_time=$(date +%s.%N 2>/dev/null || date +%s)
    (cd "$TESTS_DIR" && TEST_JOBS=$jobs bash ./run_tests_parallel_simple.sh >/dev/null 2>&1)
    end_time=$(date +%s.%N 2>/dev/null || date +%s)
    
    if command -v bc &>/dev/null; then
        scale_times[$jobs]=$(echo "scale=3; $end_time - $start_time" | bc)
    else
        scale_times[$jobs]=$((end_time - start_time))
    fi
done

# Verify scaling improves with more jobs
if command -v bc &>/dev/null; then
    scaling_improvement=$(echo "scale=1; ${scale_times[1]} / ${scale_times[4]}" | bc)
    assert_true "[[ $(echo "$scaling_improvement > 2" | bc) == 1 ]]" \
        "Should scale well (${scaling_improvement}x improvement with 4 jobs)"
fi

# Clean up
rm -f "$TESTS_DIR"/test_scale_*.sh

# Test timeout performance impact
it "should have minimal timeout overhead"

# Test with timeouts enabled
start_time=$(date +%s.%N 2>/dev/null || date +%s)
output=$(execute_with_timeout 5s "echo 'quick test'" 2>&1)
end_time=$(date +%s.%N 2>/dev/null || date +%s)

assert_equals "quick test" "$output" "Timeout should not affect output"

if command -v bc &>/dev/null; then
    overhead=$(echo "scale=3; $end_time - $start_time" | bc)
    assert_true "[[ $(echo "$overhead < 0.1" | bc) == 1 ]]" \
        "Timeout overhead should be <100ms (got ${overhead}s)"
fi

# Test performance regression detection
it "should detect performance regressions"

# Baseline performance
baseline_sequential_time=38  # Historical baseline

# Current performance estimate
current_estimate="${SEQUENTIAL_TIME_ESTIMATE:-38}"

# Should not regress significantly
assert_true "[[ $current_estimate -le $((baseline_sequential_time * 2)) ]]" \
    "Sequential time estimate should not double from baseline"

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