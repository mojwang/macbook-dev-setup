#!/usr/bin/env bash

# Test the help/info system functionality

# Source test framework
source "$(dirname "$0")/../test_framework.sh"

# Source common functions
source "$(dirname "$0")/../../lib/common.sh"

describe "Help System Tests"

it "should have executable help script" && {
    assert_file_exists "scripts/setup-help.sh"
    assert_true "[[ -x scripts/setup-help.sh ]]" "Help script should be executable"
}

it "should show help menu when called without arguments" && {
    output=$(./scripts/setup-help.sh 2>&1)
    assert_contains "$output" "MacBook Dev Setup - Help System"
    assert_contains "$output" "Usage:"
    assert_contains "$output" "Categories:"
    assert_contains "$output" "tools"
    assert_contains "$output" "aliases"
    assert_contains "$output" "functions"
    assert_contains "$output" "features"
}

it "should show tools when requested" && {
    output=$(./scripts/setup-help.sh tools 2>&1)
    assert_contains "$output" "Installed Tools"
    assert_contains "$output" "Modern CLI Replacements"
    assert_contains "$output" "bat"
    assert_contains "$output" "eza"
    assert_contains "$output" "ripgrep"
    assert_contains "$output" "Development Tools"
}

it "should show aliases when requested" && {
    output=$(./scripts/setup-help.sh aliases 2>&1)
    assert_contains "$output" "Shell Aliases"
    assert_contains "$output" "Git Shortcuts"
    assert_contains "$output" "gs"
    assert_contains "$output" "git status"
    assert_contains "$output" "Enhanced Commands"
}

it "should show functions when requested" && {
    output=$(./scripts/setup-help.sh functions 2>&1)
    assert_contains "$output" "Custom Functions"
    assert_contains "$output" "mkcd"
    assert_contains "$output" "extract"
    assert_contains "$output" "devinfo"
}

it "should show features when requested" && {
    output=$(./scripts/setup-help.sh features 2>&1)
    assert_contains "$output" "Special Features"
    assert_contains "$output" "Shell Enhancements"
    assert_contains "$output" "Git Enhancements"
    assert_contains "$output" "Safety & Backup"
}

it "should show examples when requested" && {
    output=$(./scripts/setup-help.sh examples 2>&1)
    assert_contains "$output" "Usage Examples"
    assert_contains "$output" "Finding files"
    assert_contains "$output" "fd"
    assert_contains "$output" "Searching in files"
    assert_contains "$output" "rg"
}

it "should search for commands" && {
    # Test searching for a known command
    output=$(./scripts/setup-help.sh search fd 2>&1)
    assert_contains "$output" "Searching for: fd"
    assert_contains "$output" "Found in"
}

it "should error when search is called without a query" && {
    output=$(./scripts/setup-help.sh search 2>&1)
    assert_contains "$output" "Error: Please provide a search query"
    assert_not_equals "$?" "0" "Should exit with error code"
}

it "should integrate with setup.sh info command" && {
    output=$(./setup.sh info 2>&1)
    # Should show the help system
    assert_contains "$output" "Categories"
}

it "should have devhelp alias in shell config" && {
    assert_file_exists "dotfiles/.config/zsh/30-aliases.zsh"
    content=$(cat "dotfiles/.config/zsh/30-aliases.zsh")
    assert_contains "$content" "alias devhelp"
    assert_contains "$content" "setup.sh info"
}

# Test the search functionality more thoroughly
it "should find commands in PATH when searching" && {
    # Create a mock command for testing
    mock_command "test_cmd" "echo 'test command'"
    
    output=$(./scripts/setup-help.sh search test_cmd 2>&1)
    assert_contains "$output" "Found in PATH"
    
    cleanup_mocks
}

it "should handle 'all' category with pagination prompts" && {
    # The 'all' command should have pagination prompts
    output=$(echo "" | ./scripts/setup-help.sh all 2>&1)
    assert_contains "$output" "Installed Tools"
    # Should contain at least one "Press Enter to continue" prompt
    assert_contains "$output" "Press Enter to continue"
}

run_tests