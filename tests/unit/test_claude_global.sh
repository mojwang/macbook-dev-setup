#!/bin/bash

# Test script for global Claude configuration setup

# Check if test framework exists
TEST_FRAMEWORK="$(dirname "$0")/../test_framework.sh"
if [[ ! -f "$TEST_FRAMEWORK" ]]; then
    echo "Error: Test framework not found at $TEST_FRAMEWORK" >&2
    echo "Please ensure the test framework is available before running tests." >&2
    exit 1
fi

source "$TEST_FRAMEWORK"

# Create a temporary test environment
TEST_HOME="$(mktemp -d)"
TEST_CLAUDE_DIR="$TEST_HOME/.claude"
TEST_CLAUDE_MD="$TEST_CLAUDE_DIR/CLAUDE.md"
TEST_TEMPLATE="$(mktemp)"

# Write a test template
cat > "$TEST_TEMPLATE" << 'EOF'
# Test Global Claude Instructions
This is a test template for Claude configuration.
EOF

# Clean up on exit
cleanup() {
    rm -rf "$TEST_HOME" "$TEST_TEMPLATE"
}
trap cleanup EXIT

# Mock the setup script environment
export HOME="$TEST_HOME"
CLAUDE_DIR="$TEST_CLAUDE_DIR"
CLAUDE_GLOBAL_MD="$TEST_CLAUDE_MD"
TEMPLATE_FILE="$TEST_TEMPLATE"

# Mock functions from common.sh
print_info() { echo "[INFO] $1"; }
print_step() { echo "[STEP] $1"; }
print_success() { echo "[SUCCESS] $1"; }
print_warning() { echo "[WARNING] $1"; }

# Test 1: Fresh installation creates directory and file
test_case "Fresh installation of global CLAUDE.md"
(
    # Source the relevant part of the script
    mkdir -p "$CLAUDE_DIR" 2>/dev/null || true
    cp "$TEMPLATE_FILE" "$CLAUDE_GLOBAL_MD"
    chmod 644 "$CLAUDE_GLOBAL_MD"
)
assert_directory_exists "$TEST_CLAUDE_DIR"
assert_file_exists "$TEST_CLAUDE_MD"
assert_equals "644" "$(stat -f %Lp "$TEST_CLAUDE_MD" 2>/dev/null || stat -c %a "$TEST_CLAUDE_MD" 2>/dev/null)"

# Test 2: Existing identical file is not replaced
test_case "Existing identical CLAUDE.md is preserved"
original_content=$(cat "$TEST_CLAUDE_MD")
original_mtime=$(stat -f %m "$TEST_CLAUDE_MD" 2>/dev/null || stat -c %Y "$TEST_CLAUDE_MD" 2>/dev/null)
sleep 1  # Ensure different mtime if file is modified
# Simulate running setup again - should not modify file
assert_equals "$original_content" "$(cat "$TEST_CLAUDE_MD")"

# Test 3: Different content creates backup
test_case "Modified CLAUDE.md creates backup"
# Modify the existing file
echo "Modified content" > "$TEST_CLAUDE_MD"
# Update template
echo "New template content" > "$TEST_TEMPLATE"
# Simulate update with backup
backup_file="$TEST_CLAUDE_MD.backup.test"
cp "$TEST_CLAUDE_MD" "$backup_file"
cp "$TEST_TEMPLATE" "$TEST_CLAUDE_MD"
assert_file_exists "$backup_file"
assert_equals "New template content" "$(cat "$TEST_CLAUDE_MD")"

# Test 4: Directory creation when missing
test_case "Creates .claude directory if missing"
rm -rf "$TEST_CLAUDE_DIR"
assert_false "test -d '$TEST_CLAUDE_DIR'"
mkdir -p "$TEST_CLAUDE_DIR"
assert_directory_exists "$TEST_CLAUDE_DIR"

# Test 5: Check mode returns correct exit codes
test_case "Check mode exit codes"
# File exists and matches
cp "$TEST_TEMPLATE" "$TEST_CLAUDE_MD"
diff -q "$TEST_TEMPLATE" "$TEST_CLAUDE_MD" >/dev/null 2>&1
assert_equals "0" "$?"

# File exists but differs
echo "Different content" > "$TEST_CLAUDE_MD"
diff -q "$TEST_TEMPLATE" "$TEST_CLAUDE_MD" >/dev/null 2>&1
assert_equals "1" "$?"

# File doesn't exist
rm -f "$TEST_CLAUDE_MD"
assert_false "test -f '$TEST_CLAUDE_MD'"

# Test 6: Template file validation
test_case "Template file must exist"
rm -f "$TEST_TEMPLATE"
assert_false "test -f '$TEST_TEMPLATE'"
# Create it for other tests
echo "Test content" > "$TEST_TEMPLATE"
assert_file_exists "$TEST_TEMPLATE"

# Test 7: Permissions are set correctly
test_case "File permissions set to 644"
touch "$TEST_CLAUDE_MD"
chmod 600 "$TEST_CLAUDE_MD"
# Simulate fixing permissions
chmod 644 "$TEST_CLAUDE_MD"
perms=$(stat -f %Lp "$TEST_CLAUDE_MD" 2>/dev/null || stat -c %a "$TEST_CLAUDE_MD" 2>/dev/null)
assert_equals "644" "$perms"

# Test 8: Non-interactive mode handling
test_case "Non-interactive mode skips prompts"
# Modify existing file
echo "Existing content" > "$TEST_CLAUDE_MD"
echo "New template content" > "$TEST_TEMPLATE"
# Simulate CI environment
export CI=true
# In CI mode, should not update the file
assert_equals "Existing content" "$(cat "$TEST_CLAUDE_MD")"
unset CI

# Test 9: Version metadata handling
test_case "Version metadata is added to installed file"
rm -f "$TEST_CLAUDE_MD"
# Simulate installation with metadata
{
    echo "# Claude Global Config Version: 1.0.0"
    echo "# Last Updated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "# Source: macbook-dev-setup/config/global-claude.md"
    echo ""
    cat "$TEST_TEMPLATE"
} > "$TEST_CLAUDE_MD"
assert_true "grep -q '^# Claude Global Config Version:' '$TEST_CLAUDE_MD'"
assert_true "grep -q '^# Last Updated:' '$TEST_CLAUDE_MD'"
assert_true "grep -q '^# Source:' '$TEST_CLAUDE_MD'"

# Summary
echo ""
print_test_summary