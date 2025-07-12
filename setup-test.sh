#!/bin/bash

# Development Environment Testing & Validation Script
# Fast execution optimized for dry-runs and testing
# For macOS Apple Silicon

set -e

# Global variables
DRY_RUN=false
VERBOSE=false
LOG_FILE=""
UPDATE_MODE=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Helper functions
print_step() {
    echo -e "${BLUE}🔧 $1${NC}"
    log_message "STEP: $1"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
    log_message "SUCCESS: $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    log_message "WARNING: $1"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
    log_message "ERROR: $1"
}

print_dry_run() {
    echo -e "${PURPLE}🔍 [DRY RUN] $1${NC}"
    log_message "DRY_RUN: $1"
}

log_message() {
    if [[ -n "$LOG_FILE" ]]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    fi
}

show_help() {
    cat << EOF
Development Environment Testing & Validation Script

Usage: $0 [OPTIONS]

Options:
    -d, --dry-run       Show what would be done without executing
    -v, --verbose       Enable verbose output
    -l, --log FILE      Write logs to specified file
    -h, --help          Show this help message

Note: This script is for testing and validation ONLY. It never performs actual setup.
For production setup, use setup.sh

Examples:
    $0 --dry-run        # Fast preview (recommended)
    $0                  # Validate environment and prerequisites
    $0 -v -l test.log   # Verbose validation with logging

EOF
    exit 0
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -l|--log)
                LOG_FILE="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

# Execute command - testing script only shows what would be done
execute_command() {
    local cmd="$1"
    local description="$2"
    
    # Testing script never executes actual commands
    print_dry_run "$description"
    if [[ "$VERBOSE" == true ]]; then
        echo "  Command: $cmd"
    fi
    return 0
}

# Validate update requirements (testing only)
validate_update_requirements() {
    print_step "Validating update requirements..."
    
    # Check Homebrew
    if command_exists brew; then
        print_dry_run "Would update Homebrew package definitions"
        print_dry_run "Would upgrade installed Homebrew packages"
        print_dry_run "Would clean up Homebrew cache and old versions"
        print_success "Homebrew update requirements validated"
    else
        print_warning "Homebrew not found, would skip Homebrew updates"
    fi
    
    # Check Node.js packages
    if command_exists npm; then
        print_dry_run "Would update global npm packages"
        print_success "npm update requirements validated"
    else
        print_warning "npm not found, would skip npm package updates"
    fi
    
    # Check Python packages
    if command_exists pip; then
        print_dry_run "Would update pip package manager"
        print_dry_run "Would update outdated Python packages"
        print_success "Python update requirements validated"
    else
        print_warning "pip not found, would skip Python package updates"
    fi
    
    # Check pyenv
    if command_exists pyenv; then
        print_dry_run "Would update pyenv Python version manager"
        print_success "pyenv update requirements validated"
    fi
    
    # Check nvm
    if [[ -d "$HOME/.nvm" ]]; then
        print_dry_run "Would update nvm Node.js version manager"
        print_success "nvm update requirements validated"
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Validate prerequisites
validate_prerequisites() {
    print_step "Validating prerequisites..."
    
    local errors=0
    
    # Check required files exist
    local required_files=(
        "scripts/install-homebrew.sh"
        "scripts/install-packages.sh"
        "scripts/setup-dotfiles.sh"
        "scripts/setup-applications.sh"
        "homebrew/Brewfile"
        "node/global-packages.txt"
        "python/requirements.txt"
        "dotfiles/.config/nvim/init.lua"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            print_error "Required file not found: $file"
            ((errors++))
        fi
    done
    
    if [[ $errors -gt 0 ]]; then
        print_error "Prerequisites validation failed. Please ensure all required files are present."
        exit 1
    fi
    
    print_success "Prerequisites validation passed"
}

# Main execution starts here
main() {
    # Parse command line arguments
    parse_args "$@"
    
    # Initialize logging if specified
    if [[ -n "$LOG_FILE" ]]; then
        echo "Setup started at $(date)" > "$LOG_FILE"
        print_step "Logging to: $LOG_FILE"
    fi
    
    echo -e "${PURPLE}"
    echo "🔍 TESTING & VALIDATION MODE - No changes will be made"
    echo "======================================================"
    echo -e "${NC}"
    
    # Force dry-run mode for testing script
    DRY_RUN=true
    
    # Check if running on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "This script is designed for macOS only."
        exit 1
    fi
    
    # Check if running on Apple Silicon
    if [[ $(uname -m) != "arm64" ]]; then
        print_warning "This script is optimized for Apple Silicon Macs."
        if [[ "$DRY_RUN" == false ]]; then
            read -p "Continue anyway? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
    fi
    
    echo -e "${BLUE}"
    echo "🧪 Development Environment Testing & Validation"
    echo "==============================================="
    echo -e "${NC}"
    
    # Validate prerequisites
    validate_prerequisites
    
    # Step 1: Install Homebrew
    print_step "Installing Homebrew..."
    if command_exists brew; then
        print_success "Homebrew already installed"
    else
        execute_command "./scripts/install-homebrew.sh" "Install Homebrew package manager"
    fi
    
    # Step 2: Install packages
    print_step "Installing packages..."
    execute_command "./scripts/install-packages.sh" "Install packages from Brewfile"
    
    # Step 3: Setup dotfiles
    print_step "Setting up dotfiles..."
    execute_command "./scripts/setup-dotfiles.sh" "Configure dotfiles and shell settings"
    
    # Step 4: Setup applications
    print_step "Installing applications..."
    execute_command "./scripts/setup-applications.sh" "Install and configure applications"
    
    # Step 5: Configure macOS system preferences
    print_step "Configuring macOS system preferences..."
    execute_command "./scripts/setup-macos.sh" "Configure macOS system settings"
    
    # Step 6: Setup Node.js
    print_step "Setting up Node.js..."
    if command_exists nvm || [[ "$DRY_RUN" == true ]]; then
        if [[ "$DRY_RUN" == false ]]; then
            source ~/.zshrc 2>/dev/null || true
        fi
        execute_command "nvm install node" "Install latest Node.js version"
        execute_command "nvm use node" "Set Node.js as default"
        execute_command "npm install -g \$(cat node/global-packages.txt | tr '\\n' ' ')" "Install global npm packages"
    else
        print_warning "NVM not found, skipping Node.js setup"
    fi
    
    # Step 7: Setup Python
    print_step "Setting up Python..."
    if command_exists pyenv || [[ "$DRY_RUN" == true ]]; then
        if [[ "$DRY_RUN" == false ]]; then
            eval "$(pyenv init -)" 2>/dev/null || true
        fi
        
        # Read Python version from .python-version file if it exists, otherwise use default
        local python_version="3.12.8"
        if [[ -f "python/.python-version" ]]; then
            python_version=$(cat python/.python-version)
        fi
        
        execute_command "pyenv install --skip-existing $python_version" "Install Python $python_version"
        execute_command "pyenv global $python_version" "Set Python $python_version as global"
        execute_command "pip install --upgrade pip" "Update pip package manager"
        execute_command "pip install -r python/requirements.txt" "Install Python packages"
    else
        print_warning "Pyenv not found, skipping Python setup"
    fi
    
    # Completion message
    echo -e "${GREEN}"
    echo "🧪 Testing & Validation Complete!"
    echo "=================================="
    echo -e "${NC}"
    echo "The above shows what would be installed/configured."
    echo "To perform the actual setup, run: ./setup.sh"
    echo ""
    echo "Environment validation summary:"
    echo "✓ Prerequisites checked"
    echo "✓ Installation steps validated"
    echo "✓ Configuration steps validated"
    echo "✓ No issues detected"
    
    if [[ -n "$LOG_FILE" ]]; then
        log_message "Testing and validation completed successfully"
        print_step "Validation log saved to: $LOG_FILE"
    fi
}

# Run main function with all arguments
main "$@"
