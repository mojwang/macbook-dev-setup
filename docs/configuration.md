# Configuration Guide

Learn how to customize your development environment setup.

## Brewfile Customization

The main package list is in `homebrew/Brewfile`. 

### Adding New Packages

```ruby
# Add a formula (command-line tool)
brew "package-name"

# Add a cask (GUI application)
cask "application-name"

# Add a tap (third-party repository)
tap "user/repo"
```

### Creating a Minimal Setup

Use `homebrew/Brewfile.minimal` for essential tools only:

```bash
./setup.sh --minimal
```

To customize the minimal setup, edit `homebrew/Brewfile.minimal`.

### Syncing New Additions

After adding packages to Brewfile:

```bash
./setup.sh --sync
```

This installs only the new packages without updating existing ones.

## Dotfile Customization

### Zsh Configuration

The Zsh configuration is modular. Files in `~/.config/zsh/`:

- `00-homebrew.zsh` - Homebrew setup
- `10-languages.zsh` - Programming language managers
- `20-tools.zsh` - CLI tool configurations
- `30-aliases.zsh` - Command aliases
- `40-functions.zsh` - Shell functions
- `50-environment.zsh` - Environment variables
- `99-local.zsh` - Your personal customizations (gitignored)

To add personal configurations:

```bash
# Edit your local config
vim ~/.config/zsh/99-local.zsh

# Add your customizations
export MY_API_KEY="..."
alias myproject="cd ~/projects/myproject"
```

### Git Configuration

The provided `.gitconfig` includes:
- User name/email (prompted during setup)
- diff-so-fancy for better diffs
- Useful aliases
- GPG signing setup

To customize:

```bash
# Set your preferences
git config --global core.editor "nvim"
git config --global pull.rebase true

# Add custom aliases
git config --global alias.unstage "reset HEAD --"
git config --global alias.last "log -1 HEAD"
```

### VS Code Settings

Settings are in `vscode/settings.json`. To customize:

1. Edit `vscode/settings.json` for repo-wide settings
2. Use VS Code's UI for personal preferences
3. Add extensions to `vscode/extensions.txt`

## Environment Variables

### System-wide Variables

Set in `~/.config/zsh/50-environment.zsh`:

```bash
export EDITOR="nvim"
export PAGER="less"
export LANG="en_US.UTF-8"
```

### Secret Variables

Never commit secrets! Use `~/.config/zsh/99-local.zsh`:

```bash
# API Keys
export OPENAI_API_KEY="sk-..."
export AWS_ACCESS_KEY_ID="..."

# Database URLs
export DATABASE_URL="postgresql://..."
```

## Creating Configuration Profiles

### Using setup.yaml

Create `config/setup.yaml` for different profiles:

```yaml
profiles:
  web_developer:
    brew:
      formulae:
        - node
        - postgresql
        - redis
      casks:
        - visual-studio-code
        - postman
    
  data_scientist:
    brew:
      formulae:
        - python
        - jupyter
        - pandas
```

Use a profile:

```bash
./setup.sh --profile web_developer
```

### Environment-specific Configs

For different machines (work/personal):

```bash
# In ~/.config/zsh/99-local.zsh
if [[ "$(hostname)" == "work-laptop" ]]; then
    export HTTP_PROXY="http://proxy.company.com:8080"
    source ~/.work-config
fi
```

## Tool-specific Configuration

### Node.js Versions

```bash
# Set default Node version
echo "20" > ~/.nvmrc

# Project-specific version
cd myproject
echo "18" > .nvmrc
```

### Python Versions

```bash
# Set global Python version
pyenv global 3.12.0

# Project-specific version
cd myproject
echo "3.11.0" > .python-version
```

### Docker Configuration

```bash
# Docker Desktop settings
# ~/Library/Group Containers/group.com.docker/settings.json

# Resource limits
{
  "cpus": 4,
  "memoryMiB": 8192,
  "diskSizeMiB": 65536
}
```

## Backup and Restore

### Backing Up Configurations

Your configurations are automatically backed up before updates:

```bash
ls ~/.setup_restore/
```

### Manual Backup

```bash
# Backup current config
cp -r ~/.config/zsh ~/.config/zsh.backup
cp ~/.zshrc ~/.zshrc.backup
cp ~/.gitconfig ~/.gitconfig.backup
```

### Restoring Configurations

```bash
# List restore points
./scripts/rollback.sh --list

# Restore from latest
./scripts/rollback.sh --latest
```

## Advanced Customization

### Custom Install Scripts

Add your own install script:

```bash
# Create scripts/install-custom.sh
#!/bin/bash
source "$(dirname "$0")/../lib/common.sh"

print_step "Installing custom tools..."
# Your installation logic
```

### Conditional Installation

In your Brewfile:

```ruby
# Only install on work machines
if ENV['USER'] == 'work-username'
  cask "corporate-vpn"
end
```

### Post-install Hooks

Create `~/.config/zsh/post-install.zsh`:

```bash
# Run after setup completes
if [[ -f ~/.first-run ]]; then
    echo "Welcome! Running first-time setup..."
    # First-run configurations
    rm ~/.first-run
fi
```

## Troubleshooting Configuration

### Configuration Not Loading

1. Check file permissions: `ls -la ~/.config/zsh/`
2. Ensure files end with `.zsh`
3. Check for syntax errors: `zsh -n ~/.config/zsh/99-local.zsh`

### Conflicts Between Tools

Some tools may conflict (e.g., nvm and n). Check:

```bash
# See what's modifying PATH
echo $PATH | tr ':' '\n'

# Check which tool provides a command
which node
type node
```

### Resetting to Defaults

```bash
# Remove custom configs
rm ~/.config/zsh/99-local.zsh

# Reinstall dotfiles
./scripts/setup-dotfiles.sh
```