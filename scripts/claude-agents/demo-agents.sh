#!/usr/bin/env bash
set -e

# Claude Agents Demo Script
# Demonstrates the 6-agent orchestration pattern

source "$(dirname "$0")/../../lib/common.sh"

DEMO_MODE="${1:-interactive}"

print_banner() {
    echo ""
    echo "╔══════════════════════════════════════════════╗"
    echo "║     Claude Sub-Agents Demo (6-Agent)        ║"
    echo "╚══════════════════════════════════════════════╝"
    echo ""
}

demo_researcher() {
    print_info "Researcher Agent Demo"

    print_info "The Researcher explores the codebase before planning."
    print_info "Capabilities:"
    echo "  • Trace code paths and map dependencies"
    echo "  • Find patterns and conventions"
    echo "  • Identify risks and conflicts"
    echo ""

    print_info "Simulating Researcher execution..."
    echo "  → Scanning affected files... 12 files found"
    echo "  → Mapping dependencies... 3 dependency chains"
    echo "  → Identifying patterns... modular zsh config pattern"
    echo "  → Checking risks... none found"
    echo "  → Writing research.md"
    echo ""
    print_success "Researcher: Findings written to research.md"
}

demo_planner() {
    print_info "Planner Agent Demo"

    print_info "The Planner creates implementation plans from research."
    print_info "Capabilities:"
    echo "  • Read research.md for context"
    echo "  • Produce plan.md with tasks"
    echo "  • Support annotation cycles (NOTE:/Q:)"
    echo ""

    print_info "Simulating Planner execution..."
    echo "  → Reading research.md..."
    echo "  → Creating task breakdown... 4 tasks"
    echo "  → Defining testing strategy..."
    echo "  → Writing plan.md"
    echo ""
    print_success "Planner: Plan written to plan.md"
}

demo_implementer() {
    print_info "Implementer Agent Demo"

    print_info "The Implementer executes plans in worktree isolation."
    print_info "Capabilities:"
    echo "  • Execute assigned tasks from plan.md"
    echo "  • Self-sufficient loop (test → fix → commit)"
    echo "  • Checkpoint commits per task"
    echo ""

    print_info "Simulating Implementer execution..."
    echo "  → Creating worktree..."
    echo "  → Task 1: Implementing feature... done"
    echo "  → Running tests... 15/15 passed"
    echo "  → Committing: feat(scope): add feature"
    echo "  → Task 2: Adding tests... done"
    echo "  → Running tests... 18/18 passed"
    echo "  → Committing: test(scope): add coverage"
    echo ""
    print_success "Implementer: 2 tasks completed, 2 commits"
}

demo_reviewer() {
    print_info "Reviewer Agent Demo"

    print_info "The Reviewer verifies implementation quality."
    print_info "Capabilities:"
    echo "  • Run test suite"
    echo "  • Shellcheck validation"
    echo "  • Security scanning"
    echo "  • Doc consistency checks"
    echo "  • Performance anti-pattern detection"
    echo ""

    print_info "Simulating Reviewer execution..."
    echo "  → Running tests... all passed"
    echo "  → Running shellcheck... no issues"
    echo "  → Checking secrets... none found"
    echo "  → Checking doc consistency... up to date"
    echo "  → Checking performance... no anti-patterns"
    echo ""
    print_success "Reviewer: Status PASSED"
}

demo_workflow() {
    print_info "Full Workflow Demo"
    print_info "Orchestrator dispatching agents through Phase 1-4:"
    echo ""

    echo "Phase 1: Research"
    sleep 0.5
    echo "  → Researcher: Exploring codebase..."
    echo "  ✓ research.md written"
    echo ""

    echo "Phase 2: Plan"
    sleep 0.5
    echo "  → Planner: Creating plan from research..."
    echo "  ✓ plan.md written (3 tasks)"
    echo ""

    echo "Phase 3: Implement"
    sleep 0.5
    echo "  → Implementer A (worktree): Tasks 1-2"
    echo "  → Implementer B (worktree): Task 3"
    echo "  ✓ All tasks completed (parallel)"
    echo ""

    echo "Phase 4: Verify"
    sleep 0.5
    echo "  → Reviewer: Validating implementation..."
    echo "  ✓ Status: PASSED"
    echo ""

    print_success "Workflow completed — ready for PR creation!"
}

interactive_menu() {
    while true; do
        echo ""
        print_info "Select a demo:"
        echo "  1) Researcher Agent"
        echo "  2) Planner Agent"
        echo "  3) Implementer Agent"
        echo "  4) Reviewer Agent"
        echo "  5) Full Workflow"
        echo "  6) Run All Demos"
        echo "  q) Quit"
        echo ""
        read -p "Choice: " choice

        case $choice in
            1) demo_researcher ;;
            2) demo_planner ;;
            3) demo_implementer ;;
            4) demo_reviewer ;;
            5) demo_workflow ;;
            6)
                demo_researcher
                demo_planner
                demo_implementer
                demo_reviewer
                demo_workflow
                ;;
            q|Q)
                print_info "Exiting demo suite."
                exit 0
                ;;
            *)
                print_error "Invalid choice."
                ;;
        esac
    done
}

show_usage() {
    echo "Usage: $0 [mode]"
    echo ""
    echo "Modes:"
    echo "  interactive  - Interactive menu (default)"
    echo "  researcher   - Demo Researcher Agent"
    echo "  planner      - Demo Planner Agent"
    echo "  implementer  - Demo Implementer Agent"
    echo "  reviewer     - Demo Reviewer Agent"
    echo "  workflow     - Demo full workflow"
    echo "  all          - Run all demos"
}

main() {
    print_banner

    case "$DEMO_MODE" in
        interactive)  interactive_menu ;;
        researcher)   demo_researcher ;;
        planner)      demo_planner ;;
        implementer)  demo_implementer ;;
        reviewer)     demo_reviewer ;;
        workflow)     demo_workflow ;;
        all)
            demo_researcher
            demo_planner
            demo_implementer
            demo_reviewer
            demo_workflow
            ;;
        help|--help|-h) show_usage ;;
        *)
            print_error "Unknown mode: $DEMO_MODE"
            show_usage
            exit 1
            ;;
    esac

    echo ""
    print_info "For more information, see: docs/CLAUDE_AGENTS.md"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
