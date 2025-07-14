#!/usr/bin/env zsh
# Conventional Commit Aliases
# Quick shortcuts for common commit types

# Basic commit type aliases
alias gcft='git commit -m "feat: "'
alias gcfx='git commit -m "fix: "'
alias gcd='git commit -m "docs: "'
alias gcst='git commit -m "style: "'
alias gcrf='git commit -m "refactor: "'
alias gcpf='git commit -m "perf: "'
alias gct='git commit -m "test: "'
alias gcb='git commit -m "build: "'
alias gcci='git commit -m "ci: "'
alias gcc='git commit -m "chore: "'
alias gcrv='git commit -m "revert: "'

# Functions for commits with scopes
gcfs() {
    if [ $# -lt 2 ]; then
        echo "Usage: gcfs <scope> <message>"
        echo "Example: gcfs homebrew \"add terraform to packages\""
        return 1
    fi
    git commit -m "feat($1): $2"
}

gcxs() {
    if [ $# -lt 2 ]; then
        echo "Usage: gcxs <scope> <message>"
        echo "Example: gcxs zsh \"fix PATH ordering issue\""
        return 1
    fi
    git commit -m "fix($1): $2"
}

gcds() {
    if [ $# -lt 2 ]; then
        echo "Usage: gcds <scope> <message>"
        echo "Example: gcds setup \"update installation instructions\""
        return 1
    fi
    git commit -m "docs($1): $2"
}

# Interactive commit helpers
alias gchelp='cat ~/repos/personal/macbook-dev-setup/docs/commit-guide.md | less'
alias gci='~/repos/personal/macbook-dev-setup/scripts/commit-helper.sh'
alias gciq='~/repos/personal/macbook-dev-setup/scripts/commit-helper.sh --quick'

# Stage and commit shortcuts
alias gcaf='git add . && gcft'
alias gcax='git add . && gcfx'
alias gcad='git add . && gcd'
alias gcai='git add . && gci'

# Amend helpers
alias gcamend='git commit --amend --no-edit'
alias gcamendd='git commit --amend'

# Show commit format reminder
commit-help() {
    echo "📝 Conventional Commit Format:"
    echo "   <type>(<scope>): <subject>"
    echo ""
    echo "🏷️  Types:"
    echo "   feat     - New feature         (gcft)"
    echo "   fix      - Bug fix            (gcfx)"
    echo "   docs     - Documentation      (gcd)"
    echo "   style    - Code style         (gcst)"
    echo "   refactor - Refactoring        (gcrf)"
    echo "   perf     - Performance        (gcpf)"
    echo "   test     - Tests              (gct)"
    echo "   build    - Build system       (gcb)"
    echo "   ci       - CI/CD              (gcci)"
    echo "   chore    - Maintenance        (gcc)"
    echo "   revert   - Revert             (gcrv)"
    echo ""
    echo "📦 Scopes:"
    echo "   setup, dotfiles, homebrew, scripts, docs, tests, vscode, zsh"
    echo ""
    echo "💡 Examples:"
    echo "   gcft \"add docker desktop\"                    # feat: add docker desktop"
    echo "   gcfs homebrew \"add kubernetes tools\"         # feat(homebrew): add kubernetes tools"
    echo "   gcai                                          # Interactive mode"
    echo ""
    echo "📖 Full guide: gchelp"
}