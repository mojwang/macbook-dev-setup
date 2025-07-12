#!/bin/bash

# Cleanup script to free up disk space and remove unnecessary files

# Load common library
source "$(dirname "$0")/../lib/common.sh"

# Track cleanup stats
TOTAL_FREED=0
CLEANUP_ACTIONS=0

# Convert sizes to MB for consistent reporting
to_mb() {
    local size="$1"
    # Handle different size formats (B, K, M, G)
    if [[ "$size" =~ ([0-9.]+)([BKMG]) ]]; then
        local num="${BASH_REMATCH[1]}"
        local unit="${BASH_REMATCH[2]}"
        case "$unit" in
            B) echo "scale=2; $num / 1048576" | bc ;;
            K) echo "scale=2; $num / 1024" | bc ;;
            M) echo "$num" ;;
            G) echo "scale=2; $num * 1024" | bc ;;
            *) echo "0" ;;
        esac
    else
        echo "0"
    fi
}

# Cleanup Homebrew
cleanup_homebrew() {
    if ! command_exists brew; then
        print_warning "Homebrew not found, skipping"
        return 0
    fi
    
    print_step "Cleaning up Homebrew..."
    
    # Get size before cleanup
    local before_size=$(brew cleanup -n 2>/dev/null | grep "Would remove" | tail -1 | awk '{print $3}' || echo "0MB")
    
    if [[ "$before_size" != "0MB" ]]; then
        print_info "Can free up approximately $before_size"
        
        if confirm "Proceed with Homebrew cleanup?"; then
            # Clean up old versions
            execute_with_progress "brew cleanup --prune=all" "Removing old formulae and casks"
            
            # Clean up downloads
            execute_with_progress "brew cleanup -s" "Cleaning downloads cache"
            
            # Remove unused dependencies
            execute_with_progress "brew autoremove" "Removing unused dependencies"
            
            ((CLEANUP_ACTIONS++))
            print_success "Homebrew cleanup completed"
        else
            print_info "Skipping Homebrew cleanup"
        fi
    else
        print_info "Homebrew cache is already clean"
    fi
}

# Cleanup npm cache
cleanup_npm() {
    if ! command_exists npm; then
        print_warning "npm not found, skipping"
        return 0
    fi
    
    print_step "Cleaning up npm cache..."
    
    # Get cache size
    local cache_size=$(npm cache verify 2>&1 | grep "Cache verified" | grep -oE "[0-9]+(\.[0-9]+)?[BKMG]" | head -1 || echo "0")
    
    if [[ -n "$cache_size" ]] && [[ "$cache_size" != "0" ]]; then
        print_info "npm cache size: $cache_size"
        
        if confirm "Clean npm cache?"; then
            execute_with_progress "npm cache clean --force" "Cleaning npm cache"
            ((CLEANUP_ACTIONS++))
            print_success "npm cache cleaned"
        else
            print_info "Skipping npm cache cleanup"
        fi
    else
        print_info "npm cache is already clean"
    fi
}

# Cleanup pip cache
cleanup_pip() {
    if ! command_exists pip3; then
        print_warning "pip3 not found, skipping"
        return 0
    fi
    
    print_step "Cleaning up pip cache..."
    
    # Get cache info
    local cache_info=$(pip3 cache info 2>/dev/null || echo "")
    
    if [[ -n "$cache_info" ]]; then
        print_info "pip cache location: $(pip3 cache dir 2>/dev/null || echo 'unknown')"
        
        if confirm "Clean pip cache?"; then
            execute_with_progress "pip3 cache purge" "Purging pip cache"
            ((CLEANUP_ACTIONS++))
            print_success "pip cache cleaned"
        else
            print_info "Skipping pip cache cleanup"
        fi
    else
        print_info "No pip cache found"
    fi
}

# Cleanup Docker (if installed)
cleanup_docker() {
    if ! command_exists docker; then
        return 0
    fi
    
    print_step "Cleaning up Docker..."
    
    # Check if Docker daemon is running
    if ! docker info &>/dev/null; then
        print_warning "Docker daemon not running, skipping Docker cleanup"
        return 0
    fi
    
    print_info "Checking Docker disk usage..."
    docker system df
    
    if confirm "Clean up Docker (removes unused images, containers, volumes)?"; then
        execute_with_progress "docker system prune -af --volumes" "Cleaning Docker system"
        ((CLEANUP_ACTIONS++))
        print_success "Docker cleanup completed"
    else
        print_info "Skipping Docker cleanup"
    fi
}

# Cleanup macOS specific items
cleanup_macos() {
    print_step "Cleaning up macOS system files..."
    
    # Clean up Trash
    local trash_size=$(du -sh ~/.Trash 2>/dev/null | awk '{print $1}' || echo "0")
    if [[ "$trash_size" != "0" ]]; then
        print_info "Trash size: $trash_size"
        if confirm "Empty Trash?"; then
            rm -rf ~/.Trash/* 2>/dev/null
            ((CLEANUP_ACTIONS++))
            print_success "Trash emptied"
        fi
    fi
    
    # Clean up Downloads folder (old files)
    print_info "Checking Downloads folder for old files..."
    local old_downloads=$(find ~/Downloads -type f -mtime +30 2>/dev/null | wc -l | tr -d ' ')
    
    if [[ $old_downloads -gt 0 ]]; then
        print_info "Found $old_downloads files older than 30 days in Downloads"
        if confirm "Show old files in Downloads folder?"; then
            find ~/Downloads -type f -mtime +30 -exec ls -lh {} \; 2>/dev/null | head -20
            echo ""
            if confirm "Remove files older than 30 days from Downloads?"; then
                find ~/Downloads -type f -mtime +30 -delete 2>/dev/null
                ((CLEANUP_ACTIONS++))
                print_success "Old downloads removed"
            fi
        fi
    else
        print_info "No old files in Downloads folder"
    fi
    
    # Clean Xcode derived data if Xcode is installed
    if [[ -d "$HOME/Library/Developer/Xcode/DerivedData" ]]; then
        local xcode_size=$(du -sh "$HOME/Library/Developer/Xcode/DerivedData" 2>/dev/null | awk '{print $1}' || echo "0")
        if [[ "$xcode_size" != "0" ]]; then
            print_info "Xcode DerivedData size: $xcode_size"
            if confirm "Clean Xcode DerivedData?"; then
                rm -rf "$HOME/Library/Developer/Xcode/DerivedData"/*
                ((CLEANUP_ACTIONS++))
                print_success "Xcode DerivedData cleaned"
            fi
        fi
    fi
}

# Main cleanup function
main() {
    echo -e "${BLUE}"
    echo "🧹 Development Environment Cleanup"
    echo "================================="
    echo -e "${NC}"
    
    print_info "This script will help free up disk space by cleaning various caches and temporary files"
    echo ""
    
    # Show current disk usage
    print_step "Current disk usage:"
    df -h / | grep -E "^/|Filesystem"
    echo ""
    
    if ! confirm "Proceed with cleanup?"; then
        print_info "Cleanup cancelled"
        exit 0
    fi
    
    # Run cleanup tasks
    cleanup_homebrew
    echo ""
    
    cleanup_npm
    echo ""
    
    cleanup_pip
    echo ""
    
    cleanup_docker
    echo ""
    
    cleanup_macos
    echo ""
    
    # Summary
    echo -e "${BLUE}"
    echo "Cleanup Summary"
    echo "==============="
    echo -e "${NC}"
    
    print_success "Completed $CLEANUP_ACTIONS cleanup actions"
    
    # Show new disk usage
    print_step "Updated disk usage:"
    df -h / | grep -E "^/|Filesystem"
    echo ""
    
    print_info "Tip: Run this script periodically to keep your system clean"
    print_info "Consider adding to your monthly maintenance routine"
}

# Check for options
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    cat << EOF
Cleanup Script - Free up disk space in your development environment

Usage: $0 [OPTIONS]

Options:
    -h, --help    Show this help message
    
This script cleans:
  • Homebrew cache and old versions
  • npm cache
  • pip cache
  • Docker unused images/containers (if installed)
  • macOS Trash
  • Old Downloads (>30 days)
  • Xcode DerivedData (if present)

All cleanup actions are optional and require confirmation.
EOF
    exit 0
fi

# Run main function
main "$@"