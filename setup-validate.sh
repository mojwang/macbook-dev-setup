#!/bin/bash

# Development Environment Preview Script
# Fast validation and dry-run mode
# For macOS Apple Silicon

VERSION="2.0.0-validate"

# Load common library
source "$(dirname "$0")/lib/common.sh"

# Environment variables (same as main setup)
VERBOSE="${SETUP_VERBOSE:-false}"
LOG_FILE="${SETUP_LOG:-}"

# Script start time
SCRIPT_START_TIME=$(date +%s)

# Detect setup state (same logic as main setup)
detect_setup_state() {
    local state="fresh"
    
    if command -v brew &> /dev/null; then
        state="update"
    fi
    
    if [[ -f "$HOME/.zshrc" ]] && grep -q "macbook-dev-setup" "$HOME/.zshrc" 2>/dev/null; then
        state="update"
    fi
    
    echo "$state"
}

# Add missing print_section function
print_section() {
    echo ""
    echo -e "${BLUE}→ $1${NC}"
    echo "$(echo "$1" | sed 's/./-/g')"
}

# Main validation function
run_preview() {
    local setup_state=$(detect_setup_state)
    local is_minimal="${1:-false}"
    
    echo -e "${BLUE}» Preview Mode${NC}"
    echo "==============="
    echo ""
    
    # Show detected state
    if [[ "$setup_state" == "fresh" ]]; then
        print_info "Detected: Fresh installation"
        echo ""
        echo "What would happen:"
        echo "• Install Xcode Command Line Tools (if needed)"
        echo "• Install Homebrew package manager"
        if [[ "$is_minimal" == "true" ]]; then
            echo "• Install essential packages only (from Brewfile.minimal)"
        else
            echo "• Install all packages from Brewfile"
        fi
        echo "• Configure shell with dotfiles"
        echo "• Set up VS Code and extensions"
        echo "• Configure macOS settings"
        echo "• Create backup of existing configs"
        echo ""
    else
        print_info "Detected: Existing installation"
        echo ""
        echo "What would happen:"
        echo "• Check for new packages in config files"
        echo "• Update all installed packages"
        echo "• Sync VS Code extensions"
        echo "• Update shell configurations"
        echo "• Create backup before changes"
        echo ""
    fi
    
    # Check prerequisites
    print_section "Checking Prerequisites"
    
    local issues=0
    
    # Check Xcode Command Line Tools
    if ! xcode-select -p &>/dev/null; then
        print_warning "Xcode Command Line Tools not installed"
        echo "  → Would install via: xcode-select --install"
        ((issues++))
    else
        print_success "Xcode Command Line Tools installed"
    fi
    
    # Check disk space
    local free_space_gb=$(df -g / | awk 'NR==2 {print $4}')
    if [[ $free_space_gb -lt 5 ]]; then
        print_warning "Low disk space: ${free_space_gb}GB free"
        echo "  → Recommended: 5GB+ for installations"
        ((issues++))
    else
        print_success "Disk space: ${free_space_gb}GB free"
    fi
    
    # Check for Homebrew
    if ! command -v brew &>/dev/null; then
        print_warning "Homebrew not installed"
        echo "  → Would install from brew.sh"
    else
        print_success "Homebrew installed: $(brew --version | head -n1)"
    fi
    
    # Validate configuration files
    print_section "Validating Configuration Files"
    
    local required_files=(
        "homebrew/Brewfile"
        "scripts/install-homebrew.sh"
        "scripts/install-packages.sh"
        "scripts/setup-dotfiles.sh"
        "lib/common.sh"
    )
    
    local missing=0
    for file in "${required_files[@]}"; do
        if [[ -f "$file" ]]; then
            print_success "Found: $file"
        else
            print_error "Missing: $file"
            ((missing++))
        fi
    done
    
    if [[ $missing -gt 0 ]]; then
        echo ""
        print_error "Cannot proceed: $missing required files missing"
        exit 1
    fi
    
    # Show what would be installed
    if [[ "$setup_state" == "fresh" ]] || [[ "$is_minimal" == "true" ]]; then
        print_section "Packages to Install"
        
        local brewfile="homebrew/Brewfile"
        if [[ "$is_minimal" == "true" ]] && [[ -f "homebrew/Brewfile.minimal" ]]; then
            brewfile="homebrew/Brewfile.minimal"
            print_info "Using minimal package set"
        fi
        
        # Count packages
        local formulae=$(grep -c "^brew " "$brewfile" 2>/dev/null || echo 0)
        local casks=$(grep -c "^cask " "$brewfile" 2>/dev/null || echo 0)
        local total=$((formulae + casks))
        
        echo "• Formulae: $formulae packages"
        echo "• Casks: $casks applications"
        echo "• Total: $total items"
        
        if [[ "$VERBOSE" == "true" ]]; then
            echo ""
            echo "Formulae to install:"
            grep "^brew " "$brewfile" | sed 's/brew /  - /' | head -20
            if [[ $formulae -gt 20 ]]; then
                echo "  ... and $((formulae - 20)) more"
            fi
            
            echo ""
            echo "Applications to install:"
            grep "^cask " "$brewfile" | sed 's/cask /  - /' | head -10
            if [[ $casks -gt 10 ]]; then
                echo "  ... and $((casks - 10)) more"
            fi
        fi
    fi
    
    # Show update information
    if [[ "$setup_state" == "update" ]]; then
        print_section "Updates Available"
        
        if command -v brew &>/dev/null; then
            # Quick check for outdated packages
            local outdated=$(brew outdated --quiet 2>/dev/null | wc -l | xargs)
            if [[ $outdated -gt 0 ]]; then
                echo "• Homebrew packages: $outdated updates available"
                if [[ "$VERBOSE" == "true" ]]; then
                    echo "Outdated packages:"
                    brew outdated --quiet 2>/dev/null | head -10 | sed 's/^/  - /'
                    if [[ $outdated -gt 10 ]]; then
                        echo "  ... and $((outdated - 10)) more"
                    fi
                fi
            else
                print_success "All Homebrew packages up to date"
            fi
        fi
    fi
    
    # Summary
    local duration=$(($(date +%s) - SCRIPT_START_TIME))
    echo ""
    print_section "Summary"
    echo "Setup state: $setup_state"
    echo "Issues found: $issues"
    echo "Preview completed in: ${duration}s"
    echo ""
    
    if [[ $issues -eq 0 ]]; then
        print_success "Ready to run setup!"
        echo ""
        echo "To proceed with installation:"
        if [[ "$is_minimal" == "true" ]]; then
            echo "  ./setup.sh minimal"
        else
            echo "  ./setup.sh"
        fi
    else
        print_warning "Please address the issues above before running setup"
    fi
}

# Main script logic - support being called directly or from setup.sh
case "${1:-preview}" in
    "minimal")
        run_preview true
        ;;
    *)
        run_preview false
        ;;
esac