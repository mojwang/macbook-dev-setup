#!/bin/bash

# Backup existing dotfiles
backup_dir="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$backup_dir"

# Backup existing files
if [ -f ~/.zshrc ]; then
    cp ~/.zshrc "$backup_dir/.zshrc"
fi

if [ -f ~/.gitconfig ]; then
    cp ~/.gitconfig "$backup_dir/.gitconfig"
fi

if [ -d ~/.scripts ]; then
    cp -r ~/.scripts "$backup_dir/.scripts"
fi

# Copy dotfiles
cp dotfiles/.zshrc ~/.zshrc
cp dotfiles/.gitconfig ~/.gitconfig

# Create scripts directory and copy scripts
mkdir -p ~/.scripts
cp dotfiles/scripts/* ~/.scripts/
chmod +x ~/.scripts/*

echo "Dotfiles installed. Backup created at: $backup_dir"
echo "You may need to update the email in ~/.gitconfig"
