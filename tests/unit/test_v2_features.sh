#!/bin/bash

# Test script for v2.0 features
source "$(dirname "$0")/../test_framework.sh"
source "$(dirname "$0")/../lib/common.sh"

describe "v2.0 Features Tests"

# Test 1: Preview command functionality
it "should run preview without errors"
preview_output=$(./setup.sh preview 2>&1)
exit_code=$?
assert_equals "$exit_code" "0" "Preview exits successfully"
assert_contains "$preview_output" "Preview Mode" "Preview mode header shown"

# Test 2: Fix command functionality
it "should run diagnostics with fix command"
fix_output=$(./setup.sh fix 2>&1 | head -50)
assert_contains "$fix_output" "Checking" "Fix runs diagnostics"

# Test 3: Minimal command support
it "should support minimal installation mode"
# Check that minimal command is recognized
help_output=$(./setup.sh help 2>&1)
assert_contains "$help_output" "minimal" "Minimal command in help"

# Check Brewfile.minimal exists
assert_file_exists "homebrew/Brewfile.minimal" "Minimal Brewfile exists"

# Test 4: Advanced menu (non-interactive)
it "should have advanced options"
# Check that advanced command exists
setup_content=$(cat setup.sh)
assert_contains "$setup_content" "show_advanced_menu()" "Advanced menu function exists"
assert_contains "$setup_content" "Set parallel jobs" "Parallel jobs option"
assert_contains "$setup_content" "Skip creating backups" "Backup skip option"

# Test 5: Environment variable support
it "should support all environment variables"
# Test that env vars are documented
claude_content=$(cat CLAUDE.md)
assert_contains "$claude_content" "SETUP_VERBOSE" "SETUP_VERBOSE documented"
assert_contains "$claude_content" "SETUP_LOG" "SETUP_LOG documented"
assert_contains "$claude_content" "SETUP_JOBS" "SETUP_JOBS documented"
assert_contains "$claude_content" "SETUP_NO_WARP" "SETUP_NO_WARP documented"

# Test 6: Smart state detection
it "should detect installation state"
setup_content=$(cat setup.sh)
assert_contains "$setup_content" "detect_setup_state()" "State detection function"
assert_contains "$setup_content" 'state="fresh"' "Fresh state detection"
assert_contains "$setup_content" 'state="update"' "Update state detection"

# Test 7: Backup command structure
it "should support backup management commands"
# Test backup command exists
help_output=$(./setup.sh help 2>&1)
assert_contains "$help_output" "backup" "Backup command in help"

# Test backup subcommands
backup_help=$(./setup.sh backup help 2>&1 || true)
if [[ -n "$backup_help" ]]; then
    assert_contains "$backup_help" "list" "Backup list subcommand"
    assert_contains "$backup_help" "clean" "Backup clean subcommand"
fi

# Test 8: Warp command
it "should have warp setup command"
help_output=$(./setup.sh help 2>&1)
assert_contains "$help_output" "warp" "Warp command in help"

# Check Warp setup script exists
assert_file_exists "scripts/setup-warp.sh" "Warp setup script"

# Test 9: Performance optimizations
it "should have performance features"
# Check for parallel jobs support
setup_content=$(cat setup.sh)
assert_contains "$setup_content" "PARALLEL_JOBS" "Parallel jobs variable"

# Check for lazy loading
languages_content=$(cat dotfiles/.config/zsh/10-languages.zsh)
assert_contains "$languages_content" "nvm()" "Lazy NVM loading"

# Test 10: Delegation to validation script
it "should delegate preview to validation script"
# When running with preview, it should use setup-validate.sh
setup_content=$(cat setup.sh)
assert_contains "$setup_content" "./setup-validate.sh" "Delegates to validation script"

# Test 11: Organized backup structure
it "should use organized backup system"
if [[ -f "lib/backup-manager.sh" ]]; then
    backup_content=$(cat lib/backup-manager.sh)
    assert_contains "$backup_content" "BACKUP_ROOT" "Backup root defined"
    assert_contains "$backup_content" "BACKUP_CATEGORIES" "Backup categories defined"
    assert_contains "$backup_content" "create_backup()" "Create backup function"
    assert_contains "$backup_content" "clean_old_backups()" "Cleanup function"
else
    skip_test "Backup manager not found"
fi

# Test 12: Git commit helpers
it "should have commit helper integration"
assert_file_exists "scripts/commit-helper.sh" "Commit helper script"
assert_file_exists "scripts/setup-git-hooks.sh" "Git hooks setup script"
assert_file_exists "dotfiles/.config/zsh/35-commit-aliases.zsh" "Commit aliases"

# Test commit aliases content
if [[ -f "dotfiles/.config/zsh/35-commit-aliases.zsh" ]]; then
    aliases_content=$(cat dotfiles/.config/zsh/35-commit-aliases.zsh)
    assert_contains "$aliases_content" "gci" "gci alias"
    assert_contains "$aliases_content" "gcft" "gcft alias"
    assert_contains "$aliases_content" "commit-help" "commit-help alias"
fi

print_summary