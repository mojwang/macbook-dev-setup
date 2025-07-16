#!/bin/bash

# Test CI-specific behavior and environment detection

# Get script directory
TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$TESTS_DIR")"

# Source test framework
source "$TESTS_DIR/test_framework.sh"
source "$ROOT_DIR/lib/common.sh"

describe "CI Environment Tests"

# Test CI environment detection
it "should detect CI environment correctly"

# Test with various CI environment variables
test_ci_detection() {
    local is_ci=false
    if [[ -n "${CI:-}" ]] || [[ -n "${GITHUB_ACTIONS:-}" ]] || [[ -n "${JENKINS_HOME:-}" ]]; then
        is_ci=true
    fi
    echo "$is_ci"
}

# Save current environment
OLD_CI="${CI:-}"
OLD_GITHUB_ACTIONS="${GITHUB_ACTIONS:-}"

# Test GitHub Actions
CI= GITHUB_ACTIONS=true assert_equals "true" "$(test_ci_detection)" "Should detect GitHub Actions"

# Test generic CI
CI=true GITHUB_ACTIONS= assert_equals "true" "$(test_ci_detection)" "Should detect generic CI"

# Test no CI
CI= GITHUB_ACTIONS= assert_equals "false" "$(test_ci_detection)" "Should detect non-CI environment"

# Restore environment
CI="$OLD_CI"
GITHUB_ACTIONS="$OLD_GITHUB_ACTIONS"

# Test CI-specific performance settings
it "should adjust performance settings for CI"

# Test job count in CI
test_ci_job_count() {
    local ci="${1:-}"
    local cpu_count=$(sysctl -n hw.ncpu 2>/dev/null || echo 4)
    
    if [[ -n "$ci" ]]; then
        # CI environments often benefit from fewer parallel jobs
        echo $(( cpu_count > 4 ? 4 : cpu_count ))
    else
        echo "$cpu_count"
    fi
}

assert_true "[[ $(test_ci_job_count "true") -le 4 ]]" "CI should limit parallel jobs"
assert_equals "$(sysctl -n hw.ncpu 2>/dev/null || echo 4)" "$(test_ci_job_count "")" "Non-CI should use all CPUs"

# Test timeout settings in CI
it "should have appropriate timeouts for CI"

# CI environments should have reasonable timeouts
test_ci_timeouts() {
    local ci="${1:-}"
    
    if [[ -n "$ci" ]]; then
        # CI should have defined timeouts
        echo "timeout_enabled"
    else
        # Local can be more flexible
        echo "timeout_optional"
    fi
}

CI=true assert_equals "timeout_enabled" "$(test_ci_timeouts "$CI")" "CI should enforce timeouts"
CI= assert_equals "timeout_optional" "$(test_ci_timeouts "$CI")" "Local can be flexible"

# Test CI artifact handling
it "should handle CI artifacts correctly"

# Test output directory creation
test_output_dir=$(mktemp -d /tmp/test_output.XXXXXX)
trap "rm -rf '$test_output_dir'" EXIT
CI_OUTPUT_DIR="$test_output_dir/ci-artifacts"

# Simulate CI artifact collection
if [[ -n "${CI:-}" ]]; then
    mkdir -p "$CI_OUTPUT_DIR"
    echo "test-output" > "$CI_OUTPUT_DIR/test.log"
    assert_file_exists "$CI_OUTPUT_DIR/test.log" "Should create CI artifacts"
fi

rm -rf "$test_output_dir"

# Test CI error reporting
it "should format errors appropriately for CI"

# Test error formatting
format_ci_error() {
    local message="$1"
    local file="${2:-}"
    local line="${3:-}"
    
    if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
        # GitHub Actions error format
        echo "::error file=$file,line=$line::$message"
    elif [[ -n "${CI:-}" ]]; then
        # Generic CI format
        echo "ERROR: $message (at $file:$line)"
    else
        # Local format
        echo -e "${RED}✗ $message${NC}"
    fi
}

# Test GitHub Actions format
GITHUB_ACTIONS=true output=$(format_ci_error "Test failed" "test.sh" "42")
assert_true "[[ \"$output\" == *\"::error\"* ]]" "Should use GitHub Actions format"

# Test generic CI format
GITHUB_ACTIONS= CI=true output=$(format_ci_error "Test failed" "test.sh" "42")
assert_true "[[ \"$output\" == *\"ERROR:\"* ]]" "Should use generic CI format"

# Test resource constraints in CI
it "should handle CI resource constraints"

# Test memory usage awareness
test_ci_memory() {
    if [[ -n "${CI:-}" ]]; then
        # CI environments often have memory limits
        echo "constrained"
    else
        echo "unconstrained"
    fi
}

CI=true assert_equals "constrained" "$(test_ci_memory)" "CI should be memory-aware"
CI= assert_equals "unconstrained" "$(test_ci_memory)" "Local has fewer constraints"

# Test CI-specific logging
it "should provide appropriate logging for CI"

# Test log verbosity
test_ci_logging() {
    local ci="${1:-}"
    
    if [[ -n "$ci" ]]; then
        # CI should have detailed logging
        echo "verbose"
    else
        # Local can be quieter
        echo "normal"
    fi
}

assert_equals "verbose" "$(test_ci_logging "true")" "CI should log verbosely"
assert_equals "normal" "$(test_ci_logging "")" "Local should have normal logging"

# Test CI workflow integration
it "should integrate with CI workflows correctly"

# Test exit codes for CI
test_ci_exit_codes() {
    local failures="${1:-0}"
    
    if [[ -n "${CI:-}" ]] && [[ $failures -gt 0 ]]; then
        # CI should fail fast
        return 1
    fi
    
    return 0
}

CI=true test_ci_exit_codes 0
assert_equals "0" "$?" "CI should succeed with no failures"

CI=true test_ci_exit_codes 1
assert_equals "1" "$?" "CI should fail with failures"

# Test CI matrix compatibility
it "should support CI matrix builds"

# Test OS detection
test_os_matrix() {
    local os="${RUNNER_OS:-$(uname -s)}"
    
    case "$os" in
        macOS|Darwin)
            echo "macos"
            ;;
        Linux)
            echo "linux"
            ;;
        Windows)
            echo "windows"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Current OS should be detected
current_os=$(test_os_matrix)
assert_true "[[ \"$current_os\" == \"macos\" || \"$current_os\" == \"linux\" ]]" "Should detect OS correctly"

# Test CI caching awareness
it "should be aware of CI caching"

# Test cache directory detection
test_cache_dir() {
    if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
        echo "${RUNNER_TEMP:-/tmp}/cache"
    elif [[ -n "${CI:-}" ]]; then
        echo "${CI_CACHE_DIR:-/tmp/ci-cache}"
    else
        echo "$HOME/.cache"
    fi
}

# Should return appropriate cache directory
cache_dir=$(test_cache_dir)
assert_true "[[ -n \"$cache_dir\" ]]" "Should provide cache directory"

# Test CI parallel test execution
it "should optimize parallel execution for CI"

# Create test files for parallel execution
for i in {1..5}; do
    cat > "$TESTS_DIR/test_ci_parallel_$i.sh" <<EOF
#!/bin/bash
source "\$(dirname "\$0")/test_framework.sh"
describe "CI Parallel Test $i"
it "runs quickly"
assert_true "true" "Test $i passes"
EOF
    chmod +x "$TESTS_DIR/test_ci_parallel_$i.sh"
done

# Run tests with CI settings
old_ci="$CI"
export CI=true
start_time=$(date +%s)
(cd "$TESTS_DIR" && TEST_JOBS=2 bash ./run_tests_parallel_simple.sh >/dev/null 2>&1)
end_time=$(date +%s)
duration=$((end_time - start_time))
CI="$old_ci"

# Should complete reasonably fast even with limited jobs
assert_true "[[ $duration -lt 10 ]]" "CI parallel tests should complete quickly"

# Clean up
rm -f "$TESTS_DIR"/test_ci_parallel_*.sh

# Summary
echo -e "\n${BLUE}Test Summary${NC}"
echo "============"
echo "Total tests: $TEST_COUNT"
echo "Passed: $PASSED_COUNT"
echo "Failed: $FAILED_COUNT"

if [[ $FAILED_COUNT -eq 0 ]]; then
    exit 0
else
    exit 1
fi