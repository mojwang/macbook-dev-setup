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

# Function to check if a font cask is already installed
is_font_installed() {
    local font_name="$1"
    brew list --cask 2>/dev/null | grep -q "^${font_name}$"
}

# Parse and install packages with better error handling
install_packages() {
    local failed_packages=()
    local skipped_fonts=()
    
    # Process taps first
    while IFS= read -r line; do
        if [[ "$line" =~ ^tap[[:space:]]+"(.+)" ]]; then
            local tap="${BASH_REMATCH[1]}"
            echo "Tapping $tap..."
            if ! brew tap "$tap" 2>/dev/null; then
                print_warning "Failed to tap $tap"
            fi
        fi
    done < "$BREWFILE"
    
    # Process formulae
    while IFS= read -r line; do
        if [[ "$line" =~ ^brew[[:space:]]+"(.+)" ]]; then
            local formula="${BASH_REMATCH[1]}"
            if brew list --formula "$formula" &>/dev/null; then
                echo "Formula $formula already installed, skipping..."
            else
                echo "Installing formula: $formula"
                if ! HOMEBREW_NO_AUTO_UPDATE=1 brew install "$formula" 2>/dev/null; then
                    # Check if it might be a cask instead
                    if brew info --cask "$formula" &>/dev/null; then
                        print_warning "$formula appears to be a cask, not a formula. Consider updating Brewfile."
                        failed_packages+=("brew \"$formula\" # Should be: cask \"$formula\"")
                    else
                        print_warning "Failed to install formula: $formula"
                        failed_packages+=("brew \"$formula\"")
                    fi
                fi
            fi
        fi
    done < "$BREWFILE"
    
    # Process casks
    while IFS= read -r line; do
        if [[ "$line" =~ ^cask[[:space:]]+"(.+)" ]]; then
            local cask="${BASH_REMATCH[1]}"
            # Special handling for fonts
            if [[ "$cask" =~ ^font- ]]; then
                if is_font_installed "$cask"; then
                    echo "Font $cask already installed, skipping..."
                    skipped_fonts+=("$cask")
                    continue
                fi
            elif brew list --cask "$cask" &>/dev/null; then
                echo "Cask $cask already installed, skipping..."
                continue
            fi
            
            echo "Installing cask: $cask"
            if ! HOMEBREW_NO_AUTO_UPDATE=1 brew install --cask "$cask" 2>/dev/null; then
                print_warning "Failed to install cask: $cask"
                failed_packages+=("cask \"$cask\"")
            fi
        fi
    done < "$BREWFILE"
    
    # Report results
    if [[ ${#skipped_fonts[@]} -gt 0 ]]; then
        print_success "Skipped ${#skipped_fonts[@]} already installed fonts: ${skipped_fonts[*]}"
    fi
    
    if [[ ${#failed_packages[@]} -gt 0 ]]; then
        print_error "Failed to install ${#failed_packages[@]} packages:"
        for pkg in "${failed_packages[@]}"; do
            echo "  - $pkg"
        done
        return 1
    else
        print_success "All packages installed successfully"
        return 0
    fi
}

# Run installation with fallback to brew bundle if custom installation fails
if ! install_packages; then
    print_warning "Custom installation encountered errors. Trying brew bundle as fallback..."
    if ! HOMEBREW_NO_AUTO_UPDATE=1 brew bundle --file="$BREWFILE"; then
        print_error "Some packages failed to install. Check the output above for details."
        exit 1
    fi
fi

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
