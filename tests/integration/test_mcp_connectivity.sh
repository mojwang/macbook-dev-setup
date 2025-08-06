#!/usr/bin/env bash
# Test MCP server connectivity

set -e

# Source test framework
source "$(dirname "$0")/../test_framework.sh"

# Test functions
test_mcp_server_connectivity() {
    local test_name="MCP Server Connectivity"
    
    # Skip if Claude Code not installed
    if ! command -v claude &>/dev/null; then
        skip_test "$test_name" "Claude Code not installed"
        return
    fi
    
    # Check if any MCP servers are configured
    local servers_json
    servers_json=$(claude settings show 2>/dev/null | jq -r '.mcpServers // {}' 2>/dev/null || echo "{}")
    
    if [[ "$servers_json" == "{}" ]] || [[ -z "$servers_json" ]]; then
        skip_test "$test_name" "No MCP servers configured"
        return
    fi
    
    # Test each configured server
    local server_count=0
    local working_count=0
    local failed_servers=()
    
    while IFS= read -r server_name; do
        ((server_count++))
        
        # Try to list resources from the server (basic connectivity test)
        if claude mcp list 2>/dev/null | grep -q "^${server_name}:"; then
            ((working_count++))
            echo "  ✓ Server '$server_name' is responsive"
        else
            failed_servers+=("$server_name")
            echo "  ✗ Server '$server_name' is not responsive"
        fi
    done < <(echo "$servers_json" | jq -r 'keys[]' 2>/dev/null)
    
    if [[ $server_count -eq 0 ]]; then
        skip_test "$test_name" "No servers found in configuration"
    elif [[ $working_count -eq $server_count ]]; then
        pass_test "$test_name" "All $server_count servers are responsive"
    elif [[ $working_count -gt 0 ]]; then
        fail_test "$test_name" "$working_count/$server_count servers responsive. Failed: ${failed_servers[*]}"
    else
        fail_test "$test_name" "No servers are responsive"
    fi
}

test_mcp_server_initialization() {
    local test_name="MCP Server Initialization"
    
    # Skip if Claude Code not installed
    if ! command -v claude &>/dev/null; then
        skip_test "$test_name" "Claude Code not installed"
        return
    fi
    
    # Check specific critical servers
    local critical_servers=("filesystem" "git")
    local all_working=true
    
    for server in "${critical_servers[@]}"; do
        if claude mcp list 2>/dev/null | grep -q "^${server}:"; then
            echo "  ✓ Critical server '$server' initialized"
        else
            echo "  ✗ Critical server '$server' not initialized"
            all_working=false
        fi
    done
    
    if [[ "$all_working" == "true" ]]; then
        pass_test "$test_name" "All critical servers initialized"
    else
        fail_test "$test_name" "Some critical servers not initialized"
    fi
}

test_mcp_api_key_configuration() {
    local test_name="MCP API Key Configuration"
    
    # Check if API keys file exists with correct permissions
    local api_keys_file="$HOME/.config/zsh/51-api-keys.zsh"
    
    if [[ -f "$api_keys_file" ]]; then
        # Check file permissions (should be 600)
        local perms=$(stat -f "%OLp" "$api_keys_file" 2>/dev/null || stat -c "%a" "$api_keys_file" 2>/dev/null)
        
        if [[ "$perms" == "600" ]]; then
            pass_test "$test_name" "API keys file has secure permissions (600)"
        else
            fail_test "$test_name" "API keys file has insecure permissions ($perms, expected 600)"
        fi
    else
        skip_test "$test_name" "API keys file not found"
    fi
}

test_mcp_server_response_time() {
    local test_name="MCP Server Response Time"
    
    # Skip if Claude Code not installed
    if ! command -v claude &>/dev/null; then
        skip_test "$test_name" "Claude Code not installed"
        return
    fi
    
    # Test response time for filesystem server (most commonly used)
    local start_time=$(date +%s)
    
    if timeout 5 claude mcp list 2>/dev/null | grep -q "^filesystem:"; then
        local end_time=$(date +%s)
        local response_time=$((end_time - start_time))
        
        if [[ $response_time -le 2 ]]; then
            pass_test "$test_name" "Server responded in ${response_time}s (≤2s)"
        elif [[ $response_time -le 5 ]]; then
            warn_test "$test_name" "Server responded in ${response_time}s (>2s but ≤5s)"
        else
            fail_test "$test_name" "Server responded in ${response_time}s (>5s)"
        fi
    else
        fail_test "$test_name" "Server did not respond within 5 seconds"
    fi
}

# Run tests
run_test_suite "MCP Integration" \
    test_mcp_server_connectivity \
    test_mcp_server_initialization \
    test_mcp_api_key_configuration \
    test_mcp_server_response_time