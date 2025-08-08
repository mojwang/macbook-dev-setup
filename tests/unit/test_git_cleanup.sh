#!/usr/bin/env bash

# Test git cleanup aliases and functions

# Load test framework
source "$(dirname "$0")/../test_framework.sh"

# Get root directory
ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

describe "Git Cleanup Configuration"

# Test 1: Check aliases file exists
it "should have aliases configuration file"
assert_file_exists "$ROOT_DIR/dotfiles/.config/zsh/30-aliases.zsh" "30-aliases.zsh should exist"

# Test 2: Check git cleanup aliases exist
it "should have git cleanup aliases defined"
aliases_content=$(cat "$ROOT_DIR/dotfiles/.config/zsh/30-aliases.zsh")
assert_contains "$aliases_content" 'alias gprune="git remote prune origin"' "gprune alias should exist"
assert_contains "$aliases_content" 'alias gclean="git-cleanup-branches"' "gclean alias should exist"

# Test 3: Check git-cleanup-branches function exists
it "should have git-cleanup-branches function"
assert_contains "$aliases_content" "git-cleanup-branches()" "git-cleanup-branches function should be defined"
assert_contains "$aliases_content" "git remote prune origin" "Function should prune remote branches"
assert_contains "$aliases_content" 'git branch -vv | grep ": gone]"' "Function should find gone branches"
assert_contains "$aliases_content" "Delete these branches?" "Function should ask for confirmation"

# Test 4: Check function has force mode
it "should support force mode in cleanup function"
assert_contains "$aliases_content" '--force' "Function should support --force flag"
assert_contains "$aliases_content" 'Force mode: Deleting branches without confirmation' "Function should have force mode message"

# Test 5: Check function has safety checks
it "should have safety checks in cleanup function"
assert_contains "$aliases_content" 'git rev-parse --git-dir' "Function should check if in git repo"
assert_contains "$aliases_content" 'Error: Not in a git repository' "Function should have error message for non-git dirs"
assert_contains "$aliases_content" 'No stale branches to clean up' "Function should handle no branches case"

# Test 6: Check function handles unmerged branches
it "should handle unmerged branches properly"
assert_contains "$aliases_content" 'git branch -d' "Function should try safe delete first"
assert_contains "$aliases_content" 'git branch -D' "Function should offer force delete option"
assert_contains "$aliases_content" 'not fully merged' "Function should warn about unmerged branches"

# Test 7: Check documentation is updated
it "should have documentation for git cleanup"
if [[ -f "$ROOT_DIR/docs/COMMANDS.md" ]]; then
    commands_content=$(cat "$ROOT_DIR/docs/COMMANDS.md")
    assert_contains "$commands_content" "gclean" "COMMANDS.md should document gclean"
    assert_contains "$commands_content" "gprune" "COMMANDS.md should document gprune"
    assert_contains "$commands_content" "Branch Cleanup" "COMMANDS.md should have Branch Cleanup section"
else
    print_warning "docs/COMMANDS.md not found"
fi

# Test 8: Check Git workflow documentation
it "should have git cleanup in workflow documentation"
if [[ -f "$ROOT_DIR/docs/GIT-WORKFLOW.md" ]]; then
    workflow_content=$(cat "$ROOT_DIR/docs/GIT-WORKFLOW.md")
    assert_contains "$workflow_content" "Branch Cleanup" "GIT-WORKFLOW.md should have Branch Cleanup section"
    assert_contains "$workflow_content" "gclean" "GIT-WORKFLOW.md should mention gclean"
    assert_contains "$workflow_content" "Cleaning Up Stale Branches" "GIT-WORKFLOW.md should explain cleanup process"
else
    print_warning "docs/GIT-WORKFLOW.md not found"
fi

# Run the tests
run_tests