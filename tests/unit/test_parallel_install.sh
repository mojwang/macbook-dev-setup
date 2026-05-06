#!/usr/bin/env bash
set -e

# Unit tests for parallel brew installation in scripts/install-packages.sh.
# Sources the production script directly (which is source-safe via the
# _INSTALL_PACKAGES_SOURCED guard) so tests exercise real production code,
# not inline copies.

_TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_PROJECT_ROOT="$(cd "$_TEST_DIR/../.." && pwd)"

source "$_TEST_DIR/../test_framework.sh"

# Source production code — this defines functions, constants, and regex
# patterns without running the install flow (guarded by the SOURCED check).
# shellcheck source=../../scripts/install-packages.sh
source "$_PROJECT_ROOT/scripts/install-packages.sh"

# Regex patterns from production. We mirror them here ONLY for the parsing
# tests below — production uses inline regex in install_packages(), which
# isn't exposed as a separate function. If the parsing logic gets
# extracted to its own helper later, these tests should source that
# helper instead.
BREW_PATTERN='^brew[[:space:]]+"(.+)"'
CASK_PATTERN='^cask[[:space:]]+"(.+)"'
TAP_PATTERN='^tap[[:space:]]+"(.+)"'

# ── Fixtures ──

FIXTURE_DIR=$(mktemp -d /tmp/test_parallel_install.XXXXXX)
trap 'rm -rf "$FIXTURE_DIR"' EXIT

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

# ── Test: Brewfile parsing ──

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

# ── Test: Font detection ──

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

# ── Test: Concurrent writes ──

describe "Concurrent Write Safety"

it "should handle parallel appends to results files without data loss"
results_dir=$(mktemp -d)
touch "$results_dir/installed.txt"

for i in $(seq 1 10); do
    echo "package-$i" >> "$results_dir/installed.txt" &
done
wait

line_count=$(wc -l < "$results_dir/installed.txt" | tr -d ' ')
assert_equals "10" "$line_count" "All 10 parallel writes should be captured"
rm -rf "$results_dir"

# ── Test: _install_one_formula (sourced from production) ──

describe "Formula Install Helper (production code)"

it "should record success in installed.txt when brew succeeds"
results_dir=$(mktemp -d)
touch "$results_dir/installed.txt" "$results_dir/failed.txt"

# Mock brew to succeed
brew() { return 0; }
export -f brew

# _install_one_formula was sourced from production — no inline copy
_install_one_formula "test-pkg" "$results_dir"
assert_file_contains "$results_dir/installed.txt" "test-pkg" "Successful install should be recorded"

failed_count=$(wc -l < "$results_dir/failed.txt" | tr -d ' ')
assert_equals "0" "$failed_count" "Should not appear in failed.txt"

cleanup_mocks brew
rm -rf "$results_dir"

it "should record failure in failed.txt when brew fails"
results_dir=$(mktemp -d)
touch "$results_dir/installed.txt" "$results_dir/failed.txt"

brew() { return 1; }
export -f brew

_install_one_formula "broken-pkg" "$results_dir"
assert_file_contains "$results_dir/failed.txt" "broken-pkg" "Failed install should be recorded"

installed_count=$(wc -l < "$results_dir/installed.txt" | tr -d ' ')
assert_equals "0" "$installed_count" "Should not appear in installed.txt"

cleanup_mocks brew
rm -rf "$results_dir"

# ── Test: Parallelism configuration (constants from sourced production) ──

describe "Parallelism Configuration (production constants)"

it "should expose default parallelism values from production"
# PARALLEL_FORMULAE and PARALLEL_CASKS are set when the script is sourced.
# Default values come from production's `${SETUP_PARALLEL_*:-N}` lines.
assert_equals "4" "$PARALLEL_FORMULAE" "Default formula parallelism should be 4"
assert_equals "2" "$PARALLEL_CASKS" "Default cask parallelism should be 2"

it "should respect custom parallelism env vars when re-sourced"
# Re-source with overrides to verify the env var wiring works in production
(
    export SETUP_PARALLEL_FORMULAE=8
    export SETUP_PARALLEL_CASKS=3
    # shellcheck source=../../scripts/install-packages.sh
    source "$_PROJECT_ROOT/scripts/install-packages.sh"
    assert_equals "8" "$PARALLEL_FORMULAE" "Custom formula parallelism should be 8"
    assert_equals "3" "$PARALLEL_CASKS" "Custom cask parallelism should be 3"
)

# ── Test: xargs failure handling under set -e (issue #1, #7) ──

describe "Parallel xargs Failure Handling Under set -e"

it "should preserve failure-collection when one parallel install fails (set -e safety)"
results_dir=$(mktemp -d)
touch "$results_dir/installed.txt" "$results_dir/failed.txt"

# Mock brew: succeed for "good-pkg", fail for "broken-pkg"
brew() {
    if [[ "$2" == "broken-pkg" ]]; then
        return 1
    fi
    return 0
}
export -f brew

# Mimic the production xargs invocation pattern (safe form: -n1 + positional
# args + || true). Without `|| true`, set -e would kill us when broken-pkg's
# install fails inside xargs.
printf '%s\n' "good-pkg" "broken-pkg" "good-pkg-2" | \
    xargs -P 2 -n1 \
        bash -c '_install_one_formula "$2" "$1"' _ "$results_dir" \
    || true

# Both temp files should be populated
assert_file_contains "$results_dir/installed.txt" "good-pkg" \
    "Successful installs should be in installed.txt"
assert_file_contains "$results_dir/failed.txt" "broken-pkg" \
    "Failed install should be in failed.txt"

# Code reached here — set -e didn't abort us. Test the assertion.
installed_count=$(wc -l < "$results_dir/installed.txt" | tr -d ' ')
failed_count=$(wc -l < "$results_dir/failed.txt" | tr -d ' ')
assert_equals "2" "$installed_count" "Should record 2 successful installs"
assert_equals "1" "$failed_count" "Should record 1 failed install"

cleanup_mocks brew
rm -rf "$results_dir"

it "should handle package names with shell metacharacters safely (issue #7)"
# Issue #7: PR #108's original `xargs -I{}` pattern text-substitutes {} into
# the command string — package names with shell metacharacters (;, &, |, $(),
# backticks) would be interpreted by the shell. Switch to `xargs -n1` + bash
# positional args, which passes each input as a single quoted argv element.
#
# Note: spaces in package names would still be split by xargs's default
# whitespace delimiter — but Homebrew package names never contain spaces
# (lowercase + hyphens + digits only), so this test focuses on shell
# metachars that ARE realistic in malformed Brewfiles.
results_dir=$(mktemp -d)
touch "$results_dir/installed.txt" "$results_dir/failed.txt"

brew() { return 0; }
export -f brew

# Package names with shell metacharacters that the OLD -I{} pattern would
# have evaluated. With the safe -n1 pattern, they should be passed as
# literal strings to brew install (and recorded as-is in installed.txt).
printf '%s\n' 'pkg;evil' 'pkg&bg' 'pkg$(whoami)' 'pkg`id`' | \
    xargs -P 1 -n1 \
        bash -c '_install_one_formula "$2" "$1"' _ "$results_dir" \
    || true

installed_count=$(wc -l < "$results_dir/installed.txt" | tr -d ' ')
assert_equals "4" "$installed_count" \
    "All 4 metachar packages should install as single literal names"
assert_file_contains "$results_dir/installed.txt" 'pkg;evil' \
    "Semicolon should be preserved as literal"
assert_file_contains "$results_dir/installed.txt" 'pkg&bg' \
    "Ampersand should be preserved as literal"
assert_file_contains "$results_dir/installed.txt" 'pkg$(whoami)' \
    "Command substitution should NOT execute (preserved as literal)"
assert_file_contains "$results_dir/installed.txt" 'pkg`id`' \
    "Backtick command substitution should NOT execute (preserved as literal)"

cleanup_mocks brew
rm -rf "$results_dir"

# ── Test: Top-level helpers + diagnostic + signal-safe temp (commit 3) ──

describe "Top-Level Helpers + Diagnostic + Signal-Safe Temp"

it "should expose _install_one_cask at top level (issue #3)"
# After sourcing install-packages.sh, _install_one_cask should be defined
# AND exported (so xargs subshells can call it). Previously it was nested
# inside install_packages() and would silently disappear if set -e fired
# before the nested definition was reached.
if declare -F _install_one_cask >/dev/null; then
    pass_test "_install_one_cask is defined at source time"
else
    fail_test "_install_one_cask should be defined at source time"
fi

# Confirm it's exported (visible in subshells)
exported_in_subshell=$(bash -c 'declare -F _install_one_cask >/dev/null && echo "yes" || echo "no"')
assert_equals "yes" "$exported_in_subshell" "_install_one_cask should be exported to subshells"

it "should run cask install with same success/failure semantics as formula"
results_dir=$(mktemp -d)
touch "$results_dir/installed.txt" "$results_dir/failed.txt"

brew() { return 0; }  # mock cask install success
export -f brew

_install_one_cask "test-cask" "$results_dir"
assert_file_contains "$results_dir/installed.txt" "test-cask" "Successful cask install recorded"

cleanup_mocks brew
rm -rf "$results_dir"

it "should fire formula-as-cask diagnostic when failed formula is actually a cask (issue #2)"
# _warn_if_formula_is_cask runs `brew info --cask "$pkg"` and emits a
# print_warning if it succeeds. Mock brew so `brew info --cask X` succeeds
# (i.e., X IS a known cask), then verify the warning fires to stderr.
brew() {
    if [[ "$1" == "info" && "$2" == "--cask" ]]; then
        return 0   # X is a cask
    fi
    return 1
}
export -f brew

# Capture warning output
warning_output=$(_warn_if_formula_is_cask "visual-studio-code" 2>&1)
if [[ "$warning_output" == *"appears to be a cask"* ]]; then
    pass_test "Diagnostic emitted when failed formula is actually a cask"
else
    fail_test "Expected diagnostic about cask misclassification, got: $warning_output"
fi

cleanup_mocks brew

it "should NOT fire diagnostic when failed formula is genuinely just a missing formula"
brew() { return 1; }   # neither formula nor cask works
export -f brew

quiet_output=$(_warn_if_formula_is_cask "nonexistent-pkg" 2>&1)
if [[ -z "$quiet_output" ]]; then
    pass_test "No diagnostic when package isn't a cask"
else
    fail_test "Expected no output, got: $quiet_output"
fi

cleanup_mocks brew

it "should use safe_mktemp_dir when signal-safety lib is loaded (issue #4)"
# After sourcing install-packages.sh, safe_mktemp_dir should be available
# (sourced from lib/signal-safety.sh)
if declare -F safe_mktemp_dir >/dev/null; then
    pass_test "safe_mktemp_dir is available after sourcing install-packages.sh"
else
    fail_test "safe_mktemp_dir should be sourced via signal-safety.sh"
fi

if declare -F setup_cleanup >/dev/null; then
    pass_test "setup_cleanup is available for trap registration"
else
    fail_test "setup_cleanup should be sourced via signal-safety.sh"
fi

# ── Test: Pre-flight taps + shared-deps preinstall (commit 4) ──

describe "Pre-Flight Taps + Shared-Deps Preinstall"

it "should expose _preflight_taps and _preinstall_shared_deps at top level"
if declare -F _preflight_taps >/dev/null; then
    pass_test "_preflight_taps is defined"
else
    fail_test "_preflight_taps should be defined at source time"
fi

if declare -F _preinstall_shared_deps >/dev/null; then
    pass_test "_preinstall_shared_deps is defined"
else
    fail_test "_preinstall_shared_deps should be defined at source time"
fi

if [[ "${SHARED_DEPS[*]:-}" == *openssl* ]]; then
    pass_test "SHARED_DEPS array includes openssl"
else
    fail_test "SHARED_DEPS array should include openssl@3"
fi

it "should pre-flight all taps from a Brewfile in order"
# Mock brew to capture every `brew tap X` invocation
TAP_LOG=$(mktemp)
brew() {
    if [[ "$1" == "tap" ]]; then
        echo "$2" >> "$TAP_LOG"
    fi
    return 0
}
export -f brew

# Brewfile fixture with mixed taps + formulas
BREWFILE_FIXTURE=$(mktemp)
cat > "$BREWFILE_FIXTURE" << 'EOF'
tap "homebrew/autoupdate"
tap "oven-sh/bun"
brew "git"
tap "withgraphite/tap"
brew "gh"
EOF

_preflight_taps "$BREWFILE_FIXTURE"

# Verify all 3 taps were processed in file order
tap_count=$(wc -l < "$TAP_LOG" | tr -d ' ')
assert_equals "3" "$tap_count" "All 3 taps from Brewfile should be pre-flighted"

# Verify order
expected_order="homebrew/autoupdate
oven-sh/bun
withgraphite/tap"
actual_order=$(cat "$TAP_LOG")
assert_equals "$expected_order" "$actual_order" "Taps should be processed in Brewfile order"

cleanup_mocks brew
rm -f "$TAP_LOG" "$BREWFILE_FIXTURE"

it "should install missing shared deps and skip already-installed ones"
INSTALL_LOG=$(mktemp)
LIST_LOG=$(mktemp)

# Mock: pretend openssl@3 and readline are already installed; gmp/libffi/pkg-config are not
brew() {
    if [[ "$1" == "list" ]]; then
        echo "$3" >> "$LIST_LOG"
        case "$3" in
            openssl@3|readline) return 0 ;;
            *) return 1 ;;
        esac
    elif [[ "$1" == "install" ]]; then
        echo "$2" >> "$INSTALL_LOG"
        return 0
    fi
    return 0
}
export -f brew

_preinstall_shared_deps >/dev/null 2>&1

# Should have checked all 5 shared deps via `brew list --formula`
list_count=$(wc -l < "$LIST_LOG" | tr -d ' ')
assert_equals "5" "$list_count" "Should check all 5 shared deps for presence"

# Should have installed only the 3 missing ones (gmp, libffi, pkg-config) — NOT openssl@3 or readline
install_count=$(wc -l < "$INSTALL_LOG" | tr -d ' ')
assert_equals "3" "$install_count" "Should install only the 3 missing shared deps"

# Verify installed list contains the right deps
installed_set=$(sort < "$INSTALL_LOG")
expected_set=$(printf '%s\n' "gmp" "libffi" "pkg-config" | sort)
assert_equals "$expected_set" "$installed_set" "Should install gmp, libffi, pkg-config"

# Verify already-installed deps were NOT reinstalled
if grep -q '^openssl@3$' "$INSTALL_LOG"; then
    fail_test "openssl@3 should NOT be reinstalled (was already present)"
else
    pass_test "openssl@3 correctly skipped (already installed)"
fi

cleanup_mocks brew
rm -f "$INSTALL_LOG" "$LIST_LOG"

# ── Test: Bottle prefetch (commit 5) ──

describe "Bottle Prefetch Phase"

it "should expose _prefetch_bottles + PREFETCH_CONCURRENCY"
if declare -F _prefetch_bottles >/dev/null; then
    pass_test "_prefetch_bottles is defined"
else
    fail_test "_prefetch_bottles should be defined at source time"
fi

assert_equals "8" "$PREFETCH_CONCURRENCY" "Default PREFETCH_CONCURRENCY should be 8"

it "should call brew fetch with the formula list when given packages"
FETCH_LOG=$(mktemp)
brew() {
    if [[ "$1" == "fetch" ]]; then
        # Capture: subcommand, flags, package names, and the active env var
        echo "fetch:$* CONCURRENCY=$HOMEBREW_DOWNLOAD_CONCURRENCY" >> "$FETCH_LOG"
    fi
    return 0
}
export -f brew

_prefetch_bottles "git" "ripgrep" "jq" >/dev/null 2>&1

# Should have invoked brew fetch exactly once with all 3 formulae
fetch_invocations=$(wc -l < "$FETCH_LOG" | tr -d ' ')
assert_equals "1" "$fetch_invocations" "brew fetch should be called once with all formulae"

# Verify the invocation includes all 3 formulae and the concurrency env var
fetch_line=$(cat "$FETCH_LOG")
[[ "$fetch_line" == *"git"* ]] && [[ "$fetch_line" == *"ripgrep"* ]] && [[ "$fetch_line" == *"jq"* ]] \
    && pass_test "All 3 formulae passed to brew fetch" \
    || fail_test "Expected all 3 formulae in fetch call: $fetch_line"

[[ "$fetch_line" == *"CONCURRENCY=8"* ]] \
    && pass_test "HOMEBREW_DOWNLOAD_CONCURRENCY=8 set during fetch" \
    || fail_test "Expected CONCURRENCY=8 env var during fetch: $fetch_line"

cleanup_mocks brew
rm -f "$FETCH_LOG"

it "should respect PREFETCH_CONCURRENCY override"
FETCH_LOG=$(mktemp)
brew() {
    if [[ "$1" == "fetch" ]]; then
        echo "CONCURRENCY=$HOMEBREW_DOWNLOAD_CONCURRENCY" >> "$FETCH_LOG"
    fi
    return 0
}
export -f brew

(
    export PREFETCH_CONCURRENCY=16
    # shellcheck source=../../scripts/install-packages.sh
    source "$_PROJECT_ROOT/scripts/install-packages.sh"
    _prefetch_bottles "git" >/dev/null 2>&1
)

fetch_line=$(cat "$FETCH_LOG")
[[ "$fetch_line" == *"CONCURRENCY=16"* ]] \
    && pass_test "Custom PREFETCH_CONCURRENCY=16 propagates" \
    || fail_test "Expected CONCURRENCY=16: $fetch_line"

cleanup_mocks brew
rm -f "$FETCH_LOG"

it "should noop when given no formulae"
FETCH_LOG=$(mktemp)
brew() {
    [[ "$1" == "fetch" ]] && echo "should not run" >> "$FETCH_LOG"
    return 0
}
export -f brew

_prefetch_bottles >/dev/null 2>&1

fetch_invocations=$(wc -l < "$FETCH_LOG" | tr -d ' ')
assert_equals "0" "$fetch_invocations" "brew fetch should NOT be called with empty formula list"

cleanup_mocks brew
rm -f "$FETCH_LOG"

# ── Test: Collect-then-install pattern ──

describe "Collect-Then-Install Pattern"

it "should correctly separate installed vs new packages"
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
