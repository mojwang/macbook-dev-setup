#!/usr/bin/env bash

# Update script to keep all tools and dependencies up to date

# Load common library
source "$(dirname "$0")/../lib/common.sh"

# Track update status
UPDATE_FAILURES=0

# Update with error handling
safe_update() {
    local cmd="$1"
    local description="$2"
    
    print_step "Updating $description..."
    
    if eval "$cmd"; then
        print_success "$description updated successfully"
        return 0
    else
        print_error "Failed to update $description"
        ((UPDATE_FAILURES++))
        return 1
    fi
}

# Safe git update with status check
safe_git_update() {
    local dir="$1"
    local description="$2"
    
    print_step "Updating $description..."
    
    # Check if directory exists
    if [[ ! -d "$dir" ]]; then
        print_error "$description directory not found: $dir"
        ((UPDATE_FAILURES++))
        return 1
    fi
    
    # Check if repository is clean before pulling
    if (cd "$dir" && git diff --quiet && git diff --cached --quiet); then
        if (cd "$dir" && git pull); then
            print_success "$description updated successfully"
            return 0
        else
            print_error "Failed to update $description"
            ((UPDATE_FAILURES++))
            return 1
        fi
    else
        print_warning "$description has uncommitted changes, skipping update"
        return 0
    fi
}

# Main update function
main() {
    echo -e "${BLUE}"
    echo "🔄 Development Environment Update"
    echo "================================="
    echo -e "${NC}"
    
    # Create restore point before updates
    print_step "Creating restore point before updates..."
    RESTORE_POINT=$(create_restore_point "update")
    export RESTORE_POINT
    
    # Update Homebrew
    if command_exists brew; then
        print_step "Updating Homebrew..."
        
        # Update Homebrew itself
        safe_update "brew update" "Homebrew formulae"
        
        # Upgrade packages
        print_step "Upgrading Homebrew packages..."
        if brew list | grep -q .; then
            safe_update "brew upgrade" "Homebrew packages"
        fi
        
        # Upgrade casks
        print_step "Upgrading Homebrew casks..."
        if brew list --cask | grep -q .; then
            safe_update "brew upgrade --cask" "Homebrew applications"
        fi
        
        # Cleanup old versions
        print_step "Cleaning up old versions..."
        safe_update "brew cleanup -s" "Homebrew cleanup"
        safe_update "brew autoremove" "Unused dependencies"
        
        # Run diagnostics
        print_step "Running Homebrew diagnostics..."
        if brew doctor; then
            print_success "Homebrew is healthy"
        else
            print_warning "Homebrew reported issues (may not be critical)"
        fi
    else
        print_warning "Homebrew not found, skipping Homebrew updates"
    fi
    echo ""
    
    # Update Node.js and npm packages
    if command_exists npm; then
        print_step "Updating Node.js packages..."
        
        # Update npm itself
        safe_update "npm install -g npm@latest" "npm"
        
        # Get list of global packages
        print_info "Checking for outdated global npm packages..."
        outdated=$(npm outdated -g --parseable 2>/dev/null | cut -d: -f4 | grep -v "^$" || true)
        
        if [[ -n "$outdated" ]]; then
            print_info "Outdated packages found: $(echo $outdated | tr '\n' ' ')"
            for package in $outdated; do
                safe_update "npm install -g $package@latest" "npm package: $package"
            done
        else
            print_success "All npm packages are up to date"
        fi
    else
        print_warning "npm not found, skipping Node.js updates"
    fi
    echo ""
    
    # Update Python packages
    if command_exists pip3; then
        print_step "Updating Python packages..."
        
        # Update pip itself
        safe_update "pip3 install --upgrade pip" "pip"
        
        # Update all packages from requirements.txt if it exists
        if [[ -f "$ROOT_DIR/python/requirements.txt" ]]; then
            safe_update "pip3 install --upgrade -r $ROOT_DIR/python/requirements.txt" "Python packages from requirements.txt"
        fi
        
        # List outdated packages
        print_info "Checking for other outdated Python packages..."
        pip3 list --outdated || true
    else
        print_warning "pip3 not found, skipping Python updates"
    fi
    echo ""
    
    # Update version managers
    print_step "Updating version managers..."
    
    # Update pyenv
    if command_exists pyenv; then
        if [[ -d "$(pyenv root)/.git" ]]; then
            safe_git_update "$(pyenv root)" "pyenv"
        else
            print_info "pyenv installed via Homebrew, will be updated with brew"
        fi
    fi
    
    # Update nvm
    if [[ -d "$HOME/.nvm/.git" ]]; then
        safe_update "cd $HOME/.nvm && git fetch --tags && git checkout \$(git describe --tags \$(git rev-list --tags --max-count=1))" "nvm"
    fi
    echo ""
    
    # Update VS Code extensions
    if command_exists code; then
        print_step "Updating VS Code extensions..."
        
        # Update all extensions
        if code --list-extensions | grep -q .; then
            safe_update "code --update-extensions" "VS Code extensions" || true
            
            # Alternative method if --update-extensions doesn't work
            print_info "Updating extensions individually..."
            for ext in $(code --list-extensions); do
                code --install-extension "$ext" --force &>/dev/null || true
            done
            print_success "VS Code extensions updated"
        else
            print_info "No VS Code extensions installed"
        fi
    else
        print_warning "VS Code CLI not found, skipping extension updates"
    fi
    echo ""
    
    # Update Neovim plugins
    if command_exists nvim; then
        print_step "Updating Neovim plugins..."
        
        # Check for common plugin managers
        if [[ -d "$HOME/.config/nvim/pack" ]] || [[ -d "$HOME/.local/share/nvim/site/pack" ]]; then
            print_info "Neovim packages detected, updating..."
            nvim --headless "+packloadall" "+q" 2>/dev/null || true
            print_success "Neovim plugins updated"
        else
            print_info "No Neovim plugin manager detected"
        fi
    fi
    echo ""
    
    # Update shell configuration
    print_step "Updating shell configuration..."
    
    # Update Oh My Zsh if installed
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        print_info "Updating Oh My Zsh..."
        if [[ -f "$HOME/.oh-my-zsh/tools/upgrade.sh" ]]; then
            ZSH="$HOME/.oh-my-zsh" sh "$HOME/.oh-my-zsh/tools/upgrade.sh" 2>/dev/null || true
            print_success "Oh My Zsh updated"
        fi
    fi
    
    # Update starship if installed
    if command_exists starship; then
        if command_exists brew && brew list starship &>/dev/null; then
            print_info "Starship will be updated via Homebrew"
        else
            safe_update "curl -sS https://starship.rs/install.sh | sh -s -- -y" "Starship prompt"
        fi
    fi
    echo ""
    
    # Update cloud CLIs
    print_step "Updating cloud CLIs..."
    
    # AWS CLI
    if command_exists aws; then
        if command_exists brew && brew list awscli &>/dev/null; then
            print_info "AWS CLI will be updated via Homebrew"
        else
            safe_update "pip3 install --upgrade awscli" "AWS CLI"
        fi
    fi
    
    # Google Cloud SDK
    if command_exists gcloud; then
        safe_update "gcloud components update --quiet" "Google Cloud SDK"
    fi
    
    # Azure CLI is updated via Homebrew
    echo ""
    
    # macOS system updates (optional)
    if confirm "Check for macOS system updates?" "n"; then
        print_step "Checking macOS updates..."
        softwareupdate --list
        
        if confirm "Install available macOS updates?" "n"; then
            safe_update "sudo softwareupdate --install --all" "macOS updates"
        fi
    fi
    echo ""
    
    # Summary
    echo -e "${BLUE}"
    echo "Update Summary"
    echo "=============="
    echo -e "${NC}"
    
    if [[ $UPDATE_FAILURES -eq 0 ]]; then
        print_success "All updates completed successfully! 🎉"
        echo ""
        echo "Restore point created at: $RESTORE_POINT"
    else
        print_warning "Some updates failed ($UPDATE_FAILURES failures)"
        echo ""
        echo "Restore point available at: $RESTORE_POINT"
        echo "To investigate failures, check the output above"
    fi
    
    echo ""
    echo "Recommended next steps:"
    echo "  1. Run './scripts/health-check.sh' to verify system health"
    echo "  2. Restart your terminal to ensure all updates take effect"
    echo "  3. Review any warnings or errors above"
    
    exit $UPDATE_FAILURES
}

# Check for options
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    cat << EOF
Update Script - Keep your development environment up to date

Usage: $0 [OPTIONS]

Options:
    -h, --help    Show this help message
    
This script updates:
  • Homebrew packages and casks
  • Node.js global packages
  • Python packages
  • Version managers (pyenv, nvm)
  • VS Code extensions
  • Neovim plugins
  • Shell tools (Oh My Zsh, Starship)
  • Cloud CLIs
  • Optionally: macOS system updates

A restore point is created before updates begin.
EOF
    exit 0
fi

# Run main function
main "$@"