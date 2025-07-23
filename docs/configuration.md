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
./setup.sh minimal
```

To customize the minimal setup, edit `homebrew/Brewfile.minimal`.

### Syncing New Additions

After adding packages to Brewfile:

```bash
# Pull changes if needed
git pull

# Run setup to install new packages
./setup.sh
```

The setup script automatically detects and installs new packages.

## Dotfile Customization

### Zsh Configuration

The Zsh configuration is modular. Files in `~/.config/zsh/`:

- `00-homebrew.zsh` - Homebrew setup
- `10-languages.zsh` - Programming language managers
- `20-tools.zsh` - CLI tool configurations
- `30-aliases.zsh` - Command aliases
- `35-commit-aliases.zsh` - Git commit shortcuts
- `40-functions.zsh` - Shell functions
- `45-warp.zsh` - Warp terminal optimizations (created automatically when Warp is detected)
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

### Terminal Font Configuration

The setup automatically configures a consistent font (AnonymicePro Nerd Font Mono) across all terminal applications:

- **Warp**: Automatically detected and configured
- **iTerm2**: Font set in preferences
- **Terminal.app**: Font applied to Basic profile
- **VS Code**: Terminal font configured in settings

To use a different font:

1. Install your preferred Nerd Font:
   ```bash
   brew search font | grep nerd
   brew install font-your-choice-nerd-font
   ```

2. Update the font configuration:
   ```bash
   # Edit the setup script
   vim scripts/setup-terminal-fonts.sh
   # Change FONT_NAME variable to your preference
   ```

3. Re-run font configuration:
   ```bash
   ./scripts/setup-terminal-fonts.sh
   ```

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
# Note: Profile support is planned for future releases
# Currently use minimal/full installation modes
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

## Warp Terminal Configuration

### Automatic Detection and Setup

The setup script automatically detects if you're using Warp Terminal and offers to:
- Install delta for enhanced git diffs
- Configure shell integrations
- Set up optimal workflows

```bash
# Configure Warp optimizations
./setup.sh warp
```

### Warp Power Tools

When Warp is detected, you can optionally install:
- **atuin** - Advanced shell history with sync
- **direnv** - Directory-specific environment variables
- **mcfly** - Smart command history search
- **navi** - Interactive command cheatsheet

### Manual Warp Configuration

To enable Warp features manually:

```bash
# Create Warp config file
touch ~/.config/zsh/45-warp.zsh

# Add Warp-specific settings
echo 'export WARP_ENABLE_WAYLAND=1' >> ~/.config/zsh/45-warp.zsh
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
# View all backups
ls ~/.setup-backups/

# View latest backups
ls -la ~/.setup-backups/latest/
```

The backup system organizes files by category:
- `dotfiles/` - Shell configurations
- `configs/` - Application settings
- `restore-points/` - Full system snapshots
- `scripts/` - Custom scripts

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