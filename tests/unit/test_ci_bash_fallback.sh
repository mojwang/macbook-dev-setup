#!/usr/bin/env bash

# Test CI environment bash fallback behavior

# Minimal test framework for standalone running
TESTS_PASSED=0
TESTS_FAILED=0

run_test() {
    local test_name="$1"
    echo ""
    echo "Running: $test_name"
    if $test_name; then
        ((TESTS_PASSED++))
        echo "✓ $test_name passed"
    else
        ((TESTS_FAILED++))
        echo "✗ $test_name failed"
    fi
}

test_ci_environment_detection() {
    echo "Testing CI environment detection..."
    
    # Test 1: CI=true should trigger fallback mode
    local output=$(CI=true /bin/bash -c 'source ./lib/common.sh 2>&1' || true)
    if echo "$output" | grep -q "Running with bash .* in CI environment"; then
        echo "✓ CI=true detected correctly"
    else
        echo "✗ CI=true not detected"
        return 1
    fi
    
    # Test 2: GITHUB_ACTIONS=true should trigger fallback mode
    output=$(GITHUB_ACTIONS=true /bin/bash -c 'source ./lib/common.sh 2>&1' || true)
    if echo "$output" | grep -q "Running with bash .* in CI environment"; then
        echo "✓ GITHUB_ACTIONS=true detected correctly"
    else
        echo "✗ GITHUB_ACTIONS=true not detected"
        return 1
    fi
    
    # Test 3: Both CI and GITHUB_ACTIONS should work
    output=$(CI=true GITHUB_ACTIONS=true /bin/bash -c 'source ./lib/common.sh 2>&1' || true)
    if echo "$output" | grep -q "Running with bash .* in CI environment"; then
        echo "✓ Both CI and GITHUB_ACTIONS detected correctly"
    else
        echo "✗ Both flags not detected"
        return 1
    fi
    
    # Test 4: Check specific disabled features message
    if echo "$output" | grep -q "Disabled features: MCP server management, associative arrays, indirect expansion"; then
        echo "✓ Disabled features message is correct"
    else
        echo "✗ Disabled features message is missing or incorrect"
        return 1
    fi
    
    # Test 5: Check available features message
    if echo "$output" | grep -q "Available features: Basic setup preview, simple commands, file operations"; then
        echo "✓ Available features message is correct"
    else
        echo "✗ Available features message is missing or incorrect"
        return 1
    fi
}

test_ci_minimal_functions() {
    echo "Testing CI minimal functions..."
    
    # Create a test script that uses CI functions
    local test_script=$(mktemp)
    cat > "$test_script" << 'EOF'
#!/bin/bash
export CI=true
source ./lib/common.sh

# Test the minimal functions exist and work
ci_print_info "Test info message"
ci_print_success "Test success message"
ci_print_warning "Test warning message"
ci_print_step "Test step message"
ci_print_error "Test error message"
EOF
    
    # Run with system bash and check output
    local output=$(/bin/bash "$test_script" 2>&1)
    rm -f "$test_script"
    
    # Check each function output
    if echo "$output" | grep -q "ℹ Test info message"; then
        echo "✓ ci_print_info works"
    else
        echo "✗ ci_print_info failed"
        return 1
    fi
    
    if echo "$output" | grep -q "✓ Test success message"; then
        echo "✓ ci_print_success works"
    else
        echo "✗ ci_print_success failed"
        return 1
    fi
    
    if echo "$output" | grep -q "⚠ Test warning message"; then
        echo "✓ ci_print_warning works"
    else
        echo "✗ ci_print_warning failed"
        return 1
    fi
    
    if echo "$output" | grep -q "→ Test step message"; then
        echo "✓ ci_print_step works"
    else
        echo "✗ ci_print_step failed"
        return 1
    fi
    
    if echo "$output" | grep -q "✗ Test error message"; then
        echo "✓ ci_print_error works"
    else
        echo "✗ ci_print_error failed"
        return 1
    fi
}

test_ci_logging_support() {
    echo "Testing CI logging support..."
    
    local log_file=$(mktemp)
    local test_script=$(mktemp)
    
    cat > "$test_script" << EOF
#!/bin/bash
export CI=true
export LOG_FILE="$log_file"
export SCRIPT_NAME="test_ci"
source ./lib/common.sh

ci_print_info "Test log message"
EOF
    
    # Run the script
    /bin/bash "$test_script" >/dev/null 2>&1
    
    # Check if log file contains the message
    if [[ -f "$log_file" ]] && grep -q "INFO: Test log message" "$log_file"; then
        echo "✓ Logging works in CI mode"
    else
        echo "✗ Logging failed in CI mode"
        cat "$log_file" 2>/dev/null || echo "Log file not created"
        rm -f "$test_script" "$log_file"
        return 1
    fi
    
    # Check log format
    if grep -q "\[test_ci\] INFO: Test log message" "$log_file"; then
        echo "✓ Log format is correct"
    else
        echo "✗ Log format is incorrect"
        rm -f "$test_script" "$log_file"
        return 1
    fi
    
    rm -f "$test_script" "$log_file"
}

test_non_ci_behavior() {
    echo "Testing non-CI behavior..."
    
    # Without CI flags, system bash should fail
    local output=$(/bin/bash -c 'source ./lib/common.sh 2>&1' || true)
    
    if echo "$output" | grep -q "Error: This script requires bash 4.0 or higher"; then
        echo "✓ Non-CI mode correctly requires bash 4+"
    else
        echo "✗ Non-CI mode didn't enforce bash version"
        return 1
    fi
}

test_bash_version_logging() {
    echo "Testing bash version logging..."
    
    local log_file=$(mktemp)
    local test_script=$(mktemp)
    
    cat > "$test_script" << EOF
#!/bin/bash
export CI=true
export LOG_FILE="$log_file"
source ./lib/common.sh
EOF
    
    # Run the script
    /bin/bash "$test_script" >/dev/null 2>&1
    
    # Check if bash version was logged
    if [[ -f "$log_file" ]] && grep -q "CI Mode: bash .* detected" "$log_file"; then
        echo "✓ Bash version logged for debugging"
    else
        echo "✗ Bash version not logged"
        rm -f "$test_script" "$log_file"
        return 1
    fi
    
    rm -f "$test_script" "$log_file"
}

# Run all tests
run_test test_ci_environment_detection
run_test test_ci_minimal_functions
run_test test_ci_logging_support
run_test test_non_ci_behavior
run_test test_bash_version_logging

# Summary
echo ""
echo "CI Bash Fallback Test Summary:"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"

[[ $TESTS_FAILED -eq 0 ]]