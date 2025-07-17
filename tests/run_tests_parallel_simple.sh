#!/bin/bash

# Simple parallel test runner that works with bash 3.2
# Executes tests in parallel for improved performance

# Get the directory of this script
TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"

# Configuration
MAX_JOBS="${TEST_JOBS:-$(sysctl -n hw.ncpu 2>/dev/null || echo 4)}"

# Limit jobs in CI to prevent resource exhaustion
if [[ -n "${CI:-}" ]] || [[ -n "${GITHUB_ACTIONS:-}" ]]; then
    if (( MAX_JOBS > 3 )); then
        MAX_JOBS=3
    fi
fi

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Create temporary directory for test outputs
TEST_OUTPUT_DIR=$(mktemp -d)
trap "rm -rf $TEST_OUTPUT_DIR" EXIT

echo -e "${BLUE}"
echo "🧪 Development Environment Test Suite (Parallel Mode)"
echo "===================================================="
echo -e "${NC}"
echo -e "${CYAN}Running with $MAX_JOBS parallel jobs${NC}"
echo

TOTAL_START_TIME=$(date +%s)

# Function to run a single test file
run_single_test() {
    local test_file="$1"
    local test_name=$(basename "$test_file" .sh)
    local output_file="$TEST_OUTPUT_DIR/$test_name.out"
    local result_file="$TEST_OUTPUT_DIR/$test_name.result"
    
    # Run test in isolated subshell
    (
        # Unset COMMON_LIB_LOADED to ensure clean environment
        unset COMMON_LIB_LOADED
        
        # Source framework and run test
        source "$TESTS_DIR/test_framework.sh"
        source "$test_file"
        
        # Save results
        echo "$TEST_COUNT:$PASSED_COUNT:$FAILED_COUNT" > "$result_file"
    ) > "$output_file" 2>&1
    
    local exit_code=$?
    
    # Read results
    if [[ -f "$result_file" ]]; then
        local results=$(cat "$result_file")
        IFS=':' read -r total passed failed <<< "$results"
    else
        total=0
        passed=0
        failed=1
    fi
    
    # Print brief status
    if [[ $failed -eq 0 && $total -gt 0 ]]; then
        echo -e "${GREEN}✓${NC} $test_name - ${passed}/${total} tests passed"
    else
        echo -e "${RED}✗${NC} $test_name - ${failed}/${total} tests failed"
        # Show output for failed tests
        echo -e "${YELLOW}Output from $test_name:${NC}"
        cat "$output_file"
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
    while true; do
        local current_jobs=$(jobs -r 2>/dev/null | wc -l | tr -d ' ')
        # Handle case where jobs command fails
        if [[ -z "$current_jobs" ]]; then
            current_jobs=0
        fi
        if (( current_jobs < MAX_JOBS )); then
            break
        fi
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

# Read all results
for result_file in "$TEST_OUTPUT_DIR"/*.result; do
    if [[ -f "$result_file" ]]; then
        results=$(cat "$result_file")
        IFS=':' read -r total passed failed <<< "$results"
        TOTAL_TESTS=$((TOTAL_TESTS + total))
        TOTAL_PASSED=$((TOTAL_PASSED + passed))
        TOTAL_FAILED=$((TOTAL_FAILED + failed))
    fi
done

# Calculate total execution time
TOTAL_END_TIME=$(date +%s)
TOTAL_DURATION=$((TOTAL_END_TIME - TOTAL_START_TIME))

# Print summary
echo -e "\n${BLUE}Test Summary${NC}"
echo "============"
echo "Total tests: $TOTAL_TESTS"
echo "Passed: ${GREEN}$TOTAL_PASSED${NC}"
echo "Failed: ${RED}$TOTAL_FAILED${NC}"
echo -e "Total execution time: ${CYAN}${TOTAL_DURATION}s${NC}"

# Show speedup vs sequential (estimated at ~38s)
SEQUENTIAL_TIME_ESTIMATE=38
if [[ $TOTAL_DURATION -gt 0 ]]; then
    SPEEDUP=$((SEQUENTIAL_TIME_ESTIMATE / TOTAL_DURATION))
    echo -e "Sequential time estimate: ${SEQUENTIAL_TIME_ESTIMATE}s"
    echo -e "Speedup: ${GREEN}~${SPEEDUP}x${NC}"
fi

if [[ $TOTAL_FAILED -eq 0 ]]; then
    echo -e "\n${GREEN}All tests passed! 🎉${NC}"
    exit 0
else
    echo -e "\n${RED}Some tests failed 😞${NC}"
    exit 1
fi