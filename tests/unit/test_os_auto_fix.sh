#!/usr/bin/env bash

# Unit tests for lib/os-auto-fix.sh

# Set ROOT_DIR to project root (two levels up from tests/unit/)
ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

# Source test framework
source "$(dirname "$0")/../test_framework.sh"

# Source common first (provides print_* functions)
source "$ROOT_DIR/lib/common.sh"

# Source the library to test
source "$ROOT_DIR/lib/os-auto-fix.sh"

describe "OS Auto-Fix Library"

# =============================================================================
# Permission Auto-Fix Tests
# =============================================================================

it "should fix permissions on non-executable .sh files"
tmpdir=$(mktemp -d)
echo '#!/usr/bin/env bash' > "$tmpdir/test.sh"
chmod 644 "$tmpdir/test.sh"
auto_fix_permissions "$tmpdir" &>/dev/null
assert_true "test -x '$tmpdir/test.sh'" "Should make .sh files executable"
rm -rf "$tmpdir"

it "should return 1 when no permission issues found"
tmpdir=$(mktemp -d)
echo '#!/usr/bin/env bash' > "$tmpdir/test.sh"
chmod 755 "$tmpdir/test.sh"
assert_false "auto_fix_permissions '$tmpdir' &>/dev/null" "Should return 1 when all files already executable"
rm -rf "$tmpdir"

it "should handle empty directories gracefully"
tmpdir=$(mktemp -d)
assert_false "auto_fix_permissions '$tmpdir' &>/dev/null" "Should return 1 for empty directory"
rm -rf "$tmpdir"

# =============================================================================
# Preflight Check Tests
# =============================================================================

it "should pass preflight on a healthy system"
# On a normal dev machine this should pass — guard for Linux CI where sw_vers is absent
if [[ $EUID -ne 0 ]] && command -v sw_vers >/dev/null 2>&1; then
    mac_major=$(sw_vers -productVersion 2>/dev/null | cut -d. -f1)
    if [[ "$mac_major" =~ ^[0-9]+$ ]] && [[ $mac_major -ge 12 ]]; then
        assert_true "preflight_check &>/dev/null" "Preflight should pass on healthy system"
    fi
fi

it "should fail when run as root"
# We can't actually run as root, but verify the check exists in the function
output=$(declare -f preflight_check)
assert_true "echo '$output' | grep -q 'EUID -eq 0'" "Should check for root execution"

it "should use curl for internet check when available"
output=$(declare -f preflight_check)
assert_true "echo '$output' | grep -q 'curl'" "Should use curl for connectivity check"
assert_true "echo '$output' | grep -q 'max-time'" "Should have a timeout on curl check"

# =============================================================================
# Run Auto-Fixes Tests
# =============================================================================

it "should propagate manual intervention exit code"
output=$(declare -f run_auto_fixes)
assert_true "echo '$output' | grep -q 'return 2'" "Should return exit code 2 for manual intervention"

it "should use repo_root for deprecated packages path"
output=$(declare -f run_auto_fixes)
assert_true "echo '$output' | grep -q 'repo_root'" "Should use repo_root variable for path resolution"
assert_false "echo '$output' | grep -q 'dirname.*\$1.*scripts'" "Should not use dirname on \$1 for scripts path"

# =============================================================================
# Xcode CLT TTY Guard Tests
# =============================================================================

it "should check for interactive TTY before sudo operations"
output=$(declare -f auto_fix_xcode_clt)
assert_true "echo '$output' | grep -q '! -t 0'" "Should check stdin is a TTY"
assert_true "echo '$output' | grep -q '! -t 1'" "Should check stdout is a TTY"
assert_true "echo '$output' | grep -q 'read -r'" "Should prompt for confirmation"

# =============================================================================
# Shell Config TTY Guard Tests
# =============================================================================

it "should guard chsh behind interactive check"
output=$(declare -f auto_fix_shell_config)
assert_true "echo '$output' | grep -q -- '-t 0'" "chsh should be gated on interactive TTY"

# =============================================================================
# NPM Fix Security Tests
# =============================================================================

it "should not use whoami in command substitution for chown"
output=$(declare -f auto_fix_npm)
assert_false "echo '$output' | grep -q '\$(whoami)'" "Should not use \$(whoami) inline"
assert_true "echo '$output' | grep -q 'id -un'" "Should use id -un for current user"

# =============================================================================
# Architecture Detection Tests
# =============================================================================

it "should detect architecture for Homebrew path"
output=$(declare -f auto_fix_homebrew_path)
assert_true "echo '$output' | grep -q 'uname -m'" "Should detect architecture"
assert_true "echo '$output' | grep -q 'arm64'" "Should handle Apple Silicon"
assert_true "echo '$output' | grep -q '/usr/local/bin/brew'" "Should handle Intel path"

# =============================================================================
# Path Validation Before rm -rf Tests
# =============================================================================

it "should validate path exists before rm -rf"
output=$(declare -f auto_fix_xcode_clt)
assert_true "echo '$output' | grep -q '\-d /Library/Developer/CommandLineTools'" "Should check directory exists before rm -rf"

# =============================================================================
# Find Depth Limit Tests
# =============================================================================

it "should limit find depth in permission scan"
output=$(declare -f auto_fix_permissions)
assert_true "echo '$output' | grep -q 'maxdepth'" "Should limit find depth"

# =============================================================================
# NPM Manual Intervention Propagation Tests
# =============================================================================

it "should propagate npm manual intervention in run_auto_fixes"
output=$(declare -f run_auto_fixes)
assert_true "echo '$output' | grep -q 'npm_result'" "Should capture npm exit code"

# Print results
print_summary
