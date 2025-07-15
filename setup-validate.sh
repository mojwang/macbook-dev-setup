#!/bin/bash

# Development Environment Preview Script
# Fast validation and dry-run mode
# For macOS Apple Silicon

VERSION="2.0.0-validate"

# Load common library
source "$(dirname "$0")/lib/common.sh"

# Load backup manager for validation
source "$(dirname "$0")/lib/backup-manager.sh" 2>/dev/null || true

# Environment variables (same as main setup)
VERBOSE="${SETUP_VERBOSE:-false}"
LOG_FILE="${SETUP_LOG:-}"
SETUP_NO_WARP="${SETUP_NO_WARP:-false}"
SETUP_JOBS="${SETUP_JOBS:-}"

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

# Validate backup system
validate_backup_system() {
    print_section "Validating Backup System"
    
    local issues=0
    
    # Check if backup manager exists
    if [[ -f "lib/backup-manager.sh" ]]; then
        print_success "Backup manager script found"
        
        # Check backup directory structure
        if type -t BACKUP_ROOT &>/dev/null && [[ -n "$BACKUP_ROOT" ]]; then
            print_info "Backup root would be: $BACKUP_ROOT"
            
            # Check categories
            if type -t BACKUP_CATEGORIES &>/dev/null; then
                print_success "Backup categories defined"
                if [[ "$VERBOSE" == "true" ]]; then
                    echo "  Categories: dotfiles, restore-points, configs, scripts"
                fi
            else
                print_warning "Backup categories not properly defined"
                ((issues++))
            fi
        else
            print_warning "Backup root directory not configured"
            ((issues++))
        fi
    else
        print_error "Backup manager script missing"
        ((issues++))
    fi
    
    # Check for old backup migration
    local old_backups=$(find "$HOME" -maxdepth 3 -name "*.backup" -o -name "*.bak" 2>/dev/null | grep -v "$HOME/.setup-backups" | wc -l | xargs)
    if [[ $old_backups -gt 0 ]]; then
        print_info "Found $old_backups old backup files that could be migrated"
    fi
    
    return $issues
}

# Validate Warp detection and setup
validate_warp_detection() {
    print_section "Validating Warp Terminal Detection"
    
    local issues=0
    local warp_detected=false
    local warp_reason=""
    
    # Check detection methods
    if [[ "$TERM_PROGRAM" == "WarpTerminal" ]]; then
        warp_detected=true
        warp_reason="currently using Warp Terminal"
    elif [[ -d "/Applications/Warp.app" ]]; then
        warp_detected=true
        warp_reason="Warp.app installed"
    elif command -v warp &>/dev/null; then
        warp_detected=true
        warp_reason="Warp command found"
    fi
    
    if [[ "$warp_detected" == "true" ]]; then
        print_info "Warp Terminal detected: $warp_reason"
        
        if [[ "$SETUP_NO_WARP" == "true" ]]; then
            print_warning "Warp setup disabled via SETUP_NO_WARP"
        else
            echo "  → Would offer to optimize Warp setup"
        fi
    else
        print_success "No Warp Terminal detected"
    fi
    
    # Check Warp setup script
    if [[ -f "scripts/setup-warp.sh" ]]; then
        print_success "Warp setup script found"
    else
        print_error "Warp setup script missing"
        ((issues++))
    fi
    
    return $issues
}

# Validate fix/diagnostics functionality
validate_diagnostics() {
    print_section "Validating Diagnostics System"
    
    local issues=0
    
    # Check common issues that diagnostics would find
    local diagnostic_checks=(
        "Xcode Command Line Tools"
        "Homebrew installation"
        "Shell configuration"
        "Git configuration"
        "PATH setup"
    )
    
    for check in "${diagnostic_checks[@]}"; do
        case "$check" in
            "Xcode Command Line Tools")
                if xcode-select -p &>/dev/null; then
                    print_success "$check: OK"
                else
                    print_warning "$check: Would need fixing"
                fi
                ;;
            "Homebrew installation")
                if command -v brew &>/dev/null; then
                    print_success "$check: OK"
                else
                    print_warning "$check: Would need installation"
                fi
                ;;
            "Shell configuration")
                if [[ -f "$HOME/.zshrc" ]]; then
                    print_success "$check: Found"
                else
                    print_warning "$check: Would create .zshrc"
                fi
                ;;
            "Git configuration")
                if [[ -f "$HOME/.gitconfig" ]]; then
                    print_success "$check: Found"
                else
                    print_warning "$check: Would configure"
                fi
                ;;
            "PATH setup")
                if [[ "$PATH" == *"/opt/homebrew/bin"* ]] || [[ "$PATH" == *"/usr/local/bin"* ]]; then
                    print_success "$check: Homebrew in PATH"
                else
                    print_warning "$check: Would update PATH"
                fi
                ;;
        esac
    done
    
    return $issues
}

# Validate environment variables
validate_environment_vars() {
    print_section "Validating Environment Variables"
    
    echo "Current environment settings:"
    echo "  SETUP_VERBOSE: ${SETUP_VERBOSE}"
    echo "  SETUP_LOG: ${SETUP_LOG:-<none>}"
    echo "  SETUP_JOBS: ${SETUP_JOBS:-<auto>}"
    echo "  SETUP_NO_WARP: ${SETUP_NO_WARP}"
    
    if [[ -n "$SETUP_JOBS" ]] && [[ "$SETUP_JOBS" =~ ^[0-9]+$ ]]; then
        print_success "Custom parallel jobs: $SETUP_JOBS"
    elif [[ -n "$SETUP_JOBS" ]]; then
        print_warning "Invalid SETUP_JOBS value: $SETUP_JOBS (must be a number)"
    fi
}

# Validate new command structure
validate_command_structure() {
    print_section "Validating Command Structure"
    
    local commands=("help" "preview" "minimal" "fix" "warp" "backup" "advanced")
    local issues=0
    
    echo "Available commands:"
    for cmd in "${commands[@]}"; do
        echo "  ./setup.sh $cmd"
    done
    
    # Check if setup.sh has the command structure
    if [[ -f "setup.sh" ]] && grep -q 'case "${1:-}" in' setup.sh; then
        print_success "Command structure implemented"
    else
        print_error "Command structure not found in setup.sh"
        ((issues++))
    fi
    
    return $issues
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
            # Skip Homebrew outdated check in CI environment or if explicitly disabled
            if [[ "${CI:-false}" == "true" ]] || [[ "${SKIP_BREW_OUTDATED:-false}" == "true" ]]; then
                echo "• Homebrew outdated check skipped (CI environment)"
            else
                # Quick check for outdated packages with timeout
                local outdated=0
                
                # Use timeout if available, otherwise skip the check
                if command -v gtimeout &>/dev/null; then
                    outdated=$(gtimeout 5s bash -c 'HOMEBREW_NO_AUTO_UPDATE=1 brew outdated --quiet 2>/dev/null | wc -l' | xargs || echo "0")
                elif command -v timeout &>/dev/null; then
                    outdated=$(timeout 5s bash -c 'HOMEBREW_NO_AUTO_UPDATE=1 brew outdated --quiet 2>/dev/null | wc -l' | xargs || echo "0")
                else
                    # No timeout available, skip the check to avoid hanging
                    echo "• Homebrew outdated check skipped (no timeout command)"
                    outdated=-1
                fi
                
                if [[ "$outdated" -gt 0 ]]; then
                    echo "• Homebrew packages: $outdated updates available"
                    if [[ "$VERBOSE" == "true" ]]; then
                        echo "Outdated packages:"
                        HOMEBREW_NO_AUTO_UPDATE=1 brew outdated --quiet 2>/dev/null | head -10 | sed 's/^/  - /'
                        if [[ $outdated -gt 10 ]]; then
                            echo "  ... and $((outdated - 10)) more"
                        fi
                    fi
                elif [[ "$outdated" == "0" ]]; then
                    print_success "All Homebrew packages up to date"
                fi
            fi
        fi
    fi
    
    # Run additional validations
    local total_issues=$issues
    
    # Validate new features
    validate_backup_system
    ((total_issues+=$?))
    
    validate_warp_detection
    ((total_issues+=$?))
    
    validate_diagnostics
    ((total_issues+=$?))
    
    validate_environment_vars
    
    validate_command_structure
    ((total_issues+=$?))
    
    # Summary
    local duration=$(($(date +%s) - SCRIPT_START_TIME))
    echo ""
    print_section "Summary"
    echo "Setup state: $setup_state"
    echo "Total issues found: $total_issues"
    echo "Preview completed in: ${duration}s"
    echo ""
    
    if [[ $total_issues -eq 0 ]]; then
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