# Maintenance Guide

Keep your development environment healthy and up-to-date.

## Regular Maintenance

### Weekly Tasks

1. **Update packages**
   ```bash
   ./scripts/update.sh
   ```

2. **Check system health**
   ```bash
   ./scripts/health-check.sh
   ```

3. **Clean up Homebrew**
   ```bash
   brew cleanup
   brew doctor
   ```

### Monthly Tasks

1. **Review installed packages**
   ```bash
   brew list
   brew list --cask
   ```

2. **Remove unused packages**
   ```bash
   brew autoremove
   brew cleanup -s
   ```

3. **Update global npm packages**
   ```bash
   npm update -g
   npm outdated -g
   ```

## Updating Tools

### Update Everything at Once

```bash
./scripts/update.sh
```

This script:
- Updates Homebrew and all packages
- Updates npm global packages
- Updates Python packages
- Updates VS Code extensions
- Creates a restore point before updating

### Selective Updates

**Update only Homebrew packages:**
```bash
brew update && brew upgrade
```

**Update specific package:**
```bash
brew upgrade package-name
```

**Update only casks:**
```bash
brew upgrade --cask
```

**Update Node.js:**
```bash
nvm install node --reinstall-packages-from=current
nvm alias default node
```

**Update Python packages:**
```bash
pip install --upgrade pip
pip list --outdated
pip install --upgrade package-name
```

## Syncing New Tools

When new tools are added to the repository:

```bash
# Pull latest changes
git pull

# Sync new packages
./setup.sh --sync

# Or sync minimal packages only
./setup.sh --sync --minimal
```

## Health Monitoring

### Run Health Check

```bash
./scripts/health-check.sh
```

Interpret results:
- ✅ Tool is properly installed
- ❌ Tool is missing or misconfigured
- Score > 90% = Healthy system
- Score < 70% = Needs attention

### Quick Health Status

```bash
# Add to ~/.config/zsh/30-aliases.zsh
alias health="./scripts/health-check.sh | grep -E '(✅|❌|Score:)'"
```

### Common Health Issues

**Git not configured:**
```bash
git config --global user.name "Your Name"
git config --global user.email "email@example.com"
```

**Command not found:**
```bash
# Reload shell
source ~/.zshrc

# Check PATH
echo $PATH

# Reinstall tool
brew reinstall tool-name
```

## Backup and Recovery

### Automatic Backups

Backups are created automatically:
- Before major updates
- Before uninstalling
- During setup operations
- In `~/.setup-backups/` directory (organized by category)

### Backup Organization

The new backup system organizes files into categories:
- `dotfiles/` - Shell configurations and dotfiles
- `restore-points/` - Full system restore points
- `configs/` - Application configurations
- `scripts/` - Custom scripts
- `latest/` - Symlinks to most recent backups

Automatic cleanup keeps only the 10 most recent backups per category.

### Managing Backups

```bash
# View all backups
./setup.sh backup

# Clean old backups (keeps 10 most recent per category)
./setup.sh backup clean

# Manual backup of specific files
./scripts/backup-manager.sh create dotfiles "Manual backup before changes"

# View backup details
ls -la ~/.setup-backups/
tree ~/.setup-backups/latest/
```

### List Restore Points

```bash
# List all backups by category
ls -la ~/.setup-backups/restore-points/

# View latest backup in each category
ls -la ~/.setup-backups/latest/

# Check backup metadata
cat ~/.setup-backups/restore-points/*/metadata.json | jq .
```

Each backup includes:
- Timestamp
- Description
- File list
- Metadata about the backup operation

### Restore from Backup

```bash
# Restore from latest
./scripts/rollback.sh --latest

# Restore from specific point
./scripts/rollback.sh --date 2024-01-10_14:20:00

# Interactive restore
./scripts/rollback.sh
```

## Cleaning Up

### Disk Space Management

```bash
# Check Homebrew cache size
du -sh ~/Library/Caches/Homebrew

# Clean Homebrew cache
brew cleanup -s
rm -rf ~/Library/Caches/Homebrew

# Clean npm cache
npm cache clean --force

# Clean pip cache
pip cache purge
```

### Remove Unused Dependencies

```bash
# Homebrew
brew autoremove

# npm (check first)
npm prune -g

# Python
pip-autoremove  # If installed
```

### Clean Old Versions

```bash
# Remove old Node versions
nvm list
nvm uninstall 16.0.0

# Remove old Python versions
pyenv versions
pyenv uninstall 3.9.0

# Remove old gems
gem cleanup
```

## Troubleshooting Updates

### Update Failures

**Homebrew update stuck:**
```bash
# Kill stuck processes
killall brew

# Reset Homebrew
cd $(brew --repository)
git reset --hard origin/master
brew update
```

**Package conflicts:**
```bash
# Check for conflicts
brew doctor

# Unlink and relink
brew unlink package-name
brew link package-name
```

**Permission errors:**
```bash
# Fix Homebrew permissions
sudo chown -R $(whoami) /opt/homebrew
```

### Rollback Failed Updates

```bash
# If update breaks something
./scripts/rollback.sh --latest

# Or manually downgrade
brew install package-name@version
brew pin package-name
```

## Uninstalling

### Remove Specific Tools

```bash
# Remove formula
brew uninstall package-name

# Remove cask
brew uninstall --cask app-name

# Remove with dependencies
brew uninstall --ignore-dependencies package-name
brew autoremove
```

### Complete Uninstall

```bash
./scripts/uninstall.sh
```

This will:
1. Create final backup
2. Show what will be removed
3. Ask for confirmation
4. Remove tools selectively
5. Preserve personal data

### Clean Uninstall

For complete removal:

```bash
# Run uninstall script
./scripts/uninstall.sh --all

# Remove Homebrew completely
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"

# Remove dotfiles
rm -rf ~/.config/zsh
rm ~/.zshrc
rm ~/.gitconfig
```

## Performance Optimization

### Speed Up Shell Startup

```bash
# Profile shell startup
time zsh -i -c exit

# Check slow plugins
zsh -xv 2>&1 | ts -i "%.s" > startup.log
```

### Optimize Homebrew

```bash
# Disable auto-update
export HOMEBREW_NO_AUTO_UPDATE=1

# Disable analytics
brew analytics off

# Use faster mirrors
export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.ustc.edu.cn/homebrew-bottles
```

### Monitor Resource Usage

```bash
# Check disk usage
df -h
du -sh ~/.npm ~/.cache ~/.local

# Check running processes
htop
ps aux | grep -E "(node|python|ruby)"
```

## Scheduled Maintenance

### Set Up Automatic Updates

Add to crontab:
```bash
# Weekly update check (Sundays at 2 AM)
0 2 * * 0 cd ~/repos/macbook-dev-setup && ./scripts/update.sh --quiet

# Daily health check
0 9 * * * cd ~/repos/macbook-dev-setup && ./scripts/health-check.sh --quiet
```

### Maintenance Notifications

Create `~/.config/zsh/99-maintenance.zsh`:
```bash
maintenance-reminder() {
    # Check latest backup in any category
    local latest_backup=$(find ~/.setup-backups -name "metadata.json" -type f -exec stat -f %m {} \; 2>/dev/null | sort -n | tail -1)
    
    if [[ -n "$latest_backup" ]]; then
        local now=$(date +%s)
        local days=$(( (now - latest_backup) / 86400 ))
        
        if [[ $days -gt 7 ]]; then
            echo "⚠️  It's been $days days since last backup. Run: ./scripts/update.sh"
        fi
    fi
}

# Add to shell startup
maintenance-reminder
```