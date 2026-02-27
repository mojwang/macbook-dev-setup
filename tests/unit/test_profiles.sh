#!/usr/bin/env bash

# Unit tests for lib/profiles.sh

_TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_PROJECT_ROOT="$(cd "$_TEST_DIR/../.." && pwd)"

# Source test framework
source "$_TEST_DIR/../test_framework.sh"

# Source the library under test
source "$_PROJECT_ROOT/lib/signal-safety.sh" 2>/dev/null || true
source "$_PROJECT_ROOT/lib/profiles.sh" 2>/dev/null || true

# Setup test fixtures
TEST_FIXTURES_DIR=$(mktemp -d /tmp/test_profiles.XXXXXX)
TEST_PROFILES_DIR="$TEST_FIXTURES_DIR/profiles"
mkdir -p "$TEST_PROFILES_DIR"

# Create test profile files
cat > "$TEST_PROFILES_DIR/personal.conf" << 'EOF'
# Personal profile - no exclusions
skip_mcp_setup=false
EOF

cat > "$TEST_PROFILES_DIR/work.conf" << 'EOF'
# Work profile
exclude=claude,withgraphite/tap/graphite
skip_mcp_setup=false
EOF

cat > "$TEST_PROFILES_DIR/work-acme.conf" << 'EOF'
# Acme corp profile
inherit=work
exclude=1password
add=brew:acme-vpn-tool,cask:acme-browser
skip_mcp_setup=true
EOF

cat > "$TEST_PROFILES_DIR/deep-child.conf" << 'EOF'
# Profile with deep inheritance (should warn)
inherit=work-acme
exclude=slack
EOF

# Create test Brewfile
cat > "$TEST_FIXTURES_DIR/Brewfile" << 'EOF'
tap "homebrew/autoupdate"
tap "oven-sh/bun"

# Core development tools
brew "git"
brew "gh"
brew "withgraphite/tap/graphite"

# Applications
cask "claude"
cask "1password"
cask "slack"
cask "visual-studio-code"

# Fonts
cask "font-symbols-only-nerd-font"
EOF

# Override the profiles dir for tests
PROFILES_DIR="$TEST_PROFILES_DIR"

# Cleanup on exit
cleanup_test_fixtures() {
    rm -rf "$TEST_FIXTURES_DIR"
}
trap cleanup_test_fixtures EXIT

# ============================================================================
describe "parse_profile_value"
# ============================================================================

it "should parse a simple key=value"
result=$(parse_profile_value "$TEST_PROFILES_DIR/work.conf" "exclude")
assert_equals "claude,withgraphite/tap/graphite" "$result" "Should parse exclude value"

it "should parse skip_mcp_setup"
result=$(parse_profile_value "$TEST_PROFILES_DIR/work.conf" "skip_mcp_setup")
assert_equals "false" "$result" "Should parse skip_mcp_setup=false"

it "should parse inherit key"
result=$(parse_profile_value "$TEST_PROFILES_DIR/work-acme.conf" "inherit")
assert_equals "work" "$result" "Should parse inherit=work"

it "should return empty for missing key"
result=$(parse_profile_value "$TEST_PROFILES_DIR/personal.conf" "exclude")
assert_empty "$result" "Missing key should return empty"

it "should return empty for missing file"
result=$(parse_profile_value "$TEST_PROFILES_DIR/nonexistent.conf" "exclude")
assert_empty "$result" "Missing file should return empty"

it "should ignore comment lines"
result=$(parse_profile_value "$TEST_PROFILES_DIR/work.conf" "#")
assert_empty "$result" "Comment prefix should not match as key"

# ============================================================================
describe "resolve_profile - no inheritance"
# ============================================================================

it "should resolve personal profile with no excludes"
resolve_profile "personal"
assert_equals "0" "${#PROFILE_EXCLUDES[@]}" "Personal should have 0 excludes"
assert_equals "false" "$PROFILE_SKIP_MCP" "Personal should not skip MCP"

it "should resolve work profile with excludes"
resolve_profile "work"
assert_equals "2" "${#PROFILE_EXCLUDES[@]}" "Work should have 2 excludes"
assert_contains "${PROFILE_EXCLUDES[*]}" "claude" "Should exclude claude"
assert_contains "${PROFILE_EXCLUDES[*]}" "withgraphite/tap/graphite" "Should exclude graphite"
assert_equals "false" "$PROFILE_SKIP_MCP" "Work should not skip MCP"

# ============================================================================
describe "resolve_profile - with inheritance"
# ============================================================================

it "should merge excludes from parent and child"
resolve_profile "work-acme"
assert_contains "${PROFILE_EXCLUDES[*]}" "claude" "Should inherit claude exclude from work"
assert_contains "${PROFILE_EXCLUDES[*]}" "withgraphite/tap/graphite" "Should inherit graphite exclude from work"
assert_contains "${PROFILE_EXCLUDES[*]}" "1password" "Should have 1password from child"

it "should merge adds from child"
resolve_profile "work-acme"
assert_equals "2" "${#PROFILE_ADDS[@]}" "Should have 2 add entries"
assert_contains "${PROFILE_ADDS[*]}" "brew:acme-vpn-tool" "Should add acme-vpn-tool"
assert_contains "${PROFILE_ADDS[*]}" "cask:acme-browser" "Should add acme-browser"

it "should override options from child"
resolve_profile "work-acme"
assert_equals "true" "$PROFILE_SKIP_MCP" "Child should override skip_mcp_setup to true"

# ============================================================================
describe "resolve_profile - deep inheritance warning"
# ============================================================================

it "should warn on deep inheritance but still resolve"
# Capture warning output without subshell losing global state
resolve_profile "deep-child" > /tmp/test_deep_inherit_out.txt 2>&1
output=$(cat /tmp/test_deep_inherit_out.txt)
rm -f /tmp/test_deep_inherit_out.txt
assert_contains "$output" "Deep inheritance" "Should warn about deep inheritance"
# Should still have the excludes from work-acme (its parent)
assert_contains "${PROFILE_EXCLUDES[*]}" "1password" "Should still get parent excludes"
assert_contains "${PROFILE_EXCLUDES[*]}" "slack" "Should have child's own excludes"

# ============================================================================
describe "resolve_profile - missing profile"
# ============================================================================

it "should fail gracefully for missing profile"
if resolve_profile "nonexistent" 2>/dev/null; then
    fail_test "Should fail for missing profile"
else
    pass_test "Missing profile returns non-zero"
fi

# ============================================================================
describe "filter_brewfile - excludes"
# ============================================================================

it "should exclude matching packages"
resolve_profile "work"
filtered=$(filter_brewfile "$TEST_FIXTURES_DIR/Brewfile")
filtered_content=$(cat "$filtered")
assert_not_contains "$filtered_content" 'brew "withgraphite/tap/graphite"' "Graphite should be excluded"
assert_not_contains "$filtered_content" 'cask "claude"' "Claude cask should be excluded"

it "should preserve non-excluded packages"
resolve_profile "work"
filtered=$(filter_brewfile "$TEST_FIXTURES_DIR/Brewfile")
filtered_content=$(cat "$filtered")
assert_contains "$filtered_content" 'brew "git"' "git should be preserved"
assert_contains "$filtered_content" 'brew "gh"' "gh should be preserved"
assert_contains "$filtered_content" 'cask "1password"' "1password should be preserved"
assert_contains "$filtered_content" 'cask "slack"' "slack should be preserved"

it "should preserve tap lines"
resolve_profile "work"
filtered=$(filter_brewfile "$TEST_FIXTURES_DIR/Brewfile")
filtered_content=$(cat "$filtered")
assert_contains "$filtered_content" 'tap "homebrew/autoupdate"' "tap lines should be preserved"
assert_contains "$filtered_content" 'tap "oven-sh/bun"' "tap lines should be preserved"

it "should preserve comments"
resolve_profile "work"
filtered=$(filter_brewfile "$TEST_FIXTURES_DIR/Brewfile")
filtered_content=$(cat "$filtered")
assert_contains "$filtered_content" "# Core development tools" "Comments should be preserved"

# ============================================================================
describe "filter_brewfile - adds"
# ============================================================================

it "should append add entries"
resolve_profile "work-acme"
filtered=$(filter_brewfile "$TEST_FIXTURES_DIR/Brewfile")
filtered_content=$(cat "$filtered")
assert_contains "$filtered_content" 'brew "acme-vpn-tool"' "Should append brew add entry"
assert_contains "$filtered_content" 'cask "acme-browser"' "Should append cask add entry"

it "should exclude and add in same profile"
resolve_profile "work-acme"
filtered=$(filter_brewfile "$TEST_FIXTURES_DIR/Brewfile")
filtered_content=$(cat "$filtered")
assert_not_contains "$filtered_content" 'cask "claude"' "Claude should be excluded"
assert_not_contains "$filtered_content" 'cask "1password"' "1password should be excluded"
assert_contains "$filtered_content" 'cask "acme-browser"' "acme-browser should be added"

# ============================================================================
describe "filter_brewfile - no changes needed"
# ============================================================================

it "should return original path when no excludes or adds"
resolve_profile "personal"
filtered=$(filter_brewfile "$TEST_FIXTURES_DIR/Brewfile")
assert_equals "$TEST_FIXTURES_DIR/Brewfile" "$filtered" "Should return original path for personal profile"

# ============================================================================
describe "Profile files exist"
# ============================================================================

it "should have personal.conf in project"
assert_file_exists "$_PROJECT_ROOT/homebrew/profiles/personal.conf" "personal.conf should exist"

it "should have work.conf in project"
assert_file_exists "$_PROJECT_ROOT/homebrew/profiles/work.conf" "work.conf should exist"

# ============================================================================
describe "Gitignore has work-*.conf pattern"
# ============================================================================

it "should gitignore company-specific work profiles"
gitignore_content=$(cat "$_PROJECT_ROOT/.gitignore")
assert_contains "$gitignore_content" "homebrew/profiles/work-*.conf" "Gitignore should have work-*.conf pattern"

# ============================================================================
# Summary
# ============================================================================

print_test_summary
