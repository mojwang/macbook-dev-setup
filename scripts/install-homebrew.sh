#!/bin/bash

# Install Homebrew with error handling and security verification

# Load common library
source "$(dirname "$0")/../lib/common.sh"

# Homebrew installation configuration
readonly HOMEBREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
readonly TEMP_DIR="$(mktemp -d)"
readonly INSTALL_SCRIPT="$TEMP_DIR/install.sh"

# Cleanup on exit
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Check if Homebrew is already installed
if command_exists brew; then
    print_success "Homebrew is already installed"
    brew_version=$(brew --version | head -n1)
    print_info "Current version: $brew_version"
    exit 0
fi

print_step "Downloading Homebrew installation script..."

# Download installation script with retry
if ! download_with_retry "$HOMEBREW_INSTALL_URL" "$INSTALL_SCRIPT"; then
    die "Failed to download Homebrew installation script after multiple attempts"
fi

# Basic verification - check if script contains expected content
if ! grep -q "Homebrew" "$INSTALL_SCRIPT"; then
    die "Downloaded script doesn't appear to be the Homebrew installer"
fi

# Additional security check - verify script size is reasonable (should be ~20-50KB)
script_size=$(stat -f%z "$INSTALL_SCRIPT" 2>/dev/null || stat -c%s "$INSTALL_SCRIPT" 2>/dev/null || echo 0)
if [[ $script_size -lt 10000 ]] || [[ $script_size -gt 100000 ]]; then
    die "Homebrew installer size ($script_size bytes) is outside expected range (10KB-100KB)"
fi

print_success "Homebrew installer downloaded and verified"

# Install Homebrew
print_step "Installing Homebrew..."
print_info "This may take a few minutes and will ask for your password"

if ! /bin/bash "$INSTALL_SCRIPT"; then
    die "Homebrew installation failed"
fi

print_success "Homebrew core installation completed"

# Determine Homebrew path based on architecture
if check_apple_silicon; then
    BREW_PATH="/opt/homebrew/bin/brew"
    SHELL_ENV_CMD='eval "$(/opt/homebrew/bin/brew shellenv)"'
else
    BREW_PATH="/usr/local/bin/brew"
    SHELL_ENV_CMD='eval "$(/usr/local/bin/brew shellenv)"'
fi

# Add to shell profile if not already present
print_step "Configuring shell environment..."
shell_profiles=(~/.zprofile ~/.bash_profile ~/.profile)

for profile in "${shell_profiles[@]}"; do
    if [[ -f "$profile" ]]; then
        if ! grep -q "brew shellenv" "$profile"; then
            echo "$SHELL_ENV_CMD" >> "$profile"
            print_info "Added Homebrew to $profile"
        fi
    fi
done

# Create .zprofile if it doesn't exist
if [[ ! -f ~/.zprofile ]]; then
    echo "$SHELL_ENV_CMD" > ~/.zprofile
    print_info "Created ~/.zprofile with Homebrew configuration"
fi

# Configure PATH for current session
print_step "Configuring Homebrew environment..."

if [[ -f "/opt/homebrew/bin/brew" ]]; then
    # Apple Silicon path
    eval "$(/opt/homebrew/bin/brew shellenv)"
    brew_path="/opt/homebrew"
elif [[ -f "/usr/local/bin/brew" ]]; then
    # Intel Mac path
    eval "$(/usr/local/bin/brew shellenv)"
    brew_path="/usr/local"
else
    die "Unable to find Homebrew installation"
fi

# Verify installation
if command_exists brew; then
    print_success "Homebrew installed successfully"
    brew_version=$(brew --version | head -n1)
    print_info "Version: $brew_version"
    print_info "Location: $brew_path"
else
    die "Homebrew installation verification failed"
fi

# Update Homebrew
print_step "Updating Homebrew..."
if brew update --quiet; then
    print_success "Homebrew updated successfully"
else
    print_warning "Failed to update Homebrew, but installation was successful"
fi

# Run initial brew doctor to check for issues
print_step "Running brew doctor to check system..."
if brew doctor; then
    print_success "Homebrew system check passed"
else
    print_warning "Homebrew reported some issues - they may not be critical"
fi

print_success "Homebrew setup completed successfully!"
echo ""