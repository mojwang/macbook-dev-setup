#!/bin/bash

# Test suite for Graphite CLI integration

source "$(dirname "$0")/../test_framework.sh"

# Get the project root
ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

describe "Graphite CLI Integration Tests"

# Test Graphite is in Brewfile
it "should have Graphite CLI in the main Brewfile"
brewfile_content=$(cat "$ROOT_DIR/homebrew/Brewfile")
assert_contains "$brewfile_content" 'brew "withgraphite/tap/graphite"' "Graphite should be in Brewfile"
assert_contains "$brewfile_content" '# Stacked PRs workflow' "Graphite should have a descriptive comment"

# Test Graphite tap is present
it "should have Graphite tap in Brewfile"
# The tap might be implicit in the formula name or explicit
assert_true "[[ \"$brewfile_content\" =~ withgraphite/tap ]]" "Graphite tap should be referenced"

# Test Git workflow documentation mentions Graphite
it "should document Graphite in GIT-WORKFLOW.md"
workflow_doc=$(cat "$ROOT_DIR/docs/GIT-WORKFLOW.md")
assert_contains "$workflow_doc" "Graphite" "GIT-WORKFLOW.md should mention Graphite"
assert_contains "$workflow_doc" "gt create" "Should document gt create command"
assert_contains "$workflow_doc" "gt submit" "Should document gt submit command"
assert_contains "$workflow_doc" "gt sync" "Should document gt sync command"
assert_contains "$workflow_doc" "stacked" "Should explain stacked PRs concept"

# Test project CLAUDE.md mentions Graphite
it "should reference Graphite in project CLAUDE.md"
claude_content=$(cat "$ROOT_DIR/CLAUDE.md")
assert_contains "$claude_content" "Graphite" "CLAUDE.md should mention Graphite"
assert_contains "$claude_content" "gt" "CLAUDE.md should reference gt command"

# Test that Graphite doesn't conflict with existing Git setup
it "should maintain compatibility with Git aliases"
gitconfig_content=$(cat "$ROOT_DIR/dotfiles/.gitconfig")
# Ensure we still have Git aliases
assert_contains "$gitconfig_content" "[alias]" "Git aliases section should exist"
# Graphite uses 'gt' prefix, so shouldn't conflict with 'git' aliases
assert_not_contains "$gitconfig_content" "gt =" "No gt aliases in gitconfig (Graphite handles these)"

# Test documentation explains gt passthrough
it "should document Graphite's git passthrough feature"
assert_contains "$workflow_doc" "passthrough" "Should explain gt can pass commands to git" || \
assert_contains "$workflow_doc" "gt add" "Should show example of git passthrough"

print_test_summary