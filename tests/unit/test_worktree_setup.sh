#!/bin/bash

# Test suite for Git worktree setup and functionality

source "$(dirname "$0")/../test_framework.sh"

# Get the project root
ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

describe "Git Worktree Setup Tests"

# Test worktree aliases exist
it "should have worktree aliases in 30-aliases.zsh"
aliases_content=$(cat "$ROOT_DIR/dotfiles/.config/zsh/30-aliases.zsh")
assert_contains "$aliases_content" 'alias gwa="git worktree add"' "gwa alias should exist"
assert_contains "$aliases_content" 'alias gwl="git worktree list"' "gwl alias should exist"
assert_contains "$aliases_content" 'alias gwr="git worktree remove"' "gwr alias should exist"
assert_contains "$aliases_content" 'alias gwp="git worktree prune"' "gwp alias should exist"

# Test gwcd function exists
it "should have gwcd function for worktree switching"
assert_contains "$aliases_content" "gwcd()" "gwcd function should be defined"
assert_contains "$aliases_content" "fzf --header=" "gwcd should use fzf for selection"
assert_contains "$aliases_content" "git branch --show-current" "gwcd should show current branch"

# Test gw quick switcher function
it "should have gw function for quick worktree navigation"
assert_contains "$aliases_content" "gw()" "gw function should be defined"
assert_contains "$aliases_content" 'main)' "gw should handle 'main' case"
assert_contains "$aliases_content" 'review)' "gw should handle 'review' case"
assert_contains "$aliases_content" 'hotfix)' "gw should handle 'hotfix' case"
assert_contains "$aliases_content" 'test)' "gw should handle 'test' case"
assert_contains "$aliases_content" '*)' "gw should have default case"

# Test setup_worktrees function
it "should have setup_worktrees helper function"
assert_contains "$aliases_content" "setup_worktrees()" "setup_worktrees function should be defined"
assert_contains "$aliases_content" ".review" "Should create .review worktree"
assert_contains "$aliases_content" ".hotfix" "Should create .hotfix worktree"
assert_contains "$aliases_content" "git worktree list" "Should list worktrees after creation"

# Test documentation exists
it "should document worktree workflow in GIT-WORKFLOW.md"
workflow_doc=$(cat "$ROOT_DIR/docs/GIT-WORKFLOW.md")
assert_contains "$workflow_doc" "Git Worktrees" "Should have worktree section"
assert_contains "$workflow_doc" "sibling" "Should mention sibling approach"
assert_contains "$workflow_doc" ".review" "Should show .review example"
assert_contains "$workflow_doc" "gw main" "Should document gw command"
assert_contains "$workflow_doc" "setup_worktrees" "Should document setup function"

# Test CLAUDE.md mentions worktree structure
it "should reference worktree structure in CLAUDE.md"
claude_content=$(cat "$ROOT_DIR/CLAUDE.md")
assert_contains "$claude_content" "Worktrees" "Should mention worktrees"
assert_contains "$claude_content" ".purpose" "Should mention naming convention"
assert_contains "$claude_content" "gw main" "Should reference quick switch commands"

# Test VS Code workspace tip is documented
it "should include VS Code workspace tip"
assert_contains "$workflow_doc" "VS Code" "Should mention VS Code"
assert_contains "$workflow_doc" "workspace" "Should mention workspace file"
assert_contains "$workflow_doc" "folders" "Should show workspace folders example"

# Test that Git aliases don't conflict with worktree aliases
it "should not have conflicting aliases"
# Check that we removed the conflicting gc alias
assert_not_contains "$aliases_content" 'alias gc="git commit"' "Conflicting gc alias should be removed"
# Check that g alias exists for git
assert_contains "$aliases_content" 'alias g="git"' "g alias for git should exist"

print_test_summary