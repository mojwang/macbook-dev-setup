#!/usr/bin/env bash
set -e

# Setup Claude Code MCP servers

# Load common library
source "$(dirname "$0")/../lib/common.sh"

# Function to check if Claude Code is installed
check_claude_code() {
    if ! command -v claude &>/dev/null; then
        print_error "Claude Code CLI not found. Please install Claude Code extension in VS Code first."
        exit 1
    fi
}

# Function to add server to Claude Code
add_claude_code_server() {
    local server_name="$1"
    local scope="${2:-user}"  # Default to user scope
    
    # Check if server is installed
    if ! is_mcp_server_installed "$server_name"; then
        print_warning "Server $server_name is not installed, skipping"
        return 1
    fi
    
    # Get server configuration using dynamic path finding
    local server_path=$(find_mcp_server_executable "$server_name")
    local server_type="${MCP_SERVER_TYPES[$server_name]}"
    local api_key_var="${MCP_SERVER_API_KEYS[$server_name]:-}"
    
    # Check if we found a valid path
    if [[ -z "$server_path" ]]; then
        print_warning "Could not find executable for $server_name"
        return 1
    fi
    
    # Check if API key is required and set
    if [[ -n "$api_key_var" ]]; then
        if [[ -z "${!api_key_var}" ]]; then
            print_warning "Skipping $server_name ($api_key_var not set)"
            return 1
        fi
    fi
    
    print_info "Adding $server_name to Claude Code (scope: $scope)..."
    
    case "$server_type" in
        "node")
            if [[ "$server_name" == "filesystem" ]]; then
                claude mcp add "$server_name" -s "$scope" node "$server_path" "/Users/mojwang"
            elif [[ -n "$api_key_var" ]]; then
                claude mcp add "$server_name" -s "$scope" node "$server_path" --env "${api_key_var}=${!api_key_var}"
            else
                claude mcp add "$server_name" -s "$scope" node "$server_path"
            fi
            ;;
        "python-uv")
            claude mcp add "$server_name" -s "$scope" uv --directory "$server_path" run "mcp-server-$server_name"
            ;;
        "python-uvx")
            if [[ "$server_name" == "semgrep" ]]; then
                claude mcp add "$server_name" -s "$scope" uvx --with mcp==1.11.0 semgrep-mcp
            fi
            ;;
        "npx")
            local npx_package="${MCP_SERVER_NPX_PACKAGES[$server_name]}"
            if [[ "$server_name" == "figma" ]]; then
                if [[ -n "$api_key_var" ]]; then
                    claude mcp add "$server_name" -s "$scope" --env "${api_key_var}=${!api_key_var}" -- npx -y "$npx_package" --stdio
                else
                    claude mcp add "$server_name" -s "$scope" -- npx -y "$npx_package" --stdio
                fi
            else
                if [[ -n "$api_key_var" ]]; then
                    claude mcp add "$server_name" -s "$scope" --env "${api_key_var}=${!api_key_var}" -- npx -y "$npx_package"
                else
                    claude mcp add "$server_name" -s "$scope" -- npx -y "$npx_package"
                fi
            fi
            ;;
    esac
    
    if [[ $? -eq 0 ]]; then
        print_success "Added $server_name"
        return 0
    else
        print_error "Failed to add $server_name"
        return 1
    fi
}

# Function to remove all MCP servers
remove_all_servers() {
    local scope="$1"
    print_info "Removing all MCP servers from scope: $scope"
    
    # Get list of servers
    local servers=$(claude mcp list | grep -E "^[[:alnum:]_-]+:" | cut -d: -f1)
    
    for server in $servers; do
        print_info "Removing $server..."
        claude mcp remove "$server" -s "$scope" 2>/dev/null || true
    done
}

# Print usage
print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --scope SCOPE     Scope for MCP servers: user, project, local (default: user)"
    echo "  --no-api-keys     Skip servers that require API keys"
    echo "  --servers LIST    Only configure specified servers (comma-separated)"
    echo "  --remove          Remove all MCP servers before adding"
    echo "  --help, -h        Show this help message"
    echo ""
    echo "Available servers:"
    echo "  Official: filesystem, memory, git, fetch, sequentialthinking"
    echo "  Community: context7, playwright, figma, semgrep, exa"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Add all servers to user scope"
    echo "  $0 --scope project                    # Add to project scope (.mcp.json)"
    echo "  $0 --no-api-keys                      # Skip servers needing API keys"
    echo "  $0 --servers filesystem,memory,git    # Only add specific servers"
}

# Main function
main() {
    # Default options
    local SCOPE="user"
    local INCLUDE_API_KEYS=true
    local REMOVE_FIRST=false
    local SERVERS_TO_INCLUDE=()
    
    # Parse command line options
    while [[ $# -gt 0 ]]; do
        case $1 in
            --scope)
                SCOPE="$2"
                if [[ ! "$SCOPE" =~ ^(user|project|local)$ ]]; then
                    print_error "Invalid scope: $SCOPE"
                    exit 1
                fi
                shift 2
                ;;
            --no-api-keys)
                INCLUDE_API_KEYS=false
                shift
                ;;
            --servers)
                IFS=',' read -ra SERVERS_TO_INCLUDE <<< "$2"
                shift 2
                ;;
            --remove)
                REMOVE_FIRST=true
                shift
                ;;
            --help|-h)
                print_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                print_usage
                exit 1
                ;;
        esac
    done
    
    echo "========================================="
    echo "Claude Code MCP Server Setup"
    echo "========================================="
    
    # Check Claude Code is installed
    check_claude_code
    
    # Load API keys if available
    if [[ -f "$HOME/.config/zsh/51-api-keys.zsh" ]]; then
        source "$HOME/.config/zsh/51-api-keys.zsh" 2>/dev/null || true
    fi
    
    # Remove existing servers if requested
    if [[ "$REMOVE_FIRST" == "true" ]]; then
        remove_all_servers "$SCOPE"
    fi
    
    # Determine which servers to configure
    if [[ ${#SERVERS_TO_INCLUDE[@]} -gt 0 ]]; then
        # Use specified servers
        servers=("${SERVERS_TO_INCLUDE[@]}")
    else
        # Use all available servers
        servers=(
            # Official servers
            "filesystem" "memory" "git" "fetch" "sequentialthinking"
            # Community servers without API keys
            "context7" "playwright" "semgrep"
        )
        
        # Add servers with API keys if including them
        if [[ "$INCLUDE_API_KEYS" == "true" ]]; then
            servers+=("figma" "exa")
        fi
    fi
    
    # Add each server
    local success_count=0
    for server in "${servers[@]}"; do
        # Skip API key servers if not including them
        if [[ "$INCLUDE_API_KEYS" == "false" ]] && [[ -n "${MCP_SERVER_API_KEYS[$server]}" ]]; then
            print_info "Skipping $server (requires API key)"
            continue
        fi
        
        if add_claude_code_server "$server" "$SCOPE"; then
            ((success_count++))
        fi
    done
    
    echo ""
    print_success "Successfully configured $success_count MCP servers for Claude Code"
    
    # Show current configuration
    echo ""
    print_info "Current MCP servers:"
    claude mcp list || true
    
    # Additional instructions for project scope
    if [[ "$SCOPE" == "project" ]]; then
        echo ""
        print_info "Project configuration saved to .mcp.json"
        print_info "Remember to commit this file to share with your team"
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi