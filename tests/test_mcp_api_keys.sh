#!/usr/bin/env bash

# Test script for MCP API key configuration

set -e

# Source common library for print functions
source "$(dirname "$0")/../lib/common.sh"

# Test helper functions
print_test() {
    echo -e "\n🧪 $1"
}

# Test API key configuration
test_api_key_configuration() {
    print_test "Testing MCP API key configuration"
    
    # Check if API keys file exists
    local api_keys_file="$HOME/.config/zsh/51-api-keys.zsh"
    
    if [[ -f "$api_keys_file" ]]; then
        print_success "API keys file exists: $api_keys_file"
        
        # Check file permissions (should be readable by user only)
        local perms=$(stat -f "%A" "$api_keys_file" 2>/dev/null || stat -c "%a" "$api_keys_file" 2>/dev/null)
        print_info "File permissions: $perms"
        
        # Check if common API keys are defined
        local keys_found=()
        for key in EXA_API_KEY FIGMA_API_KEY; do
            if grep -q "export $key=" "$api_keys_file"; then
                keys_found+=("$key")
            fi
        done
        
        if [[ ${#keys_found[@]} -gt 0 ]]; then
            print_success "Found API key exports: ${keys_found[*]}"
        else
            print_info "No API keys configured yet"
        fi
    else
        print_info "API keys file not found (will be created during setup)"
    fi
}

# Test MCP server detection
test_mcp_server_detection() {
    print_test "Testing MCP server API key requirements"
    
    # List servers that require API keys
    print_success "Servers requiring API keys:"
    echo "  - exa: EXA_API_KEY"
    echo "  - figma: FIGMA_API_KEY"
}

# Test environment variable loading
test_env_loading() {
    print_test "Testing environment variable loading"
    
    # Check if zshrc sources the API keys file
    if grep -q "51-api-keys.zsh" ~/.zshrc 2>/dev/null || grep -q "\.config/zsh/\*.zsh" ~/.zshrc 2>/dev/null; then
        print_success "API keys file will be loaded by zsh configuration"
    else
        print_warning "API keys file may not be loaded automatically"
    fi
}

# Main test execution
main() {
    echo -e "\n========================================="
    echo "MCP API Key Configuration Tests"
    echo "========================================="
    
    test_api_key_configuration
    echo
    test_mcp_server_detection
    echo
    test_env_loading
    
    print_success "All tests completed!"
}

# Run tests
main "$@"