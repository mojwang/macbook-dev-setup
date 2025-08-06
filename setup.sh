#!/usr/bin/env bash

# Development Environment Setup Script
# Simplified interface with smart defaults
# For macOS Apple Silicon

VERSION="3.0.0"

# Load common library
source "$(dirname "$0")/lib/common.sh"

# Load backup manager
source "$(dirname "$0")/lib/backup-manager.sh"

# Environment variables for power users
VERBOSE="${SETUP_VERBOSE:-false}"
LOG_FILE="${SETUP_LOG:-}"
PARALLEL_JOBS="${SETUP_JOBS:-$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)}"

# Script start time for performance tracking
SCRIPT_START_TIME=$(date +%s)

# Simple help message
show_help() {
    cat << EOF
Development Environment Setup - Simple & Smart

Usage: ./setup.sh [command]

Commands:
    (none)     Smart setup - detects what needs to be done
    preview    Show what would be installed/updated
    minimal    Install essential tools only
    fix        Run diagnostics and fix common issues
    warp       Configure Warp terminal optimizations
    backup     Manage setup backups
    info       Learn about installed tools, aliases & features
    advanced   Interactive mode for advanced options
    help       Show this help message

Examples:
    ./setup.sh              # First run: full setup. Later: sync & update
    ./setup.sh preview      # See what would happen
    ./setup.sh minimal      # Quick essential setup

For power users - use environment variables:
    SETUP_VERBOSE=1 ./setup.sh      # Verbose output
    SETUP_JOBS=8 ./setup.sh         # Custom parallel jobs
    SETUP_LOG=file.log ./setup.sh   # Log to file

EOF
}

# Smart detection of what needs to be done
detect_setup_state() {
    local state="fresh"
    
    # Check if this is a fresh install or update
    if command -v brew &> /dev/null; then
        state="update"
    fi
    
    if [[ -f "$HOME/.zshrc" ]] && grep -q "macbook-dev-setup" "$HOME/.zshrc" 2>/dev/null; then
        state="update"
    fi
    
    echo "$state"
}

# Check for Warp and offer optimization
check_and_setup_warp() {
    # Skip if explicitly disabled
    if [[ "${SETUP_NO_WARP:-false}" == "true" ]]; then
        return 0
    fi
    
    # Check if Warp is installed or being used
    local warp_detected=false
    local warp_reason=""
    
    if [[ "$TERM_PROGRAM" == "WarpTerminal" ]]; then
        warp_detected=true
        warp_reason="currently using Warp Terminal"
    elif [[ -d "/Applications/Warp.app" ]]; then
        warp_detected=true
        warp_reason="Warp.app installed"
    elif command -v warp &> /dev/null; then
        warp_detected=true
        warp_reason="Warp command found"
    fi
    
    # If Warp detected and optimizations not already installed
    if [[ "$warp_detected" == true ]] && [[ ! -f "$HOME/.config/zsh/45-warp.zsh" ]]; then
        echo ""
        print_info "Warp Terminal detected ($warp_reason)"
        echo ""
        echo "Warp offers enhanced features that work great with your setup:"
        echo "• AI-powered command suggestions"
        echo "• Beautiful command blocks and workflows"
        echo "• Smart history search and sharing"
        echo ""
        
        if confirm "Would you like to optimize your setup for Warp?" "y"; then
            if [[ -f "scripts/setup-warp.sh" ]]; then
                echo ""
                ./scripts/setup-warp.sh --auto
            else
                print_warning "Warp setup script not found"
            fi
        else
            echo ""
            echo "You can run './setup.sh warp' later to add Warp optimizations"
        fi
    elif [[ "$warp_detected" == true ]] && [[ -f "$HOME/.config/zsh/45-warp.zsh" ]]; then
        print_success "Warp optimizations already configured"
    fi
}

# Interactive advanced options menu
show_advanced_menu() {
    echo ""
    echo "Advanced Setup Options:"
    echo "======================"
    echo "1. Use custom configuration file"
    echo "2. Set parallel jobs (current: $PARALLEL_JOBS)"
    echo "3. Skip creating backups"
    echo "4. Enable verbose logging"
    echo "5. Select installation profile"
    echo "6. Show current configuration"
    echo "7. Return to main setup"
    echo ""
    
    read -p "Choose option (1-7): " choice
    
    case $choice in
        1)
            read -p "Enter configuration file path: " config_file
            if [[ -f "$config_file" ]]; then
                export SETUP_CONFIG="$config_file"
                print_success "Using configuration: $config_file"
            else
                print_error "Configuration file not found: $config_file"
            fi
            show_advanced_menu
            ;;
        2)
            read -p "Enter number of parallel jobs (1-16): " jobs
            if [[ "$jobs" =~ ^[0-9]+$ ]] && [[ "$jobs" -ge 1 ]] && [[ "$jobs" -le 16 ]]; then
                PARALLEL_JOBS="$jobs"
                print_success "Parallel jobs set to: $jobs"
            else
                print_error "Invalid number of jobs"
            fi
            show_advanced_menu
            ;;
        3)
            export SETUP_NO_BACKUP=true
            print_success "Backup creation disabled"
            show_advanced_menu
            ;;
        4)
            VERBOSE=true
            print_success "Verbose logging enabled"
            show_advanced_menu
            ;;
        5)
            echo ""
            echo "Available profiles:"
            echo "1. Web Developer (Node.js, React, TypeScript)"
            echo "2. Data Scientist (Python, Jupyter, pandas)"
            echo "3. DevOps Engineer (Docker, Kubernetes, Terraform)"
            echo "4. Full Stack (Everything)"
            read -p "Select profile (1-4): " profile
            case $profile in
                1) export SETUP_PROFILE="web_developer" ;;
                2) export SETUP_PROFILE="data_scientist" ;;
                3) export SETUP_PROFILE="devops_engineer" ;;
                4) export SETUP_PROFILE="full_stack" ;;
                *) print_error "Invalid profile selection" ;;
            esac
            show_advanced_menu
            ;;
        6)
            echo ""
            echo "Current Configuration:"
            echo "===================="
            echo "Parallel Jobs: $PARALLEL_JOBS"
            echo "Verbose: $VERBOSE"
            echo "Log File: ${LOG_FILE:-none}"
            echo "Profile: ${SETUP_PROFILE:-default}"
            echo "Config File: ${SETUP_CONFIG:-default}"
            echo "No Backup: ${SETUP_NO_BACKUP:-false}"
            echo ""
            read -p "Press Enter to continue..."
            show_advanced_menu
            ;;
        7)
            return 0
            ;;
        *)
            print_error "Invalid option"
            show_advanced_menu
            ;;
    esac
}

# Run diagnostics and fix common issues
run_diagnostics() {
    echo ""
    echo -e "${BLUE}→ Running Diagnostics${NC}"
    echo "===================="
    
    local issues_found=0
    
    # Check Xcode Command Line Tools
    if ! xcode-select -p &>/dev/null; then
        print_warning "Xcode Command Line Tools not installed"
        if confirm "Install Xcode Command Line Tools?" "y"; then
            xcode-select --install
            print_info "Please complete the installation and run setup again"
            exit 0
        fi
        ((issues_found++))
    else
        print_success "Xcode Command Line Tools: OK"
    fi
    
    # Check Homebrew
    if command -v brew &>/dev/null; then
        print_info "Running Homebrew diagnostics..."
        if ! brew doctor &>/dev/null; then
            print_warning "Homebrew has issues"
            if confirm "Run 'brew doctor' to see details?" "y"; then
                brew doctor
            fi
            ((issues_found++))
        else
            print_success "Homebrew: OK"
        fi
    else
        print_warning "Homebrew not installed"
        ((issues_found++))
    fi
    
    # Check shell configuration
    if [[ ! -f "$HOME/.zshrc" ]]; then
        print_warning "No .zshrc file found"
        ((issues_found++))
    else
        print_success "Shell configuration: OK"
    fi
    
    # Check disk space
    local free_space_gb=$(df -g / | awk 'NR==2 {print $4}')
    if [[ $free_space_gb -lt 5 ]]; then
        print_warning "Low disk space: ${free_space_gb}GB free (recommended: 5GB+)"
        ((issues_found++))
    else
        print_success "Disk space: ${free_space_gb}GB free"
    fi
    
    # Summary
    echo ""
    if [[ $issues_found -eq 0 ]]; then
        print_success "No issues found! Your system is ready."
    else
        print_warning "Found $issues_found issue(s)"
        if confirm "Would you like to run setup to fix these issues?" "y"; then
            main_setup
        fi
    fi
}

# Main setup function
main_setup() {
    local setup_state=$(detect_setup_state)
    local is_minimal="${1:-false}"
    
    # Initialize logging if specified
    if [[ -n "$LOG_FILE" ]]; then
        echo "Setup started at $(date)" > "$LOG_FILE"
        print_info "Logging to: $LOG_FILE"
    fi
    
    # Show what we're doing
    if [[ "$setup_state" == "fresh" ]]; then
        echo -e "${BLUE}» Fresh Installation Detected${NC}"
        echo "================================"
    else
        echo -e "${BLUE}» Update & Sync Mode${NC}"
        echo "===================="
    fi
    
    # Create restore point unless disabled
    if [[ "${SETUP_NO_BACKUP:-false}" != "true" ]]; then
        print_step "Creating restore point..."
        
        # Create organized restore point
        local restore_point=$(create_backup "restore-points" "$HOME" "Setup restore point")
        
        # Backup key files to restore point
        for file in .zshrc .gitconfig .config/nvim .bashrc .bash_profile; do
            if [[ -e "$HOME/$file" ]]; then
                if [[ -d "$HOME/$file" ]]; then
                    cp -r "$HOME/$file" "$restore_point/" 2>/dev/null || true
                else
                    cp "$HOME/$file" "$restore_point/" 2>/dev/null || true
                fi
            fi
        done
        
        # Save current package states
        if command -v brew &>/dev/null; then
            brew list > "$restore_point/brew-packages.txt" 2>/dev/null || true
            brew list --cask > "$restore_point/brew-casks.txt" 2>/dev/null || true
        fi
        
        print_success "Restore point created: $restore_point"
        export RESTORE_POINT="$restore_point"
    fi
    
    # Run prerequisites check
    print_step "Checking prerequisites..."
    # Basic prerequisite checks inline since lib files may not exist
    if ! xcode-select -p &>/dev/null; then
        print_error "Xcode Command Line Tools not installed"
        echo "Please run: xcode-select --install"
        exit 1
    fi
    
    # Install or update based on state
    if [[ "$setup_state" == "fresh" ]]; then
        # Fresh installation
        print_step "Installing Homebrew..."
        ./scripts/install-homebrew.sh
        
        print_step "Installing packages..."
        if [[ "$is_minimal" == "true" ]]; then
            BREWFILE="homebrew/Brewfile.minimal" ./scripts/install-packages.sh
        else
            ./scripts/install-packages.sh
        fi
        
        print_step "Setting up dotfiles..."
        ./scripts/setup-dotfiles.sh
        
        print_step "Setting up global Claude configuration..."
        ./scripts/setup-claude-global.sh
        
        print_step "Setting up Claude MCP servers..."
        ./scripts/setup-claude-mcp.sh
        
        # Setup Claude Code MCP servers if VS Code is installed
        if command -v code &>/dev/null || [[ -d "/Applications/Visual Studio Code.app" ]]; then
            print_step "Setting up Claude Code MCP servers..."
            if command -v claude &>/dev/null; then
                ./scripts/setup-claude-code-mcp.sh
            else
                print_info "Claude Code CLI not found - install Claude Code extension in VS Code"
            fi
        fi
        
        print_step "Configuring applications..."
        ./scripts/setup-applications.sh
        
        print_step "Configuring terminal fonts..."
        ./scripts/setup-terminal-fonts.sh
        
        print_step "Configuring macOS settings..."
        ./scripts/setup-macos.sh
        
    else
        # Update existing installation
        print_step "Syncing new packages..."
        # Inline package sync
        if command -v brew &>/dev/null; then
            brew update
            if [[ "$is_minimal" == "true" ]] && [[ -f "homebrew/Brewfile.minimal" ]]; then
                brew bundle --file="homebrew/Brewfile.minimal"
            else
                brew bundle --file="homebrew/Brewfile"
            fi
        fi
        
        print_step "Updating existing packages..."
        # Inline package updates
        if command -v brew &>/dev/null; then
            brew upgrade
            brew cleanup
        fi
        
        print_step "Updating configurations..."
        if [[ -f "./scripts/setup-dotfiles.sh" ]]; then
            ./scripts/setup-dotfiles.sh --update
        fi
        
        print_step "Updating global Claude configuration..."
        if [[ -f "./scripts/setup-claude-global.sh" ]]; then
            ./scripts/setup-claude-global.sh
        fi
        
        print_step "Updating Claude MCP servers..."
        if [[ -f "./scripts/setup-claude-mcp.sh" ]]; then
            ./scripts/setup-claude-mcp.sh --update
        fi
        
        # Update Claude Code MCP servers if VS Code and Claude CLI are installed
        if command -v code &>/dev/null && command -v claude &>/dev/null; then
            print_step "Updating Claude Code MCP servers..."
            ./scripts/setup-claude-code-mcp.sh --remove --servers filesystem,memory,git,fetch,sequentialthinking,context7,playwright,figma,semgrep,exa
        fi
    fi
    
    # Check for Warp and offer optimization
    check_and_setup_warp
    
    # Show completion message
    local duration=$(($(date +%s) - SCRIPT_START_TIME))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    
    echo ""
    echo -e "${GREEN}✓ Setup Complete!${NC}"
    echo "=================="
    echo "Time: ${minutes}m ${seconds}s"
    
    # Show MCP server status if available
    if command -v claude &>/dev/null; then
        echo ""
        echo "MCP Servers Status:"
        claude mcp list | grep -E "✓ Connected|✗ Failed" | head -5
        echo "Run 'claude mcp list' for full status"
    fi
    
    if [[ "$setup_state" == "fresh" ]]; then
        echo ""
        echo -e "${YELLOW}⚠️  IMPORTANT: Restart your terminal to apply changes${NC}"
        echo ""
        echo "Next steps:"
        echo "• Open a new terminal window"
        echo "• Run 'claude setup-token' to configure Claude CLI"
        echo "• MCP servers are configured for Claude Desktop"
        if command -v claude &>/dev/null; then
            echo "• MCP servers are configured for Claude Code - run 'claude mcp list' to verify"
        else
            echo "• Install Claude Code extension in VS Code to enable MCP servers"
        fi
    fi
}

# Main script logic
case "${1:-}" in
    "help"|"-h"|"--help")
        show_help
        ;;
    
    "preview")
        print_info "Running in preview mode..."
        if [[ -f "setup-validate.sh" ]]; then
            ./setup-validate.sh
        else
            DRY_RUN=true main_setup
        fi
        ;;
    
    "minimal")
        print_info "Running minimal setup..."
        main_setup true
        ;;
    
    "fix")
        run_diagnostics
        ;;
    
    "warp")
        if [[ -f "scripts/setup-warp.sh" ]]; then
            ./scripts/setup-warp.sh
        else
            print_error "Warp setup script not found"
            print_info "Creating Warp setup script..."
            # This would be created in the next step
        fi
        ;;
    
    "backup")
        # Backup management subcommands
        case "${2:-list}" in
            "list")
                list_backups
                ;;
            "migrate")
                print_info "Migrating old backups to organized structure..."
                migrate_old_backups
                ;;
            "clean")
                print_info "Cleaning old backups..."
                for category in "${BACKUP_CATEGORIES[@]}"; do
                    clean_old_backups "$category"
                done
                print_success "Backup cleanup complete"
                ;;
            *)
                echo "Usage: ./setup.sh backup [list|clean]"
                echo "  list    - List all backups (default)"
                echo "  clean   - Remove old backups exceeding limit"
                echo ""
                echo "Note: Backups are created automatically during setup"
                ;;
        esac
        ;;
    
    "info")
        # Run the help script with any additional arguments
        if [[ -f "scripts/setup-help.sh" ]]; then
            ./scripts/setup-help.sh "$2" "$3"
        else
            print_error "Info script not found at scripts/setup-help.sh"
            exit 1
        fi
        ;;
    
    "advanced")
        show_advanced_menu
        main_setup
        ;;
    
    "")
        # Default: smart setup
        main_setup
        ;;
    
    *)
        print_error "Unknown command: $1"
        echo "Run './setup.sh help' for usage"
        exit 1
        ;;
esac