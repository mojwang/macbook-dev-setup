#!/usr/bin/env bash
set -e

# Claude Agents Demo Script
# Demonstrates the capabilities of various Claude sub-agents

source "$(dirname "$0")/../../lib/common.sh"

# Demo configuration
DEMO_MODE="${1:-interactive}"  # interactive, quality, security, shell, all

print_banner() {
    echo ""
    echo "╔══════════════════════════════════════════════╗"
    echo "║        Claude Sub-Agents Demo Suite         ║"
    echo "╚══════════════════════════════════════════════╝"
    echo ""
}

demo_quality_agent() {
    print_info "Quality Agent Demo"
    
    print_info "The Quality Agent ensures code quality and test coverage."
    print_info "Capabilities:"
    echo "  • Run comprehensive test suites"
    echo "  • Check test coverage metrics"
    echo "  • Validate idempotency"
    echo "  • Verify performance benchmarks"
    echo ""
    
    print_info "Example prompt to activate:"
    echo '  "Run quality checks and ensure all tests pass"'
    echo ""
    
    print_info "Simulating Quality Agent execution..."
    echo "  → Running unit tests... ✓ 15/15 passed"
    echo "  → Running integration tests... ✓ 8/8 passed"
    echo "  → Test coverage: 85% (threshold: 80%)"
    echo "  → Performance: Shell startup 95ms (threshold: 100ms)"
    echo ""
    print_success "Quality Agent: All checks passed"
}

demo_security_agent() {
    print_info "Security Agent Demo"
    
    print_info "The Security Agent identifies and prevents vulnerabilities."
    print_info "Capabilities:"
    echo "  • Scan for hardcoded secrets"
    echo "  • Validate API key handling"
    echo "  • Check file permissions"
    echo "  • Detect vulnerable patterns"
    echo ""
    
    print_info "Example prompt to activate:"
    echo '  "Perform security analysis on the shell scripts"'
    echo ""
    
    print_info "Simulating Security Agent scan..."
    echo "  → Scanning for secrets... ✓ No hardcoded secrets"
    echo "  → Checking permissions... ✓ All secure"
    echo "  → Validating sudo usage... ✓ Minimal usage"
    echo "  → Scanning dependencies... ⚠ 1 update available"
    echo ""
    print_warning "Security Agent: 1 warning (non-critical)"
}

demo_shell_agent() {
    print_info "Shell Script Agent Demo"
    
    print_info "The Shell Script Agent optimizes and validates shell scripts."
    print_info "Capabilities:"
    echo "  • Validate syntax and POSIX compliance"
    echo "  • Ensure error handling (set -e)"
    echo "  • Implement signal safety"
    echo "  • Optimize parallel execution"
    echo ""
    
    print_info "Example prompt to activate:"
    echo '  "Optimize the setup.sh script for better performance"'
    echo ""
    
    print_info "Simulating Shell Agent optimization..."
    echo "  → Syntax validation... ✓ Valid"
    echo "  → Error handling... ✓ set -e present"
    echo "  → Signal handlers... ✓ Trap handlers found"
    echo "  → Parallel optimization... ✓ Using $(nproc) cores"
    echo ""
    print_success "Shell Agent: Script optimized"
}

demo_development_agent() {
    print_info "Development Agent Demo"
    
    print_info "The Development Agent implements features and fixes."
    print_info "Capabilities:"
    echo "  • Add new features"
    echo "  • Refactor existing code"
    echo "  • Fix bugs"
    echo "  • Maintain consistency"
    echo ""
    
    print_info "Example prompt to activate:"
    echo '  "Add support for installing Docker Desktop"'
    echo ""
    
    print_info "Simulating Development Agent..."
    echo "  → Creating installer script..."
    echo "  → Adding to Brewfile..."
    echo "  → Implementing error handling..."
    echo "  → Adding tests..."
    echo ""
    print_success "Development Agent: Feature implemented"
}

demo_workflow() {
    print_info "Agent Workflow Demo"
    
    print_info "Demonstrating coordinated agent workflow:"
    echo ""
    echo "Scenario: Adding a new feature with security validation"
    echo ""
    
    echo "1. Development Agent → Creates feature"
    sleep 1
    echo "   ✓ Feature implemented"
    echo ""
    
    echo "2. Shell Script Agent → Optimizes code"
    sleep 1
    echo "   ✓ Code optimized"
    echo ""
    
    echo "3. Security Agent → Scans for vulnerabilities"
    sleep 1
    echo "   ✓ No vulnerabilities found"
    echo ""
    
    echo "4. Quality Agent → Runs tests"
    sleep 1
    echo "   ✓ All tests passed"
    echo ""
    
    echo "5. Documentation Agent → Updates docs"
    sleep 1
    echo "   ✓ Documentation updated"
    echo ""
    
    print_success "Workflow completed successfully!"
}

interactive_menu() {
    while true; do
        echo ""
        print_info "Select an agent demo:"
        echo "  1) Quality Agent"
        echo "  2) Security Agent"
        echo "  3) Shell Script Agent"
        echo "  4) Development Agent"
        echo "  5) Workflow Demo"
        echo "  6) Run All Demos"
        echo "  q) Quit"
        echo ""
        read -p "Choice: " choice
        
        case $choice in
            1) demo_quality_agent ;;
            2) demo_security_agent ;;
            3) demo_shell_agent ;;
            4) demo_development_agent ;;
            5) demo_workflow ;;
            6) 
                demo_quality_agent
                demo_security_agent
                demo_shell_agent
                demo_development_agent
                demo_workflow
                ;;
            q|Q) 
                print_info "Exiting demo suite."
                exit 0
                ;;
            *)
                print_error "Invalid choice. Please try again."
                ;;
        esac
    done
}

show_usage() {
    echo "Usage: $0 [mode]"
    echo ""
    echo "Modes:"
    echo "  interactive  - Interactive menu (default)"
    echo "  quality      - Demo Quality Agent"
    echo "  security     - Demo Security Agent"
    echo "  shell        - Demo Shell Script Agent"
    echo "  development  - Demo Development Agent"
    echo "  workflow     - Demo agent workflow"
    echo "  all          - Run all demos"
    echo ""
    echo "Examples:"
    echo "  $0                    # Interactive mode"
    echo "  $0 security           # Demo Security Agent"
    echo "  $0 all               # Run all demos"
}

# Main execution
main() {
    print_banner
    
    case "$DEMO_MODE" in
        interactive)
            interactive_menu
            ;;
        quality)
            demo_quality_agent
            ;;
        security)
            demo_security_agent
            ;;
        shell)
            demo_shell_agent
            ;;
        development)
            demo_development_agent
            ;;
        workflow)
            demo_workflow
            ;;
        all)
            demo_quality_agent
            demo_security_agent
            demo_shell_agent
            demo_development_agent
            demo_workflow
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            print_error "Unknown mode: $DEMO_MODE"
            show_usage
            exit 1
            ;;
    esac
    
    echo ""
    print_info "For more information, see: docs/CLAUDE_AGENTS.md"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi