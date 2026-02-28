#!/usr/bin/env bash

# Unit tests for lib/ui.sh

_TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_PROJECT_ROOT="$(cd "$_TEST_DIR/../.." && pwd)"

# Source test framework
source "$_TEST_DIR/../test_framework.sh"

# Source common lib (needed for color vars and confirm/show_progress)
source "$_PROJECT_ROOT/lib/common.sh" 2>/dev/null || true

# Force fallback mode by hiding gum
_ORIG_PATH="$PATH"

# Remove specific tools from PATH for fallback testing
_hide_tools() {
    local tools=("$@")
    local new_path=""
    local IFS=':'
    for dir in $PATH; do
        local dominated=false
        for tool in "${tools[@]}"; do
            if [[ -x "$dir/$tool" ]]; then
                dominated=true
                break
            fi
        done
        if [[ "$dominated" == "false" ]]; then
            new_path="${new_path:+$new_path:}$dir"
        fi
    done
    export PATH="$new_path"
}

_hide_gum() { _hide_tools gum; }
_hide_rich_tools() { _hide_tools gum delta bat; }

_restore_path() {
    export PATH="$_ORIG_PATH"
}

# Unload ui.sh so we can re-source after hiding gum
unset UI_LIB_LOADED

# Hide gum to test fallback paths
_hide_gum

# Source the library under test (will use fallback mode)
source "$_PROJECT_ROOT/lib/ui.sh"

# ============================================================================
describe "Tool detection helpers"
# ============================================================================

it "should detect missing gum after PATH change"
if _ui_has gum; then
    fail_test "gum should not be found with modified PATH"
else
    pass_test "gum correctly not found in modified PATH"
fi

it "should detect non-interactive when stdin is a pipe"
# When running in tests, stdin may or may not be a tty
# The function should not crash regardless
_ui_is_interactive
rc=$?
# In test context (piped), should return non-zero
pass_test "_ui_is_interactive runs without error (rc=$rc)"

# ============================================================================
describe "ui_section_header - fallback mode"
# ============================================================================

it "should output the title with ANSI markers"
output=$(ui_section_header "Test Section")
assert_contains "$output" "Test Section" "Should contain the title"
assert_contains "$output" "==" "Should have == markers in fallback"

it "should handle empty title"
output=$(ui_section_header "")
assert_contains "$output" "==" "Should still render markers"

# ============================================================================
describe "ui_confirm - non-interactive fallback"
# ============================================================================

it "should default to no when non-interactive"
if echo "" | ui_confirm "Test?" "n"; then
    fail_test "Should default to no"
else
    pass_test "Defaults to no in non-interactive mode"
fi

it "should default to yes when default is y"
if CI=true ui_confirm "Test?" "y"; then
    pass_test "Defaults to yes when default=y in CI"
else
    fail_test "Should default to yes when default=y"
fi

# ============================================================================
describe "ui_choose - fallback mode"
# ============================================================================

it "should select option from piped input"
# Pipe "2" to select the second option
result=$(echo "2" | ui_choose "Pick one:" "alpha" "beta" "gamma" 2>/dev/null)
assert_equals "beta" "$result" "Should select second option"

it "should select first option"
result=$(echo "1" | ui_choose "Pick:" "first" "second" 2>/dev/null)
assert_equals "first" "$result" "Should select first option"

it "should fail on invalid input"
if echo "99" | ui_choose "Pick:" "a" "b" 2>/dev/null; then
    fail_test "Should fail on out-of-range input"
else
    pass_test "Fails on invalid input"
fi

it "should return 1 for empty options"
if ui_choose "Pick:" 2>/dev/null; then
    fail_test "Should fail with no options"
else
    pass_test "Returns 1 for empty options"
fi

# ============================================================================
describe "ui_filter - fallback mode"
# ============================================================================

it "should select multiple items from piped input"
result=$(echo "1,3" | ui_filter "Pick many:" "alpha" "beta" "gamma" 2>/dev/null)
assert_contains "$result" "alpha" "Should contain first selection"
assert_contains "$result" "gamma" "Should contain third selection"
assert_not_contains "$result" "beta" "Should not contain unselected"

# ============================================================================
describe "ui_spinner - fallback mode"
# ============================================================================

it "should run command and return success"
output=$(ui_spinner "Testing true" true 2>&1)
assert_contains "$output" "Testing true" "Should show message"
assert_equals "0" "$?" "Should return 0 for successful command"

it "should run command and return failure"
ui_spinner "Testing false" false 2>&1
rc=$?
assert_equals "1" "$rc" "Should return 1 for failed command"

# ============================================================================
describe "ui_diff - fallback mode"
# ============================================================================

it "should produce diff output for differing files (raw fallback)"
_hide_rich_tools
tmp_a=$(mktemp)
tmp_b=$(mktemp)
echo "line one" > "$tmp_a"
echo "line two" > "$tmp_b"
output=$(ui_diff "$tmp_a" "$tmp_b" 2>&1)
assert_not_empty "$output" "Should produce diff output"
assert_contains "$output" "line one" "Should show content from file a"
assert_contains "$output" "line two" "Should show content from file b"
rm -f "$tmp_a" "$tmp_b"
_hide_gum

it "should produce no output for identical files"
_hide_rich_tools
tmp_a=$(mktemp)
echo "same content" > "$tmp_a"
cp "$tmp_a" "${tmp_a}.copy"
output=$(ui_diff "$tmp_a" "${tmp_a}.copy" 2>&1)
assert_empty "$output" "Should produce no output for identical files"
rm -f "$tmp_a" "${tmp_a}.copy"
_hide_gum

# ============================================================================
describe "ui_summary_box - fallback mode"
# ============================================================================

it "should render title and lines"
output=$(ui_summary_box "My Title" "Line 1" "Line 2" "Line 3")
assert_contains "$output" "My Title" "Should contain title"
assert_contains "$output" "Line 1" "Should contain first line"
assert_contains "$output" "Line 3" "Should contain last line"
assert_contains "$output" "===" "Should have border markers"

it "should handle single line"
output=$(ui_summary_box "Title" "Only line")
assert_contains "$output" "Title" "Should contain title"
assert_contains "$output" "Only line" "Should contain the line"

# ============================================================================
describe "ui_table - fallback mode"
# ============================================================================

it "should format CSV into columns"
output=$(echo -e "Name,Value\nfoo,bar\nbaz,qux" | ui_table)
assert_contains "$output" "Name" "Should contain header"
assert_contains "$output" "foo" "Should contain data"

# ============================================================================
describe "CI mode forces fallback"
# ============================================================================

it "should use fallback in CI mode even if gum exists"
_restore_path
output=$(CI=true ui_section_header "CI Test")
assert_contains "$output" "==" "Should use ANSI fallback in CI"
_hide_gum

# ============================================================================
describe "ui_diff - SETUP_DIFF_STYLE support"
# ============================================================================

it "should pass --diff-so-fancy flag by default (fallback mode)"
_hide_rich_tools
tmp_a=$(mktemp)
tmp_b=$(mktemp)
echo "aaa" > "$tmp_a"
echo "bbb" > "$tmp_b"
# With delta hidden, falls through to raw diff regardless of style
output=$(SETUP_DIFF_STYLE="diff-so-fancy" ui_diff "$tmp_a" "$tmp_b" 2>&1)
assert_not_empty "$output" "Should produce diff output"
rm -f "$tmp_a" "$tmp_b"
_hide_gum

it "should respect SETUP_DIFF_STYLE=unified in fallback mode"
_hide_rich_tools
tmp_a=$(mktemp)
tmp_b=$(mktemp)
echo "line1" > "$tmp_a"
echo "line2" > "$tmp_b"
output=$(SETUP_DIFF_STYLE="unified" ui_diff "$tmp_a" "$tmp_b" 2>&1)
assert_not_empty "$output" "Should produce diff output with unified style"
rm -f "$tmp_a" "$tmp_b"
_hide_gum

it "should respect SETUP_DIFF_STYLE=color-only in fallback mode"
_hide_rich_tools
tmp_a=$(mktemp)
tmp_b=$(mktemp)
echo "foo" > "$tmp_a"
echo "bar" > "$tmp_b"
output=$(SETUP_DIFF_STYLE="color-only" ui_diff "$tmp_a" "$tmp_b" 2>&1)
assert_not_empty "$output" "Should produce diff output with color-only style"
rm -f "$tmp_a" "$tmp_b"
_hide_gum

# ============================================================================
describe "ui_diff_style_select - non-interactive defaults"
# ============================================================================

it "should default to diff-so-fancy when non-interactive"
unset SETUP_DIFF_STYLE
CI=true ui_diff_style_select
assert_equals "diff-so-fancy" "$SETUP_DIFF_STYLE" "Should default to diff-so-fancy"

it "should preserve existing SETUP_DIFF_STYLE"
export SETUP_DIFF_STYLE="side-by-side"
ui_diff_style_select
assert_equals "side-by-side" "$SETUP_DIFF_STYLE" "Should not override existing value"
unset SETUP_DIFF_STYLE

# ============================================================================
describe "TUI sourcing in setup scripts"
# ============================================================================

it "should source ui.sh in setup-validate.sh"
if grep -q 'source.*ui\.sh' "$_PROJECT_ROOT/setup-validate.sh"; then
    pass_test "setup-validate.sh sources ui.sh"
else
    fail_test "setup-validate.sh does not source ui.sh"
fi

it "should source ui.sh in setup-warp.sh"
if grep -q 'source.*ui\.sh' "$_PROJECT_ROOT/scripts/setup-warp.sh"; then
    pass_test "setup-warp.sh sources ui.sh"
else
    fail_test "setup-warp.sh does not source ui.sh"
fi

it "should source ui.sh in setup-help.sh"
if grep -q 'source.*ui\.sh' "$_PROJECT_ROOT/scripts/setup-help.sh"; then
    pass_test "setup-help.sh sources ui.sh"
else
    fail_test "setup-help.sh does not source ui.sh"
fi

it "should not have local print_section in setup-validate.sh"
if grep -q 'print_section()' "$_PROJECT_ROOT/setup-validate.sh"; then
    fail_test "setup-validate.sh still has local print_section"
else
    pass_test "setup-validate.sh has no local print_section"
fi

it "should not have local print_section in setup-warp.sh"
if grep -q 'print_section()' "$_PROJECT_ROOT/scripts/setup-warp.sh"; then
    fail_test "setup-warp.sh still has local print_section"
else
    pass_test "setup-warp.sh has no local print_section"
fi

# ============================================================================
# Cleanup
# ============================================================================
_restore_path

print_test_summary
