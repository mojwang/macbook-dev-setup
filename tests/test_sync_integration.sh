#!/bin/bash

# Integration tests for sync functionality
# These tests validate that the sync flags work correctly

echo "Testing sync flag integration..."

# Test 1: Verify help text includes sync
echo -n "Test 1: Help text includes --sync flag... "
if ./setup.sh --help 2>&1 | grep -q -- "--sync"; then
    echo "PASS"
else
    echo "FAIL: --sync not found in help text"
    exit 1
fi

# Test 2: Verify sync examples in help
echo -n "Test 2: Help includes sync examples... "
if ./setup.sh --help 2>&1 | grep -q "sync.*Sync new packages"; then
    echo "PASS"
else
    echo "FAIL: Sync examples not found in help"
    exit 1
fi

# Test 3: Verify sync_packages function exists
echo -n "Test 3: sync_packages function exists in setup.sh... "
if grep -q "^sync_packages()" setup.sh; then
    echo "PASS"
else
    echo "FAIL: sync_packages function not found"
    exit 1
fi

# Test 4: Verify Brewfile.minimal exists
echo -n "Test 4: Brewfile.minimal exists... "
if [[ -f "homebrew/Brewfile.minimal" ]]; then
    echo "PASS"
else
    echo "FAIL: homebrew/Brewfile.minimal not found"
    exit 1
fi

# Test 5: Verify modular zsh config exists
echo -n "Test 5: Modular zsh config directory exists... "
if [[ -d "dotfiles/.config/zsh" ]]; then
    echo "PASS"
else
    echo "FAIL: dotfiles/.config/zsh directory not found"
    exit 1
fi

# Test 6: Verify all zsh modules exist
echo -n "Test 6: All zsh modules exist... "
missing=0
# Note: 99-local.zsh is gitignored and optional, so we don't check for it
for module in 00-homebrew 10-languages 20-tools 30-aliases 40-functions 50-environment; do
    if [[ ! -f "dotfiles/.config/zsh/${module}.zsh" ]]; then
        echo "FAIL: Missing ${module}.zsh"
        ((missing++))
    fi
done
if [[ $missing -eq 0 ]]; then
    echo "PASS"
else
    exit 1
fi

# Test 7: Verify main .zshrc loads modules
echo -n "Test 7: Main .zshrc loads modular config... "
if grep -q "for config in ~/.config/zsh/\*.zsh" dotfiles/.zshrc; then
    echo "PASS"
else
    echo "FAIL: Module loading not found in .zshrc"
    exit 1
fi

# Test 8: Verify lazy NVM loading
echo -n "Test 8: Lazy NVM loading implemented... "
if grep -q "^nvm() {" dotfiles/.config/zsh/10-languages.zsh && \
   grep -q "unset -f nvm node npm npx" dotfiles/.config/zsh/10-languages.zsh; then
    echo "PASS"
else
    echo "FAIL: Lazy NVM loading not properly implemented"
    exit 1
fi

# Test 9: Verify 99-local.zsh is gitignored
echo -n "Test 9: Local config is gitignored... "
if grep -q "99-local.zsh" .gitignore; then
    echo "PASS"
else
    echo "FAIL: 99-local.zsh not in .gitignore"
    exit 1
fi

# Test 10: Verify CLAUDE.md documents sync
echo -n "Test 10: CLAUDE.md documents sync feature... "
if grep -q "Package Synchronization" CLAUDE.md && \
   grep -q "Brewfile.minimal" CLAUDE.md; then
    echo "PASS"
else
    echo "FAIL: Sync documentation missing from CLAUDE.md"
    exit 1
fi

echo ""
echo "All integration tests passed! ✅"