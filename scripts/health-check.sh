#!/usr/bin/env bash

# Health check script to verify all components are working correctly

# Load common library
source "$(dirname "$0")/../lib/common.sh"

# Track overall health status
HEALTH_STATUS=0
TOTAL_CHECKS=0
PASSED_CHECKS=0

# Check installation status of a tool
check_installation() {
    local tool="$1"
    local version_cmd="${2:-$tool --version}"
    local description="${3:-$tool}"
    
    ((TOTAL_CHECKS++))
    
    if command_exists "$tool"; then
        local version
        version=$(eval "$version_cmd" 2>&1 | head -n1 || echo "version unknown")
        print_success "$description: $version"
        ((PASSED_CHECKS++))
        return 0
    else
        print_error "$description: NOT INSTALLED"
        HEALTH_STATUS=1
        return 1
    fi
}

# Check service status
check_service() {
    local service="$1"
    local check_cmd="$2"
    local description="$3"
    
    ((TOTAL_CHECKS++))
    
    if eval "$check_cmd" &>/dev/null; then
        print_success "$description: Running"
        ((PASSED_CHECKS++))
        return 0
    else
        print_warning "$description: Not running (may be normal)"
        ((PASSED_CHECKS++))
        return 0
    fi
}

# Check configuration
check_config() {
    local config_file="$1"
    local validation_cmd="$2"
    local description="$3"
    
    ((TOTAL_CHECKS++))
    
    if [[ -f "$config_file" ]]; then
        if [[ -n "$validation_cmd" ]]; then
            if eval "$validation_cmd" &>/dev/null; then
                print_success "$description: Valid"
                ((PASSED_CHECKS++))
                return 0
            else
                print_error "$description: Invalid configuration"
                HEALTH_STATUS=1
                return 1
            fi
        else
            print_success "$description: Exists"
            ((PASSED_CHECKS++))
            return 0
        fi
    else
        print_warning "$description: Not found"
        return 1
    fi
}

# Agent-mode health check: concise, non-interactive, checks only critical tools
agent_mode() {
    local missing=()
    local warnings=()

    # Critical tools for agentic workflows.
    # awk/find/cmp are macOS-baseline but still verified because their
    # absence (rare but possible on stripped environments) causes hooks
    # and session-logger scripts to fail silently. tmux is required by
    # .claude/settings.json teammateMode — missing tmux means agent-team
    # panes silently no-op.
    for tool in git gh node npm shellcheck jq tmux awk find cmp; do
        if ! command_exists "$tool"; then
            missing+=("$tool")
        fi
    done

    # Bash 3.2 (macOS default) can't use mapfile, indirect expansion, or
    # associative arrays — advisory warning so agents know to use the
    # `while IFS= read -r` compat pattern seen in scripts/grade-session.sh.
    if [[ "${BASH_VERSION:-}" == 3.* ]]; then
        warnings+=("Bash ${BASH_VERSION} (system default) — use 'while IFS= read -r' instead of mapfile in new scripts")
    fi

    # Check git identity
    local git_name
    git_name=$(git config --global user.name 2>/dev/null || echo "")
    local git_email
    git_email=$(git config --global user.email 2>/dev/null || echo "")
    if [[ -z "$git_name" || -z "$git_email" ]]; then
        warnings+=("Git identity not configured")
    fi

    # Check Homebrew in PATH
    if [[ "$PATH" != *"/opt/homebrew/bin"* ]] && [[ "$PATH" != *"/usr/local/bin"* ]]; then
        warnings+=("Homebrew not in PATH")
    fi

    # Check for stale MCP processes (high count suggests hangs)
    local mcp_count
    mcp_count=$(pgrep -f 'mcp|npx.*model|uvx.*mcp|node.*mcp' | wc -l | tr -d ' ')
    if [[ "$mcp_count" -gt 20 ]]; then
        warnings+=("$mcp_count MCP processes running (possible orphans — run ./scripts/cleanup-mcp-processes.sh --force)")
    fi

    # Output results
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "MISSING TOOLS: ${missing[*]}"
        echo "Run './setup.sh' to install missing components."
        exit 1
    fi

    if [[ ${#warnings[@]} -gt 0 ]]; then
        for w in "${warnings[@]}"; do
            echo "WARNING: $w"
        done
    fi

    exit 0
}

# Main health check
main() {
    # Handle --agent-mode flag
    if [[ "${1:-}" == "--agent-mode" ]]; then
        agent_mode
        return
    fi

    echo -e "${BLUE}"
    echo "» Development Environment Health Check"
    echo "======================================="
    echo -e "${NC}"

    print_step "Checking system information..."
    print_info "macOS Version: $MACOS_VERSION"
    print_info "Architecture: $ARCH_TYPE"
    print_info "Current Shell: $SHELL"
    echo ""

    # Core tools
    print_step "Checking core tools..."
    check_installation "brew" "brew --version | head -n1" "Homebrew"
    check_installation "git" "git --version" "Git"
    check_installation "curl" "curl --version | head -n1" "curl"
    check_installation "code" "code --version | head -n1" "VS Code"
    echo ""

    # Programming languages
    print_step "Checking programming languages..."
    check_installation "node" "node --version" "Node.js"
    check_installation "npm" "npm --version" "npm"
    check_installation "python3" "python3 --version" "Python"
    check_installation "pip3" "pip3 --version | head -n1" "pip"
    check_installation "go" "go version" "Go"
    check_installation "rustc" "rustc --version" "Rust"
    check_installation "java" "java --version 2>&1 | head -n1" "Java"
    echo ""

    # Version managers
    print_step "Checking version managers..."
    check_installation "nvm" "nvm --version 2>/dev/null || echo 'nvm installed (shell function)'" "nvm"
    check_installation "pyenv" "pyenv --version" "pyenv"
    check_installation "rbenv" "rbenv --version | head -n1" "rbenv"
    echo ""

    # Container tools
    print_step "Checking container tools..."
    check_installation "docker" "docker --version" "Docker"
    check_installation "docker-compose" "docker-compose --version 2>/dev/null || docker compose version" "Docker Compose"
    check_installation "kubectl" "kubectl version --client --short 2>/dev/null || kubectl version --client" "kubectl"
    echo ""

    # Database tools
    print_step "Checking database tools..."
    check_installation "psql" "psql --version" "PostgreSQL client"
    check_installation "mysql" "mysql --version" "MySQL client"
    check_installation "redis-cli" "redis-cli --version" "Redis client"
    check_installation "sqlite3" "sqlite3 --version" "SQLite"
    echo ""

    # Cloud CLIs
    print_step "Checking cloud CLIs..."
    check_installation "aws" "aws --version" "AWS CLI"
    check_installation "az" "az --version 2>&1 | head -n1" "Azure CLI"
    check_installation "gcloud" "gcloud --version | head -n1" "Google Cloud SDK"
    echo ""

    # Developer tools
    print_step "Checking developer tools..."
    check_installation "gh" "gh --version | head -n1" "GitHub CLI"
    check_installation "claude" "claude --version 2>/dev/null || echo 'Claude CLI installed'" "Claude CLI"
    check_installation "jq" "jq --version" "jq"
    check_installation "yq" "yq --version" "yq"
    check_installation "httpie" "http --version" "HTTPie"
    echo ""

    # Shell enhancements
    print_step "Checking shell enhancements..."
    check_installation "fzf" "fzf --version" "fzf"
    check_installation "bat" "bat --version" "bat"
    check_installation "eza" "eza --version" "eza"
    check_installation "rg" "rg --version | head -n1" "ripgrep"
    check_installation "fd" "fd --version" "fd"
    check_installation "zoxide" "zoxide --version" "zoxide"
    echo ""

    # Configuration files
    print_step "Checking configuration files..."
    check_config "$HOME/.zshrc" "" "Zsh configuration"
    check_config "$HOME/.gitconfig" "git config --list" "Git configuration"
    check_config "$HOME/.config/nvim/init.lua" "" "Neovim configuration"
    check_config "$HOME/.ssh/config" "" "SSH configuration"
    echo ""

    # Git hooks (if in a git repository)
    if [[ -d ".git" ]]; then
        print_step "Checking Git hooks..."
        ((TOTAL_CHECKS++))
        if [[ -f ".git/hooks/commit-msg" ]]; then
            print_success "Conventional commit hooks: Installed"
            ((PASSED_CHECKS++))
        else
            print_info "Conventional commit hooks: Not installed (run ./scripts/setup-git-hooks.sh)"
            ((PASSED_CHECKS++))  # Not a failure, just informational
        fi
        echo ""
    fi

    # Git configuration validation
    print_step "Checking Git configuration..."
    local git_name=$(git config --global user.name 2>/dev/null || echo "")
    local git_email=$(git config --global user.email 2>/dev/null || echo "")

    ((TOTAL_CHECKS++))
    if [[ -n "$git_name" && "$git_name" != "Your Name" && -n "$git_email" && "$git_email" != "your.email@example.com" ]]; then
        print_success "Git identity: $git_name <$git_email>"
        ((PASSED_CHECKS++))
    else
        print_error "Git identity not properly configured"
        HEALTH_STATUS=1
    fi
    echo ""

    # Services (optional)
    print_step "Checking services (optional)..."
    check_service "postgresql" "pg_isready" "PostgreSQL"
    check_service "mysql" "mysqladmin ping" "MySQL"
    check_service "redis" "redis-cli ping" "Redis"
    check_service "nginx" "nginx -t" "Nginx"
    echo ""

    # Environment variables
    print_step "Checking environment variables..."
    local env_checks=0
    local env_passed=0

    ((TOTAL_CHECKS++))
    ((env_checks++))
    if [[ -n "$HOMEBREW_PREFIX" ]]; then
        print_success "HOMEBREW_PREFIX is set: $HOMEBREW_PREFIX"
        ((env_passed++))
    else
        print_warning "HOMEBREW_PREFIX not set"
    fi

    if [[ "$PATH" == *"/opt/homebrew/bin"* ]] || [[ "$PATH" == *"/usr/local/bin"* ]]; then
        print_success "Homebrew in PATH"
        ((env_passed++))
    else
        print_error "Homebrew not in PATH"
    fi

    if [[ $env_passed -eq $env_checks ]]; then
        ((PASSED_CHECKS++))
    fi
    echo ""

    # Homebrew health check
    print_step "Running Homebrew doctor..."
    ((TOTAL_CHECKS++))
    if command_exists brew; then
        local brew_output
        brew_output=$(brew doctor 2>&1)
        local brew_status=$?

        if [[ $brew_status -eq 0 ]]; then
            print_success "Homebrew is healthy"
            ((PASSED_CHECKS++))
        else
            print_warning "Homebrew has some issues:"
            echo "$brew_output" | grep -E "Warning:|Error:" | head -10
            # Still count as passed since warnings are common and often benign
            ((PASSED_CHECKS++))
        fi
    else
        print_error "Homebrew not installed - cannot run brew doctor"
    fi
    echo ""

    # Summary
    echo -e "${BLUE}"
    echo "Health Check Summary"
    echo "===================="
    echo -e "${NC}"

    local percentage=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))

    echo "Total checks: $TOTAL_CHECKS"
    echo "Passed: $PASSED_CHECKS"
    echo "Failed: $((TOTAL_CHECKS - PASSED_CHECKS))"
    echo "Health score: ${percentage}%"
    echo ""

    if [[ $HEALTH_STATUS -eq 0 ]]; then
        print_success "Environment is healthy!"
    else
        print_warning "Some issues detected. Review the output above for details."
        echo ""
        echo "Common fixes:"
        echo "  • Run './setup.sh' to install missing components"
        echo "  • Check ~/.zshrc for proper PATH configuration"
        echo "  • Restart your terminal after making changes"
        echo "  • Run 'brew doctor' to diagnose Homebrew issues"
    fi

    exit $HEALTH_STATUS
}

# Run main function
main "$@"