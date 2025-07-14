#!/bin/bash

# Development Environment Setup Script
# High-performance setup with intelligent dry-run delegation
# For macOS Apple Silicon

VERSION="1.0.1"

# Load common library
source "$(dirname "$0")/lib/common.sh"

# Global variables
UPDATE_MODE=false
SYNC_MODE=false
PARALLEL_JOBS=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
CONFIG_FILE="$ROOT_DIR/config/setup.yaml"
RUN_HEALTH_CHECK=false
MINIMAL_INSTALL=false
CREATE_BACKUP=true
PROFILE_NAME=""

# Performance tracking
SCRIPT_START_TIME=$(date +%s)

show_help() {
    cat << EOF
Development Environment Setup Script

Usage: $0 [OPTIONS]

Options:
    -d, --dry-run       Show what would be done without executing (delegates to setup-validate.sh)
    -v, --verbose       Enable verbose output
    -l, --log FILE      Write logs to specified file
    -u, --update        Update and upgrade existing packages and tools
    -s, --sync          Sync packages from configuration files (Brewfile, extensions.txt, etc.)
    -j, --jobs N        Set number of parallel jobs (default: $PARALLEL_JOBS)
    -c, --config FILE   Use custom configuration file (default: config/setup.yaml)
    --check             Run health check after installation
    --minimal           Install only essential tools (skip optional components)
    --no-backup         Skip creating restore points
    --profile NAME      Use a predefined profile from config
    -h, --help          Show this help message

Quick Actions:
    --health            Run health check and exit
    --rollback          Show rollback options and exit
    --show-config       Display configuration and exit

Performance Features:
    - Parallel processing for faster installation
    - Progress bars for long operations
    - Smart dry-run delegation for optimal performance
    - Automatic restore points before changes
    - Configuration-based customization

Examples:
    $0                              # Run full setup with defaults
    $0 --dry-run                    # Preview what will be installed
    $0 --minimal                    # Essential tools only
    $0 --config my-config.yaml      # Use custom configuration
    $0 --profile web_developer      # Use web developer profile
    $0 --sync                       # Sync new packages from config files
    $0 --sync --update              # Sync new packages then update all
    $0 --update --check             # Update everything and verify
    $0 --health                     # Just run health check

Related Scripts:
    ./scripts/health-check.sh       # Verify system health
    ./scripts/update.sh             # Update all tools
    ./scripts/rollback.sh           # Restore previous state
    ./scripts/uninstall.sh          # Remove everything

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
            -u|--update)
                UPDATE_MODE=true
                shift
                ;;
            -s|--sync)
                SYNC_MODE=true
                shift
                ;;
            -j|--jobs)
                PARALLEL_JOBS="$2"
                shift 2
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            --check)
                RUN_HEALTH_CHECK=true
                shift
                ;;
            --minimal)
                MINIMAL_INSTALL=true
                shift
                ;;
            --no-backup)
                CREATE_BACKUP=false
                shift
                ;;
            --profile)
                PROFILE_NAME="$2"
                shift 2
                ;;
            --health)
                exec ./scripts/health-check.sh
                ;;
            --rollback)
                exec ./scripts/rollback.sh
                ;;
            --show-config)
                source "$ROOT_DIR/lib/config.sh"
                check_config_file
                print_config_summary
                exit 0
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

# Execute command with timeout support (extends common library function)
execute_command_with_timeout() {
    local cmd="$1"
    local description="$2"
    local timeout="${3:-300}"  # 5 minute default timeout
    
    if [[ "$DRY_RUN" == true ]]; then
        print_dry_run "$description"
        if [[ "$VERBOSE" == true ]]; then
            echo "  Command: $cmd"
        fi
        return 0
    else
        print_step "$description"
        if [[ "$VERBOSE" == true ]]; then
            echo "  Executing: $cmd"
        fi
        
        # Use timeout to prevent hanging
        if timeout "$timeout" bash -c "$cmd"; then
            print_success "$description completed"
            return 0
        else
            local exit_code=$?
            if [[ $exit_code -eq 124 ]]; then
                print_error "Command timed out after ${timeout}s: $description"
            else
                print_error "$description failed (exit code: $exit_code)"
            fi
            return $exit_code
        fi
    fi
}

# Execute commands in parallel with job control
execute_parallel() {
    local -a commands=("$@")
    local -a pids=()
    local -a results=()
    
    if [[ "$DRY_RUN" == true ]]; then
        for cmd in "${commands[@]}"; do
            print_dry_run "Parallel: $cmd"
        done
        return 0
    fi
    
    # Start background jobs
    for cmd in "${commands[@]}"; do
        if [[ ${#pids[@]} -ge $PARALLEL_JOBS ]]; then
            # Wait for a job to complete
            wait ${pids[0]}
            results+=(${pids[0]}:$?)
            pids=("${pids[@]:1}")  # Remove first element
        fi
        
        bash -c "$cmd" &
        pids+=($!)
    done
    
    # Wait for remaining jobs
    for pid in "${pids[@]}"; do
        wait $pid
        results+=($pid:$?)
    done
    
    # Check results
    local failed=0
    for result in "${results[@]}"; do
        if [[ "${result#*:}" != "0" ]]; then
            ((failed++))
        fi
    done
    
    return $failed
}

# Optimized package update function
update_packages() {
    print_step "Updating and upgrading packages (optimized)..."
    
    local update_commands=()
    
    # Homebrew updates
    if command_exists brew; then
        update_commands+=(
            "brew update"
            "brew upgrade --greedy"
            "brew cleanup --prune=7"
        )
    fi
    
    # Node.js updates
    if command_exists npm; then
        update_commands+=("npm update -g")
    fi
    
    # Python updates
    if command_exists pip; then
        update_commands+=(
            "pip install --upgrade pip"
            "pip list --outdated --format=freeze | grep -v '^\\-e' | cut -d = -f 1 | xargs -n1 pip install -U"
        )
    fi
    
    # Execute updates in parallel
    if [[ ${#update_commands[@]} -gt 0 ]]; then
        execute_parallel "${update_commands[@]}"
        print_success "All package updates completed"
    fi
}

# Sync packages from configuration files
sync_packages() {
    print_step "Syncing packages from configuration files..."
    
    local sync_commands=()
    local sync_failed=0
    
    # Sync Homebrew packages
    if command_exists brew; then
        print_info "Checking Brewfile for new packages..."
        
        local brewfile="homebrew/Brewfile"
        if [[ "$MINIMAL_INSTALL" == true ]] && [[ -f "homebrew/Brewfile.minimal" ]]; then
            brewfile="homebrew/Brewfile.minimal"
            print_info "Using minimal Brewfile"
        fi
        
        if [[ -f "$brewfile" ]]; then
            # Check what's missing
            if ! brew bundle check --file="$brewfile" &>/dev/null; then
                print_info "Installing missing Homebrew packages..."
                if [[ "$DRY_RUN" == true ]]; then
                    print_dry_run "Would run: brew bundle --file=$brewfile"
                else
                    if ! brew bundle --file="$brewfile"; then
                        print_warning "Some Homebrew packages failed to install"
                        ((sync_failed++))
                    fi
                fi
            else
                print_success "All Homebrew packages are already installed"
            fi
        fi
    fi
    
    # Sync VS Code extensions
    if command_exists code && [[ -f "vscode/extensions.txt" ]]; then
        print_info "Syncing VS Code extensions..."
        if [[ "$DRY_RUN" == true ]]; then
            print_dry_run "Would run: ./scripts/setup-vscode-extensions.sh"
        else
            if ! ./scripts/setup-vscode-extensions.sh; then
                print_warning "Some VS Code extensions failed to install"
                ((sync_failed++))
            fi
        fi
    fi
    
    # Sync global npm packages
    if command_exists npm && [[ -f "nodejs-config/global-packages.txt" ]]; then
        print_info "Syncing global npm packages..."
        
        if [[ "$DRY_RUN" == true ]]; then
            print_dry_run "Would install missing npm packages from nodejs-config/global-packages.txt"
        else
            # Get list of installed global packages
            local installed_npm=""
            if command_exists jq; then
                installed_npm=$(npm list -g --depth=0 --json 2>/dev/null | jq -r '.dependencies | keys[]' 2>/dev/null || echo "")
            else
                # Fallback without jq - parse npm list output
                installed_npm=$(npm list -g --depth=0 2>/dev/null | grep -E '^├──|^└──' | awk '{print $2}' | cut -d'@' -f1 || echo "")
            fi
            
            # Read desired packages and install missing ones
            while IFS= read -r package; do
                [[ -z "$package" || "$package" =~ ^[[:space:]]*# ]] && continue
                
                if ! echo "$installed_npm" | grep -q "^$package$"; then
                    print_info "Installing npm package: $package"
                    if ! npm install -g "$package"; then
                        print_warning "Failed to install npm package: $package"
                        ((sync_failed++))
                    fi
                fi
            done < "nodejs-config/global-packages.txt"
            
            print_success "npm package sync completed"
        fi
    fi
    
    # Sync Python packages
    if command_exists pip && [[ -f "python/requirements.txt" ]]; then
        print_info "Syncing Python packages..."
        
        if [[ "$DRY_RUN" == true ]]; then
            print_dry_run "Would run: pip install -r python/requirements.txt"
        else
            if ! pip install -r python/requirements.txt; then
                print_warning "Some Python packages failed to install"
                ((sync_failed++))
            fi
        fi
    fi
    
    if [[ $sync_failed -eq 0 ]]; then
        print_success "Package sync completed successfully"
    else
        print_warning "Package sync completed with $sync_failed warnings"
    fi
    
    return $sync_failed
}


# Fast prerequisite validation with parallel checks
validate_prerequisites() {
    print_step "Validating prerequisites..."
    
    # Check for required system commands first
    local required_commands=(
        "curl"      # For downloading files
        "git"       # For version control
        "grep"      # For text processing
        "sed"       # For text manipulation
        "awk"       # For text processing
        "sudo"      # For system-level changes
        "defaults"  # For macOS settings
        "killall"   # For restarting services
        "xcode-select" # For developer tools
    )
    
    local missing_commands=()
    for cmd in "${required_commands[@]}"; do
        if ! command_exists "$cmd"; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        print_error "Missing required system commands:"
        for cmd in "${missing_commands[@]}"; do
            echo "  - $cmd"
        done
        echo ""
        print_error "Please install Xcode Command Line Tools:"
        echo "  xcode-select --install"
        exit 1
    fi
    
    # Check if Xcode Command Line Tools are installed
    if ! xcode-select -p &>/dev/null; then
        print_error "Xcode Command Line Tools not installed"
        echo ""
        echo "Please install them by running:"
        echo "  xcode-select --install"
        echo ""
        echo "Then restart the setup script."
        exit 1
    fi
    
    # Check for required files
    local required_files=(
        "scripts/install-homebrew.sh"
        "scripts/install-packages.sh"
        "scripts/setup-dotfiles.sh"
        "scripts/setup-applications.sh"
        "homebrew/Brewfile"
        "nodejs-config/global-packages.txt"
        "python/requirements.txt"
        "dotfiles/.config/nvim/init.lua"
    )
    
    if [[ "$DRY_RUN" == true ]]; then
        print_dry_run "Would validate system commands and files"
        print_success "Prerequisites validation passed (dry run)"
        return 0
    fi
    
    local errors=0
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
    
    # Check disk space (require at least 5GB free)
    local free_space_gb=$(df -g / | awk 'NR==2 {print $4}')
    if [[ $free_space_gb -lt 5 ]]; then
        print_warning "Low disk space: ${free_space_gb}GB free (recommended: 5GB+)"
        read -p "Continue anyway? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    # Check for sudo access
    if ! sudo -n true 2>/dev/null; then
        print_info "This script will require sudo access for some operations."
        if ! sudo -v; then
            print_error "Failed to obtain sudo access"
            exit 1
        fi
    fi
    
    print_success "Prerequisites validation passed"
}

# Optimized Homebrew installation
install_homebrew_optimized() {
    print_step "Installing Homebrew (optimized)..."
    
    if command_exists brew; then
        print_success "Homebrew already installed"
        return 0
    fi
    
    local install_script_url="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
    local temp_script="/tmp/homebrew_install.sh"
    
    if [[ "$DRY_RUN" == false ]]; then
        # Download with retry logic
        local retries=3
        for ((i=1; i<=retries; i++)); do
            if curl -fsSL "$install_script_url" -o "$temp_script"; then
                break
            elif [[ $i -eq $retries ]]; then
                print_error "Failed to download Homebrew installer after $retries attempts"
                return 1
            fi
            sleep 2
        done
        
        # Install Homebrew
        if /bin/bash "$temp_script"; then
            # Setup environment
            if [[ $(uname -m) == "arm64" ]]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            else
                eval "$(/usr/local/bin/brew shellenv)"
            fi
            
            print_success "Homebrew installed successfully"
        else
            print_error "Homebrew installation failed"
            return 1
        fi
        
        rm -f "$temp_script"
    else
        print_dry_run "Would install Homebrew"
    fi
}

# Optimized package installation
install_packages_optimized() {
    print_step "Installing packages (optimized)..."
    
    if [[ "$MINIMAL_INSTALL" == true ]]; then
        print_info "Minimal installation mode - installing essential packages only"
    fi
    
    if [[ "$DRY_RUN" == false ]]; then
        # Count total packages for progress bar
        local total_formulae=$(grep -c "^brew " homebrew/Brewfile || echo 0)
        local total_casks=$(grep -c "^cask " homebrew/Brewfile || echo 0)
        local total=$((total_formulae + total_casks))
        local current=0
        
        print_info "Installing $total packages ($total_formulae formulae, $total_casks casks)"
        
        # Install packages without automatic updates (faster)
        if [[ "$VERBOSE" == true ]]; then
            HOMEBREW_NO_AUTO_UPDATE=1 brew bundle --file="homebrew/Brewfile" --verbose
        else
            # Install with progress tracking
            HOMEBREW_NO_AUTO_UPDATE=1 brew bundle --file="homebrew/Brewfile" | while IFS= read -r line; do
                if [[ "$line" =~ Installing|Pouring|Using ]]; then
                    ((current++))
                    show_progress_bar "$current" "$total" "Installing packages"
                fi
                [[ "$VERBOSE" == true ]] && echo "$line"
            done
            # Ensure we're on a new line after progress bar
            printf "\n"
        fi
        
        print_success "Packages installed successfully"
        
        # Offer cleanup option
        print_step "Homebrew cleanup..."
        print_info "Old versions and cache can take up significant disk space"
        if confirm "Run cleanup to remove old formulae and casks?" "y"; then
            # Show what will be removed
            local cleanup_size=$(brew cleanup -n 2>/dev/null | grep "Would remove" | tail -1 | awk '{print $3}' || echo "0MB")
            if [[ "$cleanup_size" != "0MB" ]]; then
                print_info "This will free up approximately $cleanup_size"
            fi
            
            # Run cleanup
            execute_with_progress "brew cleanup --prune=all" "Removing old versions"
            execute_with_progress "brew autoremove" "Removing unused dependencies"
            
            print_success "Cleanup completed"
        else
            print_info "Skipping cleanup (you can run './scripts/cleanup.sh' later)"
        fi
    else
        print_dry_run "Would install packages from Brewfile"
    fi
}

# Optimized dotfiles setup with interactive git configuration
setup_dotfiles_optimized() {
    print_step "Setting up dotfiles..."
    
    if [[ "$DRY_RUN" == false ]]; then
        # Use the full setup-dotfiles.sh script to ensure git configuration is prompted
        if [[ -f "./scripts/setup-dotfiles.sh" ]]; then
            ./scripts/setup-dotfiles.sh
        else
            # Fallback to inline setup if script not found
            local backup_dir="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
            mkdir -p "$backup_dir"
            
            # Parallel backup and copy operations
            local setup_commands=(
                "cp ~/.zshrc '$backup_dir/.zshrc' 2>/dev/null || true"
                "cp ~/.gitconfig '$backup_dir/.gitconfig' 2>/dev/null || true"
                "cp -r ~/.config/nvim '$backup_dir/.config-nvim' 2>/dev/null || true"
                "cp dotfiles/.zshrc ~/.zshrc"
                "cp dotfiles/.gitconfig ~/.gitconfig"
                "mkdir -p ~/.config/nvim && cp -r dotfiles/.config/nvim/* ~/.config/nvim/"
                "mkdir -p ~/.scripts && cp dotfiles/scripts/* ~/.scripts/ && chmod +x ~/.scripts/*"
            )
            
            execute_parallel "${setup_commands[@]}"
            print_success "Dotfiles setup completed"
            
            # Prompt for git configuration if using fallback
            print_warning "Git configuration was not set up interactively."
            print_warning "Please run: git config --global user.name 'Your Name'"
            print_warning "Please run: git config --global user.email 'your.email@example.com'"
        fi
    else
        print_dry_run "Would setup dotfiles and configure git"
    fi
}

# Performance monitoring
show_performance_stats() {
    local end_time=$(date +%s)
    local duration=$((end_time - SCRIPT_START_TIME))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    
    echo -e "${BLUE}"
    echo "» Performance Summary"
    echo "===================="
    echo -e "${NC}"
    echo "Total execution time: ${minutes}m ${seconds}s"
    echo "Parallel jobs used: $PARALLEL_JOBS"
    echo "CPU cores available: $(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo "unknown")"
    
    if [[ -n "$LOG_FILE" ]]; then
        echo "Detailed log: $LOG_FILE"
    fi
}

# Main execution starts here
main() {
    # Parse command line arguments
    parse_args "$@"
    
    # Validate flag combinations
    if [[ "$UPDATE_MODE" == true ]] && [[ "$MINIMAL_INSTALL" == true ]]; then
        print_warning "Note: --minimal flag affects --sync operations, not --update"
        print_info "--update will update ALL installed packages regardless of --minimal"
    fi
    
    # Performance optimization: delegate dry-runs to the fast validation script
    if [[ "$DRY_RUN" == true ]]; then
        if [[ -f "setup-validate.sh" ]]; then
            echo -e "${BLUE}» Delegating to fast validation script for optimal performance${NC}"
            echo -e "${YELLOW}Running setup-validate.sh for 6x faster execution${NC}"
            echo ""
            exec ./setup-validate.sh "$@"
        else
            print_warning "setup-validate.sh not found, running dry-run with overhead"
        fi
    fi
    
    # Initialize logging if specified
    if [[ -n "$LOG_FILE" ]]; then
        echo "High-performance setup started at $(date)" > "$LOG_FILE"
        print_step "Logging to: $LOG_FILE"
    fi
    
    # Handle sync and update modes (can be combined)
    if [[ "$SYNC_MODE" == true ]] || [[ "$UPDATE_MODE" == true ]]; then
        echo -e "${BLUE}"
        if [[ "$SYNC_MODE" == true ]] && [[ "$UPDATE_MODE" == true ]]; then
            echo "↻ SYNC & UPDATE MODE"
            echo "===================="
        elif [[ "$SYNC_MODE" == true ]]; then
            echo "↻ PACKAGE SYNC MODE"
            echo "==================="
        else
            echo "↻ OPTIMIZED UPDATE MODE"
            echo "======================="
        fi
        echo -e "${NC}"
        
        # Run sync first if requested
        if [[ "$SYNC_MODE" == true ]]; then
            sync_packages
        fi
        
        # Then run update if requested
        if [[ "$UPDATE_MODE" == true ]]; then
            update_packages
        fi
        
        show_performance_stats
        exit 0
    fi
    
    # Load configuration if available
    if [[ -f "$ROOT_DIR/lib/config.sh" ]]; then
        source "$ROOT_DIR/lib/config.sh"
        load_config_settings
        
        if [[ -f "$CONFIG_FILE" ]]; then
            print_info "Using configuration: $CONFIG_FILE"
            if [[ "$VERBOSE" == true ]]; then
                print_config_summary
            fi
        fi
    fi
    
    # System checks
    require_macos
    
    # Create restore point if enabled
    if [[ "$CREATE_BACKUP" == true ]]; then
        RESTORE_POINT=$(create_restore_point "setup")
        export RESTORE_POINT
    else
        print_info "Skipping restore point creation (--no-backup)"
    fi
    
    # Perform system checks
    print_step "Performing system checks..."
    
    # Check disk space (require 10GB minimum)
    if ! check_disk_space 10; then
        die "Insufficient disk space. Please free up space and try again."
    fi
    
    # Check network connectivity
    print_step "Checking network connectivity..."
    if ! check_network; then
        if ! confirm "Network issues detected. Continue anyway?" "n"; then
            die "Setup cancelled due to network issues."
        fi
    fi
    
    # Check if running on Apple Silicon
    if ! check_apple_silicon; then
        print_warning "This script is optimized for Apple Silicon Macs."
        if ! confirm "Continue anyway?" "n"; then
            die "Setup cancelled. This script is optimized for Apple Silicon."
        fi
    fi
    
    echo -e "${BLUE}"
    echo "» High-Performance Development Environment Setup"
    echo "================================================="
    echo "Using $PARALLEL_JOBS parallel jobs for optimal performance"
    echo "For testing/validation, use: ./setup-validate.sh --dry-run"
    echo -e "${NC}"
    
    # Validate prerequisites
    validate_prerequisites
    
    # Step 1: Install Homebrew
    install_homebrew_optimized
    
    # Step 2: Install packages (optimized)
    install_packages_optimized
    
    # Step 3: Setup dotfiles (optimized)
    setup_dotfiles_optimized
    
    # Step 4: Parallel application setup
    print_step "Setting up applications (parallel)..."
    local app_commands=(
        "./scripts/setup-applications.sh"
        "./scripts/setup-macos.sh"
    )
    
    execute_parallel "${app_commands[@]}"
    
    # Step 5: Language environments (parallel)
    print_step "Setting up language environments (parallel)..."
    
    local lang_commands=()
    
    # Node.js setup
    if command_exists nvm || [[ "$DRY_RUN" == true ]]; then
        lang_commands+=(
            "source ~/.zshrc 2>/dev/null || true; nvm install node; nvm use node"
            "npm install -g \$(cat nodejs-config/global-packages.txt | tr '\\n' ' ')"
        )
    fi
    
    # Python setup
    if command_exists pyenv || [[ "$DRY_RUN" == true ]]; then
        local python_version="3.12.8"
        if [[ -f "python/.python-version" ]]; then
            python_version=$(cat python/.python-version)
        fi
        
        lang_commands+=(
            "eval \"\$(pyenv init -)\" 2>/dev/null || true; pyenv install --skip-existing $python_version"
            "pyenv global $python_version; pip install --upgrade pip"
            "pip install -r python/requirements.txt"
        )
    fi
    
    if [[ ${#lang_commands[@]} -gt 0 ]]; then
        execute_parallel "${lang_commands[@]}"
    fi
    
    # Completion message
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${PURPLE}"
        echo "◊ Optimized dry run completed!"
        echo "==============================="
        echo -e "${NC}"
        echo "The above shows what would be installed/configured."
        echo "Run without --dry-run to perform the actual setup."
    else
        echo -e "${GREEN}"
        echo "✓ Optimized Setup Complete!"
        echo "============================"
        echo -e "${NC}"
        echo "Your development environment is now set up with performance optimizations!"
        echo ""
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}⚠️  IMPORTANT: Shell configuration has been updated!${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo "To apply the new shell configuration, you have 3 options:"
        echo ""
        echo -e "  1. ${BLUE}Recommended:${NC} Close this terminal and open a new one"
        echo -e "  2. ${BLUE}Quick reload:${NC} Run this command:"
        echo -e "     ${GREEN}source ~/.zshrc${NC}"
        echo -e "  3. ${BLUE}Full reload:${NC} Run this command:"
        echo -e "     ${GREEN}exec zsh${NC}"
        echo ""
        echo "Other next steps:"
        echo "• Review docs/manual-setup.md for additional configuration"
        echo -e "• Configure Claude CLI: ${GREEN}claude setup-token${NC}"
        echo ""
        echo "Happy coding!"
    fi
    
    # Show performance statistics
    show_performance_stats
    
    if [[ -n "$LOG_FILE" ]]; then
        log_message "Optimized setup completed successfully"
        show_performance_stats >> "$LOG_FILE"
    fi
    
    # Run health check if requested
    if [[ "$RUN_HEALTH_CHECK" == true ]] && [[ "$DRY_RUN" == false ]]; then
        echo ""
        print_step "Running health check..."
        sleep 2  # Give system a moment to settle
        ./scripts/health-check.sh
    fi
}

# Run main function with all arguments
main "$@"
