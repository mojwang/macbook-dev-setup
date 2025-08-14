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
    
    # Check if API key is required and set (TaskMaster is optional)
    if [[ -n "$api_key_var" ]] && [[ "$server_name" != "taskmaster" ]]; then
        if [[ -z "${!api_key_var}" ]]; then
            print_warning "Skipping $server_name ($api_key_var not set)"
            return 1
        fi
    fi
    
    print_info "Adding $server_name to Claude Code (scope: $scope)..."
    
    # Capture the command output and exit code
    local cmd_output
    local cmd_exit_code
    
    case "$server_type" in
        "node")
            if [[ "$server_name" == "filesystem" ]]; then
                cmd_output=$(claude mcp add "$server_name" -s "$scope" node "$server_path" "$HOME" 2>&1)
                cmd_exit_code=$?
            elif [[ -n "$api_key_var" ]]; then
                cmd_output=$(claude mcp add "$server_name" -s "$scope" node "$server_path" --env "${api_key_var}=${!api_key_var}" 2>&1)
                cmd_exit_code=$?
            else
                cmd_output=$(claude mcp add "$server_name" -s "$scope" node "$server_path" 2>&1)
                cmd_exit_code=$?
            fi
            ;;
        "python-uv")
            # Claude Code requires the command to be passed correctly for Python servers
            cmd_output=$(claude mcp add "$server_name" -s "$scope" -- sh -c "cd '$server_path' && uv run mcp-server-$server_name" 2>&1)
            cmd_exit_code=$?
            ;;
        "python-uvx")
            if [[ "$server_name" == "semgrep" ]]; then
                cmd_output=$(claude mcp add "$server_name" -s "$scope" -- uvx --with mcp==1.11.0 semgrep-mcp 2>&1)
                cmd_exit_code=$?
            fi
            ;;
        "npx")
            local npx_package="${MCP_SERVER_NPX_PACKAGES[$server_name]}"
            if [[ "$server_name" == "figma" ]]; then
                if [[ -n "$api_key_var" ]]; then
                    cmd_output=$(claude mcp add "$server_name" -s "$scope" --env "${api_key_var}=${!api_key_var}" -- npx -y "$npx_package" --stdio 2>&1)
                    cmd_exit_code=$?
                else
                    cmd_output=$(claude mcp add "$server_name" -s "$scope" -- npx -y "$npx_package" --stdio 2>&1)
                    cmd_exit_code=$?
                fi
            elif [[ "$server_name" == "taskmaster" ]]; then
                # TaskMaster needs multiple API keys
                local env_args=""
                if [[ -n "$ANTHROPIC_API_KEY" ]]; then
                    env_args="--env ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}"
                fi
                if [[ -n "$OPENAI_API_KEY" ]]; then
                    env_args="$env_args --env OPENAI_API_KEY=${OPENAI_API_KEY}"
                fi
                if [[ -n "$PERPLEXITY_API_KEY" ]]; then
                    env_args="$env_args --env PERPLEXITY_API_KEY=${PERPLEXITY_API_KEY}"
                fi
                cmd_output=$(claude mcp add "$server_name" -s "$scope" $env_args -- npx -y "$npx_package" 2>&1)
                cmd_exit_code=$?
            else
                if [[ -n "$api_key_var" ]]; then
                    cmd_output=$(claude mcp add "$server_name" -s "$scope" --env "${api_key_var}=${!api_key_var}" -- npx -y "$npx_package" 2>&1)
                    cmd_exit_code=$?
                else
                    cmd_output=$(claude mcp add "$server_name" -s "$scope" -- npx -y "$npx_package" 2>&1)
                    cmd_exit_code=$?
                fi
            fi
            ;;
    esac
    
    if [[ $cmd_exit_code -eq 0 ]]; then
        print_success "Added $server_name"
        
        # Special message for TaskMaster
        if [[ "$server_name" == "taskmaster" ]]; then
            echo ""
            print_info "TaskMaster Product Manager added successfully!"
            if [[ -n "$ANTHROPIC_API_KEY" ]]; then
                print_success "  ✓ AI-powered task generation enabled (ANTHROPIC_API_KEY set)"
            else
                print_info "  ℹ Basic features available (ANTHROPIC_API_KEY not set)"
                print_info "    To enable AI features, add ANTHROPIC_API_KEY to ~/.config/zsh/51-api-keys.zsh"
            fi
            if [[ -n "$PERPLEXITY_API_KEY" ]]; then
                print_success "  ✓ Research features enabled (PERPLEXITY_API_KEY set)"
            else
                print_info "  ℹ Research features disabled (PERPLEXITY_API_KEY not set)"
            fi
            echo ""
        fi
        
        return 0
    else
        # Check if the error is because the server already exists
        if echo "$cmd_output" | grep -q "already exists"; then
            print_info "Server $server_name already exists in $scope config - skipping"
            return 0  # Not really an error, server is already configured
        else
            print_error "Failed to add $server_name: $cmd_output"
            return 1
        fi
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
    echo "  --force           Force reconnect all servers (ignores update status)"
    echo "  --help, -h        Show this help message"
    echo ""
    echo "Behavior:"
    echo "  By default, only reconnects servers that were actually updated."
    echo "  Use --force to reconnect all servers regardless of update status."
    echo ""
    echo "Available servers:"
    echo "  Official: filesystem, memory, git, fetch, sequentialthinking"
    echo "  Community: context7, playwright, figma, semgrep, exa"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Smart reconnect (only if updated)"
    echo "  $0 --force                            # Force reconnect all servers"
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
    local FORCE_RECONNECT=false
    local SERVERS_TO_INCLUDE=()
    
    # Check for update status file to determine if reconnection is needed
    local UPDATE_STATUS_FILE="/tmp/mcp-update-status"
    local UPDATED_SERVERS=()
    
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
            --force)
                FORCE_RECONNECT=true
                REMOVE_FIRST=true  # Force implies remove first
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
    
    # Check for updated servers if not forcing
    if [[ "$FORCE_RECONNECT" == "false" ]] && [[ -f "$UPDATE_STATUS_FILE" ]]; then
        # Read updated servers from file
        while IFS= read -r server; do
            [[ -n "$server" ]] && UPDATED_SERVERS+=("$server")
        done < "$UPDATE_STATUS_FILE"
        
        if [[ ${#UPDATED_SERVERS[@]} -eq 0 ]]; then
            print_info "No MCP servers were updated, skipping reconnection"
            echo ""
            print_info "Use --force to force reconnection of all servers"
            exit 0
        else
            print_info "Servers that were updated: ${UPDATED_SERVERS[*]}"
            echo ""
        fi
    fi
    
    # Remove existing servers if requested or if forcing
    if [[ "$REMOVE_FIRST" == "true" ]] || [[ "$FORCE_RECONNECT" == "true" ]]; then
        remove_all_servers "$SCOPE"
    elif [[ ${#UPDATED_SERVERS[@]} -gt 0 ]]; then
        # Only remove the servers that were updated
        print_info "Removing updated servers for reconnection..."
        for server in "${UPDATED_SERVERS[@]}"; do
            print_info "Removing $server..."
            claude mcp remove "$server" -s "$SCOPE" 2>/dev/null || true
        done
    fi
    
    # Determine which servers to configure
    if [[ ${#SERVERS_TO_INCLUDE[@]} -gt 0 ]]; then
        # Use specified servers
        servers=("${SERVERS_TO_INCLUDE[@]}")
    elif [[ "$FORCE_RECONNECT" == "false" ]] && [[ ${#UPDATED_SERVERS[@]} -gt 0 ]]; then
        # Only reconnect updated servers
        servers=("${UPDATED_SERVERS[@]}")
        print_info "Reconnecting only updated servers: ${servers[*]}"
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
            servers+=("figma" "exa" "taskmaster")
        fi
    fi
    
    # Add each server
    local success_count=0
    for server in "${servers[@]}"; do
        # Skip API key servers if not including them
        if [[ "$INCLUDE_API_KEYS" == "false" ]] && [[ -n "${MCP_SERVER_API_KEYS[$server]:-}" ]]; then
            print_info "Skipping $server (requires API key)"
            continue
        fi
        
        if add_claude_code_server "$server" "$SCOPE"; then
            success_count=$((success_count + 1))
        fi
    done
    
    echo ""
    if [[ $success_count -gt 0 ]]; then
        print_success "Successfully configured $success_count MCP servers for Claude Code"
    else
        print_info "All MCP servers were already configured for Claude Code"
    fi
    
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