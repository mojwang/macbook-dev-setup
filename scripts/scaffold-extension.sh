#!/usr/bin/env bash
set -e

# Scaffold a new macbook-dev-setup extension pack
# Usage: scaffold-extension.sh <name> [target-dir]
#
# Creates a complete extension pack directory structure with:
#   install.sh, profile.conf, CLAUDE.md, scripts/, tests/, dotfiles/, claude/, CI

# Resolve symlinks so the script works when invoked via ~/.local/bin symlink
SCRIPT_PATH="${BASH_SOURCE[0]}"
while [[ -L "$SCRIPT_PATH" ]]; do
    SCRIPT_PATH=$(readlink "$SCRIPT_PATH")
done

# Load common library
source "$(dirname "$SCRIPT_PATH")/../lib/common.sh"

# Load signal safety library
source "$ROOT_DIR/lib/signal-safety.sh"

# Cleanup
cleanup_scaffold() {
    default_cleanup
}
setup_cleanup "cleanup_scaffold"

# ─────────────────────────────────────────────────────────────────────────────
# Validation
# ─────────────────────────────────────────────────────────────────────────────

NAME="${1:-}"
TARGET_DIR="${2:-}"

if [[ -z "$NAME" ]]; then
    print_error "Usage: scaffold-extension.sh <name> [target-dir]"
    print_info "  <name>       Extension pack name (lowercase, hyphens allowed)"
    print_info "  [target-dir] Target directory (defaults to ./<name>)"
    exit 1
fi

# Validate name format
if ! [[ "$NAME" =~ ^[a-z][a-z0-9-]*$ ]]; then
    print_error "Invalid name: '$NAME'"
    print_info "Name must start with a letter and contain only lowercase letters, digits, and hyphens"
    exit 1
fi

# Default target-dir to ./<name>
if [[ -z "$TARGET_DIR" ]]; then
    TARGET_DIR="./$NAME"
fi

# Abort if already exists
if [[ -f "$TARGET_DIR/profile.conf" ]]; then
    print_error "Extension pack already exists at $TARGET_DIR (profile.conf found)"
    exit 1
fi

# ─────────────────────────────────────────────────────────────────────────────
# Scaffold
# ─────────────────────────────────────────────────────────────────────────────

print_info "Scaffolding extension pack '$NAME' at $TARGET_DIR..."

mkdir -p "$TARGET_DIR"/{config,scripts,dotfiles/.config/zsh,claude,tests,.github/workflows}

# ── install.sh ──────────────────────────────────────────────────────────────

cat > "$TARGET_DIR/install.sh" <<'INSTALLEOF'
#!/usr/bin/env bash
set -e

# {{NAME}} extension pack installer for macbook-dev-setup
# Usage: git clone <repo-url> && cd <repo> && ./install.sh

DEST="$HOME/.config/macbook-dev-setup.d/{{NAME}}"

if [[ -d "$DEST" ]]; then
    echo "{{NAME}} extension pack already installed at $DEST"
    echo "To update: cd $DEST && git pull"
    exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$(dirname "$DEST")"
ln -s "$SCRIPT_DIR" "$DEST"

echo "{{NAME}} extension pack installed (symlinked to $DEST)"
echo "Run macbook-dev-setup to activate."
INSTALLEOF
sed -i '' "s/{{NAME}}/$NAME/g" "$TARGET_DIR/install.sh"

# ── profile.conf ────────────────────────────────────────────────────────────

cat > "$TARGET_DIR/profile.conf" <<PROFILEEOF
# $NAME extension pack for macbook-dev-setup
# Inherits from a base profile
inherit=work
# modules=
# exclude=
# add=brew:package1,cask:package2
# repos_dir=$NAME
# workspace=$NAME.code-workspace
PROFILEEOF

# ── CLAUDE.md ───────────────────────────────────────────────────────────────

cat > "$TARGET_DIR/CLAUDE.md" <<CLAUDEEOF
# macbook-dev-setup-ext ($NAME)

Extension pack for [macbook-dev-setup](https://github.com/mojwang/macbook-dev-setup). Adds $NAME-specific tooling, dotfiles, and profile configuration on top of the base setup.

## How It Works
This repo is symlinked into \`~/.config/macbook-dev-setup.d/$NAME/\` by \`install.sh\`. When \`macbook-dev-setup/setup.sh\` runs, it auto-discovers extension packs in that directory and:
1. Merges \`profile.conf\` into the active profile (adds/excludes packages)
2. Runs scripts in \`scripts/\` (custom tooling setup)
3. Deploys dotfiles from \`dotfiles/.config/zsh/\`

## Directory Structure
\`\`\`
profile.conf                    # Brewfile adds/excludes (inherits from base profile)
install.sh                      # Symlinks this repo to ~/.config/macbook-dev-setup.d/$NAME/
config/                         # Version configs, package lists
scripts/
  setup.sh                      # Extension-specific tool installation
dotfiles/.config/zsh/           # Modular zsh config files
claude/                         # Claude Code configuration (optional)
  global-claude-overlay.md      # Appended to ~/.claude/CLAUDE.md during setup
  plugins.conf                  # Additional Claude Code plugins to install
tests/
  run_tests.sh                  # Test runner
  test_framework.sh             # Minimal assert framework
\`\`\`

## Project Rules
1. Shell scripts: Use \`#!/usr/bin/env bash\` shebang (NOT \`#!/bin/bash\`), \`set -e\`, signal-safe cleanup
2. All scripts must be idempotent (safe to re-run)
3. Network-dependent installs must warn on failure, not exit 1
4. Version configs go in \`config/\`, not hardcoded in scripts
5. Use modular zsh config in \`dotfiles/.config/zsh/\`

## Git Workflow (ENFORCED)
- **Feature branches required**: ALL changes, no exceptions
- **Branch protection**: Main branch is read-only for Claude
- **Conventional format**: Use \`type(scope): description\`

## Boundaries

**Always** (do without asking):
- Run shellcheck on .sh files after changes
- Follow naming conventions and project patterns
- Use feature branches
- Keep scripts idempotent
- Warn (don't fail) on network-dependent installs

**Ask first**:
- Adding new CLI tools or dependencies
- Changing version configs
- Adding new dotfile overlays

**Never**:
- Commit to main
- Commit secrets, .env files, certificates, or API keys
- Force push to any shared branch
- Skip pre-commit hooks or CI checks

## Important
- Do only what's asked; nothing more
- This repo is an extension of \`macbook-dev-setup\` — follow the same shell conventions and patterns
CLAUDEEOF

# ── scripts/setup.sh ───────────────────────────────────────────────────────

cat > "$TARGET_DIR/scripts/setup.sh" <<'SETUPEOF'
#!/usr/bin/env bash
set -e

# {{NAME}} extension pack setup script
# Called automatically by macbook-dev-setup when the extension pack is detected

# shellcheck disable=SC2034  # SCRIPT_DIR used by setup functions below
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# ── Helpers ─────────────────────────────────────────────────────────

log_info()    { echo "  [{{NAME}}] $*"; }
log_success() { echo "  [{{NAME}}] ✓ $*"; }
log_warn()    { echo "  [{{NAME}}] ⚠ $*"; }

# ── Main ────────────────────────────────────────────────────────────

log_info "Setting up {{NAME}} development environment..."

# TODO: Add setup steps here
# Example:
# setup_custom_tools() {
#     if command -v my-tool &>/dev/null; then
#         log_success "my-tool already installed"
#     else
#         log_info "Installing my-tool..."
#         # install command here || log_warn "Failed to install my-tool"
#     fi
# }
# setup_custom_tools

log_success "{{NAME}} extension pack setup complete"
SETUPEOF
sed -i '' "s/{{NAME}}/$NAME/g" "$TARGET_DIR/scripts/setup.sh"

# ── dotfiles/.config/zsh/.gitkeep ───────────────────────────────────

touch "$TARGET_DIR/dotfiles/.config/zsh/.gitkeep"

# ── config/.gitkeep ─────────────────────────────────────────────────

touch "$TARGET_DIR/config/.gitkeep"

# ── claude/global-claude-overlay.md ─────────────────────────────────

cat > "$TARGET_DIR/claude/global-claude-overlay.md" <<OVERLAYEOF

## Environment ($NAME)
- Projects live in \`~/repos/\`
OVERLAYEOF

# ── claude/plugins.conf ────────────────────────────────────────────

cat > "$TARGET_DIR/claude/plugins.conf" <<'PLUGINSEOF'
# Additional Claude Code plugins
# Format: name@registry (one per line)

PLUGINSEOF

# ── tests/run_tests.sh ─────────────────────────────────────────────

cat > "$TARGET_DIR/tests/run_tests.sh" <<'TESTSEOF'
#!/usr/bin/env bash
set -e

# Run all tests in the tests/ directory

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
TOTAL_PASS=0
TOTAL_FAIL=0

for test_file in "$TESTS_DIR"/test_*.sh; do
    [[ ! -f "$test_file" ]] && continue
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Running: $(basename "$test_file")"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if bash "$test_file"; then
        ((TOTAL_PASS++)) || true
    else
        ((TOTAL_FAIL++)) || true
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test suites passed: $TOTAL_PASS  Failed: $TOTAL_FAIL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

[[ $TOTAL_FAIL -gt 0 ]] && exit 1
exit 0
TESTSEOF

# ── tests/test_framework.sh ────────────────────────────────────────

cat > "$TARGET_DIR/tests/test_framework.sh" <<'FRAMEWORKEOF'
#!/usr/bin/env bash

# Minimal test framework (subset of macbook-dev-setup's framework)

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$TESTS_DIR")"

TEST_COUNT=0
PASSED_COUNT=0
FAILED_COUNT=0

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

describe() { echo -e "\n${BLUE}Test Suite: $1${NC}\n=================================="; }
it()       { echo -e "\n  ${YELLOW}Test:${NC} $1"; }

assert_equals() {
    local expected="$1" actual="$2" message="${3:-Assertion failed}"
    ((TEST_COUNT++))
    if [[ "$expected" == "$actual" ]]; then
        echo -e "${GREEN}✓${NC} $message"; ((PASSED_COUNT++))
    else
        echo -e "${RED}✗${NC} $message"; echo "  Expected: $expected"; echo "  Actual: $actual"; ((FAILED_COUNT++))
    fi
}

assert_true() {
    local condition="$1" message="${2:-Assertion failed}"
    ((TEST_COUNT++))
    if eval "$condition"; then
        echo -e "${GREEN}✓${NC} $message"; ((PASSED_COUNT++))
    else
        echo -e "${RED}✗${NC} $message"; ((FAILED_COUNT++))
    fi
}

assert_contains() {
    local haystack="$1" needle="$2" message="${3:-Should contain substring}"
    ((TEST_COUNT++))
    if [[ "$haystack" == *"$needle"* ]]; then
        echo -e "${GREEN}✓${NC} $message"; ((PASSED_COUNT++))
    else
        echo -e "${RED}✗${NC} $message"; echo "  Missing: $needle"; ((FAILED_COUNT++))
    fi
}

assert_not_empty() {
    local value="$1" message="${2:-Should not be empty}"
    ((TEST_COUNT++))
    if [[ -n "$value" ]]; then
        echo -e "${GREEN}✓${NC} $message"; ((PASSED_COUNT++))
    else
        echo -e "${RED}✗${NC} $message"; ((FAILED_COUNT++))
    fi
}

summarize() {
    echo -e "\n${BLUE}Test Summary${NC}\n============"
    echo "Total: $TEST_COUNT  Passed: $PASSED_COUNT  Failed: $FAILED_COUNT"
    if [[ $FAILED_COUNT -eq 0 ]]; then
        echo -e "\n${GREEN}All tests passed!${NC}"
        return 0
    else
        echo -e "\n${RED}$FAILED_COUNT test(s) failed!${NC}"
        return 1
    fi
}
FRAMEWORKEOF

# ── .github/workflows/ci.yml ───────────────────────────────────────

cat > "$TARGET_DIR/.github/workflows/ci.yml" <<'CIEOF'
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  shellcheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run shellcheck
        run: |
          find . -name '*.sh' -not -path './.git/*' | while read -r f; do
            echo "Checking: $f"
            shellcheck "$f"
          done

  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run tests
        run: ./tests/run_tests.sh

  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Check for secrets
        run: |
          echo "Checking for potential secrets..."
          found=0
          if grep -rEn "(password|secret|token|api_key)[[:space:]]*=.*['\"][A-Za-z0-9]" . --include="*.sh" \
             | grep -v '=.*\$' \
             | grep -v '=.*""' \
             | grep -v '\.git/'; then
            echo "Potential hardcoded secrets found above"
            found=1
          else
            echo "No hardcoded secrets found"
          fi
          exit $found

  all-checks-pass:
    name: All Checks Pass
    runs-on: ubuntu-latest
    needs: [shellcheck, test, security-scan]
    if: always()
    steps:
      - name: Check job results
        env:
          SHELLCHECK_RESULT: ${{ needs.shellcheck.result }}
          TEST_RESULT: ${{ needs.test.result }}
          SECURITY_RESULT: ${{ needs.security-scan.result }}
        run: |
          if [[ "$SHELLCHECK_RESULT" != "success" ]]; then
            echo "Shellcheck failed"; exit 1
          fi
          if [[ "$TEST_RESULT" != "success" ]]; then
            echo "Tests failed"; exit 1
          fi
          if [[ "$SECURITY_RESULT" != "success" ]]; then
            echo "Security scan failed"; exit 1
          fi
          echo "All checks passed!"
CIEOF

# ── Set executable permissions ──────────────────────────────────────

chmod +x "$TARGET_DIR/install.sh"
chmod +x "$TARGET_DIR/scripts/setup.sh"
chmod +x "$TARGET_DIR/tests/run_tests.sh"

# ─────────────────────────────────────────────────────────────────────────────
# Git init
# ─────────────────────────────────────────────────────────────────────────────

if [[ ! -d "$TARGET_DIR/.git" ]]; then
    git -C "$TARGET_DIR" init -q
    print_success "Initialized git repository"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Install (symlink to extension discovery dir)
# ─────────────────────────────────────────────────────────────────────────────

DEST="$HOME/.config/macbook-dev-setup.d/$NAME"

if [[ -L "$DEST" ]] || [[ -d "$DEST" ]]; then
    print_info "Extension already registered at $DEST"
else
    ABSOLUTE_TARGET="$(cd "$TARGET_DIR" && pwd)"
    mkdir -p "$(dirname "$DEST")"
    ln -s "$ABSOLUTE_TARGET" "$DEST"
    print_success "Installed: $DEST -> $ABSOLUTE_TARGET"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────────────────

print_success "Extension pack '$NAME' scaffolded at $TARGET_DIR"
echo ""
echo "Created:"
echo "  $TARGET_DIR/"
echo "  ├── install.sh"
echo "  ├── profile.conf"
echo "  ├── CLAUDE.md"
echo "  ├── config/"
echo "  ├── scripts/setup.sh"
echo "  ├── dotfiles/.config/zsh/"
echo "  ├── claude/"
echo "  │   ├── global-claude-overlay.md"
echo "  │   └── plugins.conf"
echo "  ├── tests/"
echo "  │   ├── run_tests.sh"
echo "  │   └── test_framework.sh"
echo "  └── .github/workflows/ci.yml"
echo ""
echo "Next steps:"
echo "  1. Edit profile.conf to configure package adds/excludes"
echo "  2. Add setup logic to scripts/setup.sh"
echo "  3. Add zsh config files to dotfiles/.config/zsh/"
echo "  4. Create a remote repo and push"
echo "  5. Run ./setup.sh to activate the extension"
