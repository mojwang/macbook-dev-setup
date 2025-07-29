#!/bin/bash

# Simplified test for Claude MCP setup script
# Tests core functionality with better isolation

# Source test framework
TEST_FRAMEWORK="$(dirname "$0")/../test_framework.sh"
source "$TEST_FRAMEWORK"

# Test setup
SCRIPT_PATH="$(dirname "$0")/../../scripts/setup-claude-mcp.sh"

describe "Claude MCP Setup - Basic Tests"

# Test 1: Script exists and is executable
test_case "Script should exist and be executable"
assert_file_exists "$SCRIPT_PATH"
assert_true "test -x '$SCRIPT_PATH'"

# Test 2: Help command works
test_case "Should display help with --help"
output=$("$SCRIPT_PATH" --help 2>&1)
assert_contains "$output" "Claude Code MCP Server Setup"
assert_contains "$output" "--check"
assert_contains "$output" "--update"
assert_contains "$output" "--remove"

# Test 3: Check command returns proper exit code
test_case "Check command should return exit code when no servers configured"
# In a fresh environment, this should fail
if [[ -z "$CI" ]]; then
    # Only run if not in CI (since CI might have MCP configured)
    "$SCRIPT_PATH" --check >/dev/null 2>&1
    exit_code=$?
    # Should return non-zero if no servers configured
    assert_true "test $exit_code -ne 0"
else
    skip_test "Skipping in CI environment"
fi

# Test 4: Script sources common library
test_case "Script should source common library"
output=$(grep -n "source.*common.sh" "$SCRIPT_PATH" | head -1)
assert_not_empty "$output"

# Test 5: Script defines required functions
test_case "Script should define setup_mcp_servers function"
assert_true "grep -q 'setup_mcp_servers()' '$SCRIPT_PATH'"

test_case "Script should define check_prerequisites function"
assert_true "grep -q 'check_prerequisites()' '$SCRIPT_PATH'"

test_case "Script should define configure_claude_mcp function"
assert_true "grep -q 'configure_claude_mcp()' '$SCRIPT_PATH'"

test_case "Script should define clone_community_servers function"
assert_true "grep -q 'clone_community_servers()' '$SCRIPT_PATH'"

# Test 6: Script handles paths correctly
test_case "Script should use MCP_ROOT_DIR variable"
assert_true "grep -q 'MCP_ROOT_DIR=' '$SCRIPT_PATH'"

# Test 7: Script has proper JSON escaping
test_case "Script should properly escape JSON"
assert_true "grep -q 'printf.*sed.*s/\[\"\\\\]/\\\\\\\\&/g' '$SCRIPT_PATH'"

# Test 8: Script checks git status before pull
test_case "Script should check git status before pull"
assert_true "grep -q 'git diff --quiet' '$SCRIPT_PATH'"

# Test 9: Script has proper error handling for npm
test_case "Script should handle npm build failures"
assert_true "grep -q 'No build script found' '$SCRIPT_PATH'"

# Test 10: Script includes new MCP servers
test_case "Script should include sequentialthinking in OFFICIAL_SERVERS"
assert_true "grep -q 'sequentialthinking' '$SCRIPT_PATH'"

test_case "Script should define COMMUNITY_SERVERS array"
assert_true "grep -q 'COMMUNITY_SERVERS=' '$SCRIPT_PATH'"

test_case "Script should include context7 server"
assert_true "grep -q 'context7:' '$SCRIPT_PATH'"

test_case "Script should include playwright server"
assert_true "grep -q 'playwright:' '$SCRIPT_PATH'"

test_case "Script should include figma server"
assert_true "grep -q 'figma:' '$SCRIPT_PATH'"

test_case "Script should include semgrep server"
assert_true "grep -q 'semgrep:' '$SCRIPT_PATH'"

test_case "Script should include exa server"
assert_true "grep -q 'exa:' '$SCRIPT_PATH'"

# Test 11: Script handles community servers in remove
test_case "Script should remove community servers in --remove"
assert_true "grep -q 'Remove community servers' '$SCRIPT_PATH'"

# Test 12: Script mentions Pieces MCP in help
test_case "Script should mention Pieces MCP in documentation"
assert_true "grep -q 'Pieces MCP' '$SCRIPT_PATH'"

# Print summary
print_test_summary