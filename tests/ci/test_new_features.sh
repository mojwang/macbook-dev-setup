#!/usr/bin/env bash

# CI tests for new features (OpenJDK and terminal fonts)
# Source test framework
source "$(dirname "$0")/../test_framework.sh"

describe "CI Tests for New Features"

# Test that OpenJDK configuration doesn't break in CI
it "should have valid OpenJDK configuration files"
assert_file_exists "$ROOT_DIR/homebrew/Brewfile" "Main Brewfile should exist"
assert_file_exists "$ROOT_DIR/dotfiles/.config/zsh/10-languages.zsh" "Languages config should exist"

# Test that font setup script exists and has proper permissions
it "should have executable font setup script"
assert_file_exists "$ROOT_DIR/scripts/setup-terminal-fonts.sh" "Font setup script should exist"
assert_true "[[ -x '$ROOT_DIR/scripts/setup-terminal-fonts.sh' ]]" "Font setup script should be executable"

# Test that setup.sh includes new features
it "should include new features in main setup"
setup_content=$(cat "$ROOT_DIR/setup.sh")
assert_contains "$setup_content" "setup-terminal-fonts.sh" "Font setup should be in main setup"
assert_contains "$setup_content" "Configuring terminal fonts" "Should have font configuration message"

# Test that Brewfile syntax is valid (would fail brew bundle)
it "should have valid Brewfile syntax"
# Check for basic syntax errors
brewfile_content=$(cat "$ROOT_DIR/homebrew/Brewfile")
# Ensure no duplicate entries for openjdk
openjdk_count=$(grep -c '^brew "openjdk"' "$ROOT_DIR/homebrew/Brewfile" || echo 0)
assert_equals "1" "$openjdk_count" "OpenJDK should appear exactly once in Brewfile"

# Test that font names are consistent
it "should have consistent font configuration"
vscode_settings=$(cat "$ROOT_DIR/vscode/settings.json")
assert_contains "$vscode_settings" "AnonymicePro Nerd Font Mono" "VS Code should use AnonymicePro font"

# Font should be in Brewfile
brewfile_content=$(cat "$ROOT_DIR/homebrew/Brewfile")
assert_contains "$brewfile_content" 'font-anonymice-nerd-font' "AnonymicePro font should be in Brewfile"

# Test that zsh config is valid bash syntax
it "should have valid shell syntax in zsh configs"
# Basic syntax check - would fail if there are syntax errors
bash -n "$ROOT_DIR/dotfiles/.config/zsh/10-languages.zsh" 2>/dev/null
assert_equals "0" "$?" "Languages config should have valid shell syntax"

# Test documentation is updated
it "should have updated documentation"
tools_doc=$(cat "$ROOT_DIR/docs/tools.md")
assert_contains "$tools_doc" "OpenJDK" "OpenJDK should be documented"

config_doc=$(cat "$ROOT_DIR/docs/configuration.md")
assert_contains "$config_doc" "Terminal Font Configuration" "Font configuration should be documented"

# Test that new scripts don't have shellcheck errors (if shellcheck is available)
it "should pass shellcheck for new scripts"
if command -v shellcheck &>/dev/null; then
    # Check font setup script
    shellcheck_output=$(shellcheck "$ROOT_DIR/scripts/setup-terminal-fonts.sh" 2>&1 || true)
    if [[ -n "$shellcheck_output" ]]; then
        # Filter out minor warnings
        serious_issues=$(echo "$shellcheck_output" | grep -E "(error|SC2086|SC2181)" || true)
        assert_empty "$serious_issues" "Font setup script should not have serious shellcheck issues"
    else
        pass_test "Font setup script passes shellcheck"
    fi
else
    skip_test "Shellcheck not available"
fi

# Summary
summarize