#!/bin/bash

# This script handles applications that need special setup
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

echo "Setting up applications..."

# Claude CLI global installation
if command -v npm &> /dev/null; then
    echo "Installing Claude CLI..."
    if npm install -g @anthropic-ai/claude-code; then
        print_success "Claude CLI installed. Run 'claude setup-token' to authenticate."
    else
        print_error "Failed to install Claude CLI"
        exit 1
    fi
else
    print_warning "npm not found, skipping Claude CLI installation"
fi

# VS Code extensions
# Use the optimized extension installer script
if [[ -f "scripts/setup-vscode-extensions.sh" ]]; then
    echo "Setting up VS Code extensions..."
    if ./scripts/setup-vscode-extensions.sh; then
        print_success "VS Code extensions configured"
    else
        print_error "Failed to configure VS Code extensions"
    fi
else
    print_warning "VS Code extension setup script not found"
fi

# VS Code settings setup
VSCODE_SETTINGS_SOURCE="vscode/settings.json"
VSCODE_SETTINGS_DIR="$HOME/Library/Application Support/Code/User"
VSCODE_SETTINGS_TARGET="$VSCODE_SETTINGS_DIR/settings.json"

if [[ -f "$VSCODE_SETTINGS_SOURCE" ]]; then
    echo "Configuring VS Code settings..."
    
    # Create VS Code user directory if it doesn't exist
    if [[ ! -d "$VSCODE_SETTINGS_DIR" ]]; then
        mkdir -p "$VSCODE_SETTINGS_DIR"
    fi
    
    # Backup existing settings if they exist
    if [[ -f "$VSCODE_SETTINGS_TARGET" ]]; then
        cp "$VSCODE_SETTINGS_TARGET" "$VSCODE_SETTINGS_TARGET.backup.$(date +%Y%m%d_%H%M%S)"
        print_warning "Existing VS Code settings backed up"
    fi
    
    # Copy new settings
    if cp "$VSCODE_SETTINGS_SOURCE" "$VSCODE_SETTINGS_TARGET"; then
        print_success "VS Code settings configured"
    else
        print_error "Failed to configure VS Code settings"
    fi
else
    print_warning "VS Code settings file not found at $VSCODE_SETTINGS_SOURCE"
fi

print_success "Application setup complete!"
echo ""
echo "Manual steps required:"
echo "1. Authenticate Claude CLI: claude setup-token"
echo "2. Configure any remaining applications manually"
echo "3. Restart VS Code to apply new settings and extensions"
