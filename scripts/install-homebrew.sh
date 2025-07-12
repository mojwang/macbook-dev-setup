#!/bin/bash

# Install Homebrew with error handling
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

# Check if Homebrew is already installed
if command -v brew &> /dev/null; then
    print_success "Homebrew is already installed"
    exit 0
fi

# Download and verify Homebrew install script
INSTALL_SCRIPT_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
TEMP_SCRIPT="/tmp/homebrew_install.sh"

echo "Downloading Homebrew installation script..."
if ! curl -fsSL "$INSTALL_SCRIPT_URL" -o "$TEMP_SCRIPT"; then
    print_error "Failed to download Homebrew installation script"
    exit 1
fi

# Basic verification - check if script contains expected content
if ! grep -q "Homebrew" "$TEMP_SCRIPT"; then
    print_error "Downloaded script doesn't appear to be the Homebrew installer"
    rm -f "$TEMP_SCRIPT"
    exit 1
fi

# Install Homebrew
echo "Installing Homebrew..."
if ! /bin/bash "$TEMP_SCRIPT"; then
    print_error "Homebrew installation failed"
    rm -f "$TEMP_SCRIPT"
    exit 1
fi

# Cleanup temporary script
rm -f "$TEMP_SCRIPT"

# Add Homebrew to PATH for Apple Silicon
if [[ $(uname -m) == "arm64" ]]; then
    BREW_PATH="/opt/homebrew/bin/brew"
    SHELL_ENV_CMD='eval "$(/opt/homebrew/bin/brew shellenv)"'
else
    BREW_PATH="/usr/local/bin/brew"
    SHELL_ENV_CMD='eval "$(/usr/local/bin/brew shellenv)"'
fi

# Add to shell profile if not already present
if [[ -f ~/.zprofile ]] && ! grep -q "$SHELL_ENV_CMD" ~/.zprofile; then
    echo "$SHELL_ENV_CMD" >> ~/.zprofile
elif [[ ! -f ~/.zprofile ]]; then
    echo "$SHELL_ENV_CMD" >> ~/.zprofile
fi

# Source the environment for current session
if [[ -x "$BREW_PATH" ]]; then
    eval "$($BREW_PATH shellenv)"
else
    print_error "Homebrew installation verification failed"
    exit 1
fi

# Update Homebrew
if ! brew update; then
    print_warning "Failed to update Homebrew, but installation was successful"
    exit 0
fi

print_success "Homebrew installed and updated successfully"
