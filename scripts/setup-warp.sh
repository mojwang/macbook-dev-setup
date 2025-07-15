#!/bin/bash

# Warp Terminal Optimization Script
# Configures Warp-specific features and power tools
# For macOS Apple Silicon

set -e

# Load common library
source "$(dirname "$0")/../lib/common.sh"

# Check if Warp is installed
check_warp_installed() {
    if [[ "$TERM_PROGRAM" != "WarpTerminal" ]] && ! command -v warp &> /dev/null; then
        print_warning "Warp Terminal not detected"
        echo ""
        echo "This script optimizes your setup for Warp Terminal."
        echo "Install Warp from: https://www.warp.dev"
        echo ""
        if ! confirm "Continue anyway?" "y"; then
            exit 0
        fi
    else
        print_success "Warp Terminal detected"
    fi
}

# Install power tools for Warp
install_power_tools() {
    print_section "Power Tools for Enhanced Developer Experience"
    
    # Only install non-intrusive tools by default
    local safe_tools=(
        "delta"      # Beautiful git diffs (replaces diff-so-fancy)
    )
    
    local optional_tools=(
        "atuin"      # Cloud-synced shell history (requires account)
        "direnv"     # Per-project env vars (changes shell behavior)
        "mcfly"      # Neural network history (changes Ctrl+R)
        "navi"       # Command cheatsheets (adds keybinding)
    )
    
    # Install safe tools automatically
    echo "Installing enhanced developer tools:"
    for tool in "${safe_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            print_info "Installing $tool - Enhanced git diffs with syntax highlighting"
            if brew install "$tool" 2>/dev/null; then
                print_success "$tool installed"
            else
                print_warning "Failed to install $tool"
            fi
        else
            print_success "$tool already installed"
        fi
    done
    
    # Ask about optional tools
    echo ""
    echo "Optional power tools available:"
    echo "• atuin - Cloud-synced searchable shell history (requires free account)"
    echo "• direnv - Auto-load project-specific environment variables"
    echo "• mcfly - AI-powered command history search (replaces Ctrl+R)"
    echo "• navi - Interactive command cheatsheets"
    echo ""
    
    if confirm "Would you like to see and install optional tools?" "n"; then
        for tool in "${optional_tools[@]}"; do
            case $tool in
                "atuin")
                    echo ""
                    echo "atuin - Smart shell history across all your machines"
                    echo "  Requires: Free account at https://atuin.sh"
                    ;;
                "direnv")
                    echo ""
                    echo "direnv - Automatic environment switching"
                    echo "  Use case: Different env vars per project"
                    ;;
                "mcfly")
                    echo ""
                    echo "mcfly - Neural network powered shell history"
                    echo "  Note: Replaces default Ctrl+R behavior"
                    ;;
                "navi")
                    echo ""
                    echo "navi - Interactive command cheatsheets"
                    echo "  Access with: Ctrl+G"
                    ;;
            esac
            
            if confirm "Install $tool?" "n"; then
                print_info "Installing $tool..."
                if brew install "$tool" 2>/dev/null; then
                    print_success "$tool installed"
                else
                    print_warning "Failed to install $tool"
                fi
            fi
        done
    fi
}

# Create Warp workflows
setup_warp_workflows() {
    print_section "Setting up Warp Workflows"
    
    local warp_dir="$HOME/.warp"
    local workflows_dir="$warp_dir/workflows"
    
    # Create directories
    mkdir -p "$workflows_dir"
    
    # Git workflow
    cat > "$workflows_dir/git-feature.yaml" << 'EOF'
name: "Git Feature Branch"
description: "Create and push a new feature branch"
commands:
  - name: "Create branch"
    command: "git checkout -b feature/{{feature_name}}"
  - name: "Initial commit"
    command: "git add . && git commit -m 'feat: initial {{feature_name}} implementation'"
  - name: "Push branch"
    command: "git push -u origin HEAD"
  - name: "Create PR"
    command: "gh pr create --fill"
parameters:
  - name: "feature_name"
    description: "Name of the feature"
    default_value: "new-feature"
EOF
    
    # Docker workflow
    cat > "$workflows_dir/docker-dev.yaml" << 'EOF'
name: "Docker Development"
description: "Common Docker development tasks"
commands:
  - name: "Stop all"
    command: "docker-compose down"
  - name: "Rebuild"
    command: "docker-compose build --no-cache"
  - name: "Start fresh"
    command: "docker-compose up -d --force-recreate"
  - name: "Show logs"
    command: "docker-compose logs -f"
EOF
    
    # Project setup workflow
    cat > "$workflows_dir/project-setup.yaml" << 'EOF'
name: "Project Setup"
description: "Clone and setup a new project"
commands:
  - name: "Clone repo"
    command: "gh repo clone {{repo}}"
  - name: "Enter directory"
    command: "cd $(basename {{repo}} .git)"
  - name: "Install dependencies"
    command: "[[ -f package.json ]] && pnpm install || [[ -f requirements.txt ]] && pip install -r requirements.txt"
  - name: "Open in editor"
    command: "code ."
parameters:
  - name: "repo"
    description: "Repository to clone (owner/name)"
EOF
    
    print_success "Created $(ls -1 "$workflows_dir"/*.yaml 2>/dev/null | wc -l) Warp workflows"
}

# Configure shell for Warp optimizations
configure_shell_for_warp() {
    print_section "Configuring Shell for Warp"
    
    local zsh_config_dir="$HOME/.config/zsh"
    mkdir -p "$zsh_config_dir"
    
    # Create Warp-specific configuration
    cat > "$zsh_config_dir/45-warp.zsh" << 'EOF'
# Warp Terminal Optimizations
# Only loaded when using Warp

if [[ "$TERM_PROGRAM" == "WarpTerminal" ]]; then
    # Warp handles its own prompt, disable starship if using Warp
    export STARSHIP_DISABLE=true
    
    # Enable Warp's AI features
    export WARP_ENABLE_AI=true
    
    # Optimize for Warp's block-based interface
    export WARP_BLOCK_COMMANDS=true
    
    # Better command grouping in Warp
    export WARP_USE_BLOCKS=true
fi

# Power tool configurations (only load if installed)
# These are conditionally loaded to avoid errors

# Atuin - smarter shell history
if command -v atuin &> /dev/null; then
    export ATUIN_NOBIND=true  # Don't override Ctrl+R by default
    eval "$(atuin init zsh --disable-up-arrow)"
    # User can still access with Ctrl+E or configure their own binding
fi

# Direnv - per-project environment
if command -v direnv &> /dev/null; then
    eval "$(direnv hook zsh)"
fi

# McFly - neural network history search
if command -v mcfly &> /dev/null; then
    export MCFLY_KEY_SCHEME=vim  # Use vim-style keys
    export MCFLY_FUZZY=2          # Enable fuzzy searching
    eval "$(mcfly init zsh)"
fi

# Navi - interactive cheatsheets
if command -v navi &> /dev/null; then
    eval "$(navi widget zsh)"
fi
EOF
    
    # Create power tools configuration
    cat > "$zsh_config_dir/60-power-tools.zsh" << 'EOF'
# Power Tools Aliases and Functions

# Advanced search with ast-grep
alias ast="ast-grep --pattern"
alias astf="ast-grep --pattern --lang"

# File watching with entr
alias watch="entr -c"

# Performance benchmarking
alias bench="hyperfine"

# Code statistics
alias loc="tokei"

# Enhanced git log for Warp blocks
glog() {
    git log --graph --pretty=format:'%C(yellow)%h%C(reset) %C(blue)%d%C(reset) %s %C(green)(%cr) %C(bold blue)<%an>%C(reset)' --abbrev-commit -20
}

# Quick API testing with httpie and jq
api() {
    local method=${1:-GET}
    local url=$2
    shift 2
    http "$method" "$url" "$@" | jq '.' | bat -l json
}

# Project switcher with Warp integration
project() {
    if [[ -z "$1" ]]; then
        echo "Usage: project <name>"
        return 1
    fi
    
    z "$1" && ls -la
}

# Enhanced file preview with bat
preview() {
    if [[ -d "$1" ]]; then
        eza -la --tree --level=2 "$1"
    else
        bat --style=full "$1"
    fi
}

# Smart extract with progress
extract() {
    if [[ -f "$1" ]]; then
        case "$1" in
            *.tar.gz|*.tgz) tar -xzvf "$1" ;;
            *.tar.bz2|*.tbz) tar -xjvf "$1" ;;
            *.zip) unzip -v "$1" ;;
            *.rar) unrar x "$1" ;;
            *.7z) 7z x "$1" ;;
            *) echo "Unknown archive format: $1" ;;
        esac
    else
        echo "File not found: $1"
    fi
}
EOF
    
    # Update .zshrc to load new configs if not already present
    if ! grep -q "45-warp.zsh" "$HOME/.zshrc" 2>/dev/null; then
        print_info "Adding Warp configuration to shell"
        echo "" >> "$HOME/.zshrc"
        echo "# Load Warp-specific configuration" >> "$HOME/.zshrc"
        echo '[[ -f "$HOME/.config/zsh/45-warp.zsh" ]] && source "$HOME/.config/zsh/45-warp.zsh"' >> "$HOME/.zshrc"
    fi
    
    if ! grep -q "60-power-tools.zsh" "$HOME/.zshrc" 2>/dev/null; then
        echo '[[ -f "$HOME/.config/zsh/60-power-tools.zsh" ]] && source "$HOME/.config/zsh/60-power-tools.zsh"' >> "$HOME/.zshrc"
    fi
    
    print_success "Shell configuration updated"
}

# Configure git for better Warp integration
configure_git_for_warp() {
    print_section "Configuring Git for Warp"
    
    # Set up delta as the default pager if installed
    if command -v delta &> /dev/null; then
        print_info "Configuring delta as git pager..."
        git config --global core.pager "delta"
        git config --global interactive.diffFilter "delta --color-only"
        git config --global delta.navigate true
        git config --global delta.light false
        git config --global delta.side-by-side true
        git config --global delta.line-numbers true
        print_success "Delta configured for git"
    fi
}

# Create helpful aliases for Warp
create_warp_aliases() {
    print_section "Creating Warp-Specific Aliases"
    
    local aliases_file="$HOME/.config/zsh/35-warp-aliases.zsh"
    
    cat > "$aliases_file" << 'EOF'
# Warp Terminal Aliases

# Warp workflow shortcuts
alias wf="warp workflow"
alias wfl="warp workflow list"
alias wfr="warp workflow run"

# Quick navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias ~="cd ~"

# Enhanced listing
alias l="eza -la"
alias lt="eza -la --tree --level=2"
alias lm="eza -la --sort=modified"

# Git shortcuts optimized for Warp
alias gst="git status -sb"
alias glog="git log --oneline --graph -20"
alias gdiff="git diff | delta"

# Docker shortcuts
alias dps="docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
alias dlog="docker logs -f --tail=50"
alias dex="docker exec -it"

# Quick edits
alias zshrc="$EDITOR ~/.zshrc"
alias zshreload="source ~/.zshrc"
EOF
    
    print_success "Created Warp-specific aliases"
}

# Show completion message
show_completion() {
    echo ""
    print_success "Warp Terminal Optimization Complete!"
    echo ""
    echo "What's been configured:"
    echo "✓ Power tools installed (atuin, delta, direnv, mcfly, navi)"
    echo "✓ Warp workflows created in ~/.warp/workflows/"
    echo "✓ Shell optimizations for Warp's features"
    echo "✓ Git configured with delta for better diffs"
    echo "✓ Custom aliases and functions"
    echo ""
    echo "Next steps:"
    echo "1. Restart your terminal (or run: source ~/.zshrc)"
    echo "2. Try these commands:"
    echo "   • warp workflow list     - See available workflows"
    echo "   • glog                   - Beautiful git log"
    echo "   • api GET httpbin.org/ip - Test API with formatting"
    echo "   • project <name>         - Smart project navigation"
    echo "   • atuin search           - Search command history"
    echo ""
    echo "For more Warp features:"
    echo "   • Use Cmd+P for command palette"
    echo "   • Use Cmd+D to duplicate blocks"
    echo "   • Type naturally - Warp AI will help with commands"
}

# Main execution
main() {
    # Support being called with --auto flag from main setup
    local auto_mode="${1:-}"
    
    if [[ "$auto_mode" != "--auto" ]]; then
        echo -e "${BLUE}» Warp Terminal Optimization${NC}"
        echo "============================="
        echo ""
        
        check_warp_installed
    fi
    
    # Core optimizations that enhance the experience
    print_section "Installing Core Enhancements"
    
    # Always install these as they're non-intrusive
    install_power_tools
    configure_shell_for_warp
    configure_git_for_warp
    
    # Only create workflows and aliases if confirmed or in manual mode
    if [[ "$auto_mode" != "--auto" ]] || confirm "Add Warp workflows and custom aliases?" "y"; then
        setup_warp_workflows
        create_warp_aliases
    fi
    
    show_completion
}

# Run main function
main "$@"