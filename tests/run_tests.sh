#!/bin/bash

# Test runner for development environment setup

# Get the directory of this script
TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"

# Source test framework
source "$TESTS_DIR/test_framework.sh"

echo -e "${BLUE}"
echo "🧪 Development Environment Test Suite"
echo "====================================="
echo -e "${NC}"

# Run all test files
for test_file in "$TESTS_DIR"/test_*.sh; do
    if [[ -f "$test_file" && "$test_file" != "$TESTS_DIR/test_framework.sh" ]]; then
        run_test_file "$test_file"
    fi
done

# Print summary
print_summary

# Exit with appropriate code
exit $?