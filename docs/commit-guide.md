# Commit Message Quick Reference

## Format
```
<type>(<scope>): <subject>

<body>

<footer>
```

## Types

| Type | Description | Example |
|------|-------------|---------|
| `feat` | New feature | `feat(homebrew): add terraform package` |
| `fix` | Bug fix | `fix(zsh): resolve nvm loading issue` |
| `docs` | Documentation | `docs: update installation guide` |
| `style` | Code formatting | `style(scripts): fix indentation` |
| `refactor` | Code restructuring | `refactor(setup): extract common functions` |
| `perf` | Performance improvement | `perf(zsh): optimize shell startup time` |
| `test` | Test changes | `test: add validation tests` |
| `build` | Build system | `build: update CI configuration` |
| `ci` | CI/CD changes | `ci: add release automation` |
| `chore` | Maintenance | `chore: update dependencies` |
| `revert` | Revert commit | `revert: revert feat(homebrew): add terraform` |

## Scopes

- `setup` - Main setup script
- `dotfiles` - Dotfile configurations
- `homebrew` - Package management
- `scripts` - Component scripts
- `docs` - Documentation
- `tests` - Test suite
- `vscode` - VS Code configs
- `zsh` - Shell configuration

## Quick Commands

```bash
# Setup git hooks (one-time)
./scripts/setup-git-hooks.sh

# Use interactive helper
./scripts/commit-helper.sh

# Quick mode (fewer prompts)
./scripts/commit-helper.sh --quick

# Use Commitizen (installed with Python packages)
git cz  # or 'cz commit'

# If not installed:
pip install commitizen

# Manual commit with template
git commit  # Opens editor with template
```

## Examples

### Simple commits
```bash
git commit -m "feat: add docker desktop to casks"
git commit -m "fix(zsh): correct PATH ordering"
git commit -m "docs: add troubleshooting section"
```

### With scope
```bash
git commit -m "feat(homebrew): add kubernetes tools"
git commit -m "fix(scripts): handle spaces in paths"
git commit -m "test(setup): add integration tests"
```

### Breaking change
```bash
git commit -m "feat!: reorganize configuration structure

BREAKING CHANGE: Config files moved to ~/.config/dev-setup/"
```

### Multi-line with details
```bash
git commit -m "fix(setup): resolve installation race condition

The parallel installation was causing conflicts when multiple
formulae depended on the same dependency. This fix ensures
proper ordering while maintaining performance.

Fixes #42"
```

## Tips

1. **Subject line**:
   - Use imperative mood ("add" not "added")
   - No capitalization
   - No period at the end
   - Max 50 characters

2. **Body** (optional):
   - Explain *what* and *why*, not *how*
   - Wrap at 72 characters
   - Separate from subject with blank line

3. **Footer** (optional):
   - Reference issues: `Fixes #123`
   - Note breaking changes: `BREAKING CHANGE: description`

## Shell Aliases

Add to `~/.config/zsh/99-local.zsh`:

```bash
# Conventional commit aliases
alias gcf='./scripts/commit-helper.sh'
alias gcfq='./scripts/commit-helper.sh --quick'
alias gcft='git commit -m "feat: "'
alias gcfx='git commit -m "fix: "'
alias gcd='git commit -m "docs: "'
alias gcr='git commit -m "refactor: "'
alias gct='git commit -m "test: "'
alias gcc='git commit -m "chore: "'

# With scopes
gcfs() { git commit -m "feat($1): $2"; }
gcxs() { git commit -m "fix($1): $2"; }
```

Usage:
```bash
gcft "add new monitoring tool"
gcfs homebrew "add grafana to casks"
```