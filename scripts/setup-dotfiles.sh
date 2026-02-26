#!/usr/bin/env bash

# Setup dotfiles with error handling and Git configuration

# Load common library
source "$(dirname "$0")/../lib/common.sh"

# Load backup manager
source "$(dirname "$0")/../lib/backup-manager.sh"

print_step "Setting up dotfiles..."

# Check if dotfiles directory exists
if [[ ! -d "$DOTFILES_DIR" ]]; then
    die "Dotfiles directory not found at $DOTFILES_DIR"
fi

# Create organized backup for dotfiles
backup_dir=$(create_backup "dotfiles" "$HOME" "Dotfiles backup before setup")
print_info "Created backup directory: $backup_dir"

# Backup existing dotfiles with organization
backup_organized ~/.zshrc "dotfiles" ".zshrc backup"
backup_organized ~/.gitconfig "dotfiles" ".gitconfig backup"
backup_organized ~/.scripts "dotfiles" "scripts backup"
backup_organized ~/.config/nvim "dotfiles" "Neovim config backup"
backup_organized ~/.config/zsh "dotfiles" "Zsh config backup"

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

# Special handling for .gitconfig - don't overwrite if it already has real values
if [[ -f ~/.gitconfig ]]; then
    existing_name=$(git config --global user.name 2>/dev/null || echo "")
    existing_email=$(git config --global user.email 2>/dev/null || echo "")
    
    if [[ -n "$existing_name" && "$existing_name" != "Your Name" && -n "$existing_email" && "$existing_email" != "your.email@example.com" ]]; then
        print_warning ".gitconfig already configured with real values, skipping installation"
        print_success "Existing Git configuration: $existing_name <$existing_email>"
    else
        # Backup and install new gitconfig
        backup_file ~/.gitconfig .gitconfig
        install_dotfile "dotfiles/.gitconfig" ~/.gitconfig ".gitconfig settings"
    fi
else
    # No existing gitconfig, install the template
    install_dotfile "dotfiles/.gitconfig" ~/.gitconfig ".gitconfig settings"
fi

# Setup Zsh modular configuration
if [[ -d "dotfiles/.config/zsh" ]]; then
    echo "Setting up Zsh modular configuration..."
    mkdir -p ~/.config/zsh
    
    if cp -r dotfiles/.config/zsh/* ~/.config/zsh/ 2>/dev/null; then
        # Set secure permissions on API keys file
        if [[ -f ~/.config/zsh/51-api-keys.zsh ]]; then
            chmod 600 ~/.config/zsh/51-api-keys.zsh
        fi
        # Create local overrides from template if not already present
        if [[ ! -f ~/.config/zsh/99-local.zsh ]] && [[ -f "dotfiles/.config/zsh/99-local.zsh.example" ]]; then
            (umask 077 && cp "dotfiles/.config/zsh/99-local.zsh.example" ~/.config/zsh/99-local.zsh)
            print_info "Created ~/.config/zsh/99-local.zsh — customize for this machine"
        fi
        print_success "Zsh modular configuration installed"
    else
        print_warning "Failed to install Zsh modular configuration"
    fi
else
    print_warning "Zsh configuration directory not found"
fi

# Setup Neovim configuration
if [[ -d "dotfiles/.config/nvim" ]]; then
    echo "Setting up Neovim configuration..."
    mkdir -p ~/.config/nvim
    
    if cp -r dotfiles/.config/nvim/* ~/.config/nvim/ 2>/dev/null; then
        print_success "Neovim configuration installed"
    else
        print_warning "Failed to install Neovim configuration"
    fi
else
    print_warning "Neovim configuration directory not found"
fi

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

# Configure Git with personal information and preferences
echo "Configuring Git with your personal information..."

# Set git editor to vim (which is aliased to nvim)
current_editor=$(git config --global core.editor 2>/dev/null || echo "")
if [[ "$current_editor" != "vim" ]] && [[ "$current_editor" != "nvim" ]]; then
    git config --global core.editor "vim"
    print_success "Git editor set to vim (nvim)"
else
    print_info "Git editor already configured: $current_editor"
fi

# Check current Git configuration
current_name=$(git config --global user.name 2>/dev/null || echo "")
current_email=$(git config --global user.email 2>/dev/null || echo "")

# Only configure if not already set with real values
if [[ -z "$current_name" || "$current_name" == "Your Name" || -z "$current_email" || "$current_email" == "your.email@example.com" ]]; then
    # Auto-detect full name from system
    full_name=$(id -F 2>/dev/null || echo "")
    if [[ -z "$full_name" ]]; then
        # Fallback to username if full name not available
        full_name=$(whoami)
    fi

    echo "Detected name: $full_name"

    # Prompt for email if not in non-interactive mode
    if [[ -t 0 ]]; then
        echo -n "Enter your email address: "
        read -r email_address
        
        # Validate email format
        if [[ "$email_address" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            # Configure git with the provided information
            git config --global user.name "$full_name"
            git config --global user.email "$email_address"
            print_success "Git configured with name: $full_name and email: $email_address"
            
            # Update the .gitconfig file directly to remove placeholder comments
            if [[ -f ~/.gitconfig ]]; then
                # Remove the placeholder comment line
                sed -i '' '/# Update with your actual name and email/d' ~/.gitconfig 2>/dev/null || true
            fi
        else
            print_error "Invalid email format. Git configuration skipped."
            print_warning "Please manually update ~/.gitconfig with: git config --global user.email 'your.email@example.com'"
        fi
    else
        # Non-interactive mode - use placeholder
        print_warning "Running in non-interactive mode. Git configuration requires manual update."
        print_warning "Run: git config --global user.name 'Your Name'"
        print_warning "Run: git config --global user.email 'your.email@example.com'"
    fi
else
    print_success "Git already configured: $current_name <$current_email>"
fi

# Final validation
final_name=$(git config --global user.name 2>/dev/null || echo "")
final_email=$(git config --global user.email 2>/dev/null || echo "")

if [[ "$final_name" == "Your Name" || "$final_email" == "your.email@example.com" ]]; then
    echo ""
    print_warning "IMPORTANT: Git is configured with placeholder values!"
    print_warning "Please update your Git configuration:"
    echo "  git config --global user.name 'Your Actual Name'"
    echo "  git config --global user.email 'your.actual@email.com'"
    echo ""
fi

print_success "Dotfiles setup completed"
echo ""
echo "Backup created at: $backup_dir"

# Offer to set up git hooks for contributors
if [ -d ".git" ] && [ ! -f ".git/hooks/commit-msg" ]; then
    echo ""
    print_info "Want to set up conventional commits for this repository?"
    echo "This will:"
    echo "  • Configure git commit template"
    echo "  • Add commit message validation"
    echo "  • Enable commit helper tools"
    echo ""
    read -p "Set up git hooks? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if ./scripts/setup-git-hooks.sh; then
            print_success "Git hooks configured!"
        else
            print_warning "Git hooks setup failed, but continuing..."
        fi
    fi
fi

echo ""
echo "To apply changes immediately, run: source ~/.zshrc"
