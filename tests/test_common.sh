#!/bin/bash

# Unit tests for lib/common.sh

# Source test framework
source "$(dirname "$0")/test_framework.sh"

# Source the library to test
source "$ROOT_DIR/lib/common.sh"

describe "Common Library Functions"

# Test command_exists function
it "should detect existing commands"
assert_true "command_exists bash" "bash command should exist"
assert_true "command_exists ls" "ls command should exist"
assert_false "command_exists nonexistentcommand123" "nonexistent command should not exist"

# Test validate_email function
it "should validate email addresses correctly"
assert_true "validate_email 'test@example.com'" "Valid email should pass"
assert_true "validate_email 'user.name+tag@example.co.uk'" "Complex valid email should pass"
assert_false "validate_email 'invalid.email'" "Email without @ should fail"
assert_false "validate_email '@example.com'" "Email without local part should fail"
assert_false "validate_email 'test@'" "Email without domain should fail"
assert_false "validate_email 'test @example.com'" "Email with space should fail"

# Test system detection functions
it "should detect macOS correctly"
if [[ "$OSTYPE" == "darwin"* ]]; then
    assert_true "require_macos &>/dev/null" "require_macos should succeed on macOS"
fi

it "should detect Apple Silicon correctly"
if [[ "$(uname -m)" == "arm64" ]]; then
    assert_true "check_apple_silicon" "Should detect Apple Silicon on M1/M2 Macs"
else
    assert_false "check_apple_silicon" "Should not detect Apple Silicon on Intel Macs"
fi

# Test color output functions (just verify they don't error)
it "should output colored messages without errors"
assert_true "print_step 'Test step' &>/dev/null" "print_step should not error"
assert_true "print_success 'Test success' &>/dev/null" "print_success should not error"
assert_true "print_warning 'Test warning' &>/dev/null" "print_warning should not error"
assert_true "print_error 'Test error' &>/dev/null" "print_error should not error"
assert_true "print_info 'Test info' &>/dev/null" "print_info should not error"

# Test backup_item function
it "should create backups correctly"
temp_file=$(mktemp /tmp/test_file.XXXXXX)
echo "test content" > "$temp_file"
temp_backup_dir=$(mktemp -d /tmp/test_backup.XXXXXX)
trap "rm -f '$temp_file'; rm -rf '$temp_backup_dir'" EXIT

backup_result=$(backup_item "$temp_file" "$temp_backup_dir")
assert_file_exists "$temp_backup_dir/$(basename "$temp_file")" "Backup file should exist"

# Cleanup
rm -f "$temp_file"
rm -rf "$temp_backup_dir"

# Test create_restore_point function
it "should create restore points"
# Capture output but extract the path from the function
output=$(create_restore_point "test" 2>&1)
restore_point=$(echo "$output" | grep -o "/Users/[^[:space:]]*" | tail -1)

assert_directory_exists "$restore_point" "Restore point directory should exist"
assert_file_exists "$restore_point/metadata.json" "Metadata file should exist"

# Cleanup
rm -rf "$restore_point"
rm -f "$HOME/.setup_restore/latest"

# Test environment variables
it "should set required environment variables"
assert_true "[[ -n \$ROOT_DIR ]]" "ROOT_DIR should be set"
assert_true "[[ -n \$TIMESTAMP ]]" "TIMESTAMP should be set"
assert_true "[[ -n \$SCRIPT_NAME ]]" "SCRIPT_NAME should be set"
assert_true "[[ -n \$SCRIPT_DIR ]]" "SCRIPT_DIR should be set"

# Test disk space check (mock)
it "should check disk space"
# This test would need to be more sophisticated in a real scenario
assert_true "check_disk_space 1 / &>/dev/null" "Should pass with 1GB requirement"

# Test confirm function (non-interactive)
it "should handle non-interactive confirmations"
assert_true "confirm 'Test?' 'y' </dev/null" "Should return true with 'y' default"
assert_false "confirm 'Test?' 'n' </dev/null" "Should return false with 'n' default"