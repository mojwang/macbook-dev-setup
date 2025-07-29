#!/bin/bash

# Setup Claude Code MCP (Model Context Protocol) servers
# Installs and configures official MCP servers for global use

set -e

# Load common library
source "$(dirname "$0")/../lib/common.sh"

# Configuration
MCP_ROOT_DIR="${MCP_ROOT_DIR:-$HOME/repos/mcp-servers}"
MCP_OFFICIAL_DIR="$MCP_ROOT_DIR/official"
MCP_COMMUNITY_DIR="$MCP_ROOT_DIR/community"
MCP_CUSTOM_DIR="$MCP_ROOT_DIR/custom"

# MCP servers repository
MCP_REPO_URL="https://github.com/modelcontextprotocol/servers.git"

# List of official servers to install
OFFICIAL_SERVERS=(
    "filesystem"
    "memory"
    "git"
    "fetch"
    "sequentialthinking"
)

# List of community servers to install with optional checksums
# Format: "name:url[:sha256_checksum]"
COMMUNITY_SERVERS=(
    "context7:https://github.com/upstash/context7-mcp.git"
    "playwright:https://github.com/microsoft/playwright-mcp.git"
    "figma:https://github.com/GLips/Figma-Context-MCP.git"
    "semgrep:https://github.com/semgrep/mcp.git"
    "exa:https://github.com/exa-labs/exa-mcp-server.git"
)

# Path patterns for build artifacts
declare -A BUILD_PATHS=(
    ["node"]="dist/index.js build/index.js index.js"
    ["python"]="__main__.py main.py src/main.py"
)

# Node.js servers that need npm build
NODE_SERVERS=(
    "filesystem"
    "memory"
    "git"
    "fetch"
    "sequentialthinking"
    "context7"
    "playwright"
    "figma"
    "semgrep"
    "exa"
)

# Python servers that need package build
PYTHON_SERVERS=()

# Claude Desktop config path
CLAUDE_CONFIG_DIR="$HOME/Library/Application Support/Claude"
CLAUDE_CONFIG_FILE="$CLAUDE_CONFIG_DIR/claude_desktop_config.json"

# Backup directory
BACKUP_ROOT="${BACKUP_ROOT:-$HOME/.setup-backups}"
BACKUP_DIR="$BACKUP_ROOT/configs/claude-mcp/$(date +%Y%m%d-%H%M%S)"

# Check if running on macOS
check_macos() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "This script is designed for macOS only"
        exit 1
    fi
}

# Check prerequisites
check_prerequisites() {
    local missing_tools=()
    
    if ! command -v node &>/dev/null; then
        missing_tools+=("node")
    fi
    
    if ! command -v npm &>/dev/null; then
        missing_tools+=("npm")
    fi
    
    if ! command -v git &>/dev/null; then
        missing_tools+=("git")
    fi
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        print_info "Please run ./setup.sh first to install dependencies"
        exit 1
    fi
}

# Initialize npm with default values to prevent interactive prompts
init_npm_noninteractive() {
    local dir="$1"
    cd "$dir" || return 1
    
    # Create minimal package.json if it doesn't exist
    if [[ ! -f package.json ]]; then
        cat > package.json <<EOF
{
  "name": "$(basename "$dir")",
  "version": "1.0.0",
  "description": "MCP server",
  "private": true
}
EOF
    fi
}

# Verify checksum if provided
verify_checksum() {
    local file="$1"
    local expected_checksum="$2"
    
    if [[ -z "$expected_checksum" ]]; then
        return 0
    fi
    
    local actual_checksum
    actual_checksum=$(shasum -a 256 "$file" | awk '{print $1}')
    
    if [[ "$actual_checksum" != "$expected_checksum" ]]; then
        print_error "Checksum verification failed for $file"
        print_error "Expected: $expected_checksum"
        print_error "Actual: $actual_checksum"
        return 1
    fi
    
    return 0
}

# Clone or update a repository
clone_or_update_repo() {
    local repo_url="$1"
    local target_dir="$2"
    local repo_name=$(basename "$target_dir")
    
    if [[ -d "$target_dir/.git" ]]; then
        print_info "Updating $repo_name..."
        cd "$target_dir" || return 1
        git fetch origin >/dev/null 2>&1
        git reset --hard origin/main >/dev/null 2>&1 || git reset --hard origin/master >/dev/null 2>&1
    else
        print_info "Cloning $repo_name..."
        git clone --depth 1 "$repo_url" "$target_dir" >/dev/null 2>&1
    fi
}

# Build Node.js server
build_node_server() {
    local server_path="$1"
    local server_name=$(basename "$server_path")
    
    print_info "Building $server_name..."
    cd "$server_path" || return 1
    
    # Initialize npm non-interactively
    init_npm_noninteractive "$server_path"
    
    # Install dependencies with timeout
    timeout 120 npm install --no-audit --no-fund --loglevel=error >/dev/null 2>&1 || {
        print_error "npm install failed or timed out for $server_name"
        return 1
    }
    
    # Build if build script exists
    if grep -q '"build"' package.json 2>/dev/null; then
        timeout 60 npm run build >/dev/null 2>&1 || {
            print_warning "Build failed for $server_name, continuing anyway..."
        }
    fi
    
    return 0
}

# Build Python server
build_python_server() {
    local server_path="$1"
    local server_name=$(basename "$server_path")
    
    print_info "Building Python server $server_name..."
    cd "$server_path" || return 1
    
    # Create virtual environment if needed
    if [[ ! -d "venv" ]]; then
        python3 -m venv venv >/dev/null 2>&1
    fi
    
    # Install dependencies
    if [[ -f "requirements.txt" ]]; then
        ./venv/bin/pip install -r requirements.txt >/dev/null 2>&1
    fi
    
    return 0
}

# Install official MCP servers
install_official_servers() {
    print_section "Installing Official MCP Servers"
    
    # Clone or update the official servers repository
    if ! clone_or_update_repo "$MCP_REPO_URL" "$MCP_OFFICIAL_DIR"; then
        print_error "Failed to clone/update official MCP servers"
        return 1
    fi
    
    # Build each server
    local failed_servers=()
    for server in "${OFFICIAL_SERVERS[@]}"; do
        local server_path="$MCP_OFFICIAL_DIR/src/$server"
        
        if [[ ! -d "$server_path" ]]; then
            print_warning "Server $server not found in official repository"
            continue
        fi
        
        if [[ " ${NODE_SERVERS[@]} " =~ " $server " ]]; then
            if ! build_node_server "$server_path"; then
                failed_servers+=("$server")
            fi
        elif [[ " ${PYTHON_SERVERS[@]} " =~ " $server " ]]; then
            if ! build_python_server "$server_path"; then
                failed_servers+=("$server")
            fi
        fi
    done
    
    if [[ ${#failed_servers[@]} -gt 0 ]]; then
        print_warning "Failed to build servers: ${failed_servers[*]}"
    fi
    
    return 0
}

# Parse server info from format "name:url[:checksum]"
parse_server_info() {
    local server_info="$1"
    IFS=':' read -r server_name server_url server_checksum <<< "$server_info"
    
    # Handle URLs with colons (like https://)
    if [[ "$server_url" == "https" || "$server_url" == "http" ]]; then
        server_url="${server_url}:${server_checksum}"
        server_checksum=""
        # Check if there's another part that might be the actual checksum
        if [[ "$server_info" =~ ^[^:]+:https?://[^:]+:(.+)$ ]]; then
            server_checksum="${BASH_REMATCH[1]}"
        fi
    fi
    
    echo "$server_name|$server_url|$server_checksum"
}

# Install community MCP servers
install_community_servers() {
    print_section "Installing Community MCP Servers"
    
    mkdir -p "$MCP_COMMUNITY_DIR"
    
    local failed_servers=()
    for server_info in "${COMMUNITY_SERVERS[@]}"; do
        local parsed_info=$(parse_server_info "$server_info")
        IFS='|' read -r server_name server_url server_checksum <<< "$parsed_info"
        
        local server_path="$MCP_COMMUNITY_DIR/$server_name"
        
        if ! clone_or_update_repo "$server_url" "$server_path"; then
            print_error "Failed to clone/update $server_name"
            failed_servers+=("$server_name")
            continue
        fi
        
        # TODO: Add checksum verification when we have checksums
        
        # Detect and build based on project type
        if [[ -f "$server_path/package.json" ]]; then
            if ! build_node_server "$server_path"; then
                failed_servers+=("$server_name")
            fi
        elif [[ -f "$server_path/requirements.txt" ]] || [[ -f "$server_path/pyproject.toml" ]]; then
            if ! build_python_server "$server_path"; then
                failed_servers+=("$server_name")
            fi
        else
            print_warning "Unknown project type for $server_name"
        fi
    done
    
    if [[ ${#failed_servers[@]} -gt 0 ]]; then
        print_warning "Failed to install community servers: ${failed_servers[*]}"
    fi
    
    return 0
}

# Find the actual executable path for a server
find_server_executable() {
    local server_path="$1"
    local server_type="$2"  # node or python
    
    if [[ "$server_type" == "node" ]]; then
        # Check common Node.js build output paths
        for path in ${BUILD_PATHS["node"]}; do
            if [[ -f "$server_path/$path" ]]; then
                echo "$server_path/$path"
                return 0
            fi
        done
        
        # Fallback to finding any .js file
        local js_file=$(find "$server_path" -name "*.js" -type f | grep -E "(index|main|server)" | grep -v node_modules | head -1)
        if [[ -n "$js_file" ]]; then
            echo "$js_file"
            return 0
        fi
    elif [[ "$server_type" == "python" ]]; then
        # Check common Python entry points
        for path in ${BUILD_PATHS["python"]}; do
            if [[ -f "$server_path/$path" ]]; then
                echo "$server_path/$path"
                return 0
            fi
        done
    fi
    
    return 1
}

# Generate MCP server configuration
generate_server_config() {
    local server_name="$1"
    local server_path="$2"
    local server_type="node"  # Default to node
    
    # Detect server type
    if [[ -f "$server_path/requirements.txt" ]] || [[ -f "$server_path/pyproject.toml" ]]; then
        server_type="python"
    fi
    
    # Find executable
    local executable=$(find_server_executable "$server_path" "$server_type")
    if [[ -z "$executable" ]]; then
        print_warning "Could not find executable for $server_name"
        return 1
    fi
    
    # Generate config based on type
    if [[ "$server_type" == "node" ]]; then
        cat <<EOF
    "$server_name": {
      "command": "node",
      "args": ["$executable"],
      "cwd": "$server_path"
    }
EOF
    else
        cat <<EOF
    "$server_name": {
      "command": "$server_path/venv/bin/python",
      "args": ["$executable"],
      "cwd": "$server_path"
    }
EOF
    fi
}

# Configure Claude Desktop
configure_claude_desktop() {
    print_section "Configuring Claude Desktop"
    
    # Ensure Claude config directory exists
    mkdir -p "$CLAUDE_CONFIG_DIR"
    
    # Backup existing config
    if [[ -f "$CLAUDE_CONFIG_FILE" ]]; then
        mkdir -p "$BACKUP_DIR"
        cp "$CLAUDE_CONFIG_FILE" "$BACKUP_DIR/claude_desktop_config.json"
        print_info "Backed up existing config to $BACKUP_DIR"
    fi
    
    # Start building the configuration
    local config='{\n  "mcpServers": {\n'
    local server_configs=()
    
    # Add official servers
    for server in "${OFFICIAL_SERVERS[@]}"; do
        local server_path="$MCP_OFFICIAL_DIR/src/$server"
        if [[ -d "$server_path" ]]; then
            local server_config=$(generate_server_config "$server" "$server_path")
            if [[ -n "$server_config" ]]; then
                server_configs+=("$server_config")
            fi
        fi
    done
    
    # Add community servers
    for server_info in "${COMMUNITY_SERVERS[@]}"; do
        local parsed_info=$(parse_server_info "$server_info")
        IFS='|' read -r server_name server_url server_checksum <<< "$parsed_info"
        
        local server_path="$MCP_COMMUNITY_DIR/$server_name"
        if [[ -d "$server_path" ]]; then
            local server_config=$(generate_server_config "$server_name" "$server_path")
            if [[ -n "$server_config" ]]; then
                server_configs+=("$server_config")
            fi
        fi
    done
    
    # Join configs with commas
    local joined_configs=""
    for i in "${!server_configs[@]}"; do
        if [[ $i -eq 0 ]]; then
            joined_configs="${server_configs[$i]}"
        else
            joined_configs="${joined_configs},\n${server_configs[$i]}"
        fi
    done
    
    config="${config}${joined_configs}\n  }\n}"
    
    # Write the configuration
    echo -e "$config" > "$CLAUDE_CONFIG_FILE"
    print_success "Claude Desktop configured with MCP servers"
    
    # Handle Claude restart with timeout protection
    if pgrep -x "Claude" >/dev/null; then
        print_info "Restarting Claude Desktop to apply changes..."
        
        # Kill Claude with timeout
        timeout 5 osascript -e 'quit app "Claude"' 2>/dev/null || {
            print_warning "Could not gracefully quit Claude, forcing..."
            pkill -x "Claude" 2>/dev/null || true
        }
        
        # Wait for Claude to fully quit (with timeout)
        local wait_count=0
        while pgrep -x "Claude" >/dev/null && [[ $wait_count -lt 10 ]]; do
            sleep 1
            ((wait_count++))
        done
        
        # Reopen Claude
        open -a "Claude" 2>/dev/null || print_warning "Could not restart Claude automatically"
    fi
}

# Print usage information
print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --help     Show this help message"
    echo "  --check    Check MCP server status"
    echo "  --update   Update all MCP servers"
    echo "  --remove   Remove MCP configuration"
    echo ""
    echo "Environment Variables:"
    echo "  MCP_ROOT_DIR   Root directory for MCP servers (default: ~/repos/mcp-servers)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Install and configure MCP servers"
    echo "  $0 --check           # Check server status"
    echo "  $0 --update          # Update all servers"
}

# Check MCP server status
check_status() {
    print_section "MCP Server Status"
    
    # Check if config exists
    if [[ ! -f "$CLAUDE_CONFIG_FILE" ]]; then
        print_error "Claude Desktop config not found"
        return 1
    fi
    
    # Check official servers
    echo -e "\nOfficial Servers:"
    for server in "${OFFICIAL_SERVERS[@]}"; do
        local server_path="$MCP_OFFICIAL_DIR/src/$server"
        if [[ -d "$server_path" ]]; then
            # Check if it's in the config
            if grep -q "\"$server\"" "$CLAUDE_CONFIG_FILE" 2>/dev/null; then
                print_success "✓ $server (configured)"
            else
                print_warning "○ $server (installed but not configured)"
            fi
        else
            print_error "✗ $server (not installed)"
        fi
    done
    
    # Check community servers
    echo -e "\nCommunity Servers:"
    for server_info in "${COMMUNITY_SERVERS[@]}"; do
        local parsed_info=$(parse_server_info "$server_info")
        IFS='|' read -r server_name server_url server_checksum <<< "$parsed_info"
        
        local server_path="$MCP_COMMUNITY_DIR/$server_name"
        if [[ -d "$server_path" ]]; then
            if grep -q "\"$server_name\"" "$CLAUDE_CONFIG_FILE" 2>/dev/null; then
                print_success "✓ $server_name (configured)"
            else
                print_warning "○ $server_name (installed but not configured)"
            fi
        else
            print_error "✗ $server_name (not installed)"
        fi
    done
    
    # Show config location
    echo -e "\nConfiguration:"
    echo "  Config file: $CLAUDE_CONFIG_FILE"
    echo "  MCP root: $MCP_ROOT_DIR"
}

# Update all servers
update_servers() {
    print_section "Updating MCP Servers"
    
    # Update official servers
    if [[ -d "$MCP_OFFICIAL_DIR" ]]; then
        install_official_servers
    fi
    
    # Update community servers
    if [[ -d "$MCP_COMMUNITY_DIR" ]]; then
        install_community_servers
    fi
    
    # Reconfigure Claude Desktop
    configure_claude_desktop
}

# Remove MCP configuration
remove_configuration() {
    print_section "Removing MCP Configuration"
    
    # Backup current config
    if [[ -f "$CLAUDE_CONFIG_FILE" ]]; then
        mkdir -p "$BACKUP_DIR"
        cp "$CLAUDE_CONFIG_FILE" "$BACKUP_DIR/claude_desktop_config.json"
        print_info "Backed up config to $BACKUP_DIR"
        
        # Remove the config file
        rm -f "$CLAUDE_CONFIG_FILE"
        print_success "Removed Claude Desktop MCP configuration"
    else
        print_info "No configuration found to remove"
    fi
    
    # Note: We don't remove the actual server files
    print_info "Note: MCP server files in $MCP_ROOT_DIR were not removed"
}

# Main installation flow
main() {
    # Parse command line arguments
    case "${1:-}" in
        --help|-h)
            print_usage
            exit 0
            ;;
        --check)
            check_status
            exit 0
            ;;
        --update)
            check_macos
            check_prerequisites
            update_servers
            exit 0
            ;;
        --remove)
            remove_configuration
            exit 0
            ;;
        "")
            # Default: install
            ;;
        *)
            print_error "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
    
    # Full installation
    print_banner "Claude MCP Server Setup"
    
    check_macos
    check_prerequisites
    
    # Create directory structure
    mkdir -p "$MCP_OFFICIAL_DIR" "$MCP_COMMUNITY_DIR" "$MCP_CUSTOM_DIR"
    
    # Install servers
    install_official_servers
    install_community_servers
    
    # Configure Claude Desktop
    configure_claude_desktop
    
    print_section "Setup Complete!"
    echo ""
    echo "MCP servers have been installed and configured."
    echo ""
    echo "Installed servers:"
    echo "  Official: ${OFFICIAL_SERVERS[*]}"
    echo "  Community: $(for s in "${COMMUNITY_SERVERS[@]}"; do echo "$s" | cut -d: -f1; done | tr '\n' ' ')"
    echo ""
    echo "To check server status: $0 --check"
    echo "To update servers: $0 --update"
    echo ""
    print_success "You can now use MCP servers in Claude Desktop!"
}

# Run main function
main "$@"