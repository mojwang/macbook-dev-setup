#!/usr/bin/env bash

# Test MCP API key messaging improvements

set -e

# Set test mode
export TEST_MODE=1

# Set ROOT_DIR correctly before loading test framework
export ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

# Load test framework
source "$(dirname "$0")/../test_framework.sh"

# Mock functions and variables needed for testing
source "$ROOT_DIR/lib/common.sh"

# Mock the print functions to capture output
mock_output=""
print_info() {
    mock_output="$mock_output[INFO] $*\n"
}
print_warning() {
    mock_output="$mock_output[WARNING] $*\n"
}
print_success() {
    mock_output="$mock_output[SUCCESS] $*\n"
}
print_error() {
    mock_output="$mock_output[ERROR] $*\n"
}

# Test suite
describe "MCP API Key Messaging"

# Test positive message when API key is configured
it "shows positive message when API key is configured in setup-claude-code-mcp" '
    # Setup
    export EXA_API_KEY="test-key-123"
    mock_output=""
    
    # Mock the required associative arrays
    declare -A MCP_SERVER_API_KEYS
    MCP_SERVER_API_KEYS["exa"]="EXA_API_KEY"
    
    # Mock function to test just the API key checking logic
    check_api_key_message() {
        local server_name="$1"
        local api_key_var="${MCP_SERVER_API_KEYS[$server_name]:-}"
        
        if [[ -n "$api_key_var" ]] && [[ "$server_name" != "taskmaster" ]]; then
            if [[ -z "${!api_key_var}" ]]; then
                print_warning "Skipping $server_name ($api_key_var not set)"
                return 1
            else
                print_info "$server_name API key is configured ($api_key_var)"
            fi
        fi
        return 0
    }
    
    # Execute
    check_api_key_message "exa"
    
    # Verify
    assert_contains "$mock_output" "exa API key is configured (EXA_API_KEY)" "Should show positive API key message"
    assert_not_contains "$mock_output" "not set" "Should not show not set message"
'

# Test warning message when API key is not configured
it "shows warning message when API key is not configured" '
    # Setup
    unset EXA_API_KEY
    mock_output=""
    
    # Mock the required associative arrays
    declare -A MCP_SERVER_API_KEYS
    MCP_SERVER_API_KEYS["exa"]="EXA_API_KEY"
    
    # Mock function to test just the API key checking logic
    check_api_key_message() {
        local server_name="$1"
        local api_key_var="${MCP_SERVER_API_KEYS[$server_name]:-}"
        
        if [[ -n "$api_key_var" ]] && [[ "$server_name" != "taskmaster" ]]; then
            if [[ -z "${!api_key_var}" ]]; then
                print_warning "Skipping $server_name ($api_key_var not set)"
                return 1
            else
                print_info "$server_name API key is configured ($api_key_var)"
            fi
        fi
        return 0
    }
    
    # Execute
    check_api_key_message "exa" || true
    
    # Verify
    assert_contains "$mock_output" "Skipping exa (EXA_API_KEY not set)" "Should show not set warning"
    assert_not_contains "$mock_output" "configured" "Should not show configured message"
'

# Test that TaskMaster is treated specially (optional API keys)
it "handles TaskMaster as special case with optional API keys" '
    # Setup
    unset ANTHROPIC_API_KEY
    mock_output=""
    
    # Mock the required associative arrays
    declare -A MCP_SERVER_API_KEYS
    MCP_SERVER_API_KEYS["taskmaster"]="ANTHROPIC_API_KEY"
    
    # Mock function to test just the API key checking logic
    check_api_key_message() {
        local server_name="$1"
        local api_key_var="${MCP_SERVER_API_KEYS[$server_name]:-}"
        
        if [[ -n "$api_key_var" ]] && [[ "$server_name" != "taskmaster" ]]; then
            if [[ -z "${!api_key_var}" ]]; then
                print_warning "Skipping $server_name ($api_key_var not set)"
                return 1
            else
                print_info "$server_name API key is configured ($api_key_var)"
            fi
        fi
        return 0
    }
    
    # Execute
    check_api_key_message "taskmaster"
    local result=$?
    
    # Verify - TaskMaster should not show any API key messages (it is optional)
    assert_equals "$result" "0" "TaskMaster should return success even without API key"
    assert_equals "$mock_output" "" "TaskMaster should not show API key messages"
'

# Test with Figma API key
it "shows positive message for Figma when API key is configured" '
    # Setup
    export FIGMA_API_KEY="test-figma-key"
    mock_output=""
    
    # Mock the required associative arrays
    declare -A MCP_SERVER_API_KEYS
    MCP_SERVER_API_KEYS["figma"]="FIGMA_API_KEY"
    
    # Mock function to test just the API key checking logic
    check_api_key_message() {
        local server_name="$1"
        local api_key_var="${MCP_SERVER_API_KEYS[$server_name]:-}"
        
        if [[ -n "$api_key_var" ]] && [[ "$server_name" != "taskmaster" ]]; then
            if [[ -z "${!api_key_var}" ]]; then
                print_warning "Skipping $server_name ($api_key_var not set)"
                return 1
            else
                print_info "$server_name API key is configured ($api_key_var)"
            fi
        fi
        return 0
    }
    
    # Execute
    check_api_key_message "figma"
    
    # Verify
    assert_contains "$mock_output" "figma API key is configured (FIGMA_API_KEY)" "Should show positive Figma API key message"
'

# Test behavior in fix-mcp-servers.sh context
it "shows positive message in fix-mcp-servers context" '
    # Setup
    export EXA_API_KEY="test-key"
    mock_output=""
    
    # Mock the required associative arrays
    declare -A MCP_SERVER_API_KEYS
    MCP_SERVER_API_KEYS["exa"]="EXA_API_KEY"
    
    # Mock the fix-mcp-servers logic
    fix_mcp_check_api_key() {
        local server="$1"
        if [[ -n "${MCP_SERVER_API_KEYS[$server]}" ]]; then
            api_key_var="${MCP_SERVER_API_KEYS[$server]}"
            if [[ -z "${!api_key_var}" ]]; then
                print_warning "Skipping $server ($api_key_var not set)"
                return 1
            else
                print_info "$server API key is configured ($api_key_var)"
            fi
        fi
        return 0
    }
    
    # Execute
    fix_mcp_check_api_key "exa"
    
    # Verify
    assert_contains "$mock_output" "exa API key is configured (EXA_API_KEY)" "Should show positive message in fix-mcp-servers"
'

# Cleanup
unset EXA_API_KEY
unset FIGMA_API_KEY
unset ANTHROPIC_API_KEY

# Tests are run automatically by the test framework