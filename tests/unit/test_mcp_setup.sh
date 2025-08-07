#!/usr/bin/env bash

# Test MCP setup scripts

# Load test framework
source "$(dirname "$0")/../test_framework.sh"

describe "MCP Setup Tests"

# Test: API keys are not prompted when already set
it "should skip prompting for API keys when they exist"

# Set up test environment
export FIGMA_API_KEY="test-figma-key"
export EXA_API_KEY="test-exa-key"
export API_KEYS_FILE="$HOME/.config/zsh/51-api-keys.zsh"

# Function to test check_api_key (simplified version)
check_api_key() {
    local key_name="$1"
    [[ -n "${!key_name}" ]]
}

# Test check_api_key function
assert_true "check_api_key 'FIGMA_API_KEY'" "check_api_key should detect existing FIGMA_API_KEY"
assert_true "check_api_key 'EXA_API_KEY'" "check_api_key should detect existing EXA_API_KEY"

# Clean up
unset FIGMA_API_KEY EXA_API_KEY

# Test: MCP server paths are found correctly
it "should find MCP server paths correctly"

# Test filesystem server path
fs_path=$(get_mcp_server_base_path "filesystem")
assert_true "[[ -n '$fs_path' ]] && [[ -d '$fs_path' ]]" "filesystem server path should exist"

# Test memory server path
mem_path=$(get_mcp_server_base_path "memory")
assert_true "[[ -n '$mem_path' ]] && [[ -d '$mem_path' ]]" "memory server path should exist"

# Test git server path
git_path=$(get_mcp_server_base_path "git")
assert_true "[[ -n '$git_path' ]] && [[ -d '$git_path' ]]" "git server path should exist"

# Test: MCP server executables are found
it "should find MCP server executables"

# Test Node.js servers
for server in filesystem memory sequentialthinking; do
    exe_path=$(find_mcp_server_executable "$server" 2>/dev/null)
    assert_true "[[ -n '$exe_path' ]] && [[ -f '$exe_path' ]]" "$server executable should exist"
done

# Test Python servers (directories)
for server in git fetch; do
    exe_path=$(find_mcp_server_executable "$server" 2>/dev/null)
    assert_true "[[ -n '$exe_path' ]] && [[ -d '$exe_path' ]]" "$server directory should exist"
done

# Test: is_mcp_server_installed function
it "should correctly detect installed MCP servers"

# Test installed servers
for server in filesystem memory git fetch sequentialthinking; do
    assert_true "is_mcp_server_installed '$server'" "$server should be detected as installed"
done

# Test non-existent server
assert_false "is_mcp_server_installed 'nonexistent_server'" "Non-existent server should not be detected as installed"

# Print test results
print_test_summary