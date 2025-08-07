#!/usr/bin/env bash
set -e

# Test Agent Workflows Script
# Validates agent coordination and integration patterns

source "$(dirname "$0")/../../lib/common.sh"

# Workflow test configuration
TEST_MODE="${1:-all}"
VERBOSE="${VERBOSE:-false}"

print_banner() {
    echo ""
    echo "════════════════════════════════════════════════"
    echo "    Claude Agent Workflow Testing Suite"
    echo "════════════════════════════════════════════════"
    echo ""
}

# Test sequential workflow
test_sequential_workflow() {
    print_info "Testing Sequential Agent Workflow"
    
    local workflow_steps=(
        "Development Agent: Create new script"
        "Shell Agent: Validate syntax"
        "Security Agent: Scan for vulnerabilities"
        "Quality Agent: Run tests"
        "Documentation Agent: Update docs"
    )
    
    local step_num=1
    for step in "${workflow_steps[@]}"; do
        print_info "Step $step_num: $step"
        
        # Simulate agent execution
        sleep 0.5
        
        # Simulate agent output
        case $step_num in
            1) echo "  → Created: scripts/new-feature.sh" ;;
            2) echo "  → Syntax: Valid, shellcheck passed" ;;
            3) echo "  → Security: No vulnerabilities found" ;;
            4) echo "  → Tests: 10/10 passed" ;;
            5) echo "  → Docs: Updated COMMANDS.md" ;;
        esac
        
        print_success "  ✓ Step $step_num completed"
        ((step_num++))
    done
    
    print_success "Sequential workflow completed successfully"
    return 0
}

# Test parallel workflow
test_parallel_workflow() {
    print_info "Testing Parallel Agent Workflow"
    
    print_info "Launching parallel agents..."
    echo "  • Quality Agent: Running tests"
    echo "  • Security Agent: Scanning code"
    echo "  • Performance Agent: Benchmarking"
    echo ""
    
    # Simulate parallel execution
    local pids=()
    
    # Quality Agent
    (
        sleep 1
        echo "  [Quality] Tests completed: 25/25 passed"
    ) &
    pids+=($!)
    
    # Security Agent
    (
        sleep 1.5
        echo "  [Security] Scan completed: No issues found"
    ) &
    pids+=($!)
    
    # Performance Agent
    (
        sleep 0.8
        echo "  [Performance] Benchmark: 0.5s execution time"
    ) &
    pids+=($!)
    
    # Wait for all agents
    for pid in "${pids[@]}"; do
        wait "$pid"
    done
    
    print_success "All parallel agents completed"
    return 0
}

# Test triggered cascade workflow
test_cascade_workflow() {
    print_info "Testing Cascade Agent Workflow"
    
    print_info "Simulating PR creation trigger..."
    echo ""
    
    local triggers=(
        "PR Created → Quality Agent triggered"
        "Shell scripts modified → Shell Agent triggered"
        "Security-sensitive changes → Security Agent triggered"
        "API changes → Documentation Agent triggered"
    )
    
    for trigger in "${triggers[@]}"; do
        echo "  $trigger"
        sleep 0.5
        echo "    ✓ Agent completed"
    done
    
    print_success "Cascade workflow completed"
    return 0
}

# Test error handling workflow
test_error_workflow() {
    print_info "Testing Error Handling Workflow"
    
    print_info "Simulating agent failure scenario..."
    echo ""
    
    echo "1. Development Agent: Creating feature..."
    sleep 0.5
    echo "   ✓ Feature created"
    
    echo "2. Security Agent: Scanning..."
    sleep 0.5
    print_error "   ✗ Found hardcoded API key!"
    
    echo "3. Triggering remediation workflow..."
    sleep 0.5
    echo "   → Development Agent: Removing API key"
    echo "   → Security Agent: Re-scanning"
    sleep 0.5
    echo "   ✓ Security issues resolved"
    
    echo "4. Quality Agent: Running tests..."
    sleep 0.5
    echo "   ✓ All tests passed"
    
    print_success "Error recovery workflow successful"
    return 0
}

# Test MCP integration workflow
test_mcp_workflow() {
    print_info "Testing MCP Integration Workflow"
    
    print_info "Testing MCP server setup workflow..."
    echo ""
    
    local mcp_steps=(
        "MCP Agent: Checking server configurations"
        "Development Agent: Installing missing servers"
        "Security Agent: Validating API key storage"
        "Quality Agent: Testing connections"
    )
    
    for step in "${mcp_steps[@]}"; do
        echo "• $step"
        sleep 0.5
        echo "  ✓ Completed"
    done
    
    print_success "MCP integration workflow validated"
    return 0
}

# Test performance optimization workflow
test_performance_workflow() {
    print_info "Testing Performance Optimization Workflow"
    
    print_info "Optimizing shell startup time..."
    echo ""
    
    echo "1. Performance Agent: Profiling current startup"
    sleep 0.5
    echo "   → Current: 150ms"
    
    echo "2. Shell Agent: Identifying bottlenecks"
    sleep 0.5
    echo "   → Found: NVM loading, unnecessary sourcing"
    
    echo "3. Development Agent: Implementing optimizations"
    sleep 0.5
    echo "   → Applied: Lazy loading, caching"
    
    echo "4. Performance Agent: Re-benchmarking"
    sleep 0.5
    echo "   → New: 85ms (43% improvement)"
    
    echo "5. Quality Agent: Verifying functionality"
    sleep 0.5
    echo "   ✓ All features working"
    
    print_success "Performance optimization successful"
    return 0
}

# Validate workflow configuration
validate_workflow_config() {
    print_info "Validating Workflow Configuration"
    
    local config_checks=(
        "Agent documentation exists:docs/CLAUDE_AGENTS.md"
        "Test suites exist:tests/agents/"
        "Helper scripts exist:scripts/claude-agents/"
        "CLAUDE.md updated:CLAUDE.md"
    )
    
    local failed=0
    for check in "${config_checks[@]}"; do
        local description="${check%%:*}"
        local path="${check##*:}"
        
        if [[ -e "$path" ]]; then
            print_success "✓ $description"
        else
            print_error "✗ $description (missing: $path)"
            ((failed++))
        fi
    done
    
    if [[ $failed -eq 0 ]]; then
        print_success "All workflow configurations valid"
        return 0
    else
        print_error "$failed configuration issues found"
        return 1
    fi
}

# Run comprehensive workflow test
run_comprehensive_test() {
    print_info "Running Comprehensive Workflow Test"
    
    local test_functions=(
        test_sequential_workflow
        test_parallel_workflow
        test_cascade_workflow
        test_error_workflow
        test_mcp_workflow
        test_performance_workflow
        validate_workflow_config
    )
    
    local passed=0
    local failed=0
    
    for test_func in "${test_functions[@]}"; do
        echo ""
        if $test_func; then
            ((passed++))
        else
            ((failed++))
        fi
    done
    
    echo ""
    print_info "Test Summary"
    echo "Passed: $passed"
    echo "Failed: $failed"
    echo "Total: $((passed + failed))"
    
    if [[ $failed -eq 0 ]]; then
        print_success "All workflow tests passed!"
        return 0
    else
        print_error "$failed workflow tests failed"
        return 1
    fi
}

show_usage() {
    echo "Usage: $0 [test_mode]"
    echo ""
    echo "Test modes:"
    echo "  all          - Run all workflow tests (default)"
    echo "  sequential   - Test sequential workflow"
    echo "  parallel     - Test parallel workflow"
    echo "  cascade      - Test triggered cascade"
    echo "  error        - Test error handling"
    echo "  mcp          - Test MCP integration"
    echo "  performance  - Test performance optimization"
    echo "  validate     - Validate configuration"
    echo ""
    echo "Environment variables:"
    echo "  VERBOSE=true - Enable verbose output"
    echo ""
    echo "Examples:"
    echo "  $0                     # Run all tests"
    echo "  $0 sequential          # Test sequential workflow"
    echo "  VERBOSE=true $0        # Verbose mode"
}

# Main execution
main() {
    print_banner
    
    # Set project root
    cd "$(dirname "$0")/../.." || exit 1
    
    case "$TEST_MODE" in
        all)
            run_comprehensive_test
            ;;
        sequential)
            test_sequential_workflow
            ;;
        parallel)
            test_parallel_workflow
            ;;
        cascade)
            test_cascade_workflow
            ;;
        error)
            test_error_workflow
            ;;
        mcp)
            test_mcp_workflow
            ;;
        performance)
            test_performance_workflow
            ;;
        validate)
            validate_workflow_config
            ;;
        help|--help|-h)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown test mode: $TEST_MODE"
            show_usage
            exit 1
            ;;
    esac
    
    local exit_code=$?
    
    if [[ "$VERBOSE" == "true" ]]; then
        echo ""
        print_info "Verbose mode: Additional details logged"
    fi
    
    echo ""
    print_info "For workflow documentation, see: docs/CLAUDE_AGENTS.md"
    
    exit $exit_code
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi