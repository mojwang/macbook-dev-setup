#!/usr/bin/env bash
set -e

# Test Agent Workflows Script
# Validates the 7-agent orchestration pattern (product-strategist → product-tactician → researcher → planner → implementer → reviewer → designer)

source "$(dirname "$0")/../../lib/common.sh"

TEST_MODE="${1:-all}"

print_banner() {
    echo ""
    echo "════════════════════════════════════════════════"
    echo "    Agent Workflow Testing Suite (7-Agent)"
    echo "════════════════════════════════════════════════"
    echo ""
}

# Validate agent definitions exist and have correct frontmatter
test_agent_definitions() {
    print_info "Testing Agent Definitions"

    local agents=("product-strategist" "product-tactician" "researcher" "planner" "implementer" "reviewer" "designer")
    local failed=0

    for agent in "${agents[@]}"; do
        local agent_file=".claude/agents/${agent}.md"
        if [[ -f "$agent_file" ]]; then
            # Check YAML frontmatter exists
            if head -1 "$agent_file" | grep -q "^---"; then
                print_success "  ✓ ${agent}: definition exists with frontmatter"
            else
                print_error "  ✗ ${agent}: missing YAML frontmatter"
                ((failed++))
            fi
        else
            print_error "  ✗ ${agent}: definition missing ($agent_file)"
            ((failed++))
        fi
    done

    [[ $failed -eq 0 ]] && return 0 || return 1
}

# Validate orchestration flow (Phase 1-4)
test_orchestration_flow() {
    print_info "Testing Orchestration Flow"

    local phases=(
        "Phase 1 - Research:researcher:research.md"
        "Phase 2 - Plan:planner:plan.md"
        "Phase 3 - Implement:implementer:code changes"
        "Phase 4 - Review:reviewer:review summary"
    )

    for phase in "${phases[@]}"; do
        local name="${phase%%:*}"
        local rest="${phase#*:}"
        local agent="${rest%%:*}"
        local output="${rest#*:}"

        echo "  ${name}: ${agent} → ${output}"
        # Verify agent file exists
        [[ -f ".claude/agents/${agent}.md" ]] || {
            print_error "  ✗ Missing agent: ${agent}"
            return 1
        }
    done

    print_success "  ✓ All phases have corresponding agents"
    return 0
}

# Validate implementer worktree isolation
test_worktree_isolation() {
    print_info "Testing Implementer Worktree Isolation"

    local impl_file=".claude/agents/implementer.md"
    if grep -q "isolation.*worktree" "$impl_file" 2>/dev/null; then
        print_success "  ✓ Implementer has worktree isolation configured"
    else
        print_error "  ✗ Implementer missing worktree isolation"
        return 1
    fi

    return 0
}

# Validate artifact gitignore
test_artifacts_gitignored() {
    print_info "Testing Artifact Gitignore"

    local artifacts=("research.md" "plan.md" "design-spec.md" "product-brief.md")
    local failed=0

    for artifact in "${artifacts[@]}"; do
        if git check-ignore -q "$artifact" 2>/dev/null; then
            print_success "  ✓ ${artifact} is gitignored"
        else
            print_warning "  ⚠ ${artifact} may not be gitignored"
            ((failed++))
        fi
    done

    [[ $failed -eq 0 ]] && return 0 || return 1
}

# Validate workflow configuration files
validate_workflow_config() {
    print_info "Validating Workflow Configuration"

    local config_checks=(
        "Agent documentation:docs/CLAUDE_AGENTS.md"
        "Helper scripts dir:scripts/claude-agents/"
        "Agent definitions dir:.claude/agents/"
        "Orchestrator config:CLAUDE.md"
        "Structured metadata:.claude-agents.json"
    )

    local failed=0
    for check in "${config_checks[@]}"; do
        local description="${check%%:*}"
        local path="${check##*:}"

        if [[ -e "$path" ]]; then
            print_success "  ✓ $description"
        else
            print_error "  ✗ $description (missing: $path)"
            ((failed++))
        fi
    done

    [[ $failed -eq 0 ]] && return 0 || return 1
}

# Run all tests
run_comprehensive_test() {
    print_info "Running Comprehensive Workflow Test"

    local test_functions=(
        test_agent_definitions
        test_orchestration_flow
        test_worktree_isolation
        test_artifacts_gitignored
        validate_workflow_config
    )

    local passed=0
    local failed=0

    for test_func in "${test_functions[@]}"; do
        echo ""
        if $test_func; then
            ((passed++)) || true
        else
            ((failed++)) || true
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
    echo "  all        - Run all workflow tests (default)"
    echo "  agents     - Validate agent definitions"
    echo "  flow       - Test orchestration flow"
    echo "  worktree   - Test worktree isolation"
    echo "  artifacts  - Test artifact gitignore"
    echo "  validate   - Validate configuration"
    echo ""
}

main() {
    print_banner
    cd "$(dirname "$0")/../.." || exit 1

    case "$TEST_MODE" in
        all)        run_comprehensive_test ;;
        agents)     test_agent_definitions ;;
        flow)       test_orchestration_flow ;;
        worktree)   test_worktree_isolation ;;
        artifacts)  test_artifacts_gitignored ;;
        validate)   validate_workflow_config ;;
        help|--help|-h) show_usage; exit 0 ;;
        *)
            print_error "Unknown test mode: $TEST_MODE"
            show_usage
            exit 1
            ;;
    esac

    echo ""
    print_info "For workflow documentation, see: docs/CLAUDE_AGENTS.md"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
