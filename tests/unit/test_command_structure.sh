#!/usr/bin/env bash

# Test script for new command structure
_TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_TEST_DIR/../test_framework.sh"

describe "Command Structure Tests"

# Test 1: Help command
it "should display help with various flags"
help_output=$(./setup.sh help 2>&1)
assert_contains "$help_output" "Usage:" "Help shows usage"
assert_contains "$help_output" "preview" "Help lists preview command"
assert_contains "$help_output" "minimal" "Help lists minimal command"
assert_contains "$help_output" "fix" "Help lists fix command"
assert_contains "$help_output" "warp" "Help lists warp command"
assert_contains "$help_output" "advanced" "Help lists advanced command"

# Test same with -h and --help
help_h=$(./setup.sh -h 2>&1)
assert_contains "$help_h" "Usage:" "Help works with -h flag"

help_long=$(./setup.sh --help 2>&1)
assert_contains "$help_long" "Usage:" "Help works with --help flag"

# Test 2: Preview command
it "should run preview/dry-run mode"
# Test that preview delegates to setup-validate.sh
preview_output=$(./setup.sh preview 2>&1)
assert_contains "$preview_output" "Preview Mode" "Preview mode activated"
assert_contains "$preview_output" "What would happen" "Preview shows planned actions"

# Test minimal preview
minimal_preview=$(./setup.sh preview minimal 2>&1)
assert_contains "$minimal_preview" "minimal" "Minimal preview mode works"

# Test 3: Environment variable handling
it "should respect environment variables"
# Test SETUP_VERBOSE
verbose_output=$(SETUP_VERBOSE=true ./setup.sh preview 2>&1)
assert_contains "$verbose_output" "SETUP_VERBOSE: true" "Verbose mode detected"

# Test SETUP_NO_WARP
no_warp_output=$(SETUP_NO_WARP=true ./setup.sh preview 2>&1)
assert_contains "$no_warp_output" "SETUP_NO_WARP: true" "No-warp mode detected"

# Test SETUP_JOBS
jobs_output=$(SETUP_JOBS=8 ./setup.sh preview 2>&1)
assert_contains "$jobs_output" "SETUP_JOBS: 8" "Custom jobs detected"

# Test invalid SETUP_JOBS
invalid_jobs=$(SETUP_JOBS=invalid ./setup.sh preview 2>&1)
assert_contains "$invalid_jobs" "Invalid SETUP_JOBS" "Invalid jobs value caught"

# Test 4: Backup command structure
it "should handle backup subcommands"
# Test backup list (default)
backup_list=$(./setup.sh backup 2>&1)
if command -v create_backup &>/dev/null; then
    assert_contains "$backup_list" "backup" "Backup list command works"
else
    assert_contains "$backup_list" "Backup" "Backup command recognized"
fi

# Test backup clean
backup_help=$(./setup.sh backup help 2>&1)
assert_contains "$backup_help" "clean" "Backup help shows clean option"

# Test 5: Fix/diagnostics command
it "should run diagnostics"
# Mock a simple diagnostic check
fix_output=$(./setup.sh fix 2>&1 | head -20)
# The fix command shows "Running Diagnostics" header
assert_contains "$fix_output" "Running Diagnostics" "Fix command runs diagnostics"

# Test 6: Command validation
it "should handle invalid commands gracefully"
invalid_output=$(./setup.sh invalid_command 2>&1 || true)
# The script shows an error message and suggests help
assert_contains "$invalid_output" "Unknown command" "Invalid command recognized"
assert_contains "$invalid_output" "help" "Suggests running help"

# Test 7: Deprecation notice
it "should handle old flags gracefully"
# Test unrecognized flags show error
invalid_output=$(./setup.sh --sync 2>&1 || true)
assert_contains "$invalid_output" "Unknown command" "Old flags show error message"
assert_contains "$invalid_output" "help" "Suggests running help"

# Test that help mentions the new way
help_output=$(./setup.sh help 2>&1)
assert_contains "$help_output" "preview" "Help shows preview instead of --dry-run"
assert_contains "$help_output" "minimal" "Help shows minimal command"

print_summary