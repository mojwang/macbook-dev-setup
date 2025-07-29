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

verify_repository_integrity() {
    local repo_dir="$1"
    local expected_checksum="$2"
    
    if [[ -z "$expected_checksum" ]]; then
        print_warning "No checksum provided for verification"
        return 0
    fi
    
    # Create a deterministic hash of repository content
    local actual_checksum
    actual_checksum=$(cd "$repo_dir" && git ls-tree -r HEAD | sha256sum | cut -d' ' -f1)
    
    if [[ "$actual_checksum" == "$expected_checksum" ]]; then
        print_success "Repository checksum verified"
        return 0
    else
        print_error "Repository checksum mismatch!"
        print_error "Expected: $expected_checksum"
        print_error "Actual: $actual_checksum"
        return 1
    fi
}

clone_community_servers() {
    print_step "Cloning community MCP servers..."
    
    local clone_pids=()
    local clone_servers=()
    local clone_urls=()
    local clone_checksums=()
    
    # Parse server configurations
    for server_config in "${COMMUNITY_SERVERS[@]}"; do
        # Parse server name, URL, and optional checksum
        local parts
        IFS=':' read -ra parts <<< "$server_config"
        local server_name="${parts[0]}"
        local server_url="${parts[1]}:${parts[2]}"
        local checksum="${parts[3]:-}"
        
        clone_servers+=("$server_name")
        clone_urls+=("$server_url")
        clone_checksums+=("$checksum")
    done
    
    # Clone servers in parallel
    for i in "${!clone_servers[@]}"; do
        local server_name="${clone_servers[$i]}"
        local server_url="${clone_urls[$i]}"
        local checksum="${clone_checksums[$i]}"
        local server_dir="$MCP_COMMUNITY_DIR/$server_name"
        
        (
            if [[ ! -d "$server_dir" ]]; then
                print_info "Cloning $server_name from $server_url..."
                if git clone "$server_url" "$server_dir" 2>/dev/null; then
                    if verify_repository_integrity "$server_dir" "$checksum"; then
                        print_success "Cloned and verified $server_name successfully"
                    else
                        print_warning "$server_name cloned but verification failed"
                    fi
                else
                    print_error "Failed to clone $server_name"
                fi
            else
                print_info "$server_name already exists, checking for updates..."
                
                # Check if repository is clean before pulling
                if (cd "$server_dir" && git diff --quiet && git diff --cached --quiet); then
                    print_info "Repository is clean, updating..."
                    if (cd "$server_dir" && git pull 2>/dev/null); then
                        verify_repository_integrity "$server_dir" "$checksum" || true
                    fi
                else
                    print_warning "Repository has uncommitted changes, skipping update"
                fi
            fi
        ) &
        
        clone_pids+=("$!")
    done
    
    # Wait for all clones to complete
    local failed=0
    for pid in "${clone_pids[@]}"; do
        if ! wait "$pid"; then
            ((failed++))
        fi
    done
    
    if [[ $failed -gt 0 ]]; then
        print_warning "$failed community servers failed to clone"
    else
        print_success "All community servers processed successfully"
    fi
}

verify_server_build() {
    local server_dir="$1"
    local server_type="$2"
    
    local paths="${BUILD_PATHS[$server_type]}"
    for path in $paths; do
        if [[ -f "$server_dir/$path" ]]; then
            print_success "Build artifact found: $path"
            return 0
        fi
    done
    
    print_error "No build artifacts found in $server_dir"
    return 1
}

install_server_node() {
    local server="$1"
    local server_dir="$2"
    
    print_info "Building $server server..."
    
    # Install dependencies
    if ! (cd "$server_dir" && npm install --silent 2>/dev/null); then
        print_error "Failed to install dependencies for $server server"
        return 1
    fi
    
    print_info "Dependencies installed for $server"
    
    # Build the server if build script exists
    if (cd "$server_dir" && npm run build 2>/dev/null); then
        print_success "Built $server server"
    else
        print_warning "No build script found for $server"
    fi
    
    # Verify build artifacts
    if verify_server_build "$server_dir" "node"; then
        return 0
    else
        return 1
    fi
}

install_server_python() {
    local server="$1"
    local server_dir="$2"
    
    print_info "Installing $server server dependencies..."
    
    if (cd "$server_dir" && uv sync 2>/dev/null); then
        print_success "Installed $server server dependencies"
        return 0
    else
        # Fallback to pip if uv fails
        print_warning "uv sync failed, trying pip install..."
        if [[ -f "$server_dir/requirements.txt" ]]; then
            if (cd "$server_dir" && pip install -r requirements.txt 2>/dev/null); then
                return 0
            fi
        elif [[ -f "$server_dir/pyproject.toml" ]]; then
            if (cd "$server_dir" && pip install -e . 2>/dev/null); then
                return 0
            fi
        fi
    fi
    
    print_error "Failed to install dependencies for $server"
    return 1
}

install_mcp_servers() {
    print_step "Building and installing MCP servers..."
    
    local install_pids=()
    local install_servers=()
    
    # Process Node.js servers in parallel
    for server in "${NODE_SERVERS[@]}"; do
        # Check official directory first
        local server_dir=""
        if [[ -d "$MCP_OFFICIAL_DIR/$server" ]]; then
            server_dir="$MCP_OFFICIAL_DIR/$server"
        elif [[ -d "$MCP_COMMUNITY_DIR/$server" ]]; then
            server_dir="$MCP_COMMUNITY_DIR/$server"
        fi
        
        if [[ -n "$server_dir" ]]; then
            (install_server_node "$server" "$server_dir") &
            install_pids+=("$!")
            install_servers+=("$server")
        else
            print_warning "Server directory not found for $server"
        fi
    done
    
    # Process Python servers in parallel
    for server in "${PYTHON_SERVERS[@]}"; do
        # Check official directory first
        local server_dir=""
        if [[ -d "$MCP_OFFICIAL_DIR/$server" ]]; then
            server_dir="$MCP_OFFICIAL_DIR/$server"
        elif [[ -d "$MCP_COMMUNITY_DIR/$server" ]]; then
            server_dir="$MCP_COMMUNITY_DIR/$server"
        fi
        
        if [[ -n "$server_dir" ]]; then
            (install_server_python "$server" "$server_dir") &
            install_pids+=("$!")
            install_servers+=("$server")
        else
            print_warning "Server directory not found for $server"
        fi
    done
    
    # Wait for all installations to complete
    local failed=0
    for i in "${!install_pids[@]}"; do
        if ! wait "${install_pids[$i]}"; then
            print_error "Failed to install ${install_servers[$i]}"
            ((failed++))
        fi
    done
    
    if [[ $failed -gt 0 ]]; then
        print_warning "$failed servers failed to install"
    else
        print_success "All servers installed successfully"
    fi
}

# Helper function for consistent JSON escaping
escape_json_path() {
    printf '%s' "$1" | sed 's/["\\/]/\\\\&/g'
}

# Helper function to find Node.js entry point
find_node_entry() {
    local server_dir="$1"
    local paths="${BUILD_PATHS[node]}"
    
    for path in $paths; do
        if [[ -f "$server_dir/$path" ]]; then
            echo "$server_dir/$path"
            return 0
        fi
    done
    return 1
}

# Configure individual servers
configure_node_server() {
    local name="$1"
    local server_dir="$2"
    
    local entry_point
    if entry_point=$(find_node_entry "$server_dir"); then
        print_info "Adding $name server..."
        if claude mcp add --scope user "$name" node "$entry_point"; then
            print_success "Added $name server"
            return 0
        else
            print_error "Failed to add $name server"
            return 1
        fi
    else
        print_warning "No entry point found for $name server"
        return 1
    fi
}

configure_python_server() {
    local name="$1"
    local server_dir="$2"
    local command="${3:-mcp-server-$name}"
    
    if [[ ! -d "$server_dir" ]]; then
        print_error "$name server directory not found: $server_dir"
        return 1
    fi
    
    print_info "Adding $name server..."
    local json_config
    json_config=$(printf '{"type": "stdio", "command": "uv", "args": ["--directory", "%s", "run", "%s"]}' \
        "$(escape_json_path "$server_dir")" "$command")
    
    if claude mcp add-json --scope user "$name" "$json_config"; then
        print_success "Added $name server"
        return 0
    else
        print_error "Failed to add $name server"
        return 1
    fi
}

configure_semgrep_server() {
    local server_dir="$MCP_COMMUNITY_DIR/semgrep"
    
    if [[ ! -d "$server_dir" ]]; then
        print_warning "Semgrep server directory not found"
        return 1
    fi
    
    print_info "Adding semgrep server..."
    local json_config
    
    # Check if it uses Python package setup
    if [[ -f "$server_dir/pyproject.toml" ]] || [[ -f "$server_dir/setup.py" ]]; then
        json_config=$(printf '{"type": "stdio", "command": "uv", "args": ["--directory", "%s", "run", "mcp-server-semgrep"]}' \
            "$(escape_json_path "$server_dir")")
    else
        # Fallback to direct Python execution
        local main_script=""
        for script in main.py src/main.py __main__.py; do
            if [[ -f "$server_dir/$script" ]]; then
                main_script="$script"
                break
            fi
        done
        
        if [[ -z "$main_script" ]]; then
            print_error "No main script found for semgrep server"
            return 1
        fi
        
        json_config=$(printf '{"type": "stdio", "command": "python", "args": ["%s/%s"]}' \
            "$(escape_json_path "$server_dir")" "$main_script")
    fi
    
    if claude mcp add-json --scope user semgrep "$json_config"; then
        print_success "Added semgrep server"
        return 0
    else
        print_error "Failed to add semgrep server"
        return 1
    fi
}

configure_claude_mcp() {
    print_step "Configuring Claude Code with MCP servers..."
    
    local failed=0
    
    # Configure official servers
    configure_node_server "filesystem" "$MCP_OFFICIAL_DIR/filesystem" || ((failed++))
    configure_node_server "memory" "$MCP_OFFICIAL_DIR/memory" || ((failed++))
    configure_python_server "git" "$MCP_OFFICIAL_DIR/git" || ((failed++))
    configure_python_server "fetch" "$MCP_OFFICIAL_DIR/fetch" || ((failed++))
    configure_python_server "sequentialthinking" "$MCP_OFFICIAL_DIR/sequentialthinking" || ((failed++))
    
    # Configure community servers
    configure_node_server "context7" "$MCP_COMMUNITY_DIR/context7" || ((failed++))
    configure_node_server "playwright" "$MCP_COMMUNITY_DIR/playwright" || ((failed++))
    configure_node_server "figma" "$MCP_COMMUNITY_DIR/figma" || ((failed++))
    configure_semgrep_server || ((failed++))
    configure_node_server "exa" "$MCP_COMMUNITY_DIR/exa" || ((failed++))
    
    # Note about Pieces MCP
    print_info "Note: Pieces MCP requires PiecesOS running locally."
    print_info "To configure Pieces, add the SSE endpoint manually:"
    print_info "  http://localhost:39300/model_context_protocol/2024-11-05/sse"
    
    if [[ $failed -gt 0 ]]; then
        print_warning "$failed servers failed to configure"
    else
        print_success "All MCP servers configured successfully"
    fi
}

verify_mcp_installation() {
    print_step "Verifying MCP installation..."
    
    # List configured servers
    print_info "Configured MCP servers:"
    if claude mcp list; then
        # Count connected servers
        local connected_count
        connected_count=$(claude mcp list | grep -c "✓ Connected" || echo "0")
        local configured_count
        configured_count=$(claude mcp list | grep -cE "(✓|✗)" || echo "0")
        
        if [[ $connected_count -gt 0 ]]; then
            print_success "$connected_count/$configured_count MCP servers connected successfully"
        else
            print_warning "MCP servers configured but none are connected"
        fi
    else
        print_error "Failed to list MCP servers"
        return 1
    fi
    
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