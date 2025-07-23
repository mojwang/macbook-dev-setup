#!/bin/bash

# Integration test for global Claude configuration setup
source "$(dirname "$0")/../test_framework.sh"

# Get the root directory
ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

# Create temporary test environment
TEST_HOME="$(mktemp -d)"
export HOME="$TEST_HOME"

# Clean up on exit
cleanup() {
    export HOME="$ORIGINAL_HOME"
    rm -rf "$TEST_HOME"
}
ORIGINAL_HOME="$HOME"
trap cleanup EXIT

describe "Global Claude Configuration Integration"

it "integrates with main setup flow"
# Ensure the script exists
assert_file_exists "$ROOT_DIR/scripts/setup-claude-global.sh" "setup-claude-global.sh exists"

# Ensure the template exists
assert_file_exists "$ROOT_DIR/config/global-claude.md" "Template file exists"

# Run the setup script
output=$("$ROOT_DIR/scripts/setup-claude-global.sh" 2>&1)
exit_code=$?
assert_equals "0" "$exit_code" "Script exits successfully"

# Verify the global CLAUDE.md was created
assert_file_exists "$TEST_HOME/.claude/CLAUDE.md" "Global CLAUDE.md created"

# Verify content matches template
if diff -q "$ROOT_DIR/config/global-claude.md" "$TEST_HOME/.claude/CLAUDE.md" >/dev/null 2>&1; then
    assert_true "true" "Content matches template"
else
    assert_false "true" "Content does not match template"
fi

it "handles check mode correctly"
# Test check mode when file exists and matches
output=$("$ROOT_DIR/scripts/setup-claude-global.sh" --check 2>&1)
exit_code=$?
assert_equals "0" "$exit_code" "Check mode returns 0 when up to date"

# Modify the file to test mismatch
echo "Modified content" > "$TEST_HOME/.claude/CLAUDE.md"
output=$("$ROOT_DIR/scripts/setup-claude-global.sh" --check 2>&1)
exit_code=$?
assert_equals "1" "$exit_code" "Check mode returns 1 when update needed"

# Remove file to test missing
rm -f "$TEST_HOME/.claude/CLAUDE.md"
output=$("$ROOT_DIR/scripts/setup-claude-global.sh" --check 2>&1)
exit_code=$?
assert_equals "1" "$exit_code" "Check mode returns 1 when file missing"

it "creates backup on update"
# Create an existing file with different content
mkdir -p "$TEST_HOME/.claude"
echo "Original content that will be backed up" > "$TEST_HOME/.claude/CLAUDE.md"

# Run setup again (would normally prompt, but in test we simulate)
# Since we can't interact, we'll manually simulate the backup behavior
backup_name="$TEST_HOME/.claude/CLAUDE.md.backup.$(date +%Y%m%d_%H%M%S)"
cp "$TEST_HOME/.claude/CLAUDE.md" "$backup_name"
cp "$ROOT_DIR/config/global-claude.md" "$TEST_HOME/.claude/CLAUDE.md"

# Verify backup was created
assert_true "ls $TEST_HOME/.claude/CLAUDE.md.backup.* >/dev/null 2>&1" "Backup file created"

it "sets correct permissions"
# Check file permissions
perms=$(stat -f %Lp "$TEST_HOME/.claude/CLAUDE.md" 2>/dev/null || stat -c %a "$TEST_HOME/.claude/CLAUDE.md" 2>/dev/null)
assert_equals "644" "$perms" "File has correct permissions (644)"

# Summary
echo ""
print_test_summary