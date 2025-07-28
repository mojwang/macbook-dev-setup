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

# List of community servers to install
COMMUNITY_SERVERS=(
    "context7:https://github.com/upstash/context7-mcp.git"
    "playwright:https://github.com/microsoft/playwright-mcp.git"
    "figma:https://github.com/GLips/Figma-Context-MCP.git"
    "semgrep:https://github.com/semgrep/mcp.git"
    "exa:https://github.com/exa-labs/exa-mcp-server.git"
)

# Node.js servers that need npm build
NODE_SERVERS=(
    "filesystem"
    "memory"
    "context7"
    "playwright"
    "figma"
    "exa"
)

# Python servers that need uv
PYTHON_SERVERS=(
    "git"
    "fetch"
    "sequentialthinking"
    "semgrep"
)

setup_mcp_servers() {
    print_info "Setting up Claude Code MCP servers..."
    
    # Check prerequisites
    check_prerequisites
    
    # Create directory structure
    create_mcp_directories
    
    # Clone and install servers
    clone_mcp_repository
    clone_community_servers
    
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

clone_community_servers() {
    print_step "Cloning community MCP servers..."
    
    for server_config in "${COMMUNITY_SERVERS[@]}"; do
        # Parse server name and URL
        local server_name="${server_config%%:*}"
        local server_url="${server_config#*:}"
        local server_dir="$MCP_COMMUNITY_DIR/$server_name"
        
        print_info "Processing $server_name server..."
        
        if [[ ! -d "$server_dir" ]]; then
            print_info "Cloning $server_name from $server_url..."
            if git clone "$server_url" "$server_dir"; then
                print_success "Cloned $server_name successfully"
            else
                print_error "Failed to clone $server_name"
                continue
            fi
        else
            print_info "$server_name already exists, checking for updates..."
            
            # Check if repository is clean before pulling
            if (cd "$server_dir" && git diff --quiet && git diff --cached --quiet); then
                print_info "Repository is clean, updating..."
                (cd "$server_dir" && git pull)
            else
                print_warning "Repository has uncommitted changes, skipping update"
            fi
        fi
    done
    
    print_success "Community servers processed successfully"
}

install_mcp_servers() {
    print_step "Building and installing MCP servers..."
    
    # Install Node.js servers
    for server in "${NODE_SERVERS[@]}"; do
        # Check official directory first
        local server_dir=""
        if [[ -d "$MCP_OFFICIAL_DIR/$server" ]]; then
            server_dir="$MCP_OFFICIAL_DIR/$server"
        elif [[ -d "$MCP_COMMUNITY_DIR/$server" ]]; then
            server_dir="$MCP_COMMUNITY_DIR/$server"
        fi
        
        if [[ -n "$server_dir" ]]; then
            print_info "Building $server server..."
            
            # Install dependencies
            if (cd "$server_dir" && npm install --silent); then
                print_info "Dependencies installed for $server"
                
                # Build the server if build script exists
                if (cd "$server_dir" && npm run build 2>/dev/null); then
                    print_success "Built $server server"
                else
                    # Check if dist/index.js already exists (pre-built)
                    if [[ -f "$server_dir/dist/index.js" ]] || [[ -f "$server_dir/build/index.js" ]]; then
                        print_info "$server server appears to be pre-built"
                    else
                        print_warning "No build script found for $server, checking for entry point..."
                    fi
                fi
            else
                print_error "Failed to install dependencies for $server server"
            fi
        else
            print_warning "Server directory not found for $server"
        fi
    done
    
    # Install Python servers
    for server in "${PYTHON_SERVERS[@]}"; do
        # Check official directory first
        local server_dir=""
        if [[ -d "$MCP_OFFICIAL_DIR/$server" ]]; then
            server_dir="$MCP_OFFICIAL_DIR/$server"
        elif [[ -d "$MCP_COMMUNITY_DIR/$server" ]]; then
            server_dir="$MCP_COMMUNITY_DIR/$server"
        fi
        
        if [[ -n "$server_dir" ]]; then
            print_info "Installing $server server dependencies..."
            if (cd "$server_dir" && uv sync); then
                print_success "Installed $server server dependencies"
            else
                # Fallback to pip if uv fails
                print_warning "uv sync failed, trying pip install..."
                if [[ -f "$server_dir/requirements.txt" ]]; then
                    (cd "$server_dir" && pip install -r requirements.txt)
                elif [[ -f "$server_dir/pyproject.toml" ]]; then
                    (cd "$server_dir" && pip install -e .)
                fi
            fi
        else
            print_warning "Server directory not found for $server"
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
    
    # Add sequential thinking server
    if [[ -d "$MCP_OFFICIAL_DIR/sequentialthinking" ]]; then
        print_info "Adding sequential thinking server..."
        local seq_json
        seq_json=$(printf '{"type": "stdio", "command": "uv", "args": ["--directory", "%s", "run", "mcp-server-sequentialthinking"]}' \
            "$(printf '%s' "$MCP_OFFICIAL_DIR/sequentialthinking" | sed 's/["\\/]/\\\\&/g')")
        
        claude mcp add-json --scope user sequentialthinking "$seq_json" || true
    fi
    
    # Add context7 server
    if [[ -f "$MCP_COMMUNITY_DIR/context7/dist/index.js" ]] || [[ -f "$MCP_COMMUNITY_DIR/context7/build/index.js" ]]; then
        print_info "Adding context7 server..."
        local context7_path=""
        if [[ -f "$MCP_COMMUNITY_DIR/context7/dist/index.js" ]]; then
            context7_path="$MCP_COMMUNITY_DIR/context7/dist/index.js"
        else
            context7_path="$MCP_COMMUNITY_DIR/context7/build/index.js"
        fi
        claude mcp add --scope user context7 node "$context7_path" || true
    fi
    
    # Add playwright server
    if [[ -f "$MCP_COMMUNITY_DIR/playwright/dist/index.js" ]] || [[ -f "$MCP_COMMUNITY_DIR/playwright/build/index.js" ]]; then
        print_info "Adding playwright server..."
        local playwright_path=""
        if [[ -f "$MCP_COMMUNITY_DIR/playwright/dist/index.js" ]]; then
            playwright_path="$MCP_COMMUNITY_DIR/playwright/dist/index.js"
        else
            playwright_path="$MCP_COMMUNITY_DIR/playwright/build/index.js"
        fi
        claude mcp add --scope user playwright node "$playwright_path" || true
    fi
    
    # Add figma server
    if [[ -f "$MCP_COMMUNITY_DIR/figma/dist/index.js" ]] || [[ -f "$MCP_COMMUNITY_DIR/figma/build/index.js" ]]; then
        print_info "Adding figma server..."
        local figma_path=""
        if [[ -f "$MCP_COMMUNITY_DIR/figma/dist/index.js" ]]; then
            figma_path="$MCP_COMMUNITY_DIR/figma/dist/index.js"
        else
            figma_path="$MCP_COMMUNITY_DIR/figma/build/index.js"
        fi
        claude mcp add --scope user figma node "$figma_path" || true
    fi
    
    # Add semgrep server
    if [[ -d "$MCP_COMMUNITY_DIR/semgrep" ]]; then
        print_info "Adding semgrep server..."
        local semgrep_json
        # Check if it uses Python entry point
        if [[ -f "$MCP_COMMUNITY_DIR/semgrep/pyproject.toml" ]] || [[ -f "$MCP_COMMUNITY_DIR/semgrep/setup.py" ]]; then
            semgrep_json=$(printf '{"type": "stdio", "command": "uv", "args": ["--directory", "%s", "run", "mcp-server-semgrep"]}' \
                "$(printf '%s' "$MCP_COMMUNITY_DIR/semgrep" | sed 's/["\\/]/\\\\&/g')")
        else
            # Fallback to python command
            semgrep_json=$(printf '{"type": "stdio", "command": "python", "args": ["%s/main.py"]}' \
                "$(printf '%s' "$MCP_COMMUNITY_DIR/semgrep" | sed 's/["\\/]/\\\\&/g')")
        fi
        
        claude mcp add-json --scope user semgrep "$semgrep_json" || true
    fi
    
    # Add exa server
    if [[ -f "$MCP_COMMUNITY_DIR/exa/dist/index.js" ]] || [[ -f "$MCP_COMMUNITY_DIR/exa/build/index.js" ]]; then
        print_info "Adding exa server..."
        local exa_path=""
        if [[ -f "$MCP_COMMUNITY_DIR/exa/dist/index.js" ]]; then
            exa_path="$MCP_COMMUNITY_DIR/exa/dist/index.js"
        else
            exa_path="$MCP_COMMUNITY_DIR/exa/build/index.js"
        fi
        claude mcp add --scope user exa node "$exa_path" || true
    fi
    
    # Note about Pieces MCP
    print_info "Note: Pieces MCP requires PiecesOS running locally."
    print_info "To configure Pieces, add the SSE endpoint manually:"
    print_info "  http://localhost:39300/model_context_protocol/2024-11-05/sse"
    
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
    Official servers:
    - filesystem: Secure file operations with access controls
    - memory: In-memory key-value storage for temporary data
    - git: Tools to read, search, and manipulate Git repositories
    - fetch: Web content fetching and conversion
    - sequentialthinking: Dynamic problem-solving through thought sequences
    
    Community servers:
    - context7: Up-to-date documentation for any library/framework
    - playwright: Browser automation and web scraping
    - figma: Access Figma design data for AI coding tools
    - semgrep: Security scanning and code analysis
    - exa: AI-optimized search engine integration
    
    Note: Pieces MCP requires PiecesOS running locally

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
        # Remove official servers
        for server in "${OFFICIAL_SERVERS[@]}"; do
            claude mcp remove --scope user "$server" 2>/dev/null || true
        done
        # Remove community servers
        for server_config in "${COMMUNITY_SERVERS[@]}"; do
            local server_name="${server_config%%:*}"
            claude mcp remove --scope user "$server_name" 2>/dev/null || true
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