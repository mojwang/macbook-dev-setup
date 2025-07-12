#!/bin/bash

# Development Environment Setup Script
# For macOS Apple Silicon

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_step() {
    echo -e "${BLUE}🔧 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is designed for macOS only."
    exit 1
fi

# Check if running on Apple Silicon
if [[ $(uname -m) != "arm64" ]]; then
    print_warning "This script is optimized for Apple Silicon Macs."
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo -e "${BLUE}"
echo "🚀 Development Environment Setup"
echo "================================"
echo -e "${NC}"

# Step 1: Install Homebrew
print_step "Installing Homebrew..."
if command -v brew &> /dev/null; then
    print_success "Homebrew already installed"
else
    ./scripts/install-homebrew.sh
    print_success "Homebrew installed"
fi

# Step 2: Install packages
print_step "Installing packages..."
./scripts/install-packages.sh

# Step 3: Setup dotfiles
print_step "Setting up dotfiles..."
./scripts/setup-dotfiles.sh

# Step 4: Setup applications
print_step "Installing applications..."
./scripts/setup-applications.sh

# Step 5: Setup Node.js
print_step "Setting up Node.js..."
if command -v nvm &> /dev/null; then
    source ~/.zshrc
    nvm install node
    nvm use node
    npm install -g $(cat node/global-packages.txt | tr '\n' ' ')
    print_success "Node.js setup complete"
else
    print_warning "NVM not found, skipping Node.js setup"
fi

# Step 6: Setup Python
print_step "Setting up Python..."
if command -v pyenv &> /dev/null; then
    eval "$(pyenv init -)"
    pyenv install --skip-existing 3.12.6
    pyenv global 3.12.6
    pip install --upgrade pip
    pip install -r python/requirements.txt
    print_success "Python setup complete"
else
    print_warning "Pyenv not found, skipping Python setup"
fi

# Completion message
echo -e "${GREEN}"
echo "🎉 Setup Complete!"
echo "=================="
echo -e "${NC}"
echo "Your development environment is now set up!"
echo ""
echo "Next steps:"
echo "1. Restart your terminal or run: source ~/.zshrc"
echo "2. Review docs/manual-setup.md for additional configuration"
echo "3. Install VS Code extensions: cat vscode/extensions.txt"
echo "4. Configure Claude CLI: claude setup-token"
echo ""
echo "Happy coding! 🚀"
