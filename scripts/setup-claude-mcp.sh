#!/usr/bin/env bash

# Setup Claude Code MCP (Model Context Protocol) servers
# Installs and configures official MCP servers for global use

set -e

# Load common library
source "$(dirname "$0")/../lib/common.sh"

# Load signal safety library
# ROOT_DIR is already set by common.sh
source "$ROOT_DIR/lib/signal-safety.sh"

# MCP-specific cleanup function
cleanup_mcp() {
    print_info "Cleaning up MCP installation..."
    
    # Clean up any npm build directories
    if [[ -n "${MCP_ROOT_DIR:-}" ]]; then
        find "$MCP_ROOT_DIR" -name "node_modules" -type d -prune -exec rm -rf {} \; 2>/dev/null || true
        find "$MCP_ROOT_DIR" -name ".npm" -type d -prune -exec rm -rf {} \; 2>/dev/null || true
    fi
    
    # Clean up any Python virtual environments
    if [[ -n "${MCP_ROOT_DIR:-}" ]]; then
        find "$MCP_ROOT_DIR" -name "venv" -type d -prune -exec rm -rf {} \; 2>/dev/null || true
        find "$MCP_ROOT_DIR" -name "__pycache__" -type d -prune -exec rm -rf {} \; 2>/dev/null || true
    fi
    
    # Remove partial installations
    if [[ -n "${CLAUDE_CONFIG_FILE:-}" ]] && [[ -f "${CLAUDE_CONFIG_FILE}.tmp" ]]; then
        rm -f "${CLAUDE_CONFIG_FILE}.tmp" 2>/dev/null || true
    fi
    
    # Call default cleanup
    default_cleanup
}

# Set up cleanup trap
setup_cleanup "cleanup_mcp"

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

# Function to get build paths for a server type
get_build_paths() {
    local server_type="$1"
    case "$server_type" in
        node)
            echo "dist/index.js build/index.js index.js"
            ;;
        python)
            echo "__main__.py main.py src/main.py"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Node.js servers that need npm build
NODE_SERVERS=(
    "filesystem"
    "memory"
    "sequentialthinking"
    "context7"
    "playwright"
    "figma"
    "exa"
)

# Python servers that need package build
PYTHON_SERVERS=(
    "git"
    "fetch"
    "semgrep"
)

# Servers that require API keys
# Using regular arrays for compatibility
SERVER_NAMES_WITH_KEYS=("exa" "figma")
SERVER_KEY_NAMES=("EXA_API_KEY" "FIGMA_API_KEY")

# API key file location
API_KEYS_FILE="$HOME/.config/zsh/51-api-keys.zsh"

# Claude Desktop config path
CLAUDE_CONFIG_DIR="$HOME/Library/Application Support/Claude"
CLAUDE_CONFIG_FILE="$CLAUDE_CONFIG_DIR/claude_desktop_config.json"

# Backup directory
BACKUP_ROOT="${BACKUP_ROOT:-$HOME/.setup-backups}"
BACKUP_DIR="$BACKUP_ROOT/configs/claude-mcp/$(date +%Y%m%d-%H%M%S)"

# Load existing API keys if available
load_api_keys() {
    if [[ -f "$API_KEYS_FILE" ]]; then
        # Source the file to load API keys into environment
        source "$API_KEYS_FILE" 2>/dev/null || true
    fi
}

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

# Check if an API key is already set
check_api_key() {
    local key_name="$1"
    
    # Check environment variable
    if [[ -n "${!key_name}" ]]; then
        return 0
    fi
    
    # Check API keys file
    if [[ -f "$API_KEYS_FILE" ]] && grep -q "export ${key_name}=" "$API_KEYS_FILE" 2>/dev/null; then
        local key_value=$(grep "export ${key_name}=" "$API_KEYS_FILE" | sed -E 's/.*="(.*)".*/\1/')
        if [[ -n "$key_value" && "$key_value" != "\${${key_name}:-}" ]]; then
            return 0
        fi
    fi
    
    return 1
}

# Prompt for API key
prompt_for_api_key() {
    local server_name="$1"
    local key_name="$2"
    local api_key=""
    
    print_info "The $server_name server requires an API key."
    
    case "$server_name" in
        "exa")
            echo "  Get your API key from: https://dashboard.exa.ai/api-keys"
            ;;
        "figma")
            echo "  Get your API key from: https://www.figma.com/developers/api#access-tokens"
            ;;
    esac
    
    echo -n "Enter your $server_name API key (or press Enter to skip): "
    read -r api_key
    
    if [[ -n "$api_key" ]]; then
        save_api_key "$key_name" "$api_key"
        export "$key_name=$api_key"
        return 0
    else
        print_warning "Skipping $server_name configuration (no API key provided)"
        return 1
    fi
}

# Save API key to file
save_api_key() {
    local key_name="$1"
    local key_value="$2"
    
    # Basic validation - API keys should not contain quotes or shell special chars
    if [[ "$key_value" =~ [\"\'\\$\`] ]]; then
        print_error "API key contains invalid characters"
        return 1
    fi
    
    # Ensure the directory exists
    mkdir -p "$(dirname "$API_KEYS_FILE")"
    
    # Create the file if it doesn't exist with proper permissions
    if [[ ! -f "$API_KEYS_FILE" ]]; then
        cat > "$API_KEYS_FILE" << 'EOF'
# API Keys and Tokens
# This file is managed by the setup scripts
# Manual edits are preserved

EOF
        # Set restrictive permissions (user read/write only)
        chmod 600 "$API_KEYS_FILE"
    fi
    
    # Check if the key already exists
    if grep -q "^export ${key_name}=" "$API_KEYS_FILE" 2>/dev/null; then
        # Update existing key using a more robust method
        local temp_file="${API_KEYS_FILE}.tmp"
        grep -v "^export ${key_name}=" "$API_KEYS_FILE" > "$temp_file"
        echo "export ${key_name}=\"${key_value}\"" >> "$temp_file"
        mv "$temp_file" "$API_KEYS_FILE"
        print_success "Updated $key_name in $API_KEYS_FILE"
    else
        # Add new key
        echo "export ${key_name}=\"${key_value}\"" >> "$API_KEYS_FILE"
        print_success "Added $key_name to $API_KEYS_FILE"
    fi
}

# Get API key name for a server
get_api_key_name() {
    local server_name="$1"
    for i in "${!SERVER_NAMES_WITH_KEYS[@]}"; do
        if [[ "${SERVER_NAMES_WITH_KEYS[$i]}" == "$server_name" ]]; then
            echo "${SERVER_KEY_NAMES[$i]}"
            return 0
        fi
    done
    return 1
}

# Configure API keys for servers that need them
configure_api_keys() {
    local server_name="$1"
    
    # Check if this server needs an API key
    local key_name=$(get_api_key_name "$server_name")
    if [[ -n "$key_name" ]]; then
        # Check if key already exists
        if check_api_key "$key_name"; then
            print_info "$server_name API key already configured"
            return 0
        else
            # Prompt for the key
            if prompt_for_api_key "$server_name" "$key_name"; then
                return 0
            else
                return 1
            fi
        fi
    fi
    
    return 0
}

# Build Node.js server
build_node_server() {
    local server_path="$1"
    local server_name=$(basename "$server_path")
    
    # Skip building npx-based servers
    local server_type="${MCP_SERVER_TYPES[$server_name]}"
    if [[ "$server_type" == "npx" ]]; then
        print_info "Skipping build for $server_name (npx-based server)"
        return 0
    fi
    
    print_info "Building $server_name..."
    cd "$server_path" || return 1
    
    # Initialize npm non-interactively
    init_npm_noninteractive "$server_path"
    
    # Install dependencies with timeout
    local npm_timeout=120
    if command -v gtimeout &>/dev/null; then
        gtimeout ${npm_timeout}s npm install --no-audit --no-fund >/dev/null 2>&1 || {
            print_error "npm install failed or timed out for $server_name"
            return 1
        }
    else
        npm install --no-audit --no-fund >/dev/null 2>&1 || {
            print_error "npm install failed for $server_name"
            return 1
        }
    fi
    
    # Build if build script exists (with timeout)
    if grep -q '"build"' package.json 2>/dev/null; then
        local build_timeout=60
        if command -v gtimeout &>/dev/null; then
            gtimeout ${build_timeout}s npm run build >/dev/null 2>&1 || {
                print_warning "Build failed or timed out for $server_name, continuing anyway..."
            }
        else
            npm run build >/dev/null 2>&1 || {
                print_warning "Build failed for $server_name, continuing anyway..."
            }
        fi
    fi
    
    return 0
}

# Build Python server
build_python_server() {
    local server_path="$1"
    local server_name=$(basename "$server_path")
    
    print_info "Building Python server $server_name..."
    cd "$server_path" || return 1
    
    # Use uv for Python dependency management
    if command -v uv &>/dev/null; then
        # For servers with pyproject.toml, use uv sync
        if [[ -f "pyproject.toml" ]]; then
            uv sync >/dev/null 2>&1 || {
                print_warning "uv sync failed for $server_name, trying pip fallback..."
                # Fallback to traditional venv approach
                if [[ ! -d "venv" ]]; then
                    python3 -m venv venv >/dev/null 2>&1
                fi
                if [[ -f "requirements.txt" ]]; then
                    ./venv/bin/pip install -r requirements.txt >/dev/null 2>&1
                fi
            }
        else
            # For servers with only requirements.txt, use traditional approach
            if [[ ! -d "venv" ]]; then
                python3 -m venv venv >/dev/null 2>&1
            fi
            if [[ -f "requirements.txt" ]]; then
                ./venv/bin/pip install -r requirements.txt >/dev/null 2>&1
            fi
        fi
    else
        # Fallback if uv is not available
        if [[ ! -d "venv" ]]; then
            python3 -m venv venv >/dev/null 2>&1
        fi
        if [[ -f "requirements.txt" ]]; then
            ./venv/bin/pip install -r requirements.txt >/dev/null 2>&1
        fi
    fi
    
    return 0
}

# Install official MCP servers
install_official_servers() {
    print_info "Installing Official MCP Servers"
    
    # Check if we need to reorganize the directory structure
    if [[ -d "$MCP_OFFICIAL_DIR" ]] && [[ ! -d "$MCP_OFFICIAL_DIR/.git" ]]; then
        # Looks like individual server directories, not the full repo
        print_info "Official servers already installed individually"
    else
        # Clone or update the official servers repository
        if ! clone_or_update_repo "$MCP_REPO_URL" "$MCP_OFFICIAL_DIR"; then
            print_error "Failed to clone/update official MCP servers"
            return 1
        fi
    fi
    
    # Build each server
    local failed_servers=()
    for server in "${OFFICIAL_SERVERS[@]}"; do
        local server_path=""
        
        # Check both possible locations (some repos have src/, some don't)
        if [[ -d "$MCP_OFFICIAL_DIR/src/$server" ]]; then
            server_path="$MCP_OFFICIAL_DIR/src/$server"
        elif [[ -d "$MCP_OFFICIAL_DIR/$server" ]]; then
            server_path="$MCP_OFFICIAL_DIR/$server"
        else
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
    print_info "Installing Community MCP Servers"
    
    mkdir -p "$MCP_COMMUNITY_DIR"
    
    local failed_servers=()
    for server_info in "${COMMUNITY_SERVERS[@]}"; do
        local parsed_info=$(parse_server_info "$server_info")
        IFS='|' read -r server_name server_url server_checksum <<< "$parsed_info"
        
        # Skip cloning for npx-based servers
        local server_type="${MCP_SERVER_TYPES[$server_name]}"
        if [[ "$server_type" == "npx" ]]; then
            print_info "$server_name is an npx-based server, skipping clone"
            # Configure API keys if needed
            configure_api_keys "$server_name"
            continue
        fi
        
        local server_path="$MCP_COMMUNITY_DIR/$server_name"
        
        if ! clone_or_update_repo "$server_url" "$server_path"; then
            print_error "Failed to clone/update $server_name"
            failed_servers+=("$server_name")
            continue
        fi
        
        # TODO: Add checksum verification when we have checksums
        
        # Configure API keys if needed
        configure_api_keys "$server_name"
        
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
        for path in $(get_build_paths node); do
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
        for path in $(get_build_paths python); do
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
    
    # Use the shared function from common.sh
    generate_mcp_server_config "$server_name"
}

# Configure Claude Desktop
configure_claude_desktop() {
    print_info "Configuring Claude Desktop"
    
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
    
    # Get all available servers
    local all_servers=("${OFFICIAL_SERVERS[@]}" $(for s in "${COMMUNITY_SERVERS[@]}"; do echo "$s" | cut -d: -f1; done))
    
    # Generate configs for each server
    for server in "${all_servers[@]}"; do
        if is_mcp_server_installed "$server"; then
            local server_config=$(generate_mcp_server_config "$server")
            if [[ -n "$server_config" ]]; then
                server_configs+=("$server_config")
            else
                print_warning "Could not configure $server"
            fi
        else
            print_warning "Server $server is not installed"
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
    
    # Validate JSON configuration before writing
    if ! echo -e "$config" | python3 -m json.tool >/dev/null 2>&1; then
        print_error "Generated configuration is not valid JSON"
        print_info "Debug output:"
        echo -e "$config"
        return 1
    fi
    
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
    print_info "MCP Server Status"
    
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
        
        # Check server type
        local server_type="${MCP_SERVER_TYPES[$server_name]}"
        
        if [[ "$server_type" == "npx" ]]; then
            # For npx servers, just check if they're configured
            if grep -q "\"$server_name\"" "$CLAUDE_CONFIG_FILE" 2>/dev/null; then
                print_success "✓ $server_name (npx-based, configured)"
            else
                print_warning "○ $server_name (npx-based, not configured)"
            fi
        else
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
        fi
    done
    
    # Show config location
    echo -e "\nConfiguration:"
    echo "  Config file: $CLAUDE_CONFIG_FILE"
    echo "  MCP root: $MCP_ROOT_DIR"
}

# Update all servers
update_servers() {
    print_info "Updating MCP Servers"
    echo ""
    
    # Load existing API keys
    load_api_keys
    
    # Track update results
    local updated_servers=()
    local failed_servers=()
    
    # Update official servers
    if [[ -d "$MCP_OFFICIAL_DIR" ]]; then
        print_info "Updating official servers repository..."
        cd "$MCP_OFFICIAL_DIR"
        
        # Stash any local changes
        if git diff --quiet && git diff --cached --quiet; then
            git pull --rebase origin main 2>/dev/null || git pull --rebase origin master 2>/dev/null || {
                print_warning "Failed to update official servers repository"
            }
        else
            print_warning "Local changes detected in official servers, skipping git pull"
        fi
        
        # Rebuild official servers
        for server in "${OFFICIAL_SERVERS[@]}"; do
            local server_path=""
            if [[ -d "$MCP_OFFICIAL_DIR/src/$server" ]]; then
                server_path="$MCP_OFFICIAL_DIR/src/$server"
            elif [[ -d "$MCP_OFFICIAL_DIR/$server" ]]; then
                server_path="$MCP_OFFICIAL_DIR/$server"
            else
                continue
            fi
            
            print_info "Updating $server..."
            if [[ " ${NODE_SERVERS[@]} " =~ " $server " ]]; then
                if build_node_server "$server_path"; then
                    updated_servers+=("$server")
                else
                    failed_servers+=("$server")
                fi
            elif [[ " ${PYTHON_SERVERS[@]} " =~ " $server " ]]; then
                if build_python_server "$server_path"; then
                    updated_servers+=("$server")
                else
                    failed_servers+=("$server")
                fi
            fi
        done
    fi
    
    # Update community servers
    if [[ -d "$MCP_COMMUNITY_DIR" ]]; then
        print_info "Updating community servers..."
        for server_info in "${COMMUNITY_SERVERS[@]}"; do
            local parsed_info=$(parse_server_info "$server_info")
            IFS='|' read -r server_name server_url server_checksum <<< "$parsed_info"
            
            # Skip updating npx-based servers
            local server_type="${MCP_SERVER_TYPES[$server_name]}"
            if [[ "$server_type" == "npx" ]]; then
                print_info "$server_name is an npx-based server, no update needed"
                # Just check API keys
                configure_api_keys "$server_name"
                updated_servers+=("$server_name")
                continue
            fi
            
            local server_path="$MCP_COMMUNITY_DIR/$server_name"
            if [[ -d "$server_path" ]]; then
                print_info "Updating $server_name..."
                if clone_or_update_repo "$server_url" "$server_path"; then
                    # Configure API keys if needed
                    configure_api_keys "$server_name"
                    
                    # Rebuild the server
                    if [[ -f "$server_path/package.json" ]]; then
                        if build_node_server "$server_path"; then
                            updated_servers+=("$server_name")
                        else
                            failed_servers+=("$server_name")
                        fi
                    elif [[ -f "$server_path/requirements.txt" ]] || [[ -f "$server_path/pyproject.toml" ]]; then
                        if build_python_server "$server_path"; then
                            updated_servers+=("$server_name")
                        else
                            failed_servers+=("$server_name")
                        fi
                    fi
                else
                    failed_servers+=("$server_name")
                fi
            fi
        done
    fi
    
    # Show update results
    echo ""
    if [[ ${#updated_servers[@]} -gt 0 ]]; then
        print_success "Successfully updated servers: ${updated_servers[*]}"
    fi
    if [[ ${#failed_servers[@]} -gt 0 ]]; then
        print_warning "Failed to update servers: ${failed_servers[*]}"
    fi
    
    # Reconfigure Claude Desktop
    echo ""
    configure_claude_desktop
}

# Remove MCP configuration
remove_configuration() {
    print_info "Removing MCP Configuration"
    
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
    echo -e "\n========================================="
    echo "Claude MCP Server Setup"
    echo "========================================="
    
    check_macos
    check_prerequisites
    
    # Load existing API keys
    load_api_keys
    
    # Create directory structure
    mkdir -p "$MCP_OFFICIAL_DIR" "$MCP_COMMUNITY_DIR" "$MCP_CUSTOM_DIR"
    
    # Install servers
    install_official_servers
    install_community_servers
    
    # Configure Claude Desktop
    configure_claude_desktop
    
    print_info "Setup Complete!"
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
    
    # Check if any API keys were configured
    if [[ -f "$API_KEYS_FILE" ]] && grep -q "export.*_API_KEY=" "$API_KEYS_FILE" 2>/dev/null; then
        print_info "API keys have been saved to: $API_KEYS_FILE"
        print_info "Please run 'source ~/.zshrc' to load the API keys in your current shell"
    fi
    
    print_success "You can now use MCP servers in Claude Desktop!"
}

# Run main function
main "$@"