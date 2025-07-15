#!/bin/bash

# Tests for setup.sh functionality
# Source test framework
source "$(dirname "$0")/test_framework.sh"

# Source common library for testing
source "$ROOT_DIR/lib/common.sh"

describe "Setup Script Tests"

# Test command structure (v2.0)
it "should use new command-based structure"
# Test that setup.sh uses commands instead of flags
setup_content=$(cat "$ROOT_DIR/setup.sh")
assert_contains "$setup_content" 'case "${1:-}" in' "Command-based structure implemented"

# Test main commands exist
assert_contains "$setup_content" '"help"|"-h"|"--help")' "Help command exists"
assert_contains "$setup_content" '"preview")' "Preview command exists"
assert_contains "$setup_content" '"minimal")' "Minimal command exists"
assert_contains "$setup_content" '"fix")' "Fix command exists"
assert_contains "$setup_content" '"warp")' "Warp command exists"
assert_contains "$setup_content" '"backup")' "Backup command exists"
assert_contains "$setup_content" '"advanced")' "Advanced command exists"

# Test old functionality is integrated
it "should integrate old flag functionality into new system"
# --sync is now automatic in update mode
assert_contains "$setup_content" "Syncing new packages" "Sync functionality integrated in update flow"

# --update is now automatic when existing installation detected
assert_contains "$setup_content" "Updating existing packages" "Update functionality integrated"

# --dry-run is now preview command
assert_contains "$setup_content" "preview" "Dry-run replaced by preview command"

# --minimal is now a command
assert_contains "$setup_content" '"minimal")' "Minimal is now a command"

it "should detect Brewfile.minimal when minimal flag is set"
assert_file_exists "$ROOT_DIR/homebrew/Brewfile.minimal" "Brewfile.minimal should exist"

it "should integrate package sync in update flow"
# In v2.0, sync is integrated into the update flow, not a separate function
assert_true "[[ -f '$ROOT_DIR/setup.sh' ]]" "setup.sh should exist"
assert_contains "$setup_content" "Syncing new packages" "Sync integrated in update"

it "should use brew bundle for package management"
# In v2.0, brew bundle is called directly in the update flow
assert_contains "$setup_content" "brew bundle" "Uses brew bundle for packages"

it "should support VS Code setup"
# VS Code is set up through setup-applications.sh
assert_contains "$setup_content" "setup-applications.sh" "Calls applications setup"

it "should have npm package configuration"
# npm packages are managed through the package scripts
assert_file_exists "$ROOT_DIR/nodejs-config/global-packages.txt" "Global packages list exists"

it "should have Python requirements file"
# Python packages are managed through requirements.txt
assert_file_exists "$ROOT_DIR/python/requirements.txt" "Python requirements exists"

describe "Modular Zsh Configuration Tests"

it "should have modular zsh configuration directory"
assert_directory_exists "$ROOT_DIR/dotfiles/.config/zsh" "Zsh config directory should exist"

it "should have all required zsh modules"
assert_file_exists "$ROOT_DIR/dotfiles/.config/zsh/00-homebrew.zsh" "Homebrew module should exist"
assert_file_exists "$ROOT_DIR/dotfiles/.config/zsh/10-languages.zsh" "Languages module should exist"
assert_file_exists "$ROOT_DIR/dotfiles/.config/zsh/20-tools.zsh" "Tools module should exist"
assert_file_exists "$ROOT_DIR/dotfiles/.config/zsh/30-aliases.zsh" "Aliases module should exist"
assert_file_exists "$ROOT_DIR/dotfiles/.config/zsh/40-functions.zsh" "Functions module should exist"
assert_file_exists "$ROOT_DIR/dotfiles/.config/zsh/50-environment.zsh" "Environment module should exist"
# Note: 99-local.zsh is gitignored and created by users, so we don't test for it

it "should have modular zshrc loader"
assert_file_exists "$ROOT_DIR/dotfiles/.zshrc" "Main .zshrc should exist"
assert_contains "$(cat $ROOT_DIR/dotfiles/.zshrc)" "for config in ~/.config/zsh/*.zsh" "Main .zshrc should load modules"

it "should have lazy NVM loading"
assert_contains "$(cat $ROOT_DIR/dotfiles/.config/zsh/10-languages.zsh)" "nvm() {" "Should have lazy NVM function"
assert_contains "$(cat $ROOT_DIR/dotfiles/.config/zsh/10-languages.zsh)" "unset -f nvm node npm npx" "Should unset functions on first load"

it "should cache Homebrew prefix"
assert_contains "$(cat $ROOT_DIR/dotfiles/.config/zsh/00-homebrew.zsh)" "HOMEBREW_PREFIX" "Should use HOMEBREW_PREFIX variable"
assert_contains "$(cat $ROOT_DIR/dotfiles/.config/zsh/00-homebrew.zsh)" "if [[ -z \"\$HOMEBREW_PREFIX\" ]]" "Should check if already cached"

it "should have 99-local.zsh in gitignore"
assert_contains "$(cat $ROOT_DIR/.gitignore)" "99-local.zsh" ".gitignore should exclude local customizations"

describe "Documentation Tests"

it "should document new command structure in help"
help_output=$(./setup.sh help 2>&1)
assert_contains "$help_output" "preview" "Help documents preview command"
assert_contains "$help_output" "minimal" "Help documents minimal command"
assert_contains "$help_output" "fix" "Help documents fix command"

it "should document new commands in CLAUDE.md"
CLAUDE_content=$(cat $ROOT_DIR/CLAUDE.md)
assert_contains "$CLAUDE_content" "./setup.sh preview" "CLAUDE.md documents preview command"
assert_contains "$CLAUDE_content" "./setup.sh minimal" "CLAUDE.md documents minimal command"
assert_contains "$CLAUDE_content" "./setup.sh fix" "CLAUDE.md documents fix command"
assert_contains "$CLAUDE_content" "Package Synchronization" "CLAUDE.md explains sync is automatic"
assert_contains "$(cat $ROOT_DIR/CLAUDE.md)" "Brewfile.minimal" "CLAUDE.md should document minimal Brewfile"

describe "Command Validation Tests"

it "should handle minimal mode in both fresh and update states"
# In v2.0, minimal is a command that works with both fresh and update states
assert_contains "$setup_content" '"minimal")' "Minimal command exists"
assert_contains "$setup_content" 'is_minimal="${1:-false}"' "Minimal mode parameter in main_setup"

it "should support minimal mode with automatic state detection"
# Check that minimal mode can be used with smart state detection
assert_contains "$setup_content" 'Brewfile.minimal' "Supports minimal Brewfile in logic"