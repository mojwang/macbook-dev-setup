#!/usr/bin/env bash

# Cleanup script to remove accumulated test artifacts and temporary files
# This provides a safety net for interrupted scripts that didn't clean up properly

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Source common functions for colored output
source "$ROOT_DIR/lib/common.sh"

# Default to dry-run mode for safety
DRY_RUN=true
VERBOSE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --execute|-e)
            DRY_RUN=false
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --execute, -e    Actually remove files (default is dry-run)"
            echo "  --verbose, -v    Show detailed output"
            echo "  --help, -h       Show this help message"
            echo ""
            echo "This script cleans up:"
            echo "  - Test backup directories (.test-setup-backups-*)"
            echo "  - Temporary test files in tests directory"
            echo "  - Old dotfiles backups (older than 30 days)"
            echo "  - Old setup restore points (older than 30 days)"
            echo "  - Orphaned test artifacts"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Function to safely remove items
safe_remove() {
    local item="$1"
    local type="$2"  # "file" or "directory"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "  Would remove: $item"
    else
        if [[ "$type" == "directory" ]]; then
            rm -rf "$item" 2>/dev/null && [[ "$VERBOSE" == "true" ]] && echo "  Removed: $item"
        else
            rm -f "$item" 2>/dev/null && [[ "$VERBOSE" == "true" ]] && echo "  Removed: $item"
        fi
    fi
}

# Start cleanup
if [[ "$DRY_RUN" == "true" ]]; then
    print_step "Running in DRY-RUN mode (use --execute to actually remove files)"
else
    print_warning "Running in EXECUTE mode - files will be removed!"
fi

echo ""

# 1. Clean up test backup directories
print_step "Checking for test backup directories..."
test_backup_count=$(find "$HOME" -maxdepth 1 -name ".test-setup-backups-*" -type d 2>/dev/null | wc -l)
if [[ $test_backup_count -gt 0 ]]; then
    echo "Found $test_backup_count test backup directories"
    find "$HOME" -maxdepth 1 -name ".test-setup-backups-*" -type d 2>/dev/null | while read -r dir; do
        safe_remove "$dir" "directory"
    done
else
    echo "No test backup directories found"
fi

# 2. Clean up temporary files in tests directory
print_step "Checking for temporary files in tests directory..."
if [[ -d "$ROOT_DIR/tests" ]]; then
    temp_file_count=$(find "$ROOT_DIR/tests" -name "tmp.*" -o -name "failing_test.*" -o -name "interrupt_test.*" -o -name "timeout_cleanup.*" -o -name "trap_test.*" -o -name "syntax_test.*" 2>/dev/null | wc -l)
    if [[ $temp_file_count -gt 0 ]]; then
        echo "Found $temp_file_count temporary test files"
        find "$ROOT_DIR/tests" \( -name "tmp.*" -o -name "failing_test.*" -o -name "interrupt_test.*" -o -name "timeout_cleanup.*" -o -name "trap_test.*" -o -name "syntax_test.*" \) 2>/dev/null | while read -r file; do
            safe_remove "$file" "file"
        done
    else
        echo "No temporary test files found"
    fi
fi

# 3. Clean up old dotfiles backups (older than 30 days)
print_step "Checking for old dotfiles backups..."
old_backup_count=$(find "$HOME" -maxdepth 1 -name ".dotfiles_backup_*" -type d -mtime +30 2>/dev/null | wc -l)
if [[ $old_backup_count -gt 0 ]]; then
    echo "Found $old_backup_count old dotfiles backups (>30 days)"
    find "$HOME" -maxdepth 1 -name ".dotfiles_backup_*" -type d -mtime +30 2>/dev/null | while read -r dir; do
        safe_remove "$dir" "directory"
    done
else
    echo "No old dotfiles backups found"
fi

# 4. Clean up old setup backup directories (older than 30 days)
print_step "Checking for old setup backups..."
if [[ -d "$HOME/.setup_backup" ]]; then
    old_setup_count=$(find "$HOME/.setup_backup" -mindepth 1 -maxdepth 1 -type d -mtime +30 2>/dev/null | wc -l)
    if [[ $old_setup_count -gt 0 ]]; then
        echo "Found $old_setup_count old setup backups (>30 days)"
        find "$HOME/.setup_backup" -mindepth 1 -maxdepth 1 -type d -mtime +30 2>/dev/null | while read -r dir; do
            safe_remove "$dir" "directory"
        done
    else
        echo "No old setup backups found"
    fi
fi

# 5. Clean up old restore points (older than 30 days)
print_step "Checking for old restore points..."
if [[ -d "$HOME/.setup_restore" ]]; then
    old_restore_count=$(find "$HOME/.setup_restore" -mindepth 1 -maxdepth 1 -type d -mtime +30 2>/dev/null | wc -l)
    if [[ $old_restore_count -gt 0 ]]; then
        echo "Found $old_restore_count old restore points (>30 days)"
        find "$HOME/.setup_restore" -mindepth 1 -maxdepth 1 -type d -mtime +30 2>/dev/null | while read -r dir; do
            safe_remove "$dir" "directory"
        done
    else
        echo "No old restore points found"
    fi
fi

# 6. Clean up rollback backups
print_step "Checking for old rollback backups..."
rollback_count=$(find "$HOME" -maxdepth 1 -name ".setup_rollback_backup_*" -type d 2>/dev/null | wc -l)
if [[ $rollback_count -gt 0 ]]; then
    echo "Found $rollback_count rollback backup directories"
    find "$HOME" -maxdepth 1 -name ".setup_rollback_backup_*" -type d 2>/dev/null | while read -r dir; do
        safe_remove "$dir" "directory"
    done
else
    echo "No rollback backup directories found"
fi

# Summary
echo ""
if [[ "$DRY_RUN" == "true" ]]; then
    print_info "Dry-run complete. Use '$0 --execute' to actually remove files."
else
    print_success "Cleanup complete!"
fi

# Add to crontab suggestion
echo ""
print_info "TIP: To run this cleanup automatically, add to crontab:"
echo "  0 3 * * 0 $SCRIPT_DIR/cleanup-artifacts.sh --execute"
echo "  (Runs every Sunday at 3 AM)"