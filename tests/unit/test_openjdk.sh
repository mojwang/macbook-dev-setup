#!/usr/bin/env bash

# Tests for OpenJDK installation functionality
# Source test framework
source "$(dirname "$0")/../test_framework.sh"

# Source common library if it exists
if [[ -f "$ROOT_DIR/lib/common.sh" ]]; then
    source "$ROOT_DIR/lib/common.sh"
fi

describe "OpenJDK Installation Tests"

# Test OpenJDK is in Brewfile
it "should have OpenJDK in the main Brewfile"
brewfile_content=$(cat "$ROOT_DIR/homebrew/Brewfile")
assert_contains "$brewfile_content" 'brew "openjdk"' "OpenJDK should be in Brewfile"
assert_contains "$brewfile_content" '# Java Development Kit' "OpenJDK should have a comment"

# Test OpenJDK is NOT in minimal Brewfile (as it's not essential)
it "should NOT have OpenJDK in the minimal Brewfile"
minimal_brewfile_content=$(cat "$ROOT_DIR/homebrew/Brewfile.minimal")
assert_not_contains "$minimal_brewfile_content" 'brew "openjdk"' "OpenJDK should not be in minimal Brewfile"

# Test Java configuration in zsh config
it "should configure Java/OpenJDK in 10-languages.zsh"
languages_config=$(cat "$ROOT_DIR/dotfiles/.config/zsh/10-languages.zsh")
assert_contains "$languages_config" '# Java/OpenJDK configuration' "Java section should exist"
assert_contains "$languages_config" 'JAVA_HOME=' "JAVA_HOME should be set"
assert_contains "$languages_config" '$HOMEBREW_PREFIX/opt/openjdk' "OpenJDK path should be configured"
assert_contains "$languages_config" 'export PATH="$HOMEBREW_PREFIX/opt/openjdk/bin:$PATH"' "OpenJDK should be added to PATH"
assert_contains "$languages_config" 'CPPFLAGS=' "CPPFLAGS should be set for compilers"

# Test conditional configuration
it "should only configure Java if OpenJDK directory exists"
assert_contains "$languages_config" 'if [ -d "$HOMEBREW_PREFIX/opt/openjdk" ]; then' "Configuration should be conditional"

# Test documentation
it "should be documented in tools.md"
tools_doc=$(cat "$ROOT_DIR/docs/tools.md")
assert_contains "$tools_doc" 'OpenJDK' "OpenJDK should be listed in tools"
assert_contains "$tools_doc" 'Java Development Kit' "Should have description"
assert_contains "$tools_doc" 'https://openjdk.java.net/' "Should have link to OpenJDK"

# Test that setup script includes necessary components
it "should have proper setup flow for language configurations"
setup_content=$(cat "$ROOT_DIR/setup.sh")
assert_contains "$setup_content" './scripts/setup-dotfiles.sh' "Dotfiles setup should be called"

# Check Brewfile is well-formed
it "should have valid Brewfile syntax for OpenJDK"
# Basic syntax check - ensure line has proper format
brewfile_line=$(grep -E '^brew "openjdk"' "$ROOT_DIR/homebrew/Brewfile" || echo "")
assert_not_empty "$brewfile_line" "OpenJDK brew line should exist and be properly formatted"

# Test Java configuration ordering
it "should configure Java after other language managers"
languages_content=$(cat "$ROOT_DIR/dotfiles/.config/zsh/10-languages.zsh")
# Get line numbers for different sections
nvm_line=$(grep -n "Node.js version management" "$ROOT_DIR/dotfiles/.config/zsh/10-languages.zsh" | cut -d: -f1)
pyenv_line=$(grep -n "Python version management" "$ROOT_DIR/dotfiles/.config/zsh/10-languages.zsh" | cut -d: -f1)
java_line=$(grep -n "Java/OpenJDK configuration" "$ROOT_DIR/dotfiles/.config/zsh/10-languages.zsh" | cut -d: -f1)

# Java should come after other language managers
assert_true "[[ $java_line -gt $nvm_line ]]" "Java config should come after Node.js config"
assert_true "[[ $java_line -gt $pyenv_line ]]" "Java config should come after Python config"

# Summary
summarize