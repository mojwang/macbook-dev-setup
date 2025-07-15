#!/bin/bash

# Test that migration from old flags to new commands is documented
source "$(dirname "$0")/test_framework.sh"

describe "Migration Guide Tests"

# Test 1: Help shows migration path
it "should guide users from old flags to new commands"
help_output=$(./setup.sh help 2>&1)

# Instead of --dry-run, use preview
assert_contains "$help_output" "preview" "Preview command documented"

# Instead of --minimal flag, use minimal command
assert_contains "$help_output" "minimal" "Minimal command documented"

# Instead of explicit --update/--sync, it's automatic
assert_contains "$help_output" "First run: full setup" "Automatic detection documented"
assert_contains "$help_output" "Later: sync & update" "Automatic sync/update documented"

# Test 2: Invalid old flags show helpful message
it "should show help when old flags are used"
# Test various old flags
for flag in "--sync" "--update" "--dry-run" "--verbose"; do
    output=$(./setup.sh $flag 2>&1 || true)
    assert_contains "$output" "Unknown command" "Old flag '$flag' shows error"
    assert_contains "$output" "help" "Suggests help for '$flag'"
done

# Test 3: Documentation explains the change
it "should document the migration in CLAUDE.md"
claude_content=$(cat CLAUDE.md)

# Check for v2.0 command documentation
assert_contains "$claude_content" "Simple Setup Commands (v2.0)" "v2.0 commands documented"
assert_contains "$claude_content" "./setup.sh preview" "Preview command documented"
assert_contains "$claude_content" "./setup.sh minimal" "Minimal command documented"

# Check that old flag usage is not recommended
assert_false "grep -q 'setup.sh --sync' CLAUDE.md" "Old --sync flag not in examples"
assert_false "grep -q 'setup.sh --dry-run' CLAUDE.md" "Old --dry-run flag not in examples"

# Test 4: Feature mapping is clear
it "should map old features to new commands"
# Verify the mapping is logical:
# --dry-run -> preview
# --minimal (flag) -> minimal (command)
# --sync/--update -> automatic based on state
# --verbose -> SETUP_VERBOSE=1

# Check environment variable documentation
assert_contains "$claude_content" "SETUP_VERBOSE" "Verbose via env var documented"
assert_contains "$claude_content" "For Power Users" "Power user section exists"

# Test 5: Examples use new syntax
it "should use new command syntax in examples"
# Check examples in help
help_output=$(./setup.sh help 2>&1)
assert_contains "$help_output" "./setup.sh preview" "Preview example uses new syntax"
assert_contains "$help_output" "./setup.sh minimal" "Minimal example uses new syntax"

# Check that examples don't use old flags
assert_false "echo '$help_output' | grep -q '\\-\\-sync'" "No --sync in examples"
assert_false "echo '$help_output' | grep -q '\\-\\-dry-run'" "No --dry-run in examples"

# Test 6: Smart detection replaces manual flags
it "should explain automatic sync/update detection"
# The system now automatically detects whether to sync or update
setup_content=$(cat setup.sh)
assert_contains "$setup_content" "detect_setup_state()" "State detection function exists"
assert_contains "$setup_content" "state=\"fresh\"" "Fresh install detection"
assert_contains "$setup_content" "state=\"update\"" "Update detection"

# Documentation should explain this
assert_contains "$claude_content" "Smart setup - detects what needs to be done" "Smart detection documented"

print_summary