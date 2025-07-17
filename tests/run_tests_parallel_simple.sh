#!/bin/bash

# Simple parallel test runner that works with bash 3.2
# Executes tests in parallel for improved performance

# Get the directory of this script
TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"

# Configuration
# Get CPU count first
CPU_COUNT=$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 4)

# Validate TEST_JOBS if provided
if [[ -n "${TEST_JOBS:-}" ]]; then
    # Check if it's a valid positive number
    if [[ "$TEST_JOBS" =~ ^[0-9]+$ ]] && (( TEST_JOBS > 0 && TEST_JOBS <= 32 )); then
        MAX_JOBS="$TEST_JOBS"
    else
        echo "Invalid TEST_JOBS value: $TEST_JOBS. Using CPU count." >&2
        MAX_JOBS="$CPU_COUNT"
    fi
else
    MAX_JOBS="$CPU_COUNT"
fi

# Limit jobs in CI to prevent resource exhaustion
if [[ -n "${CI:-}" ]] || [[ -n "${GITHUB_ACTIONS:-}" ]]; then
    # Further reduce parallelism in CI to prevent fork exhaustion
    if (( MAX_JOBS > 2 )); then
        MAX_JOBS=2
    fi
fi

# Check process limits and adjust if needed
if command -v ulimit >/dev/null 2>&1; then
    PROC_LIMIT=$(ulimit -u 2>/dev/null || echo "unlimited")
    if [[ "$PROC_LIMIT" != "unlimited" ]] && [[ "$PROC_LIMIT" =~ ^[0-9]+$ ]]; then
        # Reserve processes for system and test operations
        AVAILABLE_PROCS=$((PROC_LIMIT - 50))
        if (( AVAILABLE_PROCS < MAX_JOBS * 10 )); then
            NEW_MAX=$((AVAILABLE_PROCS / 10))
            if (( NEW_MAX < MAX_JOBS && NEW_MAX > 0 )); then
                echo -e "${YELLOW}Reducing parallel jobs from $MAX_JOBS to $NEW_MAX due to process limits${NC}"
                MAX_JOBS=$NEW_MAX
            fi
        fi
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
    
    # Run test in isolated subshell with proper process group
    (
        # Set process group to ensure all children can be cleaned up
        set -m
        
        # Set up timeout and cleanup
        test_timeout=30
        test_start=$(date +%s)
        
        # Unset COMMON_LIB_LOADED to ensure clean environment
        unset COMMON_LIB_LOADED
        
        # Source framework and run test with timeout check
        if source "$TESTS_DIR/test_framework.sh" 2>/dev/null; then
            # Run with timeout
            timeout "$test_timeout" bash -c "source '$test_file'" || {
                echo "Test timed out after ${test_timeout}s"
                exit 124
            }
        else
            echo "Failed to source test framework"
            exit 1
        fi
        
        # Save results
        echo "${TEST_COUNT:-0}:${PASSED_COUNT:-0}:${FAILED_COUNT:-1}" > "$result_file"
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

# Track all child PIDs for cleanup
CHILD_PIDS=()

# Cleanup function to kill all child processes
cleanup_children() {
    local pids=("${CHILD_PIDS[@]}")
    if [[ ${#pids[@]} -gt 0 ]]; then
        echo -e "\n${YELLOW}Cleaning up ${#pids[@]} child processes...${NC}"
        for pid in "${pids[@]}"; do
            if kill -0 "$pid" 2>/dev/null; then
                kill -TERM "$pid" 2>/dev/null || true
            fi
        done
        # Give processes time to terminate gracefully
        sleep 1
        # Force kill any remaining
        for pid in "${pids[@]}"; do
            if kill -0 "$pid" 2>/dev/null; then
                kill -KILL "$pid" 2>/dev/null || true
            fi
        done
    fi
}

# Set up cleanup on exit
trap cleanup_children EXIT INT TERM

# Run tests in parallel with job control
job_count=0
for test_file in "${test_files[@]}"; do
    # Wait if we've reached max jobs  
    while true; do
        # Count only our direct children, not all jobs
        current_jobs=0
        for pid in "${CHILD_PIDS[@]}"; do
            if kill -0 "$pid" 2>/dev/null; then
                ((current_jobs++))
            fi
        done
        
        if (( current_jobs < MAX_JOBS )); then
            break
        fi
        sleep 0.2
    done
    
    # Add small delay in CI to prevent fork storms
    if [[ -n "${CI:-}" ]]; then
        sleep 0.05
    fi
    
    # Launch test in background
    run_single_test "$test_file" &
    local test_pid=$!
    CHILD_PIDS+=("$test_pid")
    ((job_count++))
done

# Wait for all tests to complete with timeout
echo -e "\n${CYAN}Waiting for ${job_count} test files to complete...${NC}"

# Maximum wait time (5 minutes)
MAX_WAIT_TIME=300
start_wait=$(date +%s)

while true; do
    active_count=0
    for pid in "${CHILD_PIDS[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
            ((active_count++))
        fi
    done
    
    if [[ $active_count -eq 0 ]]; then
        break
    fi
    
    # Check timeout
    current_time=$(date +%s)
    elapsed=$((current_time - start_wait))
    if [[ $elapsed -gt $MAX_WAIT_TIME ]]; then
        echo -e "\n${RED}Timeout waiting for tests to complete!${NC}"
        cleanup_children
        exit 124
    fi
    
    sleep 1
done

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