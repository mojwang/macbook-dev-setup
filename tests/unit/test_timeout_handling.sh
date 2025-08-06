#!/usr/bin/env bash

# Test timeout handling mechanisms

# Get script directory
TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$TESTS_DIR")"

# Source test framework and common library
source "$TESTS_DIR/test_framework.sh"
source "$ROOT_DIR/lib/common.sh"

describe "Timeout Handling Mechanisms"

# Test execute_with_timeout function
it "should detect available timeout commands"

# Check which timeout command is available
timeout_available=false
if command -v gtimeout &>/dev/null; then
    timeout_available=true
    timeout_cmd="gtimeout"
elif command -v timeout &>/dev/null; then
    timeout_available=true
    timeout_cmd="timeout"
fi

if [[ "$timeout_available" == "true" ]]; then
    assert_true "command -v $timeout_cmd &>/dev/null" "Timeout command $timeout_cmd should be available"
else
    echo "  ⚠️  No timeout command available, some tests will be skipped"
fi

# Test successful command execution with timeout
it "should execute commands successfully within timeout"

output=$(execute_with_timeout 2s "echo 'success'" 2>&1)
assert_equals "success" "$output" "Should execute echo command successfully"

# Test command that completes before timeout
start_time=$(date +%s)
execute_with_timeout 2s "sleep 0.5"
end_time=$(date +%s)
duration=$((end_time - start_time))
assert_true "[[ $duration -lt 2 ]]" "Should complete before timeout"

# Test timeout behavior
it "should handle command timeouts properly"

if [[ "$timeout_available" == "true" ]]; then
    # Test command that exceeds timeout
    start_time=$(date +%s)
    execute_with_timeout 1s "sleep 3" 2>/dev/null
    exit_code=$?
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    
    assert_equals "124" "$exit_code" "Should return timeout exit code 124"
    assert_true "[[ $duration -ge 1 && $duration -lt 3 ]]" "Should timeout after ~1 second"
else
    echo "  ⚠️  Skipping timeout test - no timeout command available"
fi

# Test fallback behavior without timeout command
it "should handle missing timeout command gracefully"

# Temporarily hide timeout commands
test_without_timeout() {
    # Override command to simulate missing timeout commands
    command() {
        if [[ "$1" == "-v" && ("$2" == "gtimeout" || "$2" == "timeout") ]]; then
            return 1
        else
            builtin command "$@"
        fi
    }
    
    # Export the overridden function
    export -f command
    
    # Test execute_with_timeout without timeout command
    output=$(VERBOSE=true execute_with_timeout 1s "echo 'no timeout'" 2>&1)
    echo "$output"
}

output=$(test_without_timeout)
assert_true "[[ \"$output\" == *\"no timeout\"* ]]" "Should execute command without timeout"
assert_true "[[ \"$output\" == *\"No timeout command available\"* ]]" "Should warn about missing timeout"

# Test nested timeouts
it "should handle nested timeout calls"

if [[ "$timeout_available" == "true" ]]; then
    # Create a nested timeout scenario
    output=$(execute_with_timeout 3s "execute_with_timeout 1s 'echo nested'" 2>&1)
    assert_equals "nested" "$output" "Should handle nested timeouts"
    
    # Test nested timeout where inner times out
    execute_with_timeout 3s "execute_with_timeout 1s 'sleep 2'" 2>/dev/null
    exit_code=$?
    assert_equals "124" "$exit_code" "Inner timeout should trigger"
else
    echo "  ⚠️  Skipping nested timeout test - no timeout command available"
fi

# Test signal handling with timeouts
it "should handle signals properly during timeout"

if [[ "$timeout_available" == "true" ]]; then
    # Create a test script that traps signals
    test_script=$(mktemp /tmp/test_script.XXXXXX)
    trap "rm -f '$test_script'" EXIT
    cat > "$test_script" <<'EOF'
#!/bin/bash
trap 'echo "SIGTERM received"; exit 143' TERM
trap 'echo "SIGINT received"; exit 130' INT
sleep 10
EOF
    chmod +x "$test_script"
    
    # Test timeout signal handling
    output=$(execute_with_timeout 1s "$test_script" 2>&1)
    exit_code=$?
    
    # Timeout sends SIGTERM by default
    assert_equals "124" "$exit_code" "Should return timeout exit code"
    
    rm -f "$test_script"
else
    echo "  ⚠️  Skipping signal handling test - no timeout command available"
fi

# Test timeout with complex commands
it "should handle complex commands with timeout"

# Test with pipes
output=$(execute_with_timeout 2s "echo 'test' | grep 'test'" 2>&1)
assert_equals "test" "$output" "Should handle piped commands"

# Test with command substitution
output=$(execute_with_timeout 2s "echo \$(date +%Y)" 2>&1)
current_year=$(date +%Y)
assert_equals "$current_year" "$output" "Should handle command substitution"

# Test with redirections
temp_file=$(mktemp /tmp/temp_file.XXXXXX)
trap "rm -f '$temp_file'" EXIT
execute_with_timeout 2s "echo 'redirect test' > $temp_file"
content=$(cat "$temp_file")
assert_equals "redirect test" "$content" "Should handle redirections"
rm -f "$temp_file"

# Test timeout in CI environment
it "should work correctly in CI environment"

# Simulate CI environment
CI=true execute_with_timeout 1s "echo 'CI test'" &>/dev/null
assert_equals "0" "$?" "Should work in CI environment"

# Test timeout with brew commands (from setup-validate.sh)
it "should handle brew command timeouts"

if command -v brew &>/dev/null && [[ "$timeout_available" == "true" ]]; then
    # Test the actual code pattern from setup-validate.sh
    outdated=$(execute_with_timeout 5s 'HOMEBREW_NO_AUTO_UPDATE=1 brew outdated --quiet 2>/dev/null | wc -l' | xargs || echo "0")
    assert_true "[[ \"$outdated\" =~ ^[0-9]+$ ]]" "Should return numeric count or 0"
else
    echo "  ⚠️  Skipping brew timeout test - brew or timeout not available"
fi

# Test timeout with find commands (from setup-validate.sh)
it "should handle find command timeouts"

# Create test directory structure
test_dir=$(mktemp -d /tmp/test_dir.XXXXXX)
trap "rm -rf '$test_dir'" EXIT
mkdir -p "$test_dir/level1/level2/level3/level4/level5"
touch "$test_dir/level1/test.backup"
touch "$test_dir/level1/level2/test.bak"
touch "$test_dir/level1/level2/level3/test.backup"

# Test find with timeout (similar to setup-validate.sh)
result=$(execute_with_timeout 10s "find \"$test_dir\" -maxdepth 5 -name \"*.backup\" -o -name \"*.bak\" 2>/dev/null" | wc -l | xargs)
assert_equals "3" "$result" "Should find all backup files within timeout"

# Clean up
rm -rf "$test_dir"

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