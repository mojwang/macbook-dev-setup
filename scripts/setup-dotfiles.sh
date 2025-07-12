#!/bin/bash

# Setup dotfiles with error handling
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

echo "Setting up dotfiles..."

# Check if dotfiles directory exists
if [[ ! -d "dotfiles" ]]; then
    print_error "Dotfiles directory not found"
    exit 1
fi

# Create backup directory
backup_dir="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$backup_dir"
echo "Created backup directory: $backup_dir"

# Backup existing files
backup_file() {
    local source="$1"
    local backup_name="$2"
    
    if [[ -f "$source" ]]; then
        cp "$source" "$backup_dir/$backup_name"
        echo "Backed up $source"
    fi
}

backup_directory() {
    local source="$1"
    local backup_name="$2"
    
    if [[ -d "$source" ]]; then
        cp -r "$source" "$backup_dir/$backup_name"
        echo "Backed up $source directory"
    fi
}

# Backup existing dotfiles
backup_file ~/.zshrc .zshrc
backup_file ~/.gitconfig .gitconfig
backup_directory ~/.scripts .scripts

# Install dotfiles
install_dotfile() {
    local source="$1"
    local target="$2"
    local description="$3"
    
    if [[ -f "$source" ]]; then
        if cp "$source" "$target"; then
            echo "Installed $description"
        else
            print_error "Failed to install $description"
            return 1
        fi
    else
        print_warning "$description not found at $source"
        return 1
    fi
}

# Install main dotfiles
install_dotfile "dotfiles/.zshrc" ~/.zshrc ".zshrc configuration"
install_dotfile "dotfiles/.gitconfig" ~/.gitconfig ".gitconfig settings"

# Create scripts directory and copy scripts
if [[ -d "dotfiles/scripts" ]]; then
    echo "Setting up custom scripts..."
    mkdir -p ~/.scripts
    
    if cp dotfiles/scripts/* ~/.scripts/ 2>/dev/null; then
        chmod +x ~/.scripts/*
        print_success "Custom scripts installed"
    else
        print_warning "No scripts found in dotfiles/scripts"
    fi
else
    print_warning "Scripts directory not found"
fi

print_success "Dotfiles setup completed"
echo ""
echo "Backup created at: $backup_dir"
echo ""
echo "⚠️  IMPORTANT: Please update your personal information in ~/.gitconfig:"
echo "   - Name: Update 'Your Name' with your actual name"
echo "   - Email: Update 'your.email@example.com' with your actual email"
echo ""
echo "To apply changes immediately, run: source ~/.zshrc"
