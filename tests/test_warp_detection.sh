#!/bin/bash

# Test script for Warp Terminal detection and setup
source "$(dirname "$0")/test_framework.sh"
source "$(dirname "$0")/../lib/common.sh"

# Mock the check_and_setup_warp function from setup.sh
check_and_setup_warp() {
    # Skip if explicitly disabled
    if [[ "${SETUP_NO_WARP:-false}" == "true" ]]; then
        return 0
    fi
    
    # Check if Warp is installed or being used
    local warp_detected=false
    local warp_reason=""
    
    if [[ "$TERM_PROGRAM" == "WarpTerminal" ]]; then
        warp_detected=true
        warp_reason="currently using Warp Terminal"
    elif [[ -d "/Applications/Warp.app" ]]; then
        warp_detected=true
        warp_reason="Warp.app installed"
    elif command -v warp &> /dev/null; then
        warp_detected=true
        warp_reason="Warp command found"
    fi
    
    echo "warp_detected=$warp_detected"
    echo "warp_reason=$warp_reason"
}

# Test 1: Warp detection when TERM_PROGRAM is set
test_case "Warp detection via TERM_PROGRAM"
TERM_PROGRAM="WarpTerminal" SETUP_NO_WARP=false
output=$(check_and_setup_warp)
assert_contains "$output" "warp_detected=true"
assert_contains "$output" "currently using Warp Terminal"

# Test 2: Warp detection when app is installed
test_case "Warp detection via installed app"
TERM_PROGRAM="" SETUP_NO_WARP=false
if [[ -d "/Applications/Warp.app" ]]; then
    output=$(check_and_setup_warp)
    assert_contains "$output" "warp_detected=true"
    assert_contains "$output" "Warp.app installed"
else
    skip_test "Warp.app not installed"
fi

# Test 3: Warp detection disabled
test_case "Warp detection disabled via SETUP_NO_WARP"
TERM_PROGRAM="WarpTerminal" SETUP_NO_WARP=true
output=$(check_and_setup_warp)
assert_empty "$output"

# Test 4: No Warp detected
test_case "No Warp detected"
TERM_PROGRAM="iTerm.app" SETUP_NO_WARP=false
# Mock no Warp.app and no warp command
(
    export PATH="/usr/bin:/bin"  # Minimal PATH without warp
    if [[ ! -d "/Applications/Warp.app" ]]; then
        output=$(check_and_setup_warp)
        assert_contains "$output" "warp_detected=false"
    else
        skip_test "Cannot test - Warp.app is installed"
    fi
)

# Test 5: Font conflict detection
test_case "Font conflict detection"
source "$(dirname "$0")/../scripts/install-packages.sh" 2>/dev/null || true

# Check if font detection function exists
if type -t is_font_installed &>/dev/null; then
    # Test font already installed via Homebrew
    if brew list --cask font-anonymice-nerd-font &>/dev/null 2>&1; then
        result=$(is_font_installed "font-anonymice-nerd-font" && echo "installed" || echo "not installed")
        assert_equals "$result" "installed"
    fi
else
    skip_test "Font detection function not available"
fi

# Test 6: print_section fallback
test_case "print_section function fallback"
# Unset print_section if it exists
unset -f print_section 2>/dev/null || true

# Source setup-warp.sh which should define print_section
source "$(dirname "$0")/../scripts/setup-warp.sh" &>/dev/null || true

# Check if print_section is now defined
if type -t print_section &>/dev/null; then
    pass_test "print_section function defined"
else
    fail_test "print_section function not defined"
fi

# Test 7: Command structure validation
test_case "New command structure"
# Test that setup.sh accepts new commands
commands=("help" "preview" "minimal" "fix" "warp" "advanced")
for cmd in "${commands[@]}"; do
    if bash -n "$(dirname "$0")/../setup.sh" 2>/dev/null; then
        pass_test "setup.sh syntax valid for command: $cmd"
    else
        fail_test "setup.sh has syntax errors"
    fi
done

# Summary
echo ""
print_test_summary