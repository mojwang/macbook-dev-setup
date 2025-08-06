#!/usr/bin/env bash

# Pre-push Check Script
# Run this before pushing to main to ensure your changes will pass CI
# This helps avoid pushing code that will fail status checks

set -e

# Source common functions
source "$(dirname "$0")/../lib/common.sh"

# Track failures
FAILED_CHECKS=0

# Run tests
run_tests() {
    print_step "Running test suite..."
    
    if ./tests/run_tests.sh; then
        print_success "All tests passed"
    else
        print_error "Tests failed"
        ((FAILED_CHECKS++))
    fi
}

# Validate setup script
validate_setup() {
    print_step "Validating setup script..."
    
    if ./setup.sh --dry-run > /dev/null 2>&1; then
        print_success "Setup validation passed"
    else
        print_error "Setup validation failed"
        ((FAILED_CHECKS++))
    fi
}

# Check for common issues
check_common_issues() {
    print_step "Checking for common issues..."
    
    # Check for debugging code
    if grep -rn "console\.log\|binding\.pry\|debugger\|TODO\|FIXME\|XXX" . \
        --include="*.sh" \
        --exclude-dir=".git" \
        --exclude-dir="node_modules" | grep -v "^Binary file"; then
        print_warning "Found debugging code or TODO comments"
    fi
    
    # Check for large files
    large_files=$(find . -type f -size +10M ! -path "./.git/*" 2>/dev/null)
    if [[ -n "$large_files" ]]; then
        print_warning "Found large files (>10MB):"
        echo "$large_files"
    fi
    
    print_success "Common issues check completed"
}

# Check shellcheck if available
run_shellcheck() {
    if command -v shellcheck &> /dev/null; then
        print_step "Running shellcheck..."
        
        local errors=0
        while IFS= read -r script; do
            if ! shellcheck "$script" > /dev/null 2>&1; then
                print_warning "ShellCheck issues in: $script"
                ((errors++))
            fi
        done < <(find . -name "*.sh" -type f ! -path "./.git/*")
        
        if [[ $errors -eq 0 ]]; then
            print_success "ShellCheck validation passed"
        else
            print_warning "ShellCheck found issues in $errors files"
        fi
    else
        print_info "ShellCheck not installed (optional)"
    fi
}

# Check git status
check_git_status() {
    print_step "Checking git status..."
    
    # Check for uncommitted changes
    if [[ -n $(git status --porcelain) ]]; then
        print_warning "You have uncommitted changes:"
        git status --short
        echo
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        print_success "Working directory clean"
    fi
    
    # Check which branch we're on
    current_branch=$(git branch --show-current)
    if [[ "$current_branch" == "main" ]]; then
        print_warning "You're on the main branch"
        echo "As an admin, you can push directly, but tests must pass!"
    else
        print_info "Current branch: $current_branch"
    fi
}

# Main execution
main() {
    echo -e "${BLUE}"
    echo "Pre-Push Validation Check"
    echo "========================"
    echo -e "${NC}"
    
    # Run all checks
    check_git_status
    echo
    
    run_tests
    echo
    
    validate_setup
    echo
    
    run_shellcheck
    echo
    
    check_common_issues
    echo
    
    # Summary
    if [[ $FAILED_CHECKS -eq 0 ]]; then
        echo -e "${GREEN}"
        echo "✅ All checks passed!"
        echo "====================" 
        echo -e "${NC}"
        echo "Your code is ready to push."
        echo
        echo "To push to main:"
        echo "  git push origin main"
    else
        echo -e "${RED}"
        echo "❌ Some checks failed!"
        echo "====================="
        echo -e "${NC}"
        echo "$FAILED_CHECKS check(s) failed."
        echo
        echo "Please fix the issues before pushing."
        echo "GitHub Actions will run these same checks."
        exit 1
    fi
}

# Handle Ctrl+C gracefully
trap 'echo -e "\n${YELLOW}Check interrupted${NC}"; exit 130' INT

main "$@"