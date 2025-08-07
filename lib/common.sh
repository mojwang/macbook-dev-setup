#!/usr/bin/env bash

# Common library for macOS development setup scripts
# This file contains shared functions, variables, and utilities
# Source this file in other scripts: source "$(dirname "$0")/../lib/common.sh"

# Note: Strict mode is not set here to allow sourcing from various scripts
# Individual scripts should set their own error handling as needed

# =============================================================================
# Bash Version Compatibility Check
# =============================================================================
# This library requires bash 4+ for full functionality due to:
# - Associative arrays (declare -A) for MCP server configurations
# - Indirect variable expansion (${!var}) for dynamic references
# - Advanced string manipulation features
#
# CI Fallback Mode:
# GitHub Actions and other CI environments typically only have bash 3.2.
# When detected, we provide minimal functions to allow basic operations
# while skipping advanced features. This enables CI/CD pipelines to run
# preview/test commands without full functionality.
# =============================================================================

if [[ "${BASH_VERSION%%.*}" -lt 4 ]]; then
    if [[ "${CI:-false}" == "true" ]] || [[ "${GITHUB_ACTIONS:-false}" == "true" ]]; then
        # CI Fallback Mode - provide minimal functionality for bash 3.2
        echo "Warning: Running with bash $BASH_VERSION in CI environment" >&2
        echo "Disabled features: MCP server management, associative arrays, indirect expansion" >&2
        echo "Available features: Basic setup preview, simple commands, file operations" >&2
        
        # Mark library as loaded to prevent duplicate sourcing
        COMMON_LIB_LOADED=true
        
        # Define minimal print functions with optional logging support
        # These use 'ci_' prefix to avoid confusion with full implementations
        ci_print_info() { 
            echo "ℹ $*"
            [[ -n "${LOG_FILE:-}" ]] && echo "$(date '+%Y-%m-%d %H:%M:%S') [${SCRIPT_NAME:-common}] INFO: $*" >> "$LOG_FILE" 2>/dev/null || true
        }
        ci_print_success() { 
            echo "✓ $*"
            [[ -n "${LOG_FILE:-}" ]] && echo "$(date '+%Y-%m-%d %H:%M:%S') [${SCRIPT_NAME:-common}] SUCCESS: $*" >> "$LOG_FILE" 2>/dev/null || true
        }
        ci_print_error() { 
            echo "✗ $*" >&2
            [[ -n "${LOG_FILE:-}" ]] && echo "$(date '+%Y-%m-%d %H:%M:%S') [${SCRIPT_NAME:-common}] ERROR: $*" >> "$LOG_FILE" 2>/dev/null || true
        }
        ci_print_warning() { 
            echo "⚠ $*"
            [[ -n "${LOG_FILE:-}" ]] && echo "$(date '+%Y-%m-%d %H:%M:%S') [${SCRIPT_NAME:-common}] WARNING: $*" >> "$LOG_FILE" 2>/dev/null || true
        }
        ci_print_step() { 
            echo "→ $*"
            [[ -n "${LOG_FILE:-}" ]] && echo "$(date '+%Y-%m-%d %H:%M:%S') [${SCRIPT_NAME:-common}] STEP: $*" >> "$LOG_FILE" 2>/dev/null || true
        }
        
        # Alias the CI functions to standard names for compatibility
        alias print_info='ci_print_info'
        alias print_success='ci_print_success'
        alias print_error='ci_print_error'
        alias print_warning='ci_print_warning'
        alias print_step='ci_print_step'
        
        # Export the CI functions
        export -f ci_print_info ci_print_success ci_print_error ci_print_warning ci_print_step
        
        # Log the bash version for debugging
        [[ -n "${LOG_FILE:-}" ]] && echo "$(date '+%Y-%m-%d %H:%M:%S') [${SCRIPT_NAME:-common}] CI Mode: bash $BASH_VERSION detected" >> "$LOG_FILE" 2>/dev/null || true
        
        return 0
    else
        echo "Error: This script requires bash 4.0 or higher (found $BASH_VERSION)" >&2
        echo "Please run with Homebrew bash: brew install bash" >&2
        echo "Ensure /opt/homebrew/bin is in your PATH" >&2
        exit 1
    fi
fi

# Prevent multiple sourcing of this file to avoid readonly variable errors
if [[ -n "${COMMON_LIB_LOADED:-}" ]]; then
    return 0
fi
COMMON_LIB_LOADED=true

# Script information
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[1]}")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

# Color definitions
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Logging configuration
LOG_FILE="${LOG_FILE:-}"
VERBOSE="${VERBOSE:-false}"
DRY_RUN="${DRY_RUN:-false}"

# System information
readonly OS_TYPE="$(uname -s)"
readonly ARCH_TYPE="$(uname -m)"
readonly MACOS_VERSION="$(sw_vers -productVersion 2>/dev/null || echo "unknown")"

# Utility functions
print_step() {
    echo -e "${BLUE}→ $1${NC}"
    log_message "STEP: $1"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
    log_message "SUCCESS: $1"
}

print_warning() {
    echo -e "${YELLOW}! $1${NC}"
    log_message "WARNING: $1"
}

print_error() {
    echo -e "${RED}✗ $1${NC}" >&2
    log_message "ERROR: $1"
}

print_info() {
    echo -e "${CYAN}i $1${NC}"
    log_message "INFO: $1"
}

print_dry_run() {
    echo -e "${PURPLE}◊ [DRY RUN] $1${NC}"
    log_message "DRY_RUN: $1"
}

# Logging function
log_message() {
    if [[ -n "$LOG_FILE" ]]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') [$SCRIPT_NAME] $1" >> "$LOG_FILE"
    fi
}

# Error handling
die() {
    print_error "${1:-Unknown error occurred}"
    exit "${2:-1}"
}

# Command execution with dry-run support
execute_command() {
    local cmd="$1"
    local description="${2:-Executing command}"
    
    if [[ "$DRY_RUN" == true ]]; then
        print_dry_run "$description"
        [[ "$VERBOSE" == true ]] && echo "  Command: $cmd"
        return 0
    fi
    
    print_step "$description"
    if [[ "$VERBOSE" == true ]]; then
        echo "  Command: $cmd"
    fi
    
    if eval "$cmd"; then
        return 0
    else
        local exit_code=$?
        print_error "Failed: $description (exit code: $exit_code)"
        return $exit_code
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Run command with timeout (standardized approach)
# Usage: run_with_timeout SECONDS COMMAND [ARGS...]
run_with_timeout() {
    local timeout_seconds="$1"
    shift
    
    # Prefer gtimeout (GNU coreutils on macOS), then timeout, then fallback
    if command_exists gtimeout; then
        gtimeout "${timeout_seconds}s" "$@"
    elif command_exists timeout; then
        timeout "${timeout_seconds}s" "$@"
    else
        # Fallback: run in background and kill after timeout
        "$@" &
        local pid=$!
        local count=0
        
        while kill -0 $pid 2>/dev/null; do
            if [[ $count -ge $timeout_seconds ]]; then
                kill -TERM $pid 2>/dev/null || true
                sleep 1
                kill -0 $pid 2>/dev/null && kill -KILL $pid 2>/dev/null || true
                return 124  # Standard timeout exit code
            fi
            sleep 1
            ((count++))
        done
        
        wait $pid
        return $?
    fi
}

# Check if running on macOS
require_macos() {
    if [[ "$OS_TYPE" != "Darwin" ]]; then
        die "This script is designed for macOS only."
    fi
}

# Check if running on Apple Silicon
check_apple_silicon() {
    [[ "$ARCH_TYPE" == "arm64" ]]
}

# Prompt user for confirmation
confirm() {
    local prompt="${1:-Are you sure?}"
    local default="${2:-n}"
    
    if [[ "$default" =~ ^[Yy]$ ]]; then
        prompt="$prompt [Y/n]: "
    else
        prompt="$prompt [y/N]: "
    fi
    
    if [[ -t 0 ]]; then
        read -r -p "$prompt" response
        response=$(echo "$response" | tr '[:upper:]' '[:lower:]')
        case "$response" in
            y|yes) return 0 ;;
            n|no) return 1 ;;
            "") [[ "$default" =~ ^[Yy]$ ]] && return 0 || return 1 ;;
            *) return 1 ;;
        esac
    else
        # Non-interactive mode
        [[ "$default" =~ ^[Yy]$ ]] && return 0 || return 1
    fi
}

# Backup file or directory
backup_item() {
    local source="$1"
    local backup_dir="${2:-$HOME/.setup_backup/$TIMESTAMP}"
    
    if [[ ! -e "$source" ]]; then
        return 0
    fi
    
    mkdir -p "$backup_dir"
    
    local backup_name="$(basename "$source")"
    local backup_path="$backup_dir/$backup_name"
    
    if [[ -d "$source" ]]; then
        cp -r "$source" "$backup_path"
        print_info "Backed up directory: $source → $backup_path"
    else
        cp "$source" "$backup_path"
        print_info "Backed up file: $source → $backup_path"
    fi
    
    echo "$backup_path"
}

# Network connectivity check
check_network() {
    local test_urls=(
        "https://github.com"
        "https://raw.githubusercontent.com"
        "https://brew.sh"
        "https://registry.npmjs.org"
        "https://pypi.org"
    )
    
    local failed=0
    for url in "${test_urls[@]}"; do
        if ! curl -fsS --connect-timeout 5 "$url" >/dev/null 2>&1; then
            print_warning "Cannot reach $url"
            ((failed++))
        fi
    done
    
    if [[ $failed -gt 0 ]]; then
        print_warning "Network connectivity issues detected ($failed/${#test_urls[@]} URLs unreachable)"
        return 1
    fi
    
    return 0
}

# Disk space check
check_disk_space() {
    local required_gb="${1:-10}"
    local mount_point="${2:-/}"
    
    local available_gb
    # macOS disk space check
    available_gb=$(df -g "$mount_point" | awk 'NR==2 {print $4}')
    
    if [[ -z "$available_gb" ]] || (( available_gb < required_gb )); then
        print_error "Insufficient disk space. Required: ${required_gb}GB, Available: ${available_gb:-unknown}GB"
        return 1
    fi
    
    print_info "Disk space check passed: ${available_gb}GB available (${required_gb}GB required)"
    return 0
}

# Download with retry and exponential backoff
download_with_retry() {
    local url="$1"
    local output="${2:--}"
    local max_attempts="${3:-3}"
    local timeout="${4:-30}"
    
    local attempt=1
    local wait_time=2
    
    while (( attempt <= max_attempts )); do
        print_info "Download attempt $attempt/$max_attempts: $url"
        
        if curl -fsSL --connect-timeout "$timeout" --max-time $((timeout * 2)) "$url" -o "$output"; then
            print_success "Download successful"
            return 0
        fi
        
        if (( attempt < max_attempts )); then
            print_warning "Download failed, retrying in ${wait_time}s..."
            sleep "$wait_time"
            wait_time=$((wait_time * 2))
        fi
        
        ((attempt++))
    done
    
    print_error "Download failed after $max_attempts attempts: $url"
    return 1
}

# Validate email address
validate_email() {
    local email="$1"
    local regex="^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
    
    [[ "$email" =~ $regex ]]
}

# Create restore point for rollback
create_restore_point() {
    local name="${1:-setup}"
    local restore_dir="$HOME/.setup_restore/$TIMESTAMP"
    
    mkdir -p "$restore_dir"
    
    # Save metadata
    cat > "$restore_dir/metadata.json" <<EOF
{
    "name": "$name",
    "timestamp": "$TIMESTAMP",
    "date": "$(date)",
    "script": "$SCRIPT_NAME",
    "macos_version": "$MACOS_VERSION",
    "arch": "$ARCH_TYPE"
}
EOF
    
    # Save current state information
    if command_exists brew; then
        brew list > "$restore_dir/brew_list.txt" 2>/dev/null || true
        brew list --cask > "$restore_dir/brew_cask_list.txt" 2>/dev/null || true
    fi
    
    if command_exists npm; then
        npm list -g --depth=0 > "$restore_dir/npm_global.txt" 2>/dev/null || true
    fi
    
    if command_exists pip3; then
        pip3 list > "$restore_dir/pip_list.txt" 2>/dev/null || true
    fi
    
    # Save reference to latest restore point
    echo "$restore_dir" > "$HOME/.setup_restore/latest"
    
    print_info "Created restore point: $restore_dir"
    echo "$restore_dir"
}

# Get latest restore point
get_latest_restore_point() {
    local latest_file="$HOME/.setup_restore/latest"
    
    if [[ -f "$latest_file" ]]; then
        cat "$latest_file"
    else
        echo ""
    fi
}

# Progress indicator for long operations
show_progress() {
    local pid="$1"
    local message="${2:-Processing}"
    
    local spin='-\|/'
    local i=0
    
    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i+1) %4 ))
        printf "\r${BLUE}${spin:$i:1} $message...${NC}"
        sleep 0.1
    done
    
    printf "\r"
}

# Progress bar for operations with known total
show_progress_bar() {
    local current="$1"
    local total="$2"
    local message="${3:-Progress}"
    local width="${4:-50}"
    
    local percentage=$((current * 100 / total))
    # Cap percentage at 100 to handle cases where current exceeds total
    [[ $percentage -gt 100 ]] && percentage=100
    local filled=$((percentage * width / 100))
    local empty=$((width - filled))
    
    # Build the bar
    printf "\r${BLUE}$message: [${NC}"
    printf "%${filled}s" | tr ' ' '='
    printf "%${empty}s" | tr ' ' '>'
    printf "${BLUE}] $percentage%% ${NC}"
    
    # Always move to next line when complete to prevent overlap
    if [[ $current -eq $total ]]; then
        printf "\n"
    fi
}

# Execute command with progress indicator
execute_with_progress() {
    local cmd="$1"
    local message="${2:-Executing}"
    
    if [[ "$DRY_RUN" == true ]]; then
        print_dry_run "$message"
        return 0
    fi
    
    # Run command in background
    eval "$cmd" &
    local pid=$!
    
    # Show progress
    show_progress "$pid" "$message"
    
    # Wait for completion
    wait "$pid"
    local exit_code=$?
    
    # Clear the spinner line and show result on a new line
    printf "\r\033[K"
    if [[ $exit_code -eq 0 ]]; then
        printf "${GREEN}✓ $message completed${NC}\n"
    else
        printf "${RED}✗ $message failed${NC}\n"
    fi
    
    return $exit_code
}

# Cleanup function to be called on exit
cleanup() {
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        print_warning "Script exited with code: $exit_code"
        
        if [[ -n "${RESTORE_POINT:-}" ]]; then
            print_info "Restore point available at: $RESTORE_POINT"
            print_info "To rollback, run: ./scripts/rollback.sh"
        fi
    fi
    
    # Any other cleanup tasks
}

# Set up signal-safe cleanup trap
trap cleanup EXIT INT TERM HUP

# Test-related functions
validate_test_jobs() {
    local jobs="${1:-}"
    local cpu_count=$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 4)
    
    if [[ ! "$jobs" =~ ^[0-9]+$ ]] || (( jobs < 1 || jobs > 32 )); then
        echo "Invalid TEST_JOBS value: $jobs. Using CPU count." >&2
        echo "$cpu_count"
    else
        echo "$jobs"
    fi
}

wait_for_job_slot() {
    local max_jobs="${1:-4}"
    while true; do
        local current_jobs=$(jobs -r 2>/dev/null | wc -l | tr -d ' ')
        if [[ -z "$current_jobs" ]]; then
            current_jobs=0
        fi
        if (( current_jobs < max_jobs )); then
            break
        fi
        sleep 0.1
    done
}

check_suite_timeout() {
    local start_time="$1"
    local timeout="$2"
    local current_time=$(date +%s)
    if (( current_time - start_time > timeout )); then
        return 124  # timeout exit code
    fi
    return 0
}

kill_all_test_jobs() {
    # Kill all background jobs
    local pids=$(jobs -p 2>/dev/null)
    if [[ -n "$pids" ]]; then
        echo "$pids" | xargs kill 2>/dev/null || true
        # Wait a moment for processes to die
        sleep 0.5
        # Force kill any remaining
        echo "$pids" | xargs kill -9 2>/dev/null || true
    fi
}

# Export common variables for child scripts
export ROOT_DIR
export LIB_DIR="$ROOT_DIR/lib"
export SCRIPTS_DIR="$ROOT_DIR/scripts"
export DOTFILES_DIR="$ROOT_DIR/dotfiles"

# Export functions for progress tracking
export -f show_progress
export -f show_progress_bar
export -f execute_with_progress

# Export test-related functions
export -f validate_test_jobs
export -f wait_for_job_slot
export -f check_suite_timeout
export -f kill_all_test_jobs

# ============================================================================
# MCP Configuration Functions
# ============================================================================

# MCP server configurations - base paths
# Check both possible locations for official servers (src/ subfolder or direct)
get_mcp_server_base_path() {
    local server_name="$1"
    
    # Official servers - check both locations
    if [[ "$server_name" =~ ^(filesystem|memory|sequentialthinking|git|fetch)$ ]]; then
        if [[ -d "$HOME/repos/mcp-servers/official/src/$server_name" ]]; then
            echo "$HOME/repos/mcp-servers/official/src/$server_name"
        elif [[ -d "$HOME/repos/mcp-servers/official/$server_name" ]]; then
            echo "$HOME/repos/mcp-servers/official/$server_name"
        fi
    # Community servers
    elif [[ -d "$HOME/repos/mcp-servers/community/$server_name" ]]; then
        echo "$HOME/repos/mcp-servers/community/$server_name"
    fi
}

declare -A MCP_SERVER_BASE_PATHS=(
    # Official servers - will be dynamically determined
    ["filesystem"]="$(get_mcp_server_base_path filesystem)"
    ["memory"]="$(get_mcp_server_base_path memory)"
    ["sequentialthinking"]="$(get_mcp_server_base_path sequentialthinking)"
    ["git"]="$(get_mcp_server_base_path git)"
    ["fetch"]="$(get_mcp_server_base_path fetch)"
    # Community servers
    ["context7"]="$HOME/repos/mcp-servers/community/context7"
    ["playwright"]="$HOME/repos/mcp-servers/community/playwright"
    ["figma"]="$HOME/repos/mcp-servers/community/figma"
    ["exa"]="$HOME/repos/mcp-servers/community/exa"
    ["semgrep"]="$HOME/repos/mcp-servers/community/semgrep"
)

# MCP server executable patterns - used to find the actual executable
declare -A MCP_SERVER_EXECUTABLES=(
    # Node servers - common patterns
    ["filesystem"]="dist/index.js"
    ["memory"]="dist/index.js"
    ["sequentialthinking"]="dist/index.js"
    ["context7"]="dist/index.js"
    ["playwright"]="cli.js build/index.js dist/index.js"
    ["figma"]="dist/index.js"
    ["exa"]="build/index.js .smithery/index.cjs dist/index.js"
    # Python servers use directory
    ["git"]=""
    ["fetch"]=""
    ["semgrep"]=""
)

# MCP server types
declare -A MCP_SERVER_TYPES=(
    ["filesystem"]="node"
    ["memory"]="node"
    ["sequentialthinking"]="node"
    ["git"]="python-uv"
    ["fetch"]="python-uv"
    ["context7"]="node"
    ["playwright"]="node"
    ["figma"]="npx"
    ["exa"]="npx"
    ["semgrep"]="python-uvx"
)

# NPX-based servers and their package names
declare -A MCP_SERVER_NPX_PACKAGES=(
    ["figma"]="figma-developer-mcp"
    ["exa"]="exa-mcp-server"
)

# MCP servers that require API keys
declare -A MCP_SERVER_API_KEYS=(
    ["figma"]="FIGMA_API_KEY"
    ["exa"]="EXA_API_KEY"
)

# Find the actual executable path for an MCP server
find_mcp_server_executable() {
    local server_name="$1"
    local server_type="${MCP_SERVER_TYPES[$server_name]}"
    
    # For npx servers, return the npx package name
    if [[ "$server_type" == "npx" ]]; then
        echo "${MCP_SERVER_NPX_PACKAGES[$server_name]}"
        return 0
    fi
    
    # Get the base path dynamically
    local base_path=$(get_mcp_server_base_path "$server_name")
    
    # If base path doesn't exist, return error
    if [[ -z "$base_path" ]] || [[ ! -d "$base_path" ]]; then
        return 1
    fi
    
    local executables="${MCP_SERVER_EXECUTABLES[$server_name]}"
    
    # Python servers just use the base directory
    if [[ "$server_type" == "python-uv" ]] || [[ "$server_type" == "python-uvx" ]]; then
        echo "$base_path"
        return 0
    fi
    
    # For Node.js servers, try each possible executable pattern
    if [[ -n "$executables" ]]; then
        for exe in $executables; do
            if [[ -f "$base_path/$exe" ]]; then
                echo "$base_path/$exe"
                return 0
            fi
        done
    fi
    
    # Fallback: search for any index.js file
    local found=$(find "$base_path" -name "index.js" -type f 2>/dev/null | grep -v node_modules | head -1)
    if [[ -n "$found" ]]; then
        echo "$found"
        return 0
    fi
    
    return 1
}

# Generate MCP server config for Claude Desktop
generate_mcp_server_config() {
    local server_name="$1"
    local include_api_keys="${2:-true}"
    
    local server_path=$(find_mcp_server_executable "$server_name")
    local server_type="${MCP_SERVER_TYPES[$server_name]}"
    local api_key_var="${MCP_SERVER_API_KEYS[$server_name]:-}"
    
    # Check if server path exists
    if [[ -z "$server_path" ]]; then
        return 1
    fi
    
    # Skip servers that need API keys if not including them
    if [[ "$include_api_keys" == "false" ]] && [[ -n "$api_key_var" ]]; then
        return 1
    fi
    
    case "$server_type" in
        "node")
            # Special handling for filesystem server
            if [[ "$server_name" == "filesystem" ]]; then
                cat <<EOF
    "$server_name": {
      "command": "node",
      "args": [
        "$server_path",
        "$HOME"
      ]
    }
EOF
            elif [[ -n "$api_key_var" ]]; then
                cat <<EOF
    "$server_name": {
      "command": "node",
      "args": ["$server_path"],
      "env": {
        "$api_key_var": "\${$api_key_var}"
      }
    }
EOF
            else
                cat <<EOF
    "$server_name": {
      "command": "node",
      "args": ["$server_path"]
    }
EOF
            fi
            ;;
        "python-uv")
            cat <<EOF
    "$server_name": {
      "command": "uv",
      "args": [
        "--directory",
        "$server_path",
        "run",
        "mcp-server-$server_name"
      ]
    }
EOF
            ;;
        "python-uvx")
            if [[ "$server_name" == "semgrep" ]]; then
                cat <<EOF
    "$server_name": {
      "command": "uvx",
      "args": [
        "--with",
        "mcp==1.11.0",
        "semgrep-mcp"
      ]
    }
EOF
            fi
            ;;
        "npx")
            local npx_package="${MCP_SERVER_NPX_PACKAGES[$server_name]}"
            if [[ -n "$api_key_var" ]]; then
                if [[ "$server_name" == "figma" ]]; then
                    cat <<EOF
    "$server_name": {
      "command": "npx",
      "args": [
        "-y",
        "$npx_package",
        "--stdio"
      ],
      "env": {
        "$api_key_var": "\${$api_key_var}"
      }
    }
EOF
                else
                    cat <<EOF
    "$server_name": {
      "command": "npx",
      "args": [
        "-y",
        "$npx_package"
      ],
      "env": {
        "$api_key_var": "\${$api_key_var}"
      }
    }
EOF
                fi
            else
                cat <<EOF
    "$server_name": {
      "command": "npx",
      "args": [
        "-y",
        "$npx_package"
      ]
    }
EOF
            fi
            ;;
    esac
}

# Check if MCP server is installed
is_mcp_server_installed() {
    local server_name="$1"
    local server_type="${MCP_SERVER_TYPES[$server_name]}"
    
    # For npx servers, we don't need to check installation
    if [[ "$server_type" == "npx" ]]; then
        return 0
    fi
    
    # Get the base path dynamically
    local base_path=$(get_mcp_server_base_path "$server_name")
    
    # Check if base path exists
    if [[ -z "$base_path" ]] || [[ ! -d "$base_path" ]]; then
        return 1
    fi
    
    # For node servers, check if we can find an executable
    if [[ "$server_type" == "node" ]]; then
        local exe_path=$(find_mcp_server_executable "$server_name")
        [[ -n "$exe_path" ]] && [[ -f "$exe_path" ]]
    else
        # For Python servers, just check directory exists
        return 0
    fi
}

# Export MCP functions
export -f get_mcp_server_base_path
export -f find_mcp_server_executable
export -f generate_mcp_server_config
export -f is_mcp_server_installed

# Initialization message
if [[ "${COMMON_LIB_LOADED:-}" != "true" ]]; then
    export COMMON_LIB_LOADED="true"
    [[ "$VERBOSE" == "true" ]] && print_info "Common library loaded from: ${BASH_SOURCE[0]}"
fi