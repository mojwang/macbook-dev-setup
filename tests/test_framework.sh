#!/bin/bash

# Test framework for development environment setup scripts
# Provides basic unit testing capabilities for shell scripts

# Test framework configuration
TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$TESTS_DIR")"
TEST_RESULTS=()
TEST_COUNT=0
PASSED_COUNT=0
FAILED_COUNT=0

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test utilities
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Assertion failed}"
    
    ((TEST_COUNT++))
    
    if [[ "$expected" == "$actual" ]]; then
        echo -e "${GREEN}✓${NC} $message"
        ((PASSED_COUNT++))
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        echo "  Expected: $expected"
        echo "  Actual: $actual"
        ((FAILED_COUNT++))
        return 1
    fi
}

assert_true() {
    local condition="$1"
    local message="${2:-Assertion failed}"
    
    ((TEST_COUNT++))
    
    if eval "$condition"; then
        echo -e "${GREEN}✓${NC} $message"
        ((PASSED_COUNT++))
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        echo "  Condition failed: $condition"
        ((FAILED_COUNT++))
        return 1
    fi
}

assert_false() {
    local condition="$1"
    local message="${2:-Assertion failed}"
    
    ((TEST_COUNT++))
    
    if ! eval "$condition"; then
        echo -e "${GREEN}✓${NC} $message"
        ((PASSED_COUNT++))
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        echo "  Condition should have failed: $condition"
        ((FAILED_COUNT++))
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-String should contain substring}"
    
    ((TEST_COUNT++))
    
    if [[ "$haystack" == *"$needle"* ]]; then
        echo -e "${GREEN}✓${NC} $message"
        ((PASSED_COUNT++))
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        echo "  String: $haystack"
        echo "  Should contain: $needle"
        ((FAILED_COUNT++))
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local message="${2:-File should exist}"
    
    ((TEST_COUNT++))
    
    if [[ -f "$file" ]]; then
        echo -e "${GREEN}✓${NC} $message: $file"
        ((PASSED_COUNT++))
        return 0
    else
        echo -e "${RED}✗${NC} $message: $file"
        ((FAILED_COUNT++))
        return 1
    fi
}

assert_directory_exists() {
    local dir="$1"
    local message="${2:-Directory should exist}"
    
    ((TEST_COUNT++))
    
    if [[ -d "$dir" ]]; then
        echo -e "${GREEN}✓${NC} $message: $dir"
        ((PASSED_COUNT++))
        return 0
    else
        echo -e "${RED}✗${NC} $message: $dir"
        ((FAILED_COUNT++))
        return 1
    fi
}

assert_command_exists() {
    local cmd="$1"
    local message="${2:-Command should exist}"
    
    ((TEST_COUNT++))
    
    if command -v "$cmd" &>/dev/null; then
        echo -e "${GREEN}✓${NC} $message: $cmd"
        ((PASSED_COUNT++))
        return 0
    else
        echo -e "${RED}✗${NC} $message: $cmd"
        ((FAILED_COUNT++))
        return 1
    fi
}

# Test suite management
describe() {
    local suite_name="$1"
    echo -e "\n${BLUE}Test Suite: $suite_name${NC}"
    echo "=================================="
}

it() {
    local test_name="$1"
    echo -e "\n  ${YELLOW}Test:${NC} $test_name"
}

# Run a test file
run_test_file() {
    local test_file="$1"
    
    if [[ -f "$test_file" ]]; then
        echo -e "\n${BLUE}Running tests from: $test_file${NC}"
        source "$test_file"
    else
        echo -e "${RED}Test file not found: $test_file${NC}"
        ((FAILED_COUNT++))
    fi
}

# Mock functions for testing
mock_command() {
    local cmd_name="$1"
    local mock_output="$2"
    local mock_exit_code="${3:-0}"
    
    # Create a function that overrides the command
    eval "
    $cmd_name() {
        echo '$mock_output'
        return $mock_exit_code
    }
    "
}

# Cleanup mocks
cleanup_mocks() {
    # Unset any functions we've created
    unset -f "$@" 2>/dev/null || true
}

# Summary report
print_summary() {
    echo -e "\n${BLUE}Test Summary${NC}"
    echo "============"
    echo "Total tests: $TEST_COUNT"
    echo -e "Passed: ${GREEN}$PASSED_COUNT${NC}"
    echo -e "Failed: ${RED}$FAILED_COUNT${NC}"
    
    if [[ $FAILED_COUNT -eq 0 ]]; then
        echo -e "\n${GREEN}All tests passed! 🎉${NC}"
        return 0
    else
        echo -e "\n${RED}Some tests failed! ❌${NC}"
        return 1
    fi
}

# Export functions for use in test files
export -f assert_equals
export -f assert_true
export -f assert_false
export -f assert_contains
export -f assert_file_exists
export -f assert_directory_exists
export -f assert_command_exists
export -f describe
export -f it
export -f mock_command
export -f cleanup_mocks