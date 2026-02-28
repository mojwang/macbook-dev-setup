#!/usr/bin/env bash

# Setup global CLAUDE.md configuration
# This provides baseline Claude Code instructions across all projects

set -e

# Load common library
source "$(dirname "$0")/../lib/common.sh"

# Load signal safety library
# ROOT_DIR is already set by common.sh
source "$ROOT_DIR/lib/signal-safety.sh"

# Load UI presentation layer
source "$ROOT_DIR/lib/ui.sh"

# Claude global setup specific cleanup
cleanup_claude_global() {
    # Clean up any temporary files
    [[ -n "${backup_file:-}" ]] && [[ -f "${backup_file}.tmp" ]] && rm -f "${backup_file}.tmp" 2>/dev/null || true
    
    # Clean up incomplete installations
    [[ -n "${CLAUDE_GLOBAL_MD:-}" ]] && [[ -f "${CLAUDE_GLOBAL_MD}.tmp" ]] && rm -f "${CLAUDE_GLOBAL_MD}.tmp" 2>/dev/null || true
    
    # Call default cleanup
    default_cleanup
}

# Set up cleanup trap
setup_cleanup "cleanup_claude_global"

# Configuration
CLAUDE_DIR="$HOME/.claude"
CLAUDE_GLOBAL_MD="$CLAUDE_DIR/CLAUDE.md"
TEMPLATE_FILE="$(dirname "$0")/../config/global-claude.md"

# Version information
TEMPLATE_VERSION="2.0.0"
VERSION_MARKER="# Claude Global Config Version:"

setup_global_claude() {
    print_info "Setting up global Claude Code configuration..."
    
    # Validate template file exists
    if [[ ! -f "$TEMPLATE_FILE" ]]; then
        print_error "Template file not found: $TEMPLATE_FILE"
        exit 1
    fi
    
    # Create .claude directory if it doesn't exist
    if [[ ! -d "$CLAUDE_DIR" ]]; then
        print_step "Creating $CLAUDE_DIR directory..."
        if ! mkdir -p "$CLAUDE_DIR"; then
            print_error "Failed to create directory: $CLAUDE_DIR"
            exit 1
        fi
        print_success "Created $CLAUDE_DIR"
    fi
    
    # Check if global CLAUDE.md already exists
    if [[ -f "$CLAUDE_GLOBAL_MD" ]]; then
        print_warning "Global CLAUDE.md already exists at $CLAUDE_GLOBAL_MD"
        
        # Get current version if it exists
        local current_version=""
        if grep -q "^$VERSION_MARKER" "$CLAUDE_GLOBAL_MD" 2>/dev/null; then
            current_version=$(grep "^$VERSION_MARKER" "$CLAUDE_GLOBAL_MD" | sed "s/^$VERSION_MARKER *//")
        fi
        
        # Cache diff result to avoid running twice
        local diff_output=""
        if ! diff -q "$TEMPLATE_FILE" "$CLAUDE_GLOBAL_MD" >/dev/null 2>&1; then
            diff_output=$(diff -u "$CLAUDE_GLOBAL_MD" "$TEMPLATE_FILE" || true)

            # Count added/removed lines
            local lines_added lines_removed
            lines_added=$(echo "$diff_output" | grep -c '^+[^+]' || true)
            lines_removed=$(echo "$diff_output" | grep -c '^-[^-]' || true)

            ui_section_header "CLAUDE.md Update Available"
            echo "  Version: ${current_version:-unknown} → ${TEMPLATE_VERSION}"
            echo "  Changes: +${lines_added} added, -${lines_removed} removed"
            echo ""
            ui_diff_style_select
            ui_diff "$CLAUDE_GLOBAL_MD" "$TEMPLATE_FILE"

            # Check if we're in CI or non-interactive mode
            if [[ "${CI:-false}" == "true" ]] || [[ ! -t 0 ]]; then
                print_info "Running in non-interactive mode, keeping existing file"
                if [[ -n "$current_version" ]] && [[ "$current_version" != "$TEMPLATE_VERSION" ]]; then
                    print_warning "Note: Template version ($TEMPLATE_VERSION) differs from installed version ($current_version)"
                fi
            else
                if ui_confirm "Update global CLAUDE.md to version ${TEMPLATE_VERSION}?" "n"; then
                    # Backup existing file with PID to prevent collisions
                    backup_file="$CLAUDE_GLOBAL_MD.backup.$(date +%Y%m%d_%H%M%S)_$$"
                    cp "$CLAUDE_GLOBAL_MD" "$backup_file"
                    print_info "Backed up existing file to: $backup_file"
                    
                    # Copy new template with version metadata
                    install_template_with_metadata
                    print_success "Updated global CLAUDE.md"
                else
                    print_info "Keeping existing global CLAUDE.md"
                fi
            fi
        else
            # Check version even if content is identical
            if [[ -n "$current_version" ]] && [[ "$current_version" != "$TEMPLATE_VERSION" ]]; then
                print_info "Content is identical but version metadata differs"
                print_info "Installed: ${current_version:-unknown}, Template: $TEMPLATE_VERSION"
            else
                print_success "Global CLAUDE.md is up to date (version $TEMPLATE_VERSION)"
            fi
        fi
    else
        # Copy template to global location
        print_step "Installing global CLAUDE.md..."
        install_template_with_metadata
        print_success "Installed global CLAUDE.md at $CLAUDE_GLOBAL_MD (version $TEMPLATE_VERSION)"
    fi
    
    # Set appropriate permissions
    chmod 644 "$CLAUDE_GLOBAL_MD"
    
    print_success "Global Claude Code configuration complete!"
}

# Function to install template with version metadata
install_template_with_metadata() {
    local temp_file="${CLAUDE_GLOBAL_MD}.tmp.$$"
    
    # Write to temporary file first for atomic operation
    {
        echo "$VERSION_MARKER $TEMPLATE_VERSION"
        echo "# Last Updated: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "# Source: macbook-dev-setup/config/global-claude.md"
        echo ""
        cat "$TEMPLATE_FILE"
    } > "$temp_file"
    
    # Atomically move the file
    mv -f "$temp_file" "$CLAUDE_GLOBAL_MD"
}

# Main execution
case "${1:-}" in
    --check)
        # Validate template exists first
        if [[ ! -f "$TEMPLATE_FILE" ]]; then
            print_error "Template file not found: $TEMPLATE_FILE"
            exit 2
        fi
        
        # Just check if it exists and is up to date
        if [[ -f "$CLAUDE_GLOBAL_MD" ]]; then
            # Check content differences
            content_matches=true
            if ! diff -q "$TEMPLATE_FILE" "$CLAUDE_GLOBAL_MD" >/dev/null 2>&1; then
                content_matches=false
            fi
            
            # Check version
            current_version=""
            if grep -q "^$VERSION_MARKER" "$CLAUDE_GLOBAL_MD" 2>/dev/null; then
                current_version=$(grep "^$VERSION_MARKER" "$CLAUDE_GLOBAL_MD" | sed "s/^$VERSION_MARKER *//")
            fi
            
            if [[ "$content_matches" == "true" ]] && [[ "$current_version" == "$TEMPLATE_VERSION" ]]; then
                exit 0  # Up to date
            else
                exit 1  # Needs update
            fi
        else
            exit 1  # Doesn't exist
        fi
        ;;
    --version)
        echo "Template version: $TEMPLATE_VERSION"
        if [[ -f "$CLAUDE_GLOBAL_MD" ]]; then
            current_version=""
            if grep -q "^$VERSION_MARKER" "$CLAUDE_GLOBAL_MD" 2>/dev/null; then
                current_version=$(grep "^$VERSION_MARKER" "$CLAUDE_GLOBAL_MD" | sed "s/^$VERSION_MARKER *//")
            fi
            echo "Installed version: ${current_version:-unknown}"
        else
            echo "Not installed"
        fi
        ;;
    --help)
        echo "Usage: $0 [OPTIONS]"
        echo "Setup global CLAUDE.md configuration for Claude Code"
        echo ""
        echo "Options:"
        echo "  --check     Check if global config exists and is up to date"
        echo "  --version   Show template and installed versions"
        echo "  --help      Show this help message"
        echo ""
        echo "Environment variables:"
        echo "  CI          Set to 'true' to run in non-interactive mode"
        ;;
    *)
        setup_global_claude
        ;;
esac