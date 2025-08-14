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
    
    # Clean up old validation cache files
    cleanup_old_cache_files 2>/dev/null || true
    
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

# Validation cache file (valid for the duration of the session)
VALIDATION_CACHE_FILE="/tmp/mcp-validated-keys-$(date +%Y%m%d)"
VALIDATION_CACHE_DURATION=3600  # Cache validation for 1 hour

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
        
        # Verify keys were loaded
        for key_name in "${SERVER_KEY_NAMES[@]}"; do
            if [[ -n "${!key_name}" ]]; then
                print_info "Loaded existing $key_name from config"
            fi
        done
    fi
}

# Check if an API key validation is cached and still valid
is_validation_cached() {
    local key_name="$1"
    
    # Check if cache file exists
    if [[ ! -f "$VALIDATION_CACHE_FILE" ]]; then
        return 1
    fi
    
    # Check if key is in cache
    local cache_entry=$(grep "^${key_name}:" "$VALIDATION_CACHE_FILE" 2>/dev/null)
    if [[ -z "$cache_entry" ]]; then
        return 1
    fi
    
    # Check if cache entry is still valid (within duration)
    local cached_time=$(echo "$cache_entry" | cut -d: -f2)
    local current_time=$(date +%s)
    local age=$((current_time - cached_time))
    
    if [[ $age -lt $VALIDATION_CACHE_DURATION ]]; then
        return 0
    else
        # Remove expired entry
        grep -v "^${key_name}:" "$VALIDATION_CACHE_FILE" > "${VALIDATION_CACHE_FILE}.tmp" 2>/dev/null || true
        mv "${VALIDATION_CACHE_FILE}.tmp" "$VALIDATION_CACHE_FILE" 2>/dev/null || true
        return 1
    fi
}

# Add a validated key to the cache
cache_validation() {
    local key_name="$1"
    local timestamp=$(date +%s)
    
    # Create cache file if it doesn't exist
    touch "$VALIDATION_CACHE_FILE" 2>/dev/null || true
    
    # Remove any existing entry for this key
    grep -v "^${key_name}:" "$VALIDATION_CACHE_FILE" > "${VALIDATION_CACHE_FILE}.tmp" 2>/dev/null || true
    mv "${VALIDATION_CACHE_FILE}.tmp" "$VALIDATION_CACHE_FILE" 2>/dev/null || true
    
    # Add new entry
    echo "${key_name}:${timestamp}" >> "$VALIDATION_CACHE_FILE"
}

# Clean up old cache files to prevent accumulation
cleanup_old_cache_files() {
    local current_time=$(date +%s)
    local one_day_ago=$((current_time - 86400))  # 86400 seconds = 1 day
    local files_removed=0
    
    # Iterate through cache files
    for cache_file in /tmp/mcp-validated-keys-*; do
        if [[ -f "$cache_file" ]]; then
            # Get file modification time (macOS compatible)
            local file_time=$(stat -f %m "$cache_file" 2>/dev/null || stat -c %Y "$cache_file" 2>/dev/null || echo "0")
            
            # Check if file is older than 1 day or empty
            if [[ $file_time -lt $one_day_ago ]] || [[ ! -s "$cache_file" ]]; then
                rm -f "$cache_file" 2>/dev/null && ((files_removed++))
            fi
        fi
    done
    
    # Count remaining cache files
    local cache_count=$(find /tmp -name "mcp-validated-keys-*" -type f 2>/dev/null | wc -l)
    
    # If more than 7 cache files (a week's worth), clean up all but today's
    if [[ $cache_count -gt 7 ]]; then
        find /tmp -name "mcp-validated-keys-*" -type f ! -name "*$(date +%Y%m%d)*" -delete 2>/dev/null || true
    fi
    
    # Optional: Report cleanup if in verbose mode
    if [[ $files_removed -gt 0 ]] && [[ "${VERBOSE:-}" == "true" ]]; then
        print_info "Cleaned up $files_removed old cache file(s)"
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
    elif [[ -d "$target_dir" ]]; then
        # Directory exists but is not a git repo - skip cloning
        print_info "Directory $repo_name exists but is not a git repository, skipping update"
        return 0
    else
        print_info "Cloning $repo_name..."
        git clone --depth 1 "$repo_url" "$target_dir" >/dev/null 2>&1
    fi
}

# Check if an API key is already set
check_api_key() {
    local key_name="$1"
    
    # Check environment variable first (may have been loaded)
    if [[ -n "${!key_name}" ]]; then
        return 0
    fi
    
    # Check API keys file and load it if found
    if [[ -f "$API_KEYS_FILE" ]] && grep -q "export ${key_name}=" "$API_KEYS_FILE" 2>/dev/null; then
        # Extract the key value from the file
        local key_value=$(grep "export ${key_name}=" "$API_KEYS_FILE" | sed -E 's/^export [^=]+="([^"]+)".*/\1/')
        
        # Check if we got a non-empty, non-placeholder value
        if [[ -n "$key_value" && "$key_value" != "\${${key_name}:-}" && "$key_value" != "" ]]; then
            # Export it to the environment for this session
            export "${key_name}=${key_value}"
            return 0
        fi
    fi
    
    return 1
}

# Validate API key by making a test request
validate_api_key() {
    local server_name="$1"
    local key_name="$2"
    local key_value="${!key_name}"
    local skip_cache="${3:-false}"  # Optional flag to skip cache check
    
    if [[ -z "$key_value" ]]; then
        return 1
    fi
    
    # Check if validation is cached (unless explicitly skipping cache)
    if [[ "$skip_cache" != "true" ]] && is_validation_cached "$key_name"; then
        print_info "$server_name API key validation cached (valid)"
        return 0
    fi
    
    local validation_result=2  # Default to unknown
    
    case "$server_name" in
        "exa")
            # Test Exa API key with a simple search request
            local response=$(curl -s -o /dev/null -w "%{http_code}" \
                -X POST "https://api.exa.ai/search" \
                -H "x-api-key: $key_value" \
                -H "Content-Type: application/json" \
                -d '{"query":"test","numResults":1}' \
                --connect-timeout 5 2>/dev/null || echo "000")
            
            if [[ "$response" == "200" ]]; then
                validation_result=0  # Valid key
            elif [[ "$response" == "401" ]] || [[ "$response" == "403" ]]; then
                validation_result=1  # Invalid/revoked key
            else
                validation_result=2  # Network error or other issue - assume key is still valid
            fi
            ;;
        "figma")
            # Test Figma API key with a simple user request
            local response=$(curl -s -o /dev/null -w "%{http_code}" \
                "https://api.figma.com/v1/me" \
                -H "X-Figma-Token: $key_value" \
                --connect-timeout 5 2>/dev/null || echo "000")
            
            if [[ "$response" == "200" ]]; then
                validation_result=0  # Valid key
            elif [[ "$response" == "403" ]]; then
                validation_result=1  # Invalid/revoked key
            else
                validation_result=2  # Network error or other issue - assume key is still valid
            fi
            ;;
        *)
            # Unknown server type, skip validation
            validation_result=2
            ;;
    esac
    
    # Cache successful validation
    if [[ $validation_result -eq 0 ]]; then
        cache_validation "$key_name"
    fi
    
    return $validation_result
}

# Prompt for API key
prompt_for_api_key() {
    local server_name="$1"
    local key_name="$2"
    local api_key=""
    
    # Check if we're in interactive mode
    if [[ ! -t 0 ]] || [[ "${CI:-false}" == "true" ]]; then
        print_warning "$server_name requires API key ($key_name) but running in non-interactive mode"
        print_info "To configure $server_name, set $key_name in ~/.config/zsh/51-api-keys.zsh"
        return 1
    fi
    
    # Check if key already exists in the file but not loaded
    if [[ -f "$API_KEYS_FILE" ]] && grep -q "^export ${key_name}=" "$API_KEYS_FILE" 2>/dev/null; then
        # Key exists in file, try to load it
        source "$API_KEYS_FILE" 2>/dev/null || true
        if [[ -n "${!key_name}" ]]; then
            # Check if validation is cached
            if is_validation_cached "$key_name"; then
                print_success "✓ $server_name API key already validated (using existing key)"
                return 0
            fi
            
            print_info "Found existing $server_name API key, validating..."
            # Validate the existing key
            if validate_api_key "$server_name" "$key_name"; then
                print_success "✓ $server_name API key is valid (using existing key)"
                return 0
            else
                print_warning "✗ Existing $server_name API key appears to be invalid or expired"
                print_info "Please provide a new API key to replace the invalid one"
            fi
        fi
    fi
    
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
        # Validate the key before saving
        export "$key_name=$api_key"
        print_info "Validating API key..."
        if validate_api_key "$server_name" "$key_name"; then
            save_api_key "$key_name" "$api_key"
            print_success "✓ $server_name API key saved and validated successfully"
            print_info "  Key will be loaded automatically in future sessions"
            return 0
        else
            unset "$key_name"
            print_error "✗ Invalid $server_name API key"
            print_info "  Please verify your key and try again"
            print_info "  Hint: Make sure you copied the entire key without spaces"
            return 1
        fi
    else
        print_warning "○ Skipping $server_name (no API key provided)"
        print_info "  You can add it later to ~/.config/zsh/51-api-keys.zsh"
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
    local validate="${2:-true}"  # Changed default to true for better UX
    local interactive="${3:-true}"  # Whether to prompt for keys if missing
    
    # Special handling for TaskMaster - API keys are optional
    if [[ "$server_name" == "taskmaster" ]]; then
        print_info "Configuring TaskMaster Product Manager..."
        
        # Check for ANTHROPIC_API_KEY
        if [[ -n "$ANTHROPIC_API_KEY" ]]; then
            print_success "  ✓ AI-powered task generation enabled (ANTHROPIC_API_KEY set)"
        else
            print_info "  ℹ Basic features available (ANTHROPIC_API_KEY not set)"
            
            # Ask if they want to add it
            if [[ -t 0 ]] && [[ "${CI:-false}" != "true" ]]; then
                echo -n "  Would you like to add ANTHROPIC_API_KEY for AI features? (y/N): "
                read -r response
                if [[ "$response" =~ ^[Yy]$ ]]; then
                    echo "  Get your API key from: https://console.anthropic.com/settings/keys"
                    echo -n "  Enter your Anthropic API key: "
                    read -r api_key
                    if [[ -n "$api_key" ]]; then
                        save_api_key "ANTHROPIC_API_KEY" "$api_key"
                        export ANTHROPIC_API_KEY="$api_key"
                        print_success "  ANTHROPIC_API_KEY saved"
                    fi
                fi
            fi
        fi
        
        # Check for PERPLEXITY_API_KEY
        if [[ -n "$PERPLEXITY_API_KEY" ]]; then
            print_success "  ✓ Research features enabled (PERPLEXITY_API_KEY set)"
        else
            print_info "  ℹ Research features disabled (PERPLEXITY_API_KEY not set)"
        fi
        
        print_info "TaskMaster can be used with available features"
        return 0
    fi
    
    # Check if this server needs an API key
    local key_name=$(get_api_key_name "$server_name")
    if [[ -n "$key_name" ]]; then
        # Check if key already exists
        if check_api_key "$key_name"; then
            # Validate the existing key if requested
            if [[ "$validate" == "true" ]]; then
                # Check if validation is cached first
                if is_validation_cached "$key_name"; then
                    print_success "✓ $server_name API key already validated (cached)"
                    return 0
                fi
                
                print_info "Validating $server_name API key..."
                local validation_result
                validate_api_key "$server_name" "$key_name"
                validation_result=$?
                
                if [[ $validation_result -eq 0 ]]; then
                    print_success "✓ $server_name API key is valid"
                    return 0
                elif [[ $validation_result -eq 1 ]]; then
                    print_error "✗ $server_name API key is invalid or revoked"
                    if [[ "$interactive" == "true" ]]; then
                        print_info "Please provide a new API key"
                        # Prompt for a new key
                        if prompt_for_api_key "$server_name" "$key_name"; then
                            return 0
                        else
                            return 1
                        fi
                    else
                        print_warning "Skipping $server_name (invalid key, non-interactive mode)"
                        return 1
                    fi
                else
                    # Network error or unknown - assume key is still valid
                    print_info "○ $server_name API key configured (validation skipped - network issue)"
                    return 0
                fi
            else
                print_info "✓ $server_name API key already configured (validation disabled)"
                return 0
            fi
        else
            # No key exists - prompt only if in interactive mode
            if [[ "$interactive" == "true" ]]; then
                if prompt_for_api_key "$server_name" "$key_name"; then
                    return 0
                else
                    return 1
                fi
            else
                print_warning "○ $server_name requires API key (not configured)"
                return 1
            fi
        fi
    fi
    
    return 0
}

# Check if Node.js server needs building
check_node_server_needs_build() {
    local server_path="$1"
    local server_name=$(basename "$server_path")
    
    # Check if dist/build directory exists
    if [[ -d "$server_path/dist" ]] || [[ -d "$server_path/build" ]]; then
        # Check if node_modules exists
        if [[ -d "$server_path/node_modules" ]]; then
            # Check if package.json is newer than dist/build
            local package_json_time=""
            local dist_time=""
            
            if [[ -f "$server_path/package.json" ]]; then
                package_json_time=$(stat -f %m "$server_path/package.json" 2>/dev/null || stat -c %Y "$server_path/package.json" 2>/dev/null || echo "0")
            fi
            
            if [[ -d "$server_path/dist" ]]; then
                dist_time=$(find "$server_path/dist" -type f -name "*.js" -exec stat -f %m {} \; 2>/dev/null | sort -n | tail -1 || echo "0")
            elif [[ -d "$server_path/build" ]]; then
                dist_time=$(find "$server_path/build" -type f -name "*.js" -exec stat -f %m {} \; 2>/dev/null | sort -n | tail -1 || echo "0")
            fi
            
            # If dist is newer than package.json, no build needed
            if [[ -n "$dist_time" ]] && [[ -n "$package_json_time" ]] && [[ "$dist_time" -gt "$package_json_time" ]]; then
                return 1  # No build needed
            fi
        fi
    fi
    
    return 0  # Build needed
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
    
    # Check if build is actually needed
    if ! check_node_server_needs_build "$server_path"; then
        print_info "Skipping build for $server_name (already up to date)"
        return 0
    fi
    
    print_info "Building $server_name..."
    cd "$server_path" || return 1
    
    # Initialize npm non-interactively
    init_npm_noninteractive "$server_path"
    
    # Install dependencies with timeout
    # Use standardized timeout function
    if ! run_with_timeout 120 npm install --no-audit --no-fund >/dev/null 2>&1; then
        print_error "npm install failed or timed out for $server_name"
        return 1
    fi
    
    # Build if build script exists (with timeout)
    if grep -q '"build"' package.json 2>/dev/null; then
        # Use standardized timeout function
        run_with_timeout 60 npm run build >/dev/null 2>&1 || {
            print_warning "Build failed or timed out for $server_name, continuing anyway..."
        }
    fi
    
    return 0
}

# Check if Python server needs building
check_python_server_needs_build() {
    local server_path="$1"
    local server_name=$(basename "$server_path")
    
    # Check if venv exists with installed packages
    if [[ -d "$server_path/venv" ]] && [[ -d "$server_path/venv/lib" ]]; then
        # Check if requirements.txt or pyproject.toml is newer than venv
        local req_time=""
        local venv_time=""
        
        if [[ -f "$server_path/requirements.txt" ]]; then
            req_time=$(stat -f %m "$server_path/requirements.txt" 2>/dev/null || stat -c %Y "$server_path/requirements.txt" 2>/dev/null || echo "0")
        elif [[ -f "$server_path/pyproject.toml" ]]; then
            req_time=$(stat -f %m "$server_path/pyproject.toml" 2>/dev/null || stat -c %Y "$server_path/pyproject.toml" 2>/dev/null || echo "0")
        fi
        
        if [[ -d "$server_path/venv" ]]; then
            venv_time=$(stat -f %m "$server_path/venv" 2>/dev/null || stat -c %Y "$server_path/venv" 2>/dev/null || echo "0")
        fi
        
        # If venv is newer than requirements, no build needed
        if [[ -n "$venv_time" ]] && [[ -n "$req_time" ]] && [[ "$venv_time" -gt "$req_time" ]]; then
            # Also check if .uv directory exists for uv-managed projects
            if [[ -f "$server_path/pyproject.toml" ]] && command -v uv &>/dev/null; then
                if [[ -d "$server_path/.venv" ]]; then
                    return 1  # No build needed
                fi
            else
                return 1  # No build needed
            fi
        fi
    fi
    
    # Check for uv-managed projects
    if [[ -f "$server_path/pyproject.toml" ]] && [[ -d "$server_path/.venv" ]]; then
        return 1  # No build needed
    fi
    
    return 0  # Build needed
}

# Build Python server
build_python_server() {
    local server_path="$1"
    local server_name=$(basename "$server_path")
    
    # Check if build is actually needed
    if ! check_python_server_needs_build "$server_path"; then
        print_info "Skipping build for $server_name (already up to date)"
        return 0
    fi
    
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
    echo "  --help              Show this help message"
    echo "  --check             Check MCP server status"
    echo "  --update            Update all MCP servers"
    echo "  --remove            Remove MCP configuration"
    echo "  --validate-keys     Validate existing API keys"
    echo "  --skip-validation   Skip API key validation for faster setup/update"
    echo ""
    echo "Environment Variables:"
    echo "  MCP_ROOT_DIR   Root directory for MCP servers (default: ~/repos/mcp-servers)"
    echo ""
    echo "Examples:"
    echo "  $0                         # Install and configure MCP servers"
    echo "  $0 --check                # Check server status"
    echo "  $0 --update               # Update all servers"
    echo "  $0 --update --skip-validation  # Fast update without key validation"
    echo "  $0 --validate-keys        # Check if API keys are still valid"
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
    local skip_validation="${1:-false}"
    
    print_info "Updating MCP Servers"
    if [[ "$skip_validation" == "true" ]]; then
        print_info "API key validation disabled for faster update"
    fi
    echo ""
    
    # Load existing API keys
    load_api_keys
    
    # Track update results
    local updated_servers=()
    local failed_servers=()
    local actually_updated=()
    
    # Clear the update status file
    local UPDATE_STATUS_FILE="/tmp/mcp-update-status"
    > "$UPDATE_STATUS_FILE"
    
    # Update official servers
    if [[ -d "$MCP_OFFICIAL_DIR" ]]; then
        print_info "Updating official servers repository..."
        cd "$MCP_OFFICIAL_DIR"
        
        # Check if this is a git repository
        if git rev-parse --git-dir > /dev/null 2>&1; then
            # Stash any local changes
            if git diff --quiet && git diff --cached --quiet; then
                git pull --rebase origin main 2>/dev/null || git pull --rebase origin master 2>/dev/null || {
                    print_warning "Failed to update official servers repository"
                }
            else
                print_warning "Local changes detected in official servers, skipping git pull"
            fi
        else
            print_info "Official servers directory is not a git repository, skipping git operations"
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
            local needs_update=false
            
            # Check if server needs rebuilding (simplified check - could be enhanced)
            if [[ " ${NODE_SERVERS[@]} " =~ " $server " ]]; then
                if [[ ! -d "$server_path/dist" ]] || [[ ! -d "$server_path/node_modules" ]]; then
                    needs_update=true
                fi
                if build_node_server "$server_path"; then
                    updated_servers+=("$server")
                    if [[ "$needs_update" == "true" ]]; then
                        echo "$server" >> "$UPDATE_STATUS_FILE"
                        actually_updated+=("$server")
                    fi
                else
                    failed_servers+=("$server")
                fi
            elif [[ " ${PYTHON_SERVERS[@]} " =~ " $server " ]]; then
                if build_python_server "$server_path"; then
                    updated_servers+=("$server")
                    echo "$server" >> "$UPDATE_STATUS_FILE"
                    actually_updated+=("$server")
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
                # Just check API keys (skip validation if flag is set)
                local validate_keys=$([[ "$skip_validation" == "true" ]] && echo "false" || echo "true")
                configure_api_keys "$server_name" "$validate_keys" "false"  # non-interactive
                updated_servers+=("$server_name")
                continue
            fi
            
            local server_path="$MCP_COMMUNITY_DIR/$server_name"
            if [[ -d "$server_path" ]]; then
                print_info "Updating $server_name..."
                local repo_updated=false
                
                # Check if repo was actually updated
                local old_head=""
                if [[ -d "$server_path/.git" ]]; then
                    old_head=$(cd "$server_path" && git rev-parse HEAD 2>/dev/null || echo "")
                fi
                
                if clone_or_update_repo "$server_url" "$server_path"; then
                    # Check if HEAD changed
                    local new_head=""
                    if [[ -d "$server_path/.git" ]]; then
                        new_head=$(cd "$server_path" && git rev-parse HEAD 2>/dev/null || echo "")
                    fi
                    if [[ "$old_head" != "$new_head" ]] || [[ -z "$old_head" ]]; then
                        repo_updated=true
                    fi
                    
                    # Configure API keys if needed (skip validation if flag is set)
                    local validate_keys=$([[ "$skip_validation" == "true" ]] && echo "false" || echo "true")
                    configure_api_keys "$server_name" "$validate_keys" "false"  # non-interactive
                    
                    # Rebuild the server
                    if [[ -f "$server_path/package.json" ]]; then
                        if build_node_server "$server_path"; then
                            updated_servers+=("$server_name")
                            if [[ "$repo_updated" == "true" ]]; then
                                echo "$server_name" >> "$UPDATE_STATUS_FILE"
                                actually_updated+=("$server_name")
                            fi
                        else
                            failed_servers+=("$server_name")
                        fi
                    elif [[ -f "$server_path/requirements.txt" ]] || [[ -f "$server_path/pyproject.toml" ]]; then
                        if build_python_server "$server_path"; then
                            updated_servers+=("$server_name")
                            if [[ "$repo_updated" == "true" ]]; then
                                echo "$server_name" >> "$UPDATE_STATUS_FILE"
                                actually_updated+=("$server_name")
                            fi
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
    
    # Track servers missing API keys
    local missing_keys=()
    for i in "${!SERVER_NAMES_WITH_KEYS[@]}"; do
        local server_name="${SERVER_NAMES_WITH_KEYS[$i]}"
        local key_name="${SERVER_KEY_NAMES[$i]}"
        if [[ -z "${!key_name}" ]]; then
            missing_keys+=("$server_name")
        fi
    done
    
    # Show update results
    echo ""
    if [[ ${#updated_servers[@]} -gt 0 ]]; then
        print_success "Successfully updated servers: ${updated_servers[*]}"
    fi
    
    if [[ ${#actually_updated[@]} -gt 0 ]]; then
        print_info "Servers with actual changes: ${actually_updated[*]}"
    else
        print_info "No servers had actual changes"
    fi
    
    if [[ ${#failed_servers[@]} -gt 0 ]]; then
        print_warning "Failed to update servers: ${failed_servers[*]}"
    fi
    
    if [[ ${#missing_keys[@]} -gt 0 ]]; then
        print_warning "Servers missing API keys: ${missing_keys[*]}"
        print_info "To configure these servers, add their API keys to ~/.config/zsh/51-api-keys.zsh"
    fi
    
    # Reconfigure Claude Desktop
    echo ""
    configure_claude_desktop
    
    # Return status based on whether any servers were actually updated
    if [[ ${#actually_updated[@]} -gt 0 ]]; then
        return 0
    else
        return 2  # Special code to indicate no updates
    fi
}

# Validate all configured API keys
validate_all_keys() {
    print_info "Validating API Keys"
    echo ""
    
    # Load existing API keys
    load_api_keys
    
    local validation_results=()
    local invalid_keys=()
    
    # Check each server that requires API keys
    for i in "${!SERVER_NAMES_WITH_KEYS[@]}"; do
        local server_name="${SERVER_NAMES_WITH_KEYS[$i]}"
        local key_name="${SERVER_KEY_NAMES[$i]}"
        
        if check_api_key "$key_name"; then
            print_info "Validating $server_name API key..."
            local validation_result
            validate_api_key "$server_name" "$key_name"
            validation_result=$?
            
            if [[ $validation_result -eq 0 ]]; then
                print_success "✓ $server_name API key is valid"
                validation_results+=("$server_name: valid")
            elif [[ $validation_result -eq 1 ]]; then
                print_error "✗ $server_name API key is invalid or revoked"
                invalid_keys+=("$server_name")
                validation_results+=("$server_name: invalid")
            else
                print_warning "○ $server_name API key validation skipped (network issue)"
                validation_results+=("$server_name: unknown")
            fi
        else
            print_warning "○ $server_name API key not configured"
            validation_results+=("$server_name: not configured")
        fi
    done
    
    echo ""
    if [[ ${#invalid_keys[@]} -gt 0 ]]; then
        print_error "Invalid API keys detected: ${invalid_keys[*]}"
        print_info "Please run the setup again to provide new API keys"
        return 1
    else
        print_success "All configured API keys are valid"
        return 0
    fi
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
    local skip_validation=false
    local action=""
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)
                print_usage
                exit 0
                ;;
            --check)
                action="check"
                shift
                ;;
            --update)
                action="update"
                shift
                ;;
            --validate-keys)
                action="validate"
                shift
                ;;
            --remove)
                action="remove"
                shift
                ;;
            --skip-validation)
                skip_validation=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                print_usage
                exit 1
                ;;
        esac
    done
    
    # Execute the requested action
    case "$action" in
        check)
            check_status
            exit 0
            ;;
        update)
            check_macos
            check_prerequisites
            # Clean up old cache files at the start of update
            cleanup_old_cache_files
            update_servers "$skip_validation"
            exit 0
            ;;
        validate)
            validate_all_keys
            exit $?
            ;;
        remove)
            remove_configuration
            exit 0
            ;;
        "")
            # Default: install
            ;;
        *)
            print_error "Unknown action: $action"
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
    
    # Clean up old cache files at the start of installation
    cleanup_old_cache_files
    
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