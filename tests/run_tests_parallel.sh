#!/usr/bin/env bash

# Parallel test runner for development environment setup
# Executes tests in parallel for improved performance

# Get the directory of this script
TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"

# Configuration
MAX_JOBS="${TEST_JOBS:-$(sysctl -n hw.ncpu 2>/dev/null || echo 4)}"
TEST_TIMEOUT="${TEST_TIMEOUT:-60}" # Timeout per test file in seconds
TIMING_ENABLED="${TEST_TIMING:-true}"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Results tracking
declare -A test_results
declare -A test_times
declare -A test_outputs
TOTAL_START_TIME=$(date +%s.%N 2>/dev/null || date +%s)

# Create temporary directory for test outputs
TEST_OUTPUT_DIR=$(mktemp -d)
trap "rm -rf $TEST_OUTPUT_DIR" EXIT

echo -e "${BLUE}"
echo "🧪 Development Environment Test Suite (Parallel Mode)"
echo "===================================================="
echo -e "${NC}"
echo -e "${CYAN}Running with $MAX_JOBS parallel jobs${NC}"
echo

# Function to run a single test file
run_single_test() {
    local test_file="$1"
    local test_name=$(basename "$test_file" .sh)
    local output_file="$TEST_OUTPUT_DIR/$test_name.out"
    local start_time=$(date +%s.%N 2>/dev/null || date +%s)
    
    # Run test in isolated subshell with timeout
    if command -v gtimeout &>/dev/null; then
        timeout_cmd="gtimeout"
    elif command -v timeout &>/dev/null; then
        timeout_cmd="timeout"
    else
        timeout_cmd=""
    fi
    
    # Execute test
    (
        # Reset test counters for this test file
        export TEST_COUNT=0
        export PASSED_COUNT=0
        export FAILED_COUNT=0
        
        # Unset COMMON_LIB_LOADED to ensure clean environment
        unset COMMON_LIB_LOADED
        
        # Source framework and run test
        source "$TESTS_DIR/test_framework.sh"
        source "$test_file"
        
        # Output test results at the very end
        echo ""
        echo "TEST_RESULTS:$TEST_COUNT:$PASSED_COUNT:$FAILED_COUNT"
    ) > "$output_file" 2>&1 &
    
    local pid=$!
    
    # Apply timeout if available
    if [[ -n "$timeout_cmd" ]]; then
        $timeout_cmd $TEST_TIMEOUT bash -c "wait $pid" 2>/dev/null
    else
        wait $pid
    fi
    
    local exit_code=$?
    local end_time=$(date +%s.%N 2>/dev/null || date +%s)
    
    # Calculate execution time
    if command -v bc &>/dev/null; then
        local duration=$(echo "scale=2; $end_time - $start_time" | bc)
    else
        local duration=$((end_time - start_time))
    fi
    
    # Extract test results from output
    local results_line=$(grep "^TEST_RESULTS:" "$output_file" 2>/dev/null | tail -1)
    if [[ -n "$results_line" ]]; then
        IFS=':' read -r _ total passed failed <<< "$results_line"
        # Remove the results line from output
        grep -v "^TEST_RESULTS:" "$output_file" > "$output_file.tmp" && mv "$output_file.tmp" "$output_file"
    else
        total=0
        passed=0
        failed=0
        if [[ $exit_code -eq 124 ]]; then
            echo -e "${RED}✗ Test timed out after ${TEST_TIMEOUT}s${NC}" >> "$output_file"
            failed=1
            total=1
        elif [[ $exit_code -ne 0 ]]; then
            echo -e "${RED}✗ Test exited with code $exit_code${NC}" >> "$output_file"
            failed=1
            total=1
        fi
    fi
    
    # Store results
    test_results[$test_name]="$total:$passed:$failed"
    test_times[$test_name]="$duration"
    test_outputs[$test_name]="$output_file"
    
    # Print brief status
    if [[ $failed -eq 0 && $total -gt 0 ]]; then
        echo -e "${GREEN}✓${NC} $test_name (${duration}s) - ${passed}/${total} tests passed"
    else
        echo -e "${RED}✗${NC} $test_name (${duration}s) - ${failed}/${total} tests failed"
    fi
}

# Collect all test files (including those in subdirectories)
test_files=()
for test_file in "$TESTS_DIR"/{unit,integration,performance,stress,ci}/test_*.sh "$TESTS_DIR"/test_*.sh; do
    if [[ -f "$test_file" && "$test_file" != "$TESTS_DIR/test_framework.sh" ]]; then
        test_files+=("$test_file")
    fi
done

# Run tests in parallel with job control
job_count=0
for test_file in "${test_files[@]}"; do
    # Wait if we've reached max jobs
    while (( $(jobs -r | wc -l) >= MAX_JOBS )); do
        sleep 0.1
    done
    
    # Launch test in background
    run_single_test "$test_file" &
    ((job_count++))
done

# Wait for all tests to complete
echo -e "\n${CYAN}Waiting for ${job_count} test files to complete...${NC}"
wait

# Calculate totals
TOTAL_TESTS=0
TOTAL_PASSED=0
TOTAL_FAILED=0

echo -e "\n${BLUE}Detailed Test Results${NC}"
echo "===================="

# Sort tests by name for consistent output
sorted_tests=($(printf '%s\n' "${!test_results[@]}" | sort))

for test_name in "${sorted_tests[@]}"; do
    IFS=':' read -r total passed failed <<< "${test_results[$test_name]}"
    TOTAL_TESTS=$((TOTAL_TESTS + total))
    TOTAL_PASSED=$((TOTAL_PASSED + passed))
    TOTAL_FAILED=$((TOTAL_FAILED + failed))
    
    # Show test output if there were failures or if verbose
    if [[ $failed -gt 0 || "${VERBOSE:-false}" == "true" ]]; then
        echo -e "\n${YELLOW}Output from $test_name:${NC}"
        cat "${test_outputs[$test_name]}"
    fi
done

# Calculate total execution time
TOTAL_END_TIME=$(date +%s.%N 2>/dev/null || date +%s)
if command -v bc &>/dev/null; then
    TOTAL_DURATION=$(echo "scale=2; $TOTAL_END_TIME - $TOTAL_START_TIME" | bc)
else
    TOTAL_DURATION=$((TOTAL_END_TIME - TOTAL_START_TIME))
fi

# Print timing summary if enabled
if [[ "$TIMING_ENABLED" == "true" ]]; then
    echo -e "\n${BLUE}Test Execution Times${NC}"
    echo "==================="
    
    # Sort by execution time (slowest first)
    for test_name in $(for t in "${!test_times[@]}"; do
        echo "${test_times[$t]}:$t"
    done | sort -rn | cut -d: -f2); do
        printf "%-40s %6.2fs\n" "$test_name" "${test_times[$test_name]}"
    done
fi

# Print summary
echo -e "\n${BLUE}Test Summary${NC}"
echo "============"
echo "Total tests: $TOTAL_TESTS"
echo "Passed: ${GREEN}$TOTAL_PASSED${NC}"
echo "Failed: ${RED}$TOTAL_FAILED${NC}"
echo -e "Total execution time: ${CYAN}${TOTAL_DURATION}s${NC}"

# Compare with sequential time estimate
if [[ "$TIMING_ENABLED" == "true" ]]; then
    sequential_time=0
    for time in "${test_times[@]}"; do
        if command -v bc &>/dev/null; then
            sequential_time=$(echo "scale=2; $sequential_time + $time" | bc)
        else
            sequential_time=$((sequential_time + time))
        fi
    done
    
    if command -v bc &>/dev/null && (( $(echo "$sequential_time > 0" | bc -l) )); then
        speedup=$(echo "scale=2; $sequential_time / $TOTAL_DURATION" | bc)
        echo -e "Sequential time estimate: ${sequential_time}s"
        echo -e "Speedup: ${GREEN}${speedup}x${NC}"
    fi
fi

if [[ $TOTAL_FAILED -eq 0 ]]; then
    echo -e "\n${GREEN}All tests passed! 🎉${NC}"
    exit 0
else
    echo -e "\n${RED}Some tests failed 😞${NC}"
    exit 1
fi