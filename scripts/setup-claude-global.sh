#!/bin/bash

# Setup global CLAUDE.md configuration
# This provides baseline Claude Code instructions across all projects

set -e

# Load common library
source "$(dirname "$0")/../lib/common.sh"

# Configuration
CLAUDE_DIR="$HOME/.claude"
CLAUDE_GLOBAL_MD="$CLAUDE_DIR/CLAUDE.md"
TEMPLATE_FILE="$(dirname "$0")/../config/global-claude.md"

setup_global_claude() {
    print_info "Setting up global Claude Code configuration..."
    
    # Create .claude directory if it doesn't exist
    if [[ ! -d "$CLAUDE_DIR" ]]; then
        print_step "Creating $CLAUDE_DIR directory..."
        mkdir -p "$CLAUDE_DIR"
        print_success "Created $CLAUDE_DIR"
    fi
    
    # Check if global CLAUDE.md already exists
    if [[ -f "$CLAUDE_GLOBAL_MD" ]]; then
        print_warning "Global CLAUDE.md already exists at $CLAUDE_GLOBAL_MD"
        
        # Show diff if files differ
        if ! diff -q "$TEMPLATE_FILE" "$CLAUDE_GLOBAL_MD" >/dev/null 2>&1; then
            print_info "Differences found between template and existing file:"
            diff -u "$CLAUDE_GLOBAL_MD" "$TEMPLATE_FILE" || true
            
            read -p "Do you want to update the global CLAUDE.md? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                # Backup existing file
                backup_file="$CLAUDE_GLOBAL_MD.backup.$(date +%Y%m%d_%H%M%S)"
                cp "$CLAUDE_GLOBAL_MD" "$backup_file"
                print_info "Backed up existing file to: $backup_file"
                
                # Copy new template
                cp "$TEMPLATE_FILE" "$CLAUDE_GLOBAL_MD"
                print_success "Updated global CLAUDE.md"
            else
                print_info "Keeping existing global CLAUDE.md"
            fi
        else
            print_success "Global CLAUDE.md is up to date"
        fi
    else
        # Copy template to global location
        print_step "Installing global CLAUDE.md..."
        cp "$TEMPLATE_FILE" "$CLAUDE_GLOBAL_MD"
        print_success "Installed global CLAUDE.md at $CLAUDE_GLOBAL_MD"
    fi
    
    # Set appropriate permissions
    chmod 644 "$CLAUDE_GLOBAL_MD"
    
    print_success "Global Claude Code configuration complete!"
}

# Main execution
case "${1:-}" in
    --check)
        # Just check if it exists and is up to date
        if [[ -f "$CLAUDE_GLOBAL_MD" ]]; then
            if diff -q "$TEMPLATE_FILE" "$CLAUDE_GLOBAL_MD" >/dev/null 2>&1; then
                exit 0  # Up to date
            else
                exit 1  # Needs update
            fi
        else
            exit 1  # Doesn't exist
        fi
        ;;
    *)
        setup_global_claude
        ;;
esac