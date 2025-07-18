#!/bin/bash

# Integration tests for sync functionality and new v2.0 features
source "$(dirname "$0")/../test_framework.sh"

describe "Sync and Integration Tests"

# Test 1: Help system
it "should include new v2.0 commands in help"
help_output=$(./setup.sh help 2>&1)
assert_contains "$help_output" "preview" "Help includes preview command"
assert_contains "$help_output" "minimal" "Help includes minimal command"
assert_contains "$help_output" "fix" "Help includes fix command"
assert_contains "$help_output" "backup" "Help includes backup command"

# Test 2: Sync functionality preserved
it "should preserve sync functionality in v2.0"
# Check that sync is integrated into main flow
setup_content=$(cat setup.sh)
assert_contains "$setup_content" "Syncing new packages" "Sync integrated in update flow"

# Test 3: Brewfile.minimal
it "should have minimal Brewfile"
assert_file_exists "homebrew/Brewfile.minimal" "Minimal Brewfile exists"
minimal_content=$(cat homebrew/Brewfile.minimal)
assert_contains "$minimal_content" "brew " "Minimal file has brew formulae"

# Test 4: Modular zsh configuration
it "should have modular zsh config structure"
assert_directory_exists "dotfiles/.config/zsh" "Zsh config directory"

# Check all required modules
modules=("00-homebrew" "10-languages" "20-tools" "30-aliases" "35-commit-aliases" "40-functions" "50-environment")
for module in "${modules[@]}"; do
    assert_file_exists "dotfiles/.config/zsh/${module}.zsh" "Module: ${module}.zsh"
done

# Test 5: Main .zshrc loader
it "should load modular configs from .zshrc"
zshrc_content=$(cat dotfiles/.zshrc)
assert_contains "$zshrc_content" "for config in ~/.config/zsh/*.zsh" "Module loader in .zshrc"

# Test 6: Lazy loading implementations
it "should implement lazy loading for performance"
languages_content=$(cat dotfiles/.config/zsh/10-languages.zsh)
assert_contains "$languages_content" "nvm() {" "Lazy NVM loading"
assert_contains "$languages_content" "unset -f nvm" "NVM lazy loader cleanup"

# Test 7: Local config handling
it "should gitignore local config"
gitignore_content=$(cat .gitignore)
assert_contains "$gitignore_content" "99-local.zsh" "Local config gitignored"

# Test 8: Commit helper integration
it "should have commit helper aliases"
assert_file_exists "dotfiles/.config/zsh/35-commit-aliases.zsh" "Commit aliases file"
commit_aliases=$(cat dotfiles/.config/zsh/35-commit-aliases.zsh)
assert_contains "$commit_aliases" "gci" "Interactive commit alias"
assert_contains "$commit_aliases" "gcft" "Quick feat commit alias"

# Test 9: Backup system integration
it "should integrate backup system"
setup_content=$(cat setup.sh)
# Check for backup manager loading (with proper regex escaping)
assert_contains "$setup_content" 'source "$(dirname "$0")/lib/backup-manager.sh"' "Backup manager loaded"
assert_contains "$setup_content" "create_backup" "Backup creation used"

# Test 10: Warp detection integration
it "should integrate Warp detection"
setup_content=$(cat setup.sh)
assert_contains "$setup_content" "check_and_setup_warp" "Warp detection function"
assert_contains "$setup_content" "SETUP_NO_WARP" "Warp opt-out variable"

# Test 11: Environment variable support
it "should support all documented env vars"
setup_content=$(cat setup.sh)
env_vars=("SETUP_VERBOSE" "SETUP_LOG" "SETUP_JOBS" "SETUP_NO_WARP")
for var in "${env_vars[@]}"; do
    assert_contains "$setup_content" "$var" "Environment var: $var"
done

# Test 12: Documentation completeness
it "should document all new features"
claude_content=$(cat CLAUDE.md)
assert_contains "$claude_content" "./setup.sh preview" "Preview documented"
assert_contains "$claude_content" "./setup.sh fix" "Fix documented"
assert_contains "$claude_content" "./setup.sh backup" "Backup documented"
assert_contains "$claude_content" "Automatic Warp Detection" "Warp detection documented"
assert_contains "$claude_content" "Organized Backup System" "Backup system documented"

print_summary