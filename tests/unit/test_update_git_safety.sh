#!/bin/bash

# Test suite for update.sh git safety features
# Tests safe_git_update function

# Source test framework
TEST_FRAMEWORK="$(dirname "$0")/../test_framework.sh"
if [[ ! -f "$TEST_FRAMEWORK" ]]; then
    echo "Error: Test framework not found at $TEST_FRAMEWORK" >&2
    exit 1
fi

source "$TEST_FRAMEWORK"

# Create temporary test environment
TEST_HOME="$(mktemp -d)"
TEST_REPO="$TEST_HOME/test-repo"

# Set up test environment
export HOME="$TEST_HOME"

# Clean up on exit
cleanup() {
    rm -rf "$TEST_HOME"
}
trap cleanup EXIT

# Mock functions from common.sh
print_info() { echo "[INFO] $1"; }
print_step() { echo "[STEP] $1"; }
print_success() { echo "[SUCCESS] $1"; }
print_warning() { echo "[WARNING] $1"; }
print_error() { echo "[ERROR] $1"; }
UPDATE_FAILURES=0

# Extract just the safe_git_update function from update.sh
safe_git_update() {
    local dir="$1"
    local description="$2"
    
    print_step "Updating $description..."
    
    # Check if directory exists
    if [[ ! -d "$dir" ]]; then
        print_error "$description directory not found: $dir"
        ((UPDATE_FAILURES++))
        return 1
    fi
    
    # Check if repository is clean before pulling
    if (cd "$dir" && git diff --quiet && git diff --cached --quiet); then
        if (cd "$dir" && git pull); then
            print_success "$description updated successfully"
            return 0
        else
            print_error "Failed to update $description"
            ((UPDATE_FAILURES++))
            return 1
        fi
    else
        print_warning "$description has uncommitted changes, skipping update"
        return 0
    fi
}

describe "Git Safety Tests for update.sh"

# Test 1: safe_git_update with clean repository
test_case "Should update clean repository"
(
    # Create a test git repository
    mkdir -p "$TEST_REPO"
    cd "$TEST_REPO"
    git init --quiet
    echo "test" > file.txt
    git add file.txt
    git commit -m "Initial commit" --quiet
    
    # Mock git pull to succeed
    git() {
        if [[ "$1" == "pull" ]]; then
            echo "Already up to date."
            return 0
        else
            command git "$@"
        fi
    }
    export -f git
    
    # Test safe_git_update
    UPDATE_FAILURES=0
    safe_git_update "$TEST_REPO" "test repo"
    assert_equals "$?" "0"
)

# Test 2: safe_git_update with uncommitted changes
test_case "Should skip update when repository has uncommitted changes"
(
    # Create a test git repository with uncommitted changes
    mkdir -p "$TEST_REPO"
    cd "$TEST_REPO"
    git init --quiet
    echo "test" > file.txt
    git add file.txt
    git commit -m "Initial commit" --quiet
    echo "changed" > file.txt
    
    # Test safe_git_update
    UPDATE_FAILURES=0
    output=$(safe_git_update "$TEST_REPO" "test repo" 2>&1)
    assert_equals "$?" "0"
    assert_contains "$output" "uncommitted changes"
)

# Test 3: safe_git_update with non-existent directory
test_case "Should fail when directory doesn't exist"
(
    UPDATE_FAILURES=0
    safe_git_update "/non/existent/path" "test repo"
    assert_equals "$?" "1"
    assert_equals "$UPDATE_FAILURES" "1"
)

# Test 4: safe_git_update with git pull failure
test_case "Should handle git pull failure"
(
    # Create a test git repository
    mkdir -p "$TEST_REPO"
    cd "$TEST_REPO"
    git init --quiet
    echo "test" > file.txt
    git add file.txt
    git commit -m "Initial commit" --quiet
    
    # Mock git pull to fail
    git() {
        if [[ "$1" == "pull" ]]; then
            echo "error: failed to pull"
            return 1
        else
            command git "$@"
        fi
    }
    export -f git
    
    # Test safe_git_update
    UPDATE_FAILURES=0
    safe_git_update "$TEST_REPO" "test repo"
    assert_equals "$?" "1"
    assert_equals "$UPDATE_FAILURES" "1"
)

# Print summary
print_test_summary