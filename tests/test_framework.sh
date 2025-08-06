#!/usr/bin/env bash

# Test framework for development environment setup scripts
# Provides basic unit testing capabilities for shell scripts

# Test framework configuration
TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
# Only set ROOT_DIR if not already set
if [[ -z "${ROOT_DIR:-}" ]]; then
    ROOT_DIR="$(dirname "$TESTS_DIR")"
fi

# Validate critical paths exist
if [[ ! -d "$TESTS_DIR" ]]; then
    echo "Error: TESTS_DIR does not exist: $TESTS_DIR" >&2
    exit 1
fi

if [[ ! -d "$ROOT_DIR" ]]; then
    echo "Error: ROOT_DIR does not exist: $ROOT_DIR" >&2
    exit 1
fi
TEST_RESULTS=()
TEST_COUNT=0
PASSED_COUNT=0
FAILED_COUNT=0

# Colors - only set if not already defined
if [[ -z "${GREEN:-}" ]]; then
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
fi

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

# Additional test utilities
assert_empty() {
    local value="$1"
    local message="${2:-Value should be empty}"
    
    ((TEST_COUNT++))
    
    if [[ -z "$value" ]]; then
        echo -e "${GREEN}✓${NC} $message"
        ((PASSED_COUNT++))
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        echo "  Value was not empty: $value"
        ((FAILED_COUNT++))
        return 1
    fi
}

assert_not_empty() {
    local value="$1"
    local message="${2:-Value should not be empty}"
    
    ((TEST_COUNT++))
    
    if [[ -n "$value" ]]; then
        echo -e "${GREEN}✓${NC} $message"
        ((PASSED_COUNT++))
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        echo "  Value was empty"
        ((FAILED_COUNT++))
        return 1
    fi
}

assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-String should not contain substring}"
    
    ((TEST_COUNT++))
    
    if [[ "$haystack" != *"$needle"* ]]; then
        echo -e "${GREEN}✓${NC} $message"
        ((PASSED_COUNT++))
        return 0
    else
        echo -e "${RED}✗${NC} $message"
        echo "  String: $haystack"
        echo "  Should not contain: $needle"
        ((FAILED_COUNT++))
        return 1
    fi
}

test_case() {
    local test_name="$1"
    echo -e "\n  ${YELLOW}Test:${NC} $test_name"
}

skip_test() {
    local reason="$1"
    echo -e "${YELLOW}⊘ Skipped: $reason${NC}"
}

pass_test() {
    local message="$1"
    echo -e "${GREEN}✓${NC} $message"
    ((PASSED_COUNT++))
    ((TEST_COUNT++))
}

fail_test() {
    local message="$1"
    echo -e "${RED}✗${NC} $message"
    ((FAILED_COUNT++))
    ((TEST_COUNT++))
}

print_test_summary() {
    print_summary
}

# Alias for print_summary for compatibility
summarize() {
    print_summary
}

# BDD-style test functions
given() {
    echo "  Given: $*"
}

when() {
    echo "   When: $*"
}

expect() {
    local condition="$1"
    local message="${2:-Then assertion}"
    echo "   Then: $message"
    assert_true "$condition" "$message"
}

and() {
    local condition="$1"
    local message="${2:-And assertion}"
    echo "    And: $message"
    assert_true "$condition" "$message"
}

# SDD-style specification functions
specify() {
    local name="$1"
    echo -e "\n${BLUE}Specification: $name${NC}"
    echo "=================================="
}

invariant() {
    local condition="$1"
    local message="${2:-Invariant}"
    echo "  Invariant: $message"
    assert_true "$condition" "Invariant: $message"
}

precondition() {
    local condition="$1"
    local message="${2:-Precondition}"
    echo "  Precondition: $message"
    if ! eval "$condition"; then
        skip_test "Precondition not met: $message"
        return 1
    fi
    return 0
}

postcondition() {
    local condition="$1"
    local message="${2:-Postcondition}"
    echo "  Postcondition: $message"
    assert_true "$condition" "Postcondition: $message"
}
# Export functions for use in test files
export -f assert_equals
export -f assert_true
export -f assert_false
export -f assert_contains
export -f assert_not_contains
export -f assert_file_exists
export -f assert_directory_exists
export -f assert_command_exists
export -f assert_empty
export -f assert_not_empty
export -f describe
export -f it
export -f test_case
export -f skip_test
export -f pass_test
export -f fail_test
export -f mock_command
export -f cleanup_mocks
export -f print_test_summary
export -f summarize
export -f given
export -f when
export -f expect
export -f and
export -f specify
export -f invariant
export -f precondition
export -f postcondition
