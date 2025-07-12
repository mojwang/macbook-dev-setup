#!/bin/bash

# Install packages from Brewfile with error handling
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

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    print_error "Homebrew is not installed. Please run install-homebrew.sh first."
    exit 1
fi

# Check if Brewfile exists
BREWFILE="homebrew/Brewfile"
if [[ ! -f "$BREWFILE" ]]; then
    print_error "Brewfile not found at $BREWFILE"
    exit 1
fi

echo "Installing packages from Brewfile..."

# Install packages from Brewfile
if ! brew bundle --file="$BREWFILE"; then
    print_error "Some packages failed to install. Check the output above for details."
    exit 1
fi

print_success "All packages installed successfully"

# Update all packages
echo "Updating Homebrew and installed packages..."
if ! brew update; then
    print_warning "Failed to update Homebrew package list"
fi

if ! brew upgrade; then
    print_warning "Failed to upgrade some packages"
fi

# Cleanup
echo "Cleaning up old package versions..."
if ! brew cleanup; then
    print_warning "Cleanup failed, but packages are installed"
fi

print_success "Package installation and cleanup completed"
