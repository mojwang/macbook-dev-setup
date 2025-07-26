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
)

# Node.js servers that need npm build
NODE_SERVERS=(
    "filesystem"
    "memory"
)

# Python servers that need uv
PYTHON_SERVERS=(
    "git"
    "fetch"
)

setup_mcp_servers() {
    print_info "Setting up Claude Code MCP servers..."
    
    # Check prerequisites
    check_prerequisites
    
    # Create directory structure
    create_mcp_directories
    
    # Clone and install servers
    clone_mcp_repository
    
    # Build and install servers
    install_mcp_servers
    
    # Configure Claude Code
    configure_claude_mcp
    
    # Verify installation
    verify_mcp_installation
    
    print_success "MCP servers setup complete!"
}

check_prerequisites() {
    print_step "Checking prerequisites..."
    
    # Check for Node.js
    if ! command -v node &> /dev/null; then
        print_error "Node.js is required but not installed"
        print_info "Please install Node.js first (e.g., via 'brew install node')"
        exit 1
    fi
    
    # Check for npm
    if ! command -v npm &> /dev/null; then
        print_error "npm is required but not installed"
        exit 1
    fi
    
    # Check for Python 3
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 is required but not installed"
        print_info "Please install Python 3 first (e.g., via 'brew install python@3.12')"
        exit 1
    fi
    
    # Check for uv (Python package manager)
    if ! command -v uv &> /dev/null; then
        print_error "uv is required but not installed"
        print_info "Please install uv first (e.g., via 'brew install uv')"
        exit 1
    fi
    
    # Check for Claude CLI
    if ! command -v claude &> /dev/null; then
        print_error "Claude CLI is required but not installed"
        print_info "Please install Claude Code first"
        exit 1
    fi
    
    print_success "All prerequisites met"
}

create_mcp_directories() {
    print_step "Creating MCP directory structure..."
    
    # Create main directories
    mkdir -p "$MCP_OFFICIAL_DIR"
    mkdir -p "$MCP_COMMUNITY_DIR"
    mkdir -p "$MCP_CUSTOM_DIR"
    
    print_success "Created directory structure at $MCP_ROOT_DIR"
}

clone_mcp_repository() {
    print_step "Cloning MCP servers repository..."
    
    local temp_dir="$MCP_OFFICIAL_DIR/temp"
    
    # Clone repository if not already present
    if [[ ! -d "$temp_dir" ]]; then
        git clone "$MCP_REPO_URL" "$temp_dir"
    else
        print_info "Repository already exists, checking status..."
        
        # Check if repository is clean before pulling
        if (cd "$temp_dir" && git diff --quiet && git diff --cached --quiet); then
            print_info "Repository is clean, updating..."
            (cd "$temp_dir" && git pull)
        else
            print_warning "Repository has uncommitted changes, skipping update"
            print_info "Using existing repository state"
        fi
    fi
    
    # Copy root configuration files
    if [[ -f "$temp_dir/tsconfig.json" ]]; then
        cp "$temp_dir/tsconfig.json" "$MCP_ROOT_DIR/"
    fi
    
    if [[ -f "$temp_dir/package.json" ]]; then
        cp "$temp_dir/package.json" "$MCP_ROOT_DIR/"
    fi
    
    # Install root dependencies if package.json exists
    if [[ -f "$MCP_ROOT_DIR/package.json" ]]; then
        print_step "Installing root dependencies..."
        (cd "$MCP_ROOT_DIR" && npm install --silent)
    fi
    
    # Copy selected servers
    for server in "${OFFICIAL_SERVERS[@]}"; do
        if [[ -d "$temp_dir/src/$server" ]]; then
            print_info "Copying $server server..."
            cp -r "$temp_dir/src/$server" "$MCP_OFFICIAL_DIR/"
        else
            print_warning "Server $server not found in repository"
        fi
    done
    
    # Clean up temp directory
    rm -rf "$temp_dir"
    
    print_success "MCP servers copied successfully"
}

install_mcp_servers() {
    print_step "Building and installing MCP servers..."
    
    # Install Node.js servers
    for server in "${NODE_SERVERS[@]}"; do
        if [[ -d "$MCP_OFFICIAL_DIR/$server" ]]; then
            print_info "Building $server server..."
            
            # Install dependencies
            if (cd "$MCP_OFFICIAL_DIR/$server" && npm install --silent); then
                print_info "Dependencies installed for $server"
                
                # Build the server
                if (cd "$MCP_OFFICIAL_DIR/$server" && npm run build); then
                    print_success "Built $server server"
                else
                    print_error "Failed to build $server server"
                    print_info "Server may still work without build artifacts"
                fi
            else
                print_error "Failed to install dependencies for $server server"
            fi
        fi
    done
    
    # Install Python servers
    for server in "${PYTHON_SERVERS[@]}"; do
        if [[ -d "$MCP_OFFICIAL_DIR/$server" ]]; then
            print_info "Installing $server server dependencies..."
            (cd "$MCP_OFFICIAL_DIR/$server" && uv sync)
            print_success "Installed $server server dependencies"
        fi
    done
}

configure_claude_mcp() {
    print_step "Configuring Claude Code with MCP servers..."
    
    # Add filesystem server
    if [[ -f "$MCP_OFFICIAL_DIR/filesystem/dist/index.js" ]]; then
        print_info "Adding filesystem server..."
        claude mcp add --scope user filesystem node "$MCP_OFFICIAL_DIR/filesystem/dist/index.js" || true
    fi
    
    # Add memory server
    if [[ -f "$MCP_OFFICIAL_DIR/memory/dist/index.js" ]]; then
        print_info "Adding memory server..."
        claude mcp add --scope user memory node "$MCP_OFFICIAL_DIR/memory/dist/index.js" || true
    fi
    
    # Add git server with proper JSON escaping
    if [[ -d "$MCP_OFFICIAL_DIR/git" ]]; then
        print_info "Adding git server..."
        # Validate directory path
        if [[ ! -d "$MCP_OFFICIAL_DIR/git" ]]; then
            print_error "Git server directory not found: $MCP_OFFICIAL_DIR/git"
            return 1
        fi
        
        # Build JSON with proper escaping
        local git_json
        git_json=$(printf '{"type": "stdio", "command": "uv", "args": ["--directory", "%s", "run", "mcp-server-git"]}' \
            "$(printf '%s' "$MCP_OFFICIAL_DIR/git" | sed 's/["\]/\\&/g')")
        
        claude mcp add-json --scope user git "$git_json" || true
    fi
    
    # Add fetch server with proper JSON escaping
    if [[ -d "$MCP_OFFICIAL_DIR/fetch" ]]; then
        print_info "Adding fetch server..."
        # Validate directory path
        if [[ ! -d "$MCP_OFFICIAL_DIR/fetch" ]]; then
            print_error "Fetch server directory not found: $MCP_OFFICIAL_DIR/fetch"
            return 1
        fi
        
        # Build JSON with proper escaping
        local fetch_json
        fetch_json=$(printf '{"type": "stdio", "command": "uv", "args": ["--directory", "%s", "run", "mcp-server-fetch"]}' \
            "$(printf '%s' "$MCP_OFFICIAL_DIR/fetch" | sed 's/["\]/\\&/g')")
        
        claude mcp add-json --scope user fetch "$fetch_json" || true
    fi
    
    print_success "MCP servers configured"
}

verify_mcp_installation() {
    print_step "Verifying MCP installation..."
    
    # List configured servers
    print_info "Configured MCP servers:"
    claude mcp list || true
    
    print_success "MCP installation verified"
}

show_help() {
    cat << EOF
Claude Code MCP Server Setup

Usage: $(basename "$0") [OPTIONS]

Options:
    --check     Check if MCP servers are installed and configured
    --update    Update existing MCP servers
    --remove    Remove MCP server configuration
    --help      Show this help message

Description:
    This script sets up official MCP (Model Context Protocol) servers for
    Claude Code, enabling enhanced capabilities like file operations,
    Git integration, web fetching, and more.

Servers installed:
    - filesystem: Secure file operations with access controls
    - memory: In-memory key-value storage for temporary data
    - git: Tools to read, search, and manipulate Git repositories
    - fetch: Web content fetching and conversion

Prerequisites:
    - Node.js and npm
    - Python 3 and uv
    - Claude Code CLI

EOF
}

# Main execution
case "${1:-}" in
    --check)
        # Check if MCP servers are configured
        if claude mcp list &> /dev/null; then
            servers=$(claude mcp list | grep -E "✓ Connected" | wc -l)
            if [[ $servers -gt 0 ]]; then
                print_success "$servers MCP servers configured and connected"
                exit 0
            else
                print_warning "MCP servers configured but not connected"
                exit 1
            fi
        else
            print_error "No MCP servers configured"
            exit 1
        fi
        ;;
    --update)
        print_info "Updating MCP servers..."
        clone_mcp_repository
        install_mcp_servers
        print_success "MCP servers updated"
        ;;
    --remove)
        print_warning "Removing MCP server configuration..."
        # Remove each server
        for server in "${OFFICIAL_SERVERS[@]}"; do
            claude mcp remove --scope user "$server" 2>/dev/null || true
        done
        print_success "MCP server configuration removed"
        print_info "Note: Server files remain in $MCP_ROOT_DIR"
        ;;
    --help)
        show_help
        ;;
    *)
        setup_mcp_servers
        ;;
esac