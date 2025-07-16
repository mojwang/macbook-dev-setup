#!/bin/bash

# Test script for backup system functionality
source "$(dirname "$0")/test_framework.sh"
source "$(dirname "$0")/../lib/common.sh"

describe "Backup System Tests"

# Set up isolated test environment
test_backup_root="$HOME/.test-setup-backups-$$"
# Use the environment variable that backup-manager expects
export SETUP_BACKUP_ROOT="$test_backup_root"
export SETUP_MAX_BACKUPS=10

# Now source the backup manager to get it to use our test root
source "$(dirname "$0")/../lib/backup-manager.sh"

# Cleanup function
cleanup_test_env() {
    rm -rf "$test_backup_root"
    rm -f "$HOME/.test_backup_file"*
    rm -f "$HOME/.test_latest_file"
    rm -f "$HOME/.test_metadata"
    rm -f "$HOME/.test_permissions"
    # Clean up any other test files
    rm -f "$test_backup_root/test.backup" 2>/dev/null
    rm -f "$test_backup_root/test.bak" 2>/dev/null
}

# Set up cleanup trap to ensure cleanup happens on exit or interruption
trap cleanup_test_env EXIT INT TERM HUP

# Ensure clean start
cleanup_test_env

# Test 1: Backup directory structure
it "should create proper backup directory structure"
ensure_backup_root
assert_directory_exists "$BACKUP_ROOT" "Backup root directory created"

for category in "${BACKUP_CATEGORIES[@]}"; do
    assert_directory_exists "$BACKUP_ROOT/$category" "Category directory: $category"
done

# Check for latest directory
assert_directory_exists "$BACKUP_ROOT/latest" "Latest symlinks directory"

# Test 2: Create backup function
it "should create backups with proper naming"
test_file="$HOME/.test_backup_file"
echo "test content" > "$test_file"

# Use backup_organized which actually copies the file
backup_dir=$(backup_organized "$test_file" "configs" "Test backup")
assert_directory_exists "$backup_dir" "Backup directory created"
assert_contains "$backup_dir" "configs" "Backup in correct category"
assert_contains "$backup_dir" "$(date +%Y%m%d)" "Backup has date stamp"

# Check if the file was copied to the backup directory
backup_file="$backup_dir/$(basename "$test_file")"
assert_file_exists "$backup_file" "Backup file created"

rm -f "$test_file"

# Test 3: Latest symlink creation
it "should create latest symlinks in the correct location"
# Create a test file
test_file="$HOME/.test_latest_file"
echo "latest test" > "$test_file"

# Create backup
backup_dir=$(create_backup "configs" "$test_file" "Latest test")

# Check for symlink in the correct location
latest_link="$BACKUP_ROOT/latest/configs"
assert_true "[[ -L '$latest_link' ]]" "Latest symlink exists"

# Verify symlink points to the backup
if [[ -L "$latest_link" ]]; then
    link_target=$(readlink "$latest_link")
    assert_equals "$link_target" "$backup_dir" "Latest symlink points to newest backup"
fi

rm -f "$test_file"

# Test 4: Backup cleanup
it "should clean old backups when limit exceeded"
# First, lower the max backups for testing
export SETUP_MAX_BACKUPS=3
# Re-source to pick up new limit
MAX_BACKUPS=3

# Clear existing backups in test directory
rm -rf "$BACKUP_ROOT/configs"/*

# Create more backups than the limit
for i in {1..5}; do
    test_file="$HOME/.test_backup_file_$i"
    echo "content $i" > "$test_file"
    create_backup "configs" "$test_file" "Test $i" >/dev/null 2>&1
    rm -f "$test_file"
    sleep 0.1  # Ensure different timestamps
done

# Count backups after cleanup (should be MAX_BACKUPS or less)
backup_count=$(ls -1 "$BACKUP_ROOT/configs" 2>/dev/null | wc -l)
assert_true "[[ $backup_count -le 3 ]]" "Backups cleaned to limit ($backup_count <= 3)"

# Restore original max
export SETUP_MAX_BACKUPS=10
MAX_BACKUPS=10

# Test 5: Old backup migration
it "should migrate old backups to new structure"
# Create test directory structure
mkdir -p "$test_backup_root"

# Create isolated old backups in test directory
old_backup_1="$test_backup_root/test.backup"
old_backup_2="$test_backup_root/test.bak"
echo "old backup 1" > "$old_backup_1"
echo "old backup 2" > "$old_backup_2"

# Temporarily change HOME to test directory for migration
original_home="$HOME"
export HOME="$test_backup_root"

# Run migration
migrate_old_backups >/dev/null 2>&1

# Restore HOME
export HOME="$original_home"

# Check if old backups were moved
assert_false "[[ -f '$old_backup_1' ]]" "Old .backup file migrated"
assert_false "[[ -f '$old_backup_2' ]]" "Old .bak file migrated"

# Test 6: Backup metadata
it "should create backups with metadata"
test_metadata_file="$HOME/.test_metadata"
echo "metadata test" > "$test_metadata_file"

backup_dir=$(create_backup "configs" "$test_metadata_file" "Backup with metadata")
metadata_file="$backup_dir/metadata.json"

assert_file_exists "$metadata_file" "Metadata file created"
if [[ -f "$metadata_file" ]]; then
    metadata_content=$(cat "$metadata_file")
    assert_contains "$metadata_content" "Backup with metadata" "Metadata contains description"
    assert_contains "$metadata_content" "configs" "Metadata contains category"
fi

rm -f "$test_metadata_file"

# Test 7: List backups function
it "should list backups correctly"
# Ensure we have at least one backup
test_file="$HOME/.test_backup_file"
echo "list test" > "$test_file"
create_backup "configs" "$test_file" "List test backup" >/dev/null 2>&1
rm -f "$test_file"

# Capture list_backups output
list_output=$(list_backups 2>&1)
assert_contains "$list_output" "Setup Backups" "List shows header"
assert_contains "$list_output" "configs:" "List shows configs category"
assert_contains "$list_output" "•" "List shows backup items"

# Test 8: Backup permissions
it "should preserve file permissions"
test_perm_file="$HOME/.test_permissions"
echo "permission test" > "$test_perm_file"
chmod 600 "$test_perm_file"

backup_dir=$(create_backup "configs" "$test_perm_file" "Permission test")
backup_file="$backup_dir/$(basename "$test_perm_file")"
original_perms=$(stat -f "%Lp" "$test_perm_file" 2>/dev/null || stat -c "%a" "$test_perm_file" 2>/dev/null)

if [[ -f "$backup_file" ]]; then
    backup_perms=$(stat -f "%Lp" "$backup_file" 2>/dev/null || stat -c "%a" "$backup_file" 2>/dev/null)
    assert_equals "$backup_perms" "$original_perms" "File permissions preserved"
fi

rm -f "$test_perm_file"

# Test 9: Backup root initialization
it "should handle multiple ensure_backup_root calls"
# Call multiple times - should not error
ensure_backup_root
ensure_backup_root
ensure_backup_root
assert_directory_exists "$BACKUP_ROOT" "Backup root still exists after multiple calls"

# Test 10: Test backup content preservation
it "should preserve backup content correctly"
test_file1="$HOME/.test_backup_file1"
test_file2="$HOME/.test_backup_file2"
echo "content 1" > "$test_file1"
echo "content 2" > "$test_file2"

# Create backups
backup1=$(create_backup "configs" "$test_file1" "Test 1")
sleep 1  # Ensure different timestamp
backup2=$(create_backup "configs" "$test_file2" "Test 2")

# Check content is preserved
backup1_file="$backup1/$(basename "$test_file1")"
backup2_file="$backup2/$(basename "$test_file2")"

if [[ -f "$backup1_file" ]] && [[ -f "$backup2_file" ]]; then
    content1=$(cat "$backup1_file")
    content2=$(cat "$backup2_file")
    assert_equals "$content1" "content 1" "Backup 1 content preserved"
    assert_equals "$content2" "content 2" "Backup 2 content preserved"
fi

rm -f "$test_file1" "$test_file2"

print_summary