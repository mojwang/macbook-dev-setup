#!/usr/bin/env bash

# OS Auto-Fix Library
# Detects and automatically resolves common macOS update issues
# Particularly focused on permission and path issues after OS updates
#
# NOTE: This library is sourced (not executed directly), so set -e is not used.
# Functions return non-zero for "no action needed" (1) and "manual intervention" (2),
# which would cause set -e to exit the parent script. Signal-safe cleanup is handled
# by the sourcing script (setup.sh) via lib/signal-safety.sh.

# =============================================================================
# Permission Auto-Fix
# =============================================================================

# Auto-fix script permissions
auto_fix_permissions() {
    local script_dir="${1:-$(dirname "$0")}"
    local fixed_count=0
    local issues_found=()
    
    print_info "Scanning for permission issues..."
    
    # Find all shell scripts that should be executable
    while IFS= read -r script; do
        if [[ ! -x "$script" ]]; then
            issues_found+=("$script")
            chmod +x "$script" 2>/dev/null && {
                ((fixed_count++))
                print_success "Fixed permissions: ${script#$script_dir/}"
            }
        fi
    done < <(find "$script_dir" -maxdepth 3 -type f -name "*.sh" 2>/dev/null)
    
    if [[ ${#issues_found[@]} -gt 0 ]]; then
        local failed_count=$(( ${#issues_found[@]} - fixed_count ))
        if [[ $failed_count -gt 0 ]]; then
            print_warning "Fixed $fixed_count permission issue(s), $failed_count failed"
            return 2  # Partial fix — some chmod calls failed
        fi
        print_success "Auto-fixed $fixed_count permission issue(s)"
        return 0
    else
        return 1  # No issues found
    fi
}

# =============================================================================
# Homebrew Path Issues (common after OS updates)
# =============================================================================

# Detect and fix Homebrew path issues
auto_fix_homebrew_path() {
    local brew_path
    if [[ $(uname -m) == "arm64" ]]; then
        brew_path="/opt/homebrew/bin/brew"
    else
        brew_path="/usr/local/bin/brew"
    fi
    local path_fixed=false
    
    # Check if brew is in PATH
    if ! command -v brew &>/dev/null; then
        if [[ -x "$brew_path" ]]; then
            print_warning "Homebrew installed but not in PATH"
            
            # Add to current session
            eval "$($brew_path shellenv)"
            
            # Check if we need to update shell config
            local brew_dir
            brew_dir="$(dirname "$brew_path")"
            if ! grep -q "$brew_dir" ~/.zshrc 2>/dev/null; then
                print_info "Adding Homebrew to ~/.zshrc..."
                echo "eval \"\$(${brew_path} shellenv)\"" >> ~/.zshrc
                path_fixed=true
            fi
            
            if $path_fixed; then
                print_success "Fixed Homebrew PATH configuration"
                return 0
            fi
        fi
    fi
    return 1
}

# =============================================================================
# XCode Command Line Tools (often needs reinstall after major OS updates)
# =============================================================================

# Detect and fix Xcode CLT issues
auto_fix_xcode_clt() {
    local xcode_fixed=false
    
    # Check if git works (good proxy for CLT health)
    if ! git --version &>/dev/null; then
        print_warning "Xcode Command Line Tools issue detected"

        # In non-interactive environments, signal manual intervention
        if [[ ! -t 0 || ! -t 1 ]]; then
            print_warning "Non-interactive environment detected. Manual intervention required."
            print_info "Run 'sudo xcode-select --reset' manually to fix Xcode CLT issues."
            return 2
        fi

        # Ask for confirmation before using sudo
        local response
        read -r -p "Attempt to fix with 'sudo xcode-select --reset'? [y/N]: " response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            sudo xcode-select --reset 2>/dev/null && xcode_fixed=true
        else
            print_info "Skipped automatic Xcode CLT reset."
        fi

        # If that doesn't work, offer to trigger reinstall
        if ! $xcode_fixed && ! git --version &>/dev/null; then
            read -r -p "Reinstall Xcode CLT? This will remove and re-download. [y/N]: " response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                print_info "Triggering Xcode CLT installation..."
                if [[ -d /Library/Developer/CommandLineTools ]]; then
                    sudo rm -rf /Library/Developer/CommandLineTools 2>/dev/null
                fi
                xcode-select --install 2>/dev/null

                print_warning "Xcode CLT installation started. Please complete the installation dialog."
                print_info "Re-run this script after installation completes."
                return 2  # Special code for manual intervention needed
            else
                print_info "Skipped Xcode CLT reinstall. You may need to fix this manually."
                return 2
            fi
        fi

        if $xcode_fixed; then
            print_success "Fixed Xcode Command Line Tools"
            return 0
        fi
    fi
    return 1
}

# =============================================================================
# Python/pip Issues (common after OS updates)
# =============================================================================

# Auto-fix Python issues
auto_fix_python() {
    local python_fixed=false
    
    # Check if pip is broken (common after OS updates)
    if command -v python3 &>/dev/null && ! python3 -m pip --version &>/dev/null 2>&1; then
        print_warning "Python pip issue detected"
        
        # Try to fix with ensurepip
        python3 -m ensurepip --default-pip &>/dev/null 2>&1 && python_fixed=true
        
        # If that fails, try homebrew python
        if ! $python_fixed && command -v brew &>/dev/null; then
            print_info "Ensuring Python is installed via Homebrew..."
            brew list python@3.12 &>/dev/null || brew install python@3.12 &>/dev/null
            python_fixed=true
        fi
        
        if $python_fixed; then
            print_success "Fixed Python/pip configuration"
            return 0
        fi
    fi
    return 1
}

# =============================================================================
# Node/npm Permissions (often broken after updates)
# =============================================================================

# Auto-fix npm permissions
auto_fix_npm() {
    local npm_fixed=false
    
    if command -v npm &>/dev/null; then
        # Check if npm global install works
        if ! npm list -g --depth=0 &>/dev/null 2>&1; then
            print_warning "npm permission issue detected"
            
            # Fix npm permissions
            if [[ -d "/usr/local/lib/node_modules" ]]; then
                if [[ ! -t 0 || ! -t 1 ]]; then
                    print_warning "Non-interactive environment; fix npm permissions manually with sudo chown."
                    return 2
                fi
                local current_user
                current_user="$(id -un)"
                sudo chown -R "$current_user" /usr/local/lib/node_modules 2>/dev/null && npm_fixed=true
            fi
            
            # Also fix npm cache
            npm cache clean --force &>/dev/null 2>&1
            
            if $npm_fixed; then
                print_success "Fixed npm permissions"
                return 0
            fi
        fi
    fi
    return 1
}

# =============================================================================
# Shell Configuration Issues
# =============================================================================

# Auto-fix shell configuration issues
auto_fix_shell_config() {
    local shell_fixed=false
    
    # Ensure we're using zsh (macOS default)
    if [[ "$SHELL" != */zsh ]]; then
        print_warning "Shell is not set to zsh"
        if command -v zsh &>/dev/null; then
            if [[ -t 0 ]]; then
                local zsh_path
                zsh_path="$(command -v zsh)"
                chsh -s "$zsh_path" && shell_fixed=true
            else
                print_warning "Non-interactive environment; run 'chsh -s $(command -v zsh)' manually."
            fi
        fi
    fi
    
    # Fix missing .zshrc
    if [[ ! -f ~/.zshrc ]]; then
        print_warning "Missing .zshrc file"
        touch ~/.zshrc && shell_fixed=true
    fi
    
    # Ensure .config directory exists
    if [[ ! -d ~/.config ]]; then
        mkdir -p ~/.config && shell_fixed=true
    fi
    
    if $shell_fixed; then
        print_success "Fixed shell configuration"
        return 0
    fi
    return 1
}

# =============================================================================
# Rosetta 2 (needed for x86_64 apps on Apple Silicon)
# =============================================================================

# Auto-install Rosetta if needed
auto_fix_rosetta() {
    local arch=$(uname -m)
    
    if [[ "$arch" == "arm64" ]]; then
        # Check if Rosetta is installed
        if ! pkgutil --pkg-info=com.apple.pkg.RosettaUpdateAuto &>/dev/null 2>&1; then
            print_warning "Rosetta 2 not installed (needed for x86_64 apps)"
            
            # Install Rosetta
            softwareupdate --install-rosetta --agree-to-license &>/dev/null 2>&1 && {
                print_success "Installed Rosetta 2"
                return 0
            }
        fi
    fi
    return 1
}

# =============================================================================
# Main Auto-Fix Function
# =============================================================================

# Run all auto-fixes
run_auto_fixes() {
    local any_fixes=false
    local manual_intervention=false
    
    echo -e "${BLUE}» Running OS Auto-Fix Diagnostics${NC}"
    echo "================================="
    
    # Run each auto-fix function
    auto_fix_permissions "$@" && any_fixes=true
    auto_fix_homebrew_path && any_fixes=true
    
    local xcode_result
    auto_fix_xcode_clt
    xcode_result=$?
    [[ $xcode_result -eq 0 ]] && any_fixes=true
    [[ $xcode_result -eq 2 ]] && manual_intervention=true
    
    auto_fix_python && any_fixes=true
    local npm_result
    auto_fix_npm
    npm_result=$?
    [[ $npm_result -eq 0 ]] && any_fixes=true
    [[ $npm_result -eq 2 ]] && manual_intervention=true
    auto_fix_shell_config && any_fixes=true
    auto_fix_rosetta && any_fixes=true
    
    # Fix deprecated packages if script exists
    local repo_root="${1:-.}"
    if [[ -x "${repo_root}/scripts/fix-deprecated-packages.sh" ]]; then
        "${repo_root}/scripts/fix-deprecated-packages.sh" &>/dev/null && any_fixes=true
    fi
    
    # Summary
    if $manual_intervention; then
        print_warning "Some issues require manual intervention. Please complete any installation dialogs and re-run the script."
        return 2
    elif $any_fixes; then
        print_success "Auto-fix complete! Issues were found and resolved."
        print_info "You may need to restart your terminal or run 'source ~/.zshrc' for some fixes to take effect."
        return 0
    else
        print_success "No issues detected - system is healthy!"
        return 1
    fi
}

# =============================================================================
# Pre-flight Checks (run before main setup)
# =============================================================================

# Check system health before setup
preflight_check() {
    local issues=()
    
    # Check macOS version
    local macos_version=$(sw_vers -productVersion 2>/dev/null)
    local major_version=$(echo "$macos_version" | cut -d. -f1)
    
    if [[ $major_version -lt 12 ]]; then
        issues+=("macOS version $macos_version is too old (minimum: 12.0)")
    fi
    
    # Check disk space (need at least 10GB free)
    local free_space=$(df -g / | awk 'NR==2 {print $4}')
    if [[ $free_space -lt 10 ]]; then
        issues+=("Low disk space: ${free_space}GB free (minimum: 10GB)")
    fi
    
    # Check internet connectivity (prefer HTTPS over ICMP which may be blocked)
    if command -v curl &>/dev/null; then
        # 10s timeout — intentionally shorter than 30s standard for pre-flight UX
        if ! curl -s --max-time 10 https://www.apple.com >/dev/null 2>&1; then
            issues+=("No internet connection detected (HTTPS check failed)")
        fi
    elif ! ping -c 1 -W 5 8.8.8.8 &>/dev/null; then
        # ICMP fallback — may fail behind firewalls; warn rather than block
        print_warning "ICMP connectivity check failed (may be blocked by firewall)"
    fi
    
    # Check if running as root (shouldn't be)
    if [[ $EUID -eq 0 ]]; then
        issues+=("Script should not be run as root/sudo")
    fi
    
    # Report issues
    if [[ ${#issues[@]} -gt 0 ]]; then
        print_error "Pre-flight check failed:"
        for issue in "${issues[@]}"; do
            print_error "  - $issue"
        done
        return 1
    fi
    
    return 0
}

# Export functions if sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    export -f auto_fix_permissions
    export -f auto_fix_homebrew_path
    export -f auto_fix_xcode_clt
    export -f auto_fix_python
    export -f auto_fix_npm
    export -f auto_fix_shell_config
    export -f auto_fix_rosetta
    export -f run_auto_fixes
    export -f preflight_check
fi