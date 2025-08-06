#!/usr/bin/env bash

# Optimized VS Code extension installer
# Installs extensions in parallel batches to avoid overwhelming VS Code
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if VS Code is installed
if ! command -v code &> /dev/null; then
    print_error "VS Code is not installed"
    exit 1
fi

EXTENSIONS_FILE="${1:-vscode/extensions.txt}"

if [[ ! -f "$EXTENSIONS_FILE" ]]; then
    print_error "Extensions file not found at $EXTENSIONS_FILE"
    exit 1
fi

print_info "Checking VS Code extensions..."

# Get list of currently installed extensions
installed_extensions=()
while IFS= read -r ext; do
    installed_extensions+=("$ext")
done < <(code --list-extensions 2>/dev/null || true)

# Read desired extensions
desired_extensions=()
while IFS= read -r extension; do
    # Skip empty lines and comments
    [[ -z "$extension" || "$extension" =~ ^[[:space:]]*# ]] && continue
    desired_extensions+=("$extension")
done < "$EXTENSIONS_FILE"

# Find extensions to install
to_install=()
for extension in "${desired_extensions[@]}"; do
    found=false
    for installed in "${installed_extensions[@]}"; do
        if [[ "$installed" == "$extension" ]]; then
            found=true
            break
        fi
    done
    if [[ "$found" == "false" ]]; then
        to_install+=("$extension")
    fi
done

# Find extensions to uninstall (optional, disabled by default)
to_uninstall=()
if [[ "${UNINSTALL_EXTRA:-false}" == "true" ]]; then
    for installed in "${installed_extensions[@]}"; do
        found=false
        for desired in "${desired_extensions[@]}"; do
            if [[ "$installed" == "$desired" ]]; then
                found=true
                break
            fi
        done
        if [[ "$found" == "false" ]]; then
            to_uninstall+=("$installed")
        fi
    done
fi

# Report status
echo "Currently installed: ${#installed_extensions[@]} extensions"
echo "Desired: ${#desired_extensions[@]} extensions"
echo "To install: ${#to_install[@]} extensions"
[[ "${UNINSTALL_EXTRA:-false}" == "true" ]] && echo "To uninstall: ${#to_uninstall[@]} extensions"

# Install missing extensions
if [[ ${#to_install[@]} -gt 0 ]]; then
    print_info "Installing ${#to_install[@]} extensions..."
    
    # Install in batches to avoid overwhelming VS Code
    BATCH_SIZE=5
    failed_extensions=()
    
    for ((i=0; i<${#to_install[@]}; i+=BATCH_SIZE)); do
        batch=("${to_install[@]:i:BATCH_SIZE}")
        
        print_info "Installing batch $((i/BATCH_SIZE + 1)) (${#batch[@]} extensions)..."
        
        for extension in "${batch[@]}"; do
            echo "  Installing: $extension"
            if ! code --install-extension "$extension" &>/dev/null; then
                failed_extensions+=("$extension")
                print_warning "  Failed: $extension"
            else
                echo "  ✓ Installed: $extension"
            fi
        done
        
        # Small delay between batches to let VS Code process
        if [[ $((i + BATCH_SIZE)) -lt ${#to_install[@]} ]]; then
            sleep 2
        fi
    done
    
    if [[ ${#failed_extensions[@]} -eq 0 ]]; then
        print_success "All extensions installed successfully"
    else
        print_warning "Failed to install ${#failed_extensions[@]} extensions: ${failed_extensions[*]}"
    fi
else
    print_success "All desired extensions are already installed"
fi

# Uninstall extra extensions if requested
if [[ "${UNINSTALL_EXTRA:-false}" == "true" ]] && [[ ${#to_uninstall[@]} -gt 0 ]]; then
    print_info "Uninstalling ${#to_uninstall[@]} extra extensions..."
    
    for extension in "${to_uninstall[@]}"; do
        echo "  Uninstalling: $extension"
        if ! code --uninstall-extension "$extension" &>/dev/null; then
            print_warning "  Failed to uninstall: $extension"
        fi
    done
fi

print_success "VS Code extension setup complete"

# Check if VS Code needs to be reloaded
if [[ ${#to_install[@]} -gt 0 ]]; then
    print_info "Restart VS Code to ensure all extensions are properly loaded"
fi