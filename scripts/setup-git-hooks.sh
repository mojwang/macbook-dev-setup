#!/bin/bash

# Setup Git Hooks and Commit Template
# This script configures git for conventional commits

# Load common library
source "$(dirname "$0")/../lib/common.sh"

print_header "Setting up Git Hooks and Commit Template"

# Configure commit template for this repository
print_step "Configuring commit template..."
if git config --local commit.template .gitmessage; then
    print_success "Git commit template configured"
    print_info "Your commits will now use the template from .gitmessage"
else
    print_error "Failed to configure commit template"
    exit 1
fi

# Install commit-msg hook for validation
print_step "Installing commit message validation hook..."
HOOKS_DIR=".git/hooks"
mkdir -p "$HOOKS_DIR"

cat > "$HOOKS_DIR/commit-msg" << 'EOF'
#!/bin/bash
# Validate commit messages against conventional commit format

# Read the commit message
commit_regex='^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([a-z]+\))?: .{1,50}'
merge_regex='^Merge '

if ! grep -qE "($commit_regex|$merge_regex)" "$1"; then
    echo "❌ Invalid commit message format!" >&2
    echo "" >&2
    echo "📝 Commit message must follow Conventional Commits format:" >&2
    echo "   <type>(<scope>): <subject>" >&2
    echo "" >&2
    echo "📌 Valid types:" >&2
    echo "   feat     - New feature" >&2
    echo "   fix      - Bug fix" >&2
    echo "   docs     - Documentation changes" >&2
    echo "   style    - Code style changes" >&2
    echo "   refactor - Code refactoring" >&2
    echo "   perf     - Performance improvements" >&2
    echo "   test     - Test changes" >&2
    echo "   build    - Build system changes" >&2
    echo "   ci       - CI/CD changes" >&2
    echo "   chore    - Other maintenance" >&2
    echo "   revert   - Revert previous commit" >&2
    echo "" >&2
    echo "📌 Valid scopes:" >&2
    echo "   setup, dotfiles, homebrew, scripts, docs, tests, vscode, zsh" >&2
    echo "" >&2
    echo "💡 Examples:" >&2
    echo "   feat(homebrew): add terraform to developer tools" >&2
    echo "   fix(zsh): resolve nvm loading issue" >&2
    echo "   docs: update README with quick start guide" >&2
    echo "" >&2
    echo "❓ Need help? Run: git cz (if commitizen is installed)" >&2
    exit 1
fi
EOF

chmod +x "$HOOKS_DIR/commit-msg"
print_success "Commit message validation hook installed"

# Create prepare-commit-msg hook to show template
cat > "$HOOKS_DIR/prepare-commit-msg" << 'EOF'
#!/bin/bash
# Show helpful information when committing

# Only show for normal commits (not merges, squashes, etc.)
if [ -z "$2" ]; then
    echo "" >> "$1"
    echo "# 📝 Conventional Commit Format: <type>(<scope>): <subject>" >> "$1"
    echo "#" >> "$1"
    echo "# Quick reference:" >> "$1"
    echo "# feat:     New feature" >> "$1"
    echo "# fix:      Bug fix" >> "$1"
    echo "# docs:     Documentation" >> "$1"
    echo "# refactor: Code restructuring" >> "$1"
    echo "# test:     Test changes" >> "$1"
    echo "# chore:    Maintenance" >> "$1"
    echo "#" >> "$1"
    echo "# Scopes: setup, dotfiles, homebrew, scripts, docs, tests, vscode, zsh" >> "$1"
fi
EOF

chmod +x "$HOOKS_DIR/prepare-commit-msg"
print_success "Commit template helper hook installed"

# Offer to install pre-commit framework
if command_exists pre-commit && [ -f ".pre-commit-config.yaml" ]; then
    print_step "Installing pre-commit framework hooks..."
    if pre-commit install --install-hooks; then
        print_success "Pre-commit hooks installed"
    else
        print_warning "Pre-commit installation failed, but continuing..."
    fi
elif [ -f ".pre-commit-config.yaml" ]; then
    print_info "Pre-commit config found. Install pre-commit with: pip install pre-commit"
fi

# Summary
echo
print_success "Git hooks setup complete!"
echo
print_info "What's been configured:"
echo "  ✓ Commit template (.gitmessage)"
echo "  ✓ Commit message validation"
echo "  ✓ Helpful hints during commit"
if command_exists pre-commit && [ -f ".git/hooks/pre-commit" ]; then
    echo "  ✓ Pre-commit framework hooks"
fi
echo
print_info "Try it out:"
echo "  $ git add ."
echo "  $ git commit"
echo
print_info "Or use Commitizen for interactive commits:"
if command_exists cz; then
    echo "  $ git cz"
else
    echo "  $ pip install commitizen"
    echo "  $ git cz"
fi