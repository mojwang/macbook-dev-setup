#!/usr/bin/env bash
set -e

# Fix MCP server configurations

# Load common library
source "$(dirname "$0")/../lib/common.sh"

# Load API keys if available
API_KEYS_FILE="$HOME/.config/zsh/51-api-keys.zsh"
if [[ -f "$API_KEYS_FILE" ]]; then
    source "$API_KEYS_FILE" 2>/dev/null || true
fi

CLAUDE_CONFIG="$HOME/Library/Application Support/Claude/claude_desktop_config.json"

print_info "Fixing MCP server configurations..."

# Create a backup
if [[ -f "$CLAUDE_CONFIG" ]]; then
    backup_file="$CLAUDE_CONFIG.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$CLAUDE_CONFIG" "$backup_file"
    print_info "Backed up existing config to $backup_file"
fi

# Parse command line options
INCLUDE_API_KEYS=true
SERVERS_TO_INCLUDE=()
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --no-api-keys)
            INCLUDE_API_KEYS=false
            shift
            ;;
        --servers)
            shift
            IFS=',' read -ra SERVERS_TO_INCLUDE <<< "$1"
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --no-api-keys     Exclude servers that require API keys"
            echo "  --servers LIST    Only include specified servers (comma-separated)"
            echo "  --dry-run         Show what would be configured without making changes"
            echo "  --help, -h        Show this help message"
            echo ""
            echo "Available servers:"
            echo "  Official: filesystem, memory, git, fetch, sequentialthinking"
            echo "  Community: context7, playwright, figma, semgrep, exa"
            echo ""
            echo "Examples:"
            echo "  $0                                    # Fix all servers"
            echo "  $0 --no-api-keys                      # Fix only servers without API keys"
            echo "  $0 --servers filesystem,memory,git    # Fix specific servers"
            echo "  $0 --dry-run                          # Preview changes"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Start building configuration
config='{\n  "mcpServers": {\n'
server_configs=()

# Determine which servers to configure
if [[ ${#SERVERS_TO_INCLUDE[@]} -gt 0 ]]; then
    # Use specified servers
    servers=("${SERVERS_TO_INCLUDE[@]}")
else
    # Use all available servers
    servers=(
        # Official servers
        "filesystem" "memory" "git" "fetch" "sequentialthinking"
        # Community servers
        "context7" "playwright" "semgrep"
    )
    
    # Add servers with API keys if including them
    if [[ "$INCLUDE_API_KEYS" == "true" ]]; then
        servers+=("figma" "exa")
    fi
fi

# Generate configs for each server
for server in "${servers[@]}"; do
    if is_mcp_server_installed "$server"; then
        # Check if we should skip API key servers
        if [[ "$INCLUDE_API_KEYS" == "false" ]] && [[ -n "${MCP_SERVER_API_KEYS[$server]}" ]]; then
            print_warning "Skipping $server (requires API key)"
            continue
        fi
        
        # Check if API key is set for servers that need it
        if [[ -n "${MCP_SERVER_API_KEYS[$server]}" ]]; then
            api_key_var="${MCP_SERVER_API_KEYS[$server]}"
            if [[ -z "${!api_key_var}" ]]; then
                print_warning "Skipping $server ($api_key_var not set)"
                continue
            fi
        fi
        
        server_config=$(generate_mcp_server_config "$server" "$INCLUDE_API_KEYS")
        if [[ -n "$server_config" ]]; then
            server_configs+=("$server_config")
            print_success "Added $server"
        else
            print_warning "Could not configure $server"
        fi
    else
        print_warning "Server $server is not installed"
    fi
done

# Join configs with commas
joined_configs=""
for i in "${!server_configs[@]}"; do
    if [[ $i -eq 0 ]]; then
        joined_configs="${server_configs[$i]}"
    else
        joined_configs="${joined_configs},\n${server_configs[$i]}"
    fi
done

config="${config}${joined_configs}\n  }\n}"

# Validate JSON configuration
if ! echo -e "$config" | python3 -m json.tool >/dev/null 2>&1; then
    print_error "Generated configuration is not valid JSON"
    print_info "Debug output:"
    echo -e "$config"
    exit 1
fi

# Write the configuration or show in dry-run mode
if [[ "$DRY_RUN" == "true" ]]; then
    echo ""
    print_info "DRY RUN MODE - No changes will be made"
    echo ""
    echo "Would write the following configuration:"
    echo -e "$config"
else
    echo -e "$config" > "$CLAUDE_CONFIG"
    print_success "MCP configuration updated with ${#server_configs[@]} servers"
fi

# Show which servers were configured
echo ""
echo "Configured servers:"
for server in "${servers[@]}"; do
    if is_mcp_server_installed "$server"; then
        # Check if it was actually configured
        if echo -e "$config" | grep -q "\"$server\""; then
            echo "  ✓ $server"
        else
            echo "  ✗ $server (skipped)"
        fi
    fi
done

# Restart Claude Desktop if running (skip in dry-run mode)
if [[ "$DRY_RUN" == "false" ]] && pgrep -x "Claude" >/dev/null; then
    echo ""
    read -p "Restart Claude Desktop now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Restarting Claude Desktop..."
        pkill -x "Claude" 2>/dev/null || true
        sleep 2
        open -a "Claude" 2>/dev/null || print_warning "Could not restart Claude automatically"
    fi
fi