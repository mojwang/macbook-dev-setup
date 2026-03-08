#!/usr/bin/env bash
set -e

# Agent Benchmarks Script
# Performance testing for the 4-agent orchestration pattern

source "$(dirname "$0")/../../lib/common.sh"

BENCHMARK_MODE="${1:-all}"
ITERATIONS="${ITERATIONS:-5}"
OUTPUT_FORMAT="${OUTPUT_FORMAT:-table}"

print_banner() {
    echo ""
    echo "┌─────────────────────────────────────────────┐"
    echo "│   Agent Performance Benchmarks (4-Agent)    │"
    echo "└─────────────────────────────────────────────┘"
    echo ""
}

# Portable millisecond timer (macOS date lacks %N; use gdate or python fallback)
_now_ms() {
    if command -v gdate &>/dev/null; then
        echo $(( $(gdate +%s%N) / 1000000 ))
    elif command -v python3 &>/dev/null; then
        python3 -c 'import time; print(int(time.time()*1000))'
    else
        echo $(( $(date +%s) * 1000 ))
    fi
}

# Time measurement utility — always returns 0 so callers under set -e don't abort
measure_time() {
    local command="$1"
    local start
    start=$(_now_ms)

    if ! eval "$command" >/dev/null 2>&1; then
        print_warning "Command failed: ${command%% *}..." >&2
    fi

    local end
    end=$(_now_ms)
    echo $(( end - start ))
    return 0
}

# Benchmark researcher-like operations (read-only codebase exploration)
benchmark_researcher() {
    print_info "Benchmarking Researcher Operations"

    local tasks=(
        "File discovery:find . -name '*.sh' -type f 2>/dev/null | wc -l"
        "Pattern search:grep -r 'source.*common.sh' . --include='*.sh' 2>/dev/null | wc -l || true"
        "Dependency tracing:grep -r 'source\|import' . --include='*.sh' 2>/dev/null | head -20 || true"
        "Convention scan:find . -name '*.sh' -exec head -1 {} \\; 2>/dev/null | sort -u | head -5 || true"
    )

    local total_time=0
    for task in "${tasks[@]}"; do
        local name="${task%%:*}"
        local command="${task##*:}"

        printf "  %-25s" "$name"

        local task_time=0
        for ((i=1; i<=ITERATIONS; i++)); do
            local time=$(measure_time "$command")
            task_time=$((task_time + time))
        done

        local avg_time=$((task_time / ITERATIONS))
        total_time=$((total_time + avg_time))
        printf "%6dms (avg of %d runs)\n" "$avg_time" "$ITERATIONS"
    done

    echo ""
    print_info "Total Researcher ops time: ${total_time}ms"
    return 0
}

# Benchmark reviewer-like operations (validation checks)
benchmark_reviewer() {
    print_info "Benchmarking Reviewer Operations"

    local tasks=(
        "Test suite:./tests/run_tests.sh 2>/dev/null || true"
        "Shellcheck scan:command -v shellcheck >/dev/null && shellcheck setup.sh 2>/dev/null | head -10 || true"
        "Secret scan:grep -rE '(API_KEY|PASSWORD|SECRET).*=' . --include='*.sh' 2>/dev/null | wc -l || true"
        "Convention check:grep -rE 'set -e' scripts/ --include='*.sh' 2>/dev/null | wc -l || true"
    )

    local total_time=0
    for task in "${tasks[@]}"; do
        local name="${task%%:*}"
        local command="${task##*:}"

        printf "  %-25s" "$name"

        local task_time=0
        for ((i=1; i<=ITERATIONS; i++)); do
            local time=$(measure_time "$command")
            task_time=$((task_time + time))
        done

        local avg_time=$((task_time / ITERATIONS))
        total_time=$((total_time + avg_time))
        printf "%6dms (avg of %d runs)\n" "$avg_time" "$ITERATIONS"
    done

    echo ""
    print_info "Total Reviewer ops time: ${total_time}ms"
    return 0
}

# Benchmark parallel agent execution
benchmark_parallel_agents() {
    print_info "Benchmarking Parallel Agent Execution"
    print_info "Simulating 2 implementers + 1 reviewer in parallel..."

    local start
    start=$(_now_ms)

    (
        sleep 0.5  # Simulate Implementer A
        echo "  [Implementer A] Completed" >&2
    ) &
    local pid1=$!

    (
        sleep 0.5  # Simulate Implementer B
        echo "  [Implementer B] Completed" >&2
    ) &
    local pid2=$!

    (
        sleep 0.3  # Simulate Reviewer
        echo "  [Reviewer] Completed" >&2
    ) &
    local pid3=$!

    wait $pid1 $pid2 $pid3

    local end
    end=$(_now_ms)
    local parallel_time=$(( end - start ))

    echo ""
    print_info "Parallel execution time: ${parallel_time}ms"
    print_info "Expected sequential time: ~1300ms"
    print_success "Speedup: $(( 1300 * 100 / parallel_time ))%"
    return 0
}

# Generate performance report
generate_report() {
    print_info "Performance Report"

    local report_data=$(cat <<EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "architecture": "4-agent (researcher, planner, implementer, reviewer)",
  "system": {
    "os": "$(uname -s)",
    "arch": "$(uname -m)",
    "cores": $(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 1)
  },
  "agents": ["researcher", "planner", "implementer", "reviewer"],
  "recommendations": [
    "Run multiple implementers in parallel for independent tasks",
    "Skip researcher phase for well-understood areas",
    "Use worktree isolation for all implementers"
  ]
}
EOF
)

    case "$OUTPUT_FORMAT" in
        json)  echo "$report_data" ;;
        csv)
            echo "Agent,Role,Isolation"
            echo "researcher,exploration,none"
            echo "planner,planning,none"
            echo "implementer,execution,worktree"
            echo "reviewer,verification,none"
            ;;
        table|*)
            echo "╔════════════════╤═══════════════╤═══════════╗"
            echo "║ Agent          │ Role          │ Isolation ║"
            echo "╠════════════════╪═══════════════╪═══════════╣"
            echo "║ researcher     │ exploration   │ none      ║"
            echo "║ planner        │ planning      │ none      ║"
            echo "║ implementer    │ execution     │ worktree  ║"
            echo "║ reviewer       │ verification  │ none      ║"
            echo "╚════════════════╧═══════════════╧═══════════╝"
            ;;
    esac
    return 0
}

# Stress test
stress_test() {
    print_info "Agent Operations Stress Test"

    local stress_iterations="${STRESS_ITERATIONS:-20}"
    print_info "Running $stress_iterations iterations..."

    local start=$(date +%s)

    for ((i=1; i<=stress_iterations; i++)); do
        printf "\rProgress: %3d%%" $((i * 100 / stress_iterations))
        find . -name "*.sh" -type f 2>/dev/null | head -5 >/dev/null
        grep -r "test" . 2>/dev/null | head -5 >/dev/null
        ls -la scripts/ >/dev/null 2>&1
    done

    local end=$(date +%s)
    local total_time=$((end - start))

    echo ""
    echo ""
    print_success "Stress test completed"
    print_info "Total time: ${total_time}s"
    print_info "Avg per iteration: $(( total_time * 1000 / stress_iterations ))ms"
    return 0
}

show_usage() {
    echo "Usage: $0 [benchmark_mode]"
    echo ""
    echo "Benchmark modes:"
    echo "  all        - Run all benchmarks (default)"
    echo "  researcher - Benchmark researcher operations"
    echo "  reviewer   - Benchmark reviewer operations"
    echo "  parallel   - Benchmark parallel execution"
    echo "  stress     - Run stress test"
    echo "  report     - Generate performance report"
    echo ""
    echo "Environment variables:"
    echo "  ITERATIONS=n        - Number of iterations (default: 5)"
    echo "  OUTPUT_FORMAT=fmt   - Output format: table, json, csv (default: table)"
    echo "  STRESS_ITERATIONS=n - Stress test iterations (default: 20)"
}

main() {
    print_banner
    cd "$(dirname "$0")/../.." || exit 1

    case "$BENCHMARK_MODE" in
        all)
            benchmark_researcher
            benchmark_reviewer
            benchmark_parallel_agents
            generate_report
            ;;
        researcher)  benchmark_researcher ;;
        reviewer)    benchmark_reviewer ;;
        parallel)    benchmark_parallel_agents ;;
        stress)      stress_test ;;
        report)      generate_report ;;
        help|--help|-h) show_usage; exit 0 ;;
        *)
            print_error "Unknown benchmark mode: $BENCHMARK_MODE"
            show_usage
            exit 1
            ;;
    esac

    echo ""
    print_info "Benchmark completed"
    print_info "For agent documentation, see: docs/CLAUDE_AGENTS.md"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
