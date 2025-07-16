#!/bin/bash

# Test runner for development environment setup

# Get the directory of this script
TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"

# Source test framework
source "$TESTS_DIR/test_framework.sh"

# Enable timing
TIMING_ENABLED="${TEST_TIMING:-true}"
declare -A test_times
TOTAL_START_TIME=$(date +%s.%N 2>/dev/null || date +%s)

echo -e "${BLUE}"
echo "🧪 Development Environment Test Suite"
echo "====================================="
echo -e "${NC}"

# Run all test files (including those in subdirectories)
for test_file in "$TESTS_DIR"/{unit,integration,performance,stress,ci}/test_*.sh "$TESTS_DIR"/test_*.sh; do
    if [[ -f "$test_file" && "$test_file" != "$TESTS_DIR/test_framework.sh" ]]; then
        # Time each test file
        start_time=$(date +%s.%N 2>/dev/null || date +%s)
        run_test_file "$test_file"
        end_time=$(date +%s.%N 2>/dev/null || date +%s)
        
        # Calculate duration
        if command -v bc &>/dev/null; then
            duration=$(echo "scale=2; $end_time - $start_time" | bc)
        else
            duration=$((end_time - start_time))
        fi
        
        test_name=$(basename "$test_file" .sh)
        test_times[$test_name]="$duration"
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
if [[ "$TIMING_ENABLED" == "true" && ${#test_times[@]} -gt 0 ]]; then
    echo -e "\n${BLUE}Test Execution Times${NC}"
    echo "==================="
    
    # Sort by execution time (slowest first)
    for test_name in $(for t in "${!test_times[@]}"; do
        echo "${test_times[$t]}:$t"
    done | sort -rn | cut -d: -f2); do
        printf "%-40s %6.2fs\n" "$test_name" "${test_times[$test_name]}"
    done
    
    echo -e "\nTotal execution time: ${CYAN}${TOTAL_DURATION}s${NC}"
fi

# Print summary
print_summary

# Exit with appropriate code
exit $?