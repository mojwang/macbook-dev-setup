#!/usr/bin/env bash

# CI-specific test for cleanup behavior
# This test verifies that no artifacts are left behind

source "$(dirname "$0")/test_framework.sh"

describe "CI Cleanup Verification"

# Record initial state
it "should not leave artifacts in temp directories"

# Count initial temp files (baseline)
initial_tmp_count=$(find /tmp -name "test_*" -o -name "tmp.*" -o -name "signal_test*" 2>/dev/null | wc -l)
initial_tests_count=$(find "$TESTS_DIR" -name "tmp.*" -o -name "failing_test.*" 2>/dev/null | wc -l)

# Run a subset of tests that create temp files
echo "Running tests that create temporary files..."
"$TESTS_DIR/test_common.sh" >/dev/null 2>&1 || true
"$TESTS_DIR/test_backup_system.sh" >/dev/null 2>&1 || true

# Count files after tests
final_tmp_count=$(find /tmp -name "test_*" -o -name "tmp.*" -o -name "signal_test*" 2>/dev/null | wc -l)
final_tests_count=$(find "$TESTS_DIR" -name "tmp.*" -o -name "failing_test.*" 2>/dev/null | wc -l)

# Allow for some system temp files, but no significant increase
tmp_increase=$((final_tmp_count - initial_tmp_count))
tests_increase=$((final_tests_count - initial_tests_count))

assert_true "[[ $tmp_increase -le 5 ]]" "Temp files in /tmp should not increase significantly (increased by $tmp_increase)"
assert_equals "0" "$tests_increase" "No temp files should be left in tests directory"

# Check for test backup directories
it "should not leave test backup directories"

test_backup_count=$(find "$HOME" -maxdepth 1 -name ".test-setup-backups-*" -type d 2>/dev/null | wc -l)
assert_equals "0" "$test_backup_count" "No test backup directories should exist"

# Verify cleanup script exists and is executable
it "should have cleanup utilities available"

assert_file_exists "$ROOT_DIR/scripts/cleanup-artifacts.sh" "Cleanup script should exist"
assert_true "[[ -x '$ROOT_DIR/scripts/cleanup-artifacts.sh' ]]" "Cleanup script should be executable"

# Test cleanup script in dry-run mode
cleanup_output=$("$ROOT_DIR/scripts/cleanup-artifacts.sh" 2>&1)
assert_contains "$cleanup_output" "DRY-RUN mode" "Cleanup script should run in dry-run by default"

# Check for proper signal handling setup
it "should have signal-safe cleanup library"

assert_file_exists "$ROOT_DIR/lib/signal-safety.sh" "Signal safety library should exist"

# Verify critical scripts use proper traps
it "should use proper signal traps in critical scripts"

# Check test_backup_system.sh
backup_traps=$(grep -E "trap.*INT.*TERM" "$TESTS_DIR/test_backup_system.sh" | wc -l)
assert_true "[[ $backup_traps -ge 1 ]]" "test_backup_system.sh should trap interrupt signals"

# Check rollback.sh
rollback_traps=$(grep -E "trap.*INT.*TERM" "$ROOT_DIR/scripts/rollback.sh" | wc -l)
assert_true "[[ $rollback_traps -ge 1 ]]" "rollback.sh should trap interrupt signals"

# GitHub Actions specific checks
if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
    it "should handle GitHub Actions runner cleanup"
    
    # Check runner temp directory
    if [[ -d "${RUNNER_TEMP:-}" ]]; then
        runner_artifacts=$(find "${RUNNER_TEMP}" -name "test_*" -o -name "setup_*" 2>/dev/null | wc -l)
        assert_true "[[ $runner_artifacts -eq 0 ]]" "No test artifacts in GitHub runner temp"
    fi
    
    # Verify no process leaks
    zombie_count=$(ps aux | grep -c "[Zz]ombie\|<defunct>" || echo "0")
    assert_equals "0" "$zombie_count" "No zombie processes should exist"
fi

print_summary