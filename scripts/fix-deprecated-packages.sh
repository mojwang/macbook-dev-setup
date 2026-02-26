#!/usr/bin/env bash

# Fix deprecated packages script
# Migrates deprecated Homebrew packages to their replacements

set -e
source "$(dirname "$0")/../lib/common.sh"

echo -e "${BLUE}» Fixing Deprecated Packages${NC}"
echo "============================"

# Terraform migration
if brew list terraform &>/dev/null; then
    print_info "Migrating from terraform to tfenv..."
    brew uninstall terraform --ignore-dependencies 2>/dev/null || true
    brew install tfenv
    
    # Install latest terraform via tfenv
    tfenv install latest
    tfenv use latest
    print_success "Migrated to tfenv for Terraform management"
fi

# TLDR migration
if brew list tldr &>/dev/null; then
    print_info "Migrating from tldr to tealdeer..."
    brew uninstall tldr --ignore-dependencies 2>/dev/null || true
    brew install tealdeer
    
    # Update tealdeer cache
    tldr --update
    print_success "Migrated to tealdeer (faster tldr client)"
fi

# Fix Xcode CLT for macOS beta
if [[ $(sw_vers -productVersion) == "26."* ]]; then
    print_warning "macOS 26.x detected (beta/pre-release)"
    print_info "Xcode CLT issues are expected on beta versions"
    
    # Try to reset Xcode path
    sudo xcode-select --reset 2>/dev/null || true
    
    print_info "Consider downloading Xcode 26 beta from:"
    print_info "https://developer.apple.com/download/"
fi

print_success "Deprecated package fixes complete!"