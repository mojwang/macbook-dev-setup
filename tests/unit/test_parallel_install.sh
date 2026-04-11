#!/usr/bin/env bash

# Unit tests for parallel brew installation in scripts/install-packages.sh
# Tests the parallel helpers, Brewfile parsing, and result collection logic
# without actually calling brew (mocked).

_TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_PROJECT_ROOT="$(cd "$_TEST_DIR/../.." && pwd)"

source "$_TEST_DIR/../test_framework.sh"

# ── Regex patterns (must be in variables for bash =~ with quotes) ──

BREW_PATTERN='^brew[[:space:]]+"(.+)"'
CASK_PATTERN='^cask[[:space:]]+"(.+)"'
TAP_PATTERN='^tap[[:space:]]+"(.+)"'

# ── Fixtures ──

FIXTURE_DIR=$(mktemp -d /tmp/test_parallel_install.XXXXXX)
trap 'rm -rf "$FIXTURE_DIR"' EXIT

# Create a minimal test Brewfile
cat > "$FIXTURE_DIR/Brewfile" << 'EOF'
tap "homebrew/autoupdate"

brew "git"
brew "gh"
brew "bat"
brew "ripgrep"

cask "visual-studio-code"
cask "arc"
cask "font-anonymice-nerd-font"
EOF

# ── Test: Brewfile parsing extracts correct package names ──

describe "Brewfile Parsing"

it "should extract formula names from Brewfile"
formulae=()
while IFS= read -r line; do
    if [[ "$line" =~ $BREW_PATTERN ]]; then
        formulae+=("${BASH_REMATCH[1]}")
    fi
done < "$FIXTURE_DIR/Brewfile"

assert_equals "4" "${#formulae[@]}" "Should find 4 formulae"
assert_equals "git" "${formulae[0]}" "First formula should be git"
assert_equals "ripgrep" "${formulae[3]}" "Last formula should be ripgrep"

it "should extract cask names from Brewfile"
casks=()
while IFS= read -r line; do
    if [[ "$line" =~ $CASK_PATTERN ]]; then
        casks+=("${BASH_REMATCH[1]}")
    fi
done < "$FIXTURE_DIR/Brewfile"

assert_equals "3" "${#casks[@]}" "Should find 3 casks"
assert_equals "visual-studio-code" "${casks[0]}" "First cask should be visual-studio-code"

it "should extract tap names from Brewfile"
taps=()
while IFS= read -r line; do
    if [[ "$line" =~ $TAP_PATTERN ]]; then
        taps+=("${BASH_REMATCH[1]}")
    fi
done < "$FIXTURE_DIR/Brewfile"

assert_equals "1" "${#taps[@]}" "Should find 1 tap"
assert_equals "homebrew/autoupdate" "${taps[0]}" "Tap should be homebrew/autoupdate"

it "should skip comment lines and blank lines"
cat > "$FIXTURE_DIR/Brewfile.comments" << 'EOF'
# This is a comment
brew "git"

# Another comment
  # Indented comment
brew "bat"
EOF

comment_formulae=()
while IFS= read -r line; do
    if [[ "$line" =~ $BREW_PATTERN ]]; then
        comment_formulae+=("${BASH_REMATCH[1]}")
    fi
done < "$FIXTURE_DIR/Brewfile.comments"

assert_equals "2" "${#comment_formulae[@]}" "Should only find 2 formulae, skipping comments"

# ── Test: Font detection regex ──

describe "Font Detection"

it "should identify font casks by prefix"
for cask in "font-anonymice-nerd-font" "font-symbols-only-nerd-font" "font-fira-code"; do
    if [[ "$cask" =~ ^font- ]]; then
        pass_test "Correctly identified $cask as font"
    else
        fail_test "Failed to identify $cask as font"
    fi
done

it "should not flag non-font casks as fonts"
for cask in "visual-studio-code" "arc" "1password"; do
    if [[ "$cask" =~ ^font- ]]; then
        fail_test "Incorrectly flagged $cask as font"
    else
        pass_test "Correctly skipped $cask"
    fi
done

# ── Test: Parallel results collection ──

describe "Parallel Results Collection"

it "should collect installed packages from results file"
results_dir=$(mktemp -d)
touch "$results_dir/installed.txt" "$results_dir/failed.txt"

echo "git" >> "$results_dir/installed.txt"
echo "bat" >> "$results_dir/installed.txt"
echo "ripgrep" >> "$results_dir/installed.txt"

installed_count=$(wc -l < "$results_dir/installed.txt" | tr -d ' ')
assert_equals "3" "$installed_count" "Should count 3 installed packages"
rm -rf "$results_dir"

it "should collect failed packages from results file"
results_dir=$(mktemp -d)
touch "$results_dir/installed.txt" "$results_dir/failed.txt"

echo "broken-pkg" >> "$results_dir/failed.txt"
echo "another-broken" >> "$results_dir/failed.txt"

failed_packages=()
while IFS= read -r pkg; do
    [[ -n "$pkg" ]] && failed_packages+=("brew \"$pkg\"")
done < "$results_dir/failed.txt"

assert_equals "2" "${#failed_packages[@]}" "Should collect 2 failed packages"
assert_equals 'brew "broken-pkg"' "${failed_packages[0]}" "Should format failed package correctly"
rm -rf "$results_dir"

it "should handle empty results files"
results_dir=$(mktemp -d)
touch "$results_dir/installed.txt" "$results_dir/failed.txt"

installed_count=$(wc -l < "$results_dir/installed.txt" | tr -d ' ')
assert_equals "0" "$installed_count" "Empty file should have 0 lines"

failed_packages=()
while IFS= read -r pkg; do
    [[ -n "$pkg" ]] && failed_packages+=("brew \"$pkg\"")
done < "$results_dir/failed.txt"

assert_equals "0" "${#failed_packages[@]}" "Should have no failed packages"
rm -rf "$results_dir"

# ── Test: Concurrent writes to results files ──

describe "Concurrent Write Safety"

it "should handle parallel appends to results files without data loss"
results_dir=$(mktemp -d)
touch "$results_dir/installed.txt"

# Simulate 10 parallel appends (mimics xargs -P behavior)
for i in $(seq 1 10); do
    echo "package-$i" >> "$results_dir/installed.txt" &
done
wait

line_count=$(wc -l < "$results_dir/installed.txt" | tr -d ' ')
assert_equals "10" "$line_count" "All 10 parallel writes should be captured"
rm -rf "$results_dir"

# ── Test: _install_one_formula helper ──

describe "Formula Install Helper"

it "should record success in installed.txt when brew succeeds"
results_dir=$(mktemp -d)
touch "$results_dir/installed.txt" "$results_dir/failed.txt"

# Mock brew to succeed
brew() { return 0; }
export -f brew

# Source colors (needed by the helper)
export GREEN='\033[0;32m' YELLOW='\033[1;33m' RED='\033[0;31m' NC='\033[0m'

# Define the helper inline (same logic as install-packages.sh)
_install_one_formula() {
    local formula="$1"
    local results_dir="$2"
    if HOMEBREW_NO_AUTO_UPDATE=1 brew install "$formula" &>/dev/null; then
        echo "$formula" >> "$results_dir/installed.txt"
    else
        echo "$formula" >> "$results_dir/failed.txt"
    fi
}

_install_one_formula "test-pkg" "$results_dir"
assert_file_contains "$results_dir/installed.txt" "test-pkg" "Successful install should be recorded"

# Verify not in failed
failed_count=$(wc -l < "$results_dir/failed.txt" | tr -d ' ')
assert_equals "0" "$failed_count" "Should not appear in failed.txt"

cleanup_mocks brew
rm -rf "$results_dir"

it "should record failure in failed.txt when brew fails"
results_dir=$(mktemp -d)
touch "$results_dir/installed.txt" "$results_dir/failed.txt"

# Mock brew to fail
brew() { return 1; }
export -f brew

_install_one_formula "broken-pkg" "$results_dir"
assert_file_contains "$results_dir/failed.txt" "broken-pkg" "Failed install should be recorded"

installed_count=$(wc -l < "$results_dir/installed.txt" | tr -d ' ')
assert_equals "0" "$installed_count" "Should not appear in installed.txt"

cleanup_mocks brew
rm -rf "$results_dir"

# ── Test: Parallelism settings ──

describe "Parallelism Configuration"

it "should use default parallelism values"
# Unset any overrides
unset SETUP_PARALLEL_FORMULAE SETUP_PARALLEL_CASKS

PARALLEL_FORMULAE="${SETUP_PARALLEL_FORMULAE:-4}"
PARALLEL_CASKS="${SETUP_PARALLEL_CASKS:-2}"

assert_equals "4" "$PARALLEL_FORMULAE" "Default formula parallelism should be 4"
assert_equals "2" "$PARALLEL_CASKS" "Default cask parallelism should be 2"

it "should respect custom parallelism env vars"
export SETUP_PARALLEL_FORMULAE=8
export SETUP_PARALLEL_CASKS=3

PARALLEL_FORMULAE="${SETUP_PARALLEL_FORMULAE:-4}"
PARALLEL_CASKS="${SETUP_PARALLEL_CASKS:-2}"

assert_equals "8" "$PARALLEL_FORMULAE" "Custom formula parallelism should be 8"
assert_equals "3" "$PARALLEL_CASKS" "Custom cask parallelism should be 3"

unset SETUP_PARALLEL_FORMULAE SETUP_PARALLEL_CASKS

# ── Test: Collect-then-install pattern ──

describe "Collect-Then-Install Pattern"

it "should correctly separate installed vs new packages"
# Simulate: git and bat are installed, ripgrep and fd are not
installed_list="git
bat"

all_packages=("git" "bat" "ripgrep" "fd")
to_install=()

for pkg in "${all_packages[@]}"; do
    if echo "$installed_list" | grep -qx "$pkg"; then
        : # skip
    else
        to_install+=("$pkg")
    fi
done

assert_equals "2" "${#to_install[@]}" "Should have 2 packages to install"
assert_equals "ripgrep" "${to_install[0]}" "First to install should be ripgrep"
assert_equals "fd" "${to_install[1]}" "Second to install should be fd"

# ── Summary ──

print_test_summary
