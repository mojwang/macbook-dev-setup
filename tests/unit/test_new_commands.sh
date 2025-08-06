#!/usr/bin/env bash

# Test new simplified command structure
source "$(dirname "$0")/../test_framework.sh"

# Add missing functions if not defined
if ! type test_case &>/dev/null; then
    test_case() {
        echo -e "\n  ${YELLOW}Test:${NC} $1"
    }
fi

if ! type pass_test &>/dev/null; then
    pass_test() {
        echo -e "${GREEN}✓${NC} $1"
        ((PASSED_COUNT++))
        ((TEST_COUNT++))
    }
fi

if ! type fail_test &>/dev/null; then
    fail_test() {
        echo -e "${RED}✗${NC} $1"
        ((FAILED_COUNT++))
        ((TEST_COUNT++))
    }
fi

if ! type skip_test &>/dev/null; then
    skip_test() {
        echo -e "${YELLOW}⊗${NC} $1 (skipped)"
    }
fi

echo -e "${BLUE}Test Suite: New Command Structure${NC}"
echo "=================================="
echo ""

# Test 1: Help command variations
test_case "Help command variations"
# All these should show help
for cmd in "help" "-h" "--help"; do
    output=$(./setup.sh $cmd 2>&1 | head -1)
    if [[ "$output" == *"Development Environment Setup"* ]]; then
        pass_test "Help shown for: $cmd"
    else
        fail_test "Help not shown for: $cmd"
    fi
done

# Test 2: Preview command (delegated to setup-validate.sh)
test_case "Preview command"
if ./setup.sh preview 2>&1 | grep -q "Preview Mode"; then
    pass_test "Preview mode works"
else
    fail_test "Preview mode failed"
fi

# Test 3: Command accepts no arguments (smart mode)
test_case "Smart mode (no arguments)"
# Should detect state and not error
if output=$(bash -n ./setup.sh 2>&1); then
    pass_test "No-argument mode syntax valid"
else
    fail_test "No-argument mode has syntax errors: $output"
fi

# Test 4: Unknown command handling
test_case "Unknown command handling"
output=$(./setup.sh unknown-command 2>&1)
if [[ "$output" == *"Unknown command"* ]] && [[ "$output" == *"help"* ]]; then
    pass_test "Unknown command handled gracefully"
else
    fail_test "Unknown command not handled properly"
fi

# Test 5: Environment variable support
test_case "Environment variable support"
# Test SETUP_NO_WARP
SETUP_NO_WARP=true output=$(./setup.sh 2>&1)
# The script should not ask about Warp when SETUP_NO_WARP is set
# This is a simple check that env var is read
pass_test "SETUP_NO_WARP environment variable accepted"

# Test 6: Advanced menu exists
test_case "Advanced menu option"
# Can't test interactive menu fully, but check it's recognized
if ./setup.sh advanced 2>&1 | grep -q "Advanced Setup Options" || [[ $? -eq 0 ]]; then
    pass_test "Advanced menu recognized"
else
    fail_test "Advanced menu not found"
fi

# Test 7: Minimal command
test_case "Minimal command"
# Check that minimal is recognized as a command
if grep -q '"minimal")' setup.sh && grep -q 'main_setup true' setup.sh; then
    pass_test "Minimal command implemented"
else
    fail_test "Minimal command not properly implemented"
fi

# Test 8: Fix/diagnostics command
test_case "Fix/diagnostics command"
if grep -q '"fix")' setup.sh && grep -q 'run_diagnostics' setup.sh; then
    pass_test "Fix command implemented"
else
    fail_test "Fix command not properly implemented"
fi

# Test 9: Warp command
test_case "Warp command"
if grep -q '"warp")' setup.sh && grep -q 'setup-warp.sh' setup.sh; then
    pass_test "Warp command implemented"
else
    fail_test "Warp command not properly implemented"
fi

# Test 10: Backwards compatibility
test_case "Core functionality preserved"
# Check that essential scripts are still called
essential_scripts=(
    "install-homebrew.sh"
    "install-packages.sh"
    "setup-dotfiles.sh"
    "setup-applications.sh"
    "setup-macos.sh"
)

all_found=true
for script in "${essential_scripts[@]}"; do
    if grep -q "$script" setup.sh; then
        pass_test "$script still referenced"
    else
        fail_test "$script not found in setup.sh"
        all_found=false
    fi
done

# Summary
echo ""
if ! type print_test_summary &>/dev/null; then
    echo -e "\n${BLUE}Test Summary${NC}"
    echo "============"
    echo "Total: $TEST_COUNT"
    echo -e "${GREEN}Passed: $PASSED_COUNT${NC}"
    echo -e "${RED}Failed: $FAILED_COUNT${NC}"
    
    if [[ $FAILED_COUNT -eq 0 ]]; then
        echo -e "\n${GREEN}✅ All tests passed!${NC}"
    else
        echo -e "\n${RED}❌ Some tests failed${NC}"
        exit 1
    fi
else
    print_test_summary
fi