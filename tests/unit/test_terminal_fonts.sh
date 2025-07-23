#!/bin/bash

# Tests for terminal font configuration functionality
# Source test framework
source "$(dirname "$0")/../test_framework.sh"

# Source common library if it exists
if [[ -f "$ROOT_DIR/lib/common.sh" ]]; then
    source "$ROOT_DIR/lib/common.sh"
fi

describe "Terminal Font Configuration Tests"

# Test font setup script exists and is executable
it "should have terminal font setup script"
assert_file_exists "$ROOT_DIR/scripts/setup-terminal-fonts.sh" "Font setup script should exist"
assert_true "[[ -x '$ROOT_DIR/scripts/setup-terminal-fonts.sh' ]]" "Font setup script should be executable"

# Test font setup script content
it "should configure fonts dynamically based on Warp settings"
font_script=$(cat "$ROOT_DIR/scripts/setup-terminal-fonts.sh")
assert_contains "$font_script" 'defaults read dev.warp.Warp-Stable FontName' "Should read Warp font name"
assert_contains "$font_script" 'defaults read dev.warp.Warp-Stable FontSize' "Should read Warp font size"
assert_contains "$font_script" 'AnonymicePro Nerd Font Mono' "Should have fallback font"

# Test font size handling
it "should handle font size properly"
assert_contains "$font_script" 'FONT_SIZE=${FONT_SIZE%.*}' "Should convert float to int for font size"
assert_contains "$font_script" 'tr -d '\''"'\''' "Should remove quotes from font name"

# Test font detection
it "should check if font is installed"
assert_contains "$font_script" 'fc-list.*anonymice' "Should check font with fc-list"
assert_contains "$font_script" 'brew list.*font-anonymice-nerd-font' "Should check Homebrew installation"
assert_contains "$font_script" '~/Library/Fonts/*Anonymice*' "Should check user font directory"

# Test terminal configurations
it "should configure multiple terminals"
assert_contains "$font_script" 'configure_iterm2()' "Should have iTerm2 configuration function"
assert_contains "$font_script" 'configure_terminal_app()' "Should have Terminal.app configuration function"
assert_contains "$font_script" 'configure_vscode()' "Should have VS Code configuration function"
assert_contains "$font_script" 'configure_warp()' "Should have Warp configuration function"

# Test VS Code configuration
it "should configure VS Code terminal font"
assert_contains "$font_script" 'terminal.integrated.fontFamily' "Should set VS Code terminal font"
assert_contains "$font_script" 'terminal.integrated.fontSize' "Should set VS Code terminal font size"
assert_contains "$font_script" 'jq.*terminal.integrated' "Should use jq to update VS Code settings"

# Test Terminal.app configuration
it "should configure Terminal.app using AppleScript"
assert_contains "$font_script" 'osascript' "Should use AppleScript for Terminal.app"
assert_contains "$font_script" 'tell application "Terminal"' "Should interact with Terminal app"

# Test error handling
it "should have proper error handling"
assert_contains "$font_script" 'set -euo pipefail' "Should use strict error handling"
assert_contains "$font_script" 'print_error' "Should have error printing function"
assert_contains "$font_script" 'print_warning' "Should have warning printing function"
assert_contains "$font_script" 'print_success' "Should have success printing function"

# Test integration with main setup
it "should be integrated into main setup flow"
setup_content=$(cat "$ROOT_DIR/setup.sh")
assert_contains "$setup_content" './scripts/setup-terminal-fonts.sh' "Font setup should be called in main setup"
assert_contains "$setup_content" 'Configuring terminal fonts' "Should have status message for font configuration"

# Test font is in Brewfile
it "should have nerd fonts in Brewfile"
brewfile_content=$(cat "$ROOT_DIR/homebrew/Brewfile")
assert_contains "$brewfile_content" 'cask "font-anonymice-nerd-font"' "AnonymicePro Nerd Font should be in Brewfile"
assert_contains "$brewfile_content" 'cask "font-symbols-only-nerd-font"' "Symbols Nerd Font should be in Brewfile"

# Test VS Code settings
it "should have font configuration in VS Code settings"
vscode_settings=$(cat "$ROOT_DIR/vscode/settings.json")
assert_contains "$vscode_settings" '"terminal.integrated.fontFamily":' "VS Code should have terminal font setting"
assert_contains "$vscode_settings" 'AnonymicePro Nerd Font Mono' "VS Code should use AnonymicePro font"
assert_contains "$vscode_settings" '"terminal.integrated.fontSize": 18' "VS Code should use size 18"

# Test documentation
it "should be documented in configuration guide"
config_doc=$(cat "$ROOT_DIR/docs/configuration.md")
assert_contains "$config_doc" '### Terminal Font Configuration' "Should have font configuration section"
assert_contains "$config_doc" 'AnonymicePro Nerd Font Mono' "Should document the font name"
assert_contains "$config_doc" './scripts/setup-terminal-fonts.sh' "Should document how to run font setup"

# Test that script handles missing applications gracefully
it "should handle missing applications gracefully"
assert_contains "$font_script" 'if [[ -d "/Applications/iTerm.app" ]]' "Should check if iTerm exists"
assert_contains "$font_script" 'if command -v code &> /dev/null' "Should check if VS Code exists"
assert_contains "$font_script" 'not installed, skipping' "Should skip missing applications"

# Test font installation order
it "should configure fonts after applications are installed"
setup_content=$(cat "$ROOT_DIR/setup.sh")
# Find line numbers for setup steps
apps_line=$(grep -n "setup-applications.sh" "$ROOT_DIR/setup.sh" | head -1 | cut -d: -f1)
fonts_line=$(grep -n "setup-terminal-fonts.sh" "$ROOT_DIR/setup.sh" | head -1 | cut -d: -f1)

# Fonts should be configured after applications
assert_true "[[ $fonts_line -gt $apps_line ]]" "Fonts should be configured after applications"

# Summary
summarize