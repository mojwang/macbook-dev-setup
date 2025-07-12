#!/bin/bash

# Common library for macOS development setup scripts
# This file contains shared functions, variables, and utilities
# Source this file in other scripts: source "$(dirname "$0")/../lib/common.sh"

# Note: Strict mode is not set here to allow sourcing from various scripts
# Individual scripts should set their own error handling as needed

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
    echo -e "${BLUE}🔧 $1${NC}"
    log_message "STEP: $1"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
    log_message "SUCCESS: $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    log_message "WARNING: $1"
}

print_error() {
    echo -e "${RED}❌ $1${NC}" >&2
    log_message "ERROR: $1"
}

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
    log_message "INFO: $1"
}

print_dry_run() {
    echo -e "${PURPLE}🔍 [DRY RUN] $1${NC}"
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
        case "${response,,}" in
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
    local filled=$((percentage * width / 100))
    local empty=$((width - filled))
    
    # Build the bar
    printf "\r${BLUE}$message: [${NC}"
    printf "%${filled}s" | tr ' ' '='
    printf "%${empty}s" | tr ' ' '>'
    printf "${BLUE}] $percentage%%${NC}"
    
    # Clear line when complete
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
    
    if [[ $exit_code -eq 0 ]]; then
        printf "\r${GREEN}✓ $message completed${NC}\n"
    else
        printf "\r${RED}✗ $message failed${NC}\n"
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

# Set up exit trap
trap cleanup EXIT

# Export common variables for child scripts
export ROOT_DIR
export LIB_DIR="$ROOT_DIR/lib"
export SCRIPTS_DIR="$ROOT_DIR/scripts"
export DOTFILES_DIR="$ROOT_DIR/dotfiles"

# Export functions for progress tracking
export -f show_progress
export -f show_progress_bar
export -f execute_with_progress

# Initialization message
if [[ "${COMMON_LIB_LOADED:-}" != "true" ]]; then
    export COMMON_LIB_LOADED="true"
    [[ "$VERBOSE" == "true" ]] && print_info "Common library loaded from: ${BASH_SOURCE[0]}"
fi