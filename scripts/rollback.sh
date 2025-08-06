#!/usr/bin/env bash

# Rollback script to restore from a previous restore point

# Load common library
source "$(dirname "$0")/../lib/common.sh"

# Cleanup function
cleanup_rollback() {
    if [[ -n "${temp_requirements:-}" ]] && [[ -f "$temp_requirements" ]]; then
        rm -f "$temp_requirements"
    fi
}

# Set up cleanup trap for all signals
trap cleanup_rollback EXIT INT TERM HUP

# Show available restore points
show_restore_points() {
    local restore_dir="$HOME/.setup_restore"
    
    if [[ ! -d "$restore_dir" ]]; then
        print_error "No restore points found"
        return 1
    fi
    
    echo -e "${BLUE}Available Restore Points${NC}"
    echo "========================"
    echo ""
    
    local points=()
    local index=1
    
    # Find all restore points
    for point in "$restore_dir"/*; do
        if [[ -d "$point" && -f "$point/metadata.json" ]]; then
            local timestamp=$(basename "$point")
            local date=$(grep '"date"' "$point/metadata.json" | cut -d'"' -f4)
            local name=$(grep '"name"' "$point/metadata.json" | cut -d'"' -f4)
            
            points+=("$point")
            echo "$index) $timestamp - $name"
            echo "   Created: $date"
            echo ""
            ((index++))
        fi
    done
    
    if [[ ${#points[@]} -eq 0 ]]; then
        print_error "No valid restore points found"
        return 1
    fi
    
    # Check for latest
    if [[ -f "$restore_dir/latest" ]]; then
        local latest=$(cat "$restore_dir/latest")
        if [[ -d "$latest" ]]; then
            echo "Latest restore point: $(basename "$latest")"
            echo ""
        fi
    fi
    
    return 0
}

# Restore from a specific point
restore_from_point() {
    local restore_point="$1"
    
    if [[ ! -d "$restore_point" ]]; then
        print_error "Restore point not found: $restore_point"
        return 1
    fi
    
    print_step "Restoring from: $(basename "$restore_point")"
    
    # Show metadata
    if [[ -f "$restore_point/metadata.json" ]]; then
        echo "Restore point details:"
        cat "$restore_point/metadata.json" | grep -E '"(name|date|script)"' | sed 's/^/  /'
        echo ""
    fi
    
    # Create backup of current state
    print_step "Creating backup of current state..."
    local current_backup="$HOME/.setup_rollback_backup_$TIMESTAMP"
    mkdir -p "$current_backup"
    
    # Backup current important files
    for file in ~/.zshrc ~/.gitconfig ~/.config/nvim ~/.scripts; do
        if [[ -e "$file" ]]; then
            backup_item "$file" "$current_backup"
        fi
    done
    
    print_success "Current state backed up to: $current_backup"
    
    # Restore Homebrew packages
    if [[ -f "$restore_point/brew_list.txt" ]] && command_exists brew; then
        print_step "Analyzing Homebrew packages..."
        
        # Get current and restore point package lists
        local current_formulae=$(brew list --formula 2>/dev/null | sort)
        local restore_formulae=$(cat "$restore_point/brew_list.txt" | sort)
        
        # Find packages to remove (in current but not in restore)
        local to_remove=$(comm -23 <(echo "$current_formulae") <(echo "$restore_formulae"))
        
        if [[ -n "$to_remove" ]]; then
            print_warning "Packages to remove:"
            echo "$to_remove" | sed 's/^/  - /'
            
            if confirm "Remove these packages?" "n"; then
                for pkg in $to_remove; do
                    print_step "Removing: $pkg"
                    brew uninstall "$pkg" 2>/dev/null || true
                done
            fi
        fi
        
        # Find packages to install (in restore but not in current)
        local to_install=$(comm -13 <(echo "$current_formulae") <(echo "$restore_formulae"))
        
        if [[ -n "$to_install" ]]; then
            print_info "Packages to install:"
            echo "$to_install" | sed 's/^/  + /'
            
            if confirm "Install these packages?" "y"; then
                for pkg in $to_install; do
                    print_step "Installing: $pkg"
                    brew install "$pkg" 2>/dev/null || true
                done
            fi
        fi
    fi
    
    # Restore npm packages
    if [[ -f "$restore_point/npm_global.txt" ]] && command_exists npm; then
        print_step "Restoring npm global packages..."
        
        # Extract package names from npm list output
        local restore_packages=$(grep -E '^[├└]' "$restore_point/npm_global.txt" | sed 's/^[├└]── //' | cut -d@ -f1)
        
        if [[ -n "$restore_packages" ]]; then
            print_info "npm packages to restore:"
            echo "$restore_packages" | sed 's/^/  /'
            
            if confirm "Restore npm packages?" "y"; then
                for pkg in $restore_packages; do
                    npm install -g "$pkg" 2>/dev/null || true
                done
            fi
        fi
    fi
    
    # Restore Python packages
    if [[ -f "$restore_point/pip_list.txt" ]] && command_exists pip3; then
        print_step "Restoring Python packages..."
        
        # Create requirements file from pip list
        local temp_requirements=$(mktemp)
        grep -v "^Package" "$restore_point/pip_list.txt" | grep -v "^-" | awk '{print $1"=="$2}' > "$temp_requirements"
        
        if [[ -s "$temp_requirements" ]]; then
            print_info "Python packages to restore: $(wc -l < "$temp_requirements") packages"
            
            if confirm "Restore Python packages?" "y"; then
                pip3 install -r "$temp_requirements" 2>/dev/null || true
            fi
        fi
    fi
    
    print_success "Rollback completed!"
    echo ""
    echo "Important notes:"
    echo "  • Configuration files were NOT restored (to preserve your customizations)"
    echo "  • Your current state was backed up to: $current_backup"
    echo "  • Some packages may require manual intervention"
    echo "  • Run './scripts/health-check.sh' to verify system state"
}

# Main function
main() {
    echo -e "${BLUE}"
    echo "🔄 Development Environment Rollback"
    echo "==================================="
    echo -e "${NC}"
    
    # Check for command line arguments
    if [[ $# -gt 0 ]]; then
        case "$1" in
            --list|-l)
                show_restore_points
                exit $?
                ;;
            --latest)
                # Restore from latest
                local latest=$(get_latest_restore_point)
                if [[ -n "$latest" ]]; then
                    restore_from_point "$latest"
                else
                    print_error "No latest restore point found"
                    exit 1
                fi
                exit $?
                ;;
            --help|-h)
                cat << EOF
Rollback Script - Restore from a previous restore point

Usage: $0 [OPTIONS] [RESTORE_POINT]

Options:
    -l, --list      List available restore points
    --latest        Restore from the latest restore point
    -h, --help      Show this help message

Examples:
    $0                  # Interactive mode
    $0 --list           # Show all restore points
    $0 --latest         # Restore from latest point
    $0 20240112_123456  # Restore from specific point

Restore points are created automatically by:
  • setup.sh (before setup)
  • update.sh (before updates)
  • Manual restore point creation
EOF
                exit 0
                ;;
            *)
                # Assume it's a restore point timestamp
                restore_from_point "$HOME/.setup_restore/$1"
                exit $?
                ;;
        esac
    fi
    
    # Interactive mode
    if ! show_restore_points; then
        exit 1
    fi
    
    echo -n "Select a restore point number (or 'q' to quit): "
    read -r selection
    
    if [[ "$selection" == "q" ]]; then
        print_info "Rollback cancelled"
        exit 0
    fi
    
    # Find the selected restore point
    local restore_dir="$HOME/.setup_restore"
    local points=()
    
    for point in "$restore_dir"/*; do
        if [[ -d "$point" && -f "$point/metadata.json" ]]; then
            points+=("$point")
        fi
    done
    
    if [[ "$selection" =~ ^[0-9]+$ ]] && [[ $selection -ge 1 ]] && [[ $selection -le ${#points[@]} ]]; then
        local selected_point="${points[$((selection-1))]}"
        
        echo ""
        print_warning "This will modify your installed packages to match the restore point."
        print_warning "Your current configuration will be backed up first."
        echo ""
        
        if confirm "Proceed with rollback?" "n"; then
            restore_from_point "$selected_point"
        else
            print_info "Rollback cancelled"
        fi
    else
        print_error "Invalid selection"
        exit 1
    fi
}

# Run main function
main "$@"