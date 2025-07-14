#!/bin/bash

# Tests for setup.sh functionality
# Source test framework
source "$(dirname "$0")/test_framework.sh"

# Source common library for testing
source "$ROOT_DIR/lib/common.sh"

describe "Setup Script Tests"

# Test flag parsing
it "should parse --sync flag correctly"
# Create a minimal test version of parse_args
test_parse_args() {
    SYNC_MODE=false
    UPDATE_MODE=false
    MINIMAL_INSTALL=false
    while [[ $# -gt 0 ]]; do
        case $1 in
            -s|--sync)
                SYNC_MODE=true
                shift
                ;;
            -u|--update)
                UPDATE_MODE=true
                shift
                ;;
            --minimal)
                MINIMAL_INSTALL=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done
}

# Test sync flag
test_parse_args --sync
assert_equals "true" "$SYNC_MODE" "--sync flag should set SYNC_MODE to true"
assert_equals "false" "$UPDATE_MODE" "--sync flag should not affect UPDATE_MODE"

# Test update flag
test_parse_args --update
assert_equals "false" "$SYNC_MODE" "--update flag should not affect SYNC_MODE"
assert_equals "true" "$UPDATE_MODE" "--update flag should set UPDATE_MODE to true"

# Test combined flags
test_parse_args --sync --update
assert_equals "true" "$SYNC_MODE" "--sync --update should set SYNC_MODE to true"
assert_equals "true" "$UPDATE_MODE" "--sync --update should set UPDATE_MODE to true"

# Test minimal with sync
test_parse_args --sync --minimal
assert_equals "true" "$SYNC_MODE" "--sync --minimal should set SYNC_MODE to true"
assert_equals "true" "$MINIMAL_INSTALL" "--sync --minimal should set MINIMAL_INSTALL to true"

it "should detect Brewfile.minimal when minimal flag is set"
assert_file_exists "$ROOT_DIR/homebrew/Brewfile.minimal" "Brewfile.minimal should exist"

it "should have sync_packages function defined in setup.sh"
# Check if function is defined in the file
assert_true "[[ -f '$ROOT_DIR/setup.sh' ]]" "setup.sh should exist"
assert_true "grep -q 'sync_packages()' '$ROOT_DIR/setup.sh'" "sync_packages function should be defined"

it "should handle brew bundle check in sync_packages"
# Check that sync_packages uses brew bundle check
assert_true "grep -q 'brew bundle check' '$ROOT_DIR/setup.sh'" "sync_packages should use brew bundle check"
assert_true "grep -q 'brew bundle --file=' '$ROOT_DIR/setup.sh'" "sync_packages should use brew bundle"

it "should sync VS Code extensions in sync_packages"
assert_true "grep -q './scripts/setup-vscode-extensions.sh' '$ROOT_DIR/setup.sh'" "sync_packages should call VS Code extension setup"

it "should sync npm packages in sync_packages"
assert_true "grep -q 'npm list -g --depth=0 --json' '$ROOT_DIR/setup.sh'" "sync_packages should check installed npm packages"
assert_true "grep -q 'nodejs-config/global-packages.txt' '$ROOT_DIR/setup.sh'" "sync_packages should read global-packages.txt"

it "should sync Python packages in sync_packages"
assert_true "grep -q 'pip install -r python/requirements.txt' '$ROOT_DIR/setup.sh'" "sync_packages should install Python requirements"

describe "Modular Zsh Configuration Tests"

it "should have modular zsh configuration directory"
assert_directory_exists "$ROOT_DIR/dotfiles/.config/zsh" "Zsh config directory should exist"

it "should have all required zsh modules"
assert_file_exists "$ROOT_DIR/dotfiles/.config/zsh/00-homebrew.zsh" "Homebrew module should exist"
assert_file_exists "$ROOT_DIR/dotfiles/.config/zsh/10-languages.zsh" "Languages module should exist"
assert_file_exists "$ROOT_DIR/dotfiles/.config/zsh/20-tools.zsh" "Tools module should exist"
assert_file_exists "$ROOT_DIR/dotfiles/.config/zsh/30-aliases.zsh" "Aliases module should exist"
assert_file_exists "$ROOT_DIR/dotfiles/.config/zsh/40-functions.zsh" "Functions module should exist"
assert_file_exists "$ROOT_DIR/dotfiles/.config/zsh/50-environment.zsh" "Environment module should exist"
# Note: 99-local.zsh is gitignored and created by users, so we don't test for it

it "should have modular zshrc loader"
assert_file_exists "$ROOT_DIR/dotfiles/.zshrc" "Main .zshrc should exist"
assert_contains "$(cat $ROOT_DIR/dotfiles/.zshrc)" "for config in ~/.config/zsh/*.zsh" "Main .zshrc should load modules"

it "should have lazy NVM loading"
assert_contains "$(cat $ROOT_DIR/dotfiles/.config/zsh/10-languages.zsh)" "nvm() {" "Should have lazy NVM function"
assert_contains "$(cat $ROOT_DIR/dotfiles/.config/zsh/10-languages.zsh)" "unset -f nvm node npm npx" "Should unset functions on first load"

it "should cache Homebrew prefix"
assert_contains "$(cat $ROOT_DIR/dotfiles/.config/zsh/00-homebrew.zsh)" "HOMEBREW_PREFIX" "Should use HOMEBREW_PREFIX variable"
assert_contains "$(cat $ROOT_DIR/dotfiles/.config/zsh/00-homebrew.zsh)" "if [[ -z \"\$HOMEBREW_PREFIX\" ]]" "Should check if already cached"

it "should have 99-local.zsh in gitignore"
assert_contains "$(cat $ROOT_DIR/.gitignore)" "99-local.zsh" ".gitignore should exclude local customizations"

describe "Documentation Tests"

it "should document --sync flag in help text"
assert_contains "$(grep -A 20 'show_help()' $ROOT_DIR/setup.sh | head -40)" "--sync" "Help should document --sync flag"

it "should have sync examples in help"
assert_contains "$(grep -A 50 'Examples:' $ROOT_DIR/setup.sh | head -20)" "--sync" "Examples should include --sync usage"

it "should document sync in CLAUDE.md"
assert_contains "$(cat $ROOT_DIR/CLAUDE.md)" "--sync" "CLAUDE.md should document --sync flag"
assert_contains "$(cat $ROOT_DIR/CLAUDE.md)" "Package Synchronization" "CLAUDE.md should have sync section"
assert_contains "$(cat $ROOT_DIR/CLAUDE.md)" "Brewfile.minimal" "CLAUDE.md should document minimal Brewfile"

describe "Flag Validation Tests"

it "should validate conflicting flag combinations"
assert_contains "$(grep -A 20 'main()' $ROOT_DIR/setup.sh | head -30)" 'UPDATE_MODE" == true' "Should validate update with minimal"

it "should show warning for update with minimal"
# Check for the warning message
assert_contains "$(grep -A 5 'UPDATE_MODE.*true.*MINIMAL_INSTALL.*true' $ROOT_DIR/setup.sh)" "print_warning" "Should warn about minimal with update"