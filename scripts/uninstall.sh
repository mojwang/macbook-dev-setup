#!/bin/bash

# Uninstall script to cleanly remove the development environment setup

# Load common library
source "$(dirname "$0")/../lib/common.sh"

# Track uninstall status
UNINSTALL_FAILURES=0

# Safe uninstall with error handling
safe_uninstall() {
    local cmd="$1"
    local description="$2"
    
    print_step "Removing $description..."
    
    if eval "$cmd"; then
        print_success "$description removed successfully"
        return 0
    else
        print_warning "Failed to remove $description (may already be removed)"
        return 1
    fi
}

# Main uninstall function
main() {
    echo -e "${RED}"
    echo "⚠️  Development Environment Uninstall"
    echo "====================================="
    echo -e "${NC}"
    
    print_warning "This will remove most tools installed by the setup script."
    print_warning "Some system tools and manual installations will not be removed."
    echo ""
    
    if ! confirm "Are you sure you want to uninstall?" "n"; then
        print_info "Uninstall cancelled"
        exit 0
    fi
    
    # Create final backup before uninstall
    print_step "Creating final backup before uninstall..."
    BACKUP_DIR="$HOME/.setup_final_backup_$TIMESTAMP"
    mkdir -p "$BACKUP_DIR"
    
    # Backup important configurations
    backup_item ~/.zshrc "$BACKUP_DIR"
    backup_item ~/.gitconfig "$BACKUP_DIR"
    backup_item ~/.ssh "$BACKUP_DIR"
    backup_item ~/.config/nvim "$BACKUP_DIR"
    backup_item ~/.scripts "$BACKUP_DIR"
    
    print_success "Final backup created at: $BACKUP_DIR"
    echo ""
    
    # Remove Homebrew packages
    if command_exists brew; then
        print_step "Removing Homebrew packages..."
        
        # List all casks and formulae
        local casks=$(brew list --cask 2>/dev/null | grep -v "^$" || true)
        local formulae=$(brew list --formula 2>/dev/null | grep -v "^$" || true)
        
        # Remove casks first (applications)
        if [[ -n "$casks" ]]; then
            print_info "Removing Homebrew applications..."
            for cask in $casks; do
                safe_uninstall "brew uninstall --cask --force $cask" "cask: $cask"
            done
        fi
        
        # Remove formulae
        if [[ -n "$formulae" ]]; then
            print_info "Removing Homebrew packages..."
            for formula in $formulae; do
                safe_uninstall "brew uninstall --force $formula" "formula: $formula"
            done
        fi
        
        # Clean up
        print_step "Cleaning up Homebrew..."
        brew cleanup -s
        brew autoremove
        
        # Optionally remove Homebrew itself
        if confirm "Remove Homebrew completely?" "n"; then
            print_step "Uninstalling Homebrew..."
            if [[ -f "/opt/homebrew/bin/brew" ]]; then
                # Apple Silicon
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
            elif [[ -f "/usr/local/bin/brew" ]]; then
                # Intel Mac
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
            fi
        fi
    else
        print_info "Homebrew not found, skipping Homebrew removal"
    fi
    echo ""
    
    # Remove Node.js global packages
    if command_exists npm; then
        print_step "Removing global npm packages..."
        
        # Get list of globally installed packages
        local npm_packages=$(npm list -g --depth=0 --parseable | grep node_modules | grep -v "npm$" | sed 's/.*node_modules\///' || true)
        
        if [[ -n "$npm_packages" ]]; then
            for package in $npm_packages; do
                safe_uninstall "npm uninstall -g $package" "npm package: $package"
            done
        fi
    else
        print_info "npm not found, skipping npm package removal"
    fi
    echo ""
    
    # Remove Python packages
    if command_exists pip3; then
        print_step "Removing Python packages..."
        
        # Get list of installed packages (excluding pip itself)
        local pip_packages=$(pip3 list --format=freeze | grep -v "^pip=" | cut -d= -f1 || true)
        
        if [[ -n "$pip_packages" ]] && confirm "Remove all pip packages?" "n"; then
            for package in $pip_packages; do
                safe_uninstall "pip3 uninstall -y $package" "pip package: $package"
            done
        fi
    else
        print_info "pip3 not found, skipping Python package removal"
    fi
    echo ""
    
    # Remove dotfiles
    print_step "Removing dotfiles..."
    
    if confirm "Remove shell configuration files?" "n"; then
        safe_uninstall "rm -f ~/.zshrc" ".zshrc"
        safe_uninstall "rm -f ~/.zprofile" ".zprofile"
        safe_uninstall "rm -f ~/.bash_profile" ".bash_profile"
        safe_uninstall "rm -f ~/.bashrc" ".bashrc"
    fi
    
    if confirm "Remove Git configuration?" "n"; then
        safe_uninstall "rm -f ~/.gitconfig" ".gitconfig"
        safe_uninstall "rm -f ~/.gitignore_global" ".gitignore_global"
    fi
    
    if confirm "Remove other configurations?" "n"; then
        safe_uninstall "rm -rf ~/.config/nvim" "Neovim configuration"
        safe_uninstall "rm -rf ~/.scripts" "Custom scripts"
        safe_uninstall "rm -rf ~/.vim" "Vim configuration"
        safe_uninstall "rm -f ~/.vimrc" ".vimrc"
    fi
    echo ""
    
    # Remove version managers
    print_step "Removing version managers..."
    
    if [[ -d "$HOME/.nvm" ]] && confirm "Remove nvm?" "n"; then
        safe_uninstall "rm -rf $HOME/.nvm" "nvm"
    fi
    
    if [[ -d "$HOME/.pyenv" ]] && confirm "Remove pyenv?" "n"; then
        safe_uninstall "rm -rf $HOME/.pyenv" "pyenv"
    fi
    
    if [[ -d "$HOME/.rbenv" ]] && confirm "Remove rbenv?" "n"; then
        safe_uninstall "rm -rf $HOME/.rbenv" "rbenv"
    fi
    echo ""
    
    # Remove VS Code settings
    if confirm "Remove VS Code settings and extensions?" "n"; then
        print_step "Removing VS Code configurations..."
        safe_uninstall "rm -rf ~/Library/Application\\ Support/Code/User/settings.json" "VS Code settings"
        safe_uninstall "rm -rf ~/.vscode/extensions" "VS Code extensions"
    fi
    echo ""
    
    # Clean up directories
    print_step "Cleaning up directories..."
    
    # Remove setup backup directories
    if [[ -d "$HOME/.setup_backup" ]] && confirm "Remove all setup backups?" "n"; then
        safe_uninstall "rm -rf $HOME/.setup_backup*" "Setup backups"
    fi
    
    # Remove restore points
    if [[ -d "$HOME/.setup_restore" ]] && confirm "Remove all restore points?" "n"; then
        safe_uninstall "rm -rf $HOME/.setup_restore" "Restore points"
    fi
    
    # Remove cache directories
    if confirm "Remove cache directories?" "n"; then
        safe_uninstall "rm -rf ~/Library/Caches/Homebrew" "Homebrew cache"
        safe_uninstall "rm -rf ~/.npm" "npm cache"
        safe_uninstall "rm -rf ~/.cache/pip" "pip cache"
    fi
    echo ""
    
    # Final cleanup
    print_step "Final cleanup..."
    
    # Remove any dead symlinks in home directory
    find ~ -maxdepth 1 -type l -exec test ! -e {} \; -delete 2>/dev/null || true
    
    # Summary
    echo -e "${BLUE}"
    echo "Uninstall Summary"
    echo "================="
    echo -e "${NC}"
    
    print_success "Uninstall process completed!"
    echo ""
    echo "Final backup saved at: $BACKUP_DIR"
    echo ""
    echo "Items that were NOT removed:"
    echo "  • System tools (git, curl, etc.)"
    echo "  • SSH keys and configuration"
    echo "  • Personal documents and projects"
    echo "  • Applications installed outside of Homebrew"
    echo "  • macOS system settings"
    echo ""
    echo "To restore your configuration:"
    echo "  1. Copy files from $BACKUP_DIR to their original locations"
    echo "  2. Run './setup.sh' to reinstall the development environment"
    echo ""
    print_warning "You may need to restart your terminal for all changes to take effect"
}

# Check for options
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    cat << EOF
Uninstall Script - Remove the development environment setup

Usage: $0 [OPTIONS]

Options:
    -h, --help    Show this help message
    
This script removes:
  • Homebrew packages and casks
  • Node.js global packages
  • Python packages
  • Dotfiles and configurations
  • Version managers (nvm, pyenv, rbenv)
  • VS Code settings and extensions
  • Cache directories
  • Setup backups and restore points

A final backup is created before removal begins.

WARNING: This is a destructive operation. Make sure you have
         backed up any important configurations or data.
EOF
    exit 0
fi

# Run main function
main "$@"