# Troubleshooting Guide

This guide covers common issues and their solutions when using the macOS Development Setup.

## Table of Contents

1. [Installation Issues](#installation-issues)
2. [Script Errors](#script-errors)
3. [Homebrew Problems](#homebrew-problems)
4. [Git Configuration](#git-configuration)
5. [Permission Issues](#permission-issues)
6. [Network Problems](#network-problems)
7. [Tool-Specific Issues](#tool-specific-issues)
8. [Recovery Options](#recovery-options)

## Installation Issues

### "Command not found" errors

**Problem**: Scripts fail with "command not found" errors.

**Solutions**:
1. Ensure Homebrew is installed:
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. Add Homebrew to PATH:
   ```bash
   echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
   source ~/.zprofile
   ```

3. Restart your terminal or run:
   ```bash
   source ~/.zshrc
   ```

### Script exits with "This script is designed for macOS only"

**Problem**: Running on non-macOS system.

**Solution**: This setup is specifically for macOS. For other systems:
- Linux users: Fork and modify for your distribution
- Windows users: Use WSL2 with Ubuntu

### "Insufficient disk space" error

**Problem**: Not enough free disk space.

**Solutions**:
1. Check available space:
   ```bash
   df -h /
   ```

2. Free up space:
   ```bash
   # Clean Homebrew cache
   brew cleanup -s
   
   # Remove old iOS backups
   # Go to: About This Mac > Storage > Manage > iOS Files
   
   # Clear Downloads folder
   rm -rf ~/Downloads/*
   ```

3. Use external storage for large tools

## Script Errors

### "Permission denied" when running scripts

**Problem**: Scripts don't have execute permissions.

**Solution**:
```bash
chmod +x setup.sh
chmod +x scripts/*.sh
chmod +x tests/*.sh
```

### "No such file or directory" for lib/common.sh

**Problem**: Running script from wrong directory.

**Solution**: Always run from repository root:
```bash
cd /path/to/macbook-dev-setup
./setup.sh
```

### Scripts fail with syntax errors

**Problem**: Shell compatibility issues.

**Solutions**:
1. Ensure using bash (not sh):
   ```bash
   bash setup.sh
   ```

2. Check bash version:
   ```bash
   bash --version
   # Should be 3.2 or higher
   ```

## Homebrew Problems

### Homebrew installation fails

**Problem**: Cannot install Homebrew.

**Solutions**:
1. Check Xcode Command Line Tools:
   ```bash
   xcode-select --install
   ```

2. Reset Homebrew:
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

3. Fix permissions:
   ```bash
   sudo chown -R $(whoami) /opt/homebrew
   ```

### "brew: command not found" after installation

**Problem**: Homebrew not in PATH.

**Solution**: Add to shell profile:
```bash
# For Apple Silicon Macs
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile

# For Intel Macs
echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile

# Reload shell
source ~/.zprofile
```

### Formulae fail to install

**Problem**: Individual packages fail.

**Solutions**:
1. Update Homebrew:
   ```bash
   brew update
   brew upgrade
   ```

2. Fix specific formula:
   ```bash
   brew uninstall --force <formula>
   brew install <formula>
   ```

3. Check for conflicts:
   ```bash
   brew doctor
   ```

## Git Configuration

### "Your Name" still appears in commits

**Problem**: Git using placeholder values.

**Solution**: Update Git configuration:
```bash
git config --global user.name "Your Actual Name"
git config --global user.email "your.email@example.com"
```

### Git commands fail with SSL errors

**Problem**: Certificate verification issues.

**Solutions**:
1. Update certificates:
   ```bash
   brew install ca-certificates
   ```

2. Temporary workaround (not recommended):
   ```bash
   git config --global http.sslVerify false
   ```

## Permission Issues

### "Operation not permitted" errors

**Problem**: macOS security restrictions.

**Solutions**:
1. Grant Terminal full disk access:
   - System Preferences → Security & Privacy → Privacy → Full Disk Access
   - Add Terminal.app

2. For specific directories:
   ```bash
   sudo chown -R $(whoami) /path/to/directory
   ```

### Cannot modify system files

**Problem**: System Integrity Protection (SIP) blocking changes.

**Solution**: Don't disable SIP. Instead:
- Use user-specific configurations (~/.config/)
- Install tools in Homebrew locations
- Use sudo only when absolutely necessary

## Network Problems

### Downloads fail or timeout

**Problem**: Network connectivity issues.

**Solutions**:
1. Check connectivity:
   ```bash
   ./scripts/health-check.sh | grep -A5 "network"
   ```

2. Use different mirror:
   ```bash
   export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles
   ```

3. Increase timeout:
   ```bash
   export HOMEBREW_CURL_TIMEOUT=300
   ```

### Behind corporate proxy

**Problem**: Proxy blocking connections.

**Solution**: Configure proxy:
```bash
export http_proxy=http://proxy.company.com:8080
export https_proxy=$http_proxy
export no_proxy=localhost,127.0.0.1
```

## Tool-Specific Issues

### Node.js/npm issues

**Problem**: npm commands fail.

**Solutions**:
1. Reinstall Node.js:
   ```bash
   nvm uninstall node
   nvm install node
   ```

2. Clear npm cache:
   ```bash
   npm cache clean --force
   ```

3. Fix permissions:
   ```bash
   npm config set prefix ~/.npm
   echo 'export PATH="$HOME/.npm/bin:$PATH"' >> ~/.zshrc
   ```

### Python/pip issues

**Problem**: Python packages won't install.

**Solutions**:
1. Use pyenv:
   ```bash
   pyenv install 3.12.8
   pyenv global 3.12.8
   ```

2. Upgrade pip:
   ```bash
   pip install --upgrade pip
   ```

3. Use virtual environments:
   ```bash
   python -m venv myenv
   source myenv/bin/activate
   ```

### VS Code won't open from terminal

**Problem**: `code` command not found.

**Solution**: Install shell command:
1. Open VS Code
2. Press Cmd+Shift+P
3. Type "Shell Command: Install 'code' command in PATH"
4. Restart terminal

## Recovery Options

### Using restore points

List available restore points:
```bash
./scripts/rollback.sh --list
```

Restore from latest:
```bash
./scripts/rollback.sh --latest
```

### Manual recovery

1. **Backup current state**:
   ```bash
   mkdir ~/setup_backup
   cp -r ~/.zshrc ~/.gitconfig ~/.config ~/setup_backup/
   ```

2. **Run health check**:
   ```bash
   ./scripts/health-check.sh > health_report.txt
   ```

3. **Selective reinstall**:
   ```bash
   # Just Homebrew packages
   brew bundle --file=homebrew/Brewfile
   
   # Just dotfiles
   ./scripts/setup-dotfiles.sh
   ```

### Complete reset

**Warning**: This removes everything!

```bash
# 1. Uninstall everything
./scripts/uninstall.sh

# 2. Clean up
rm -rf ~/.setup_restore
rm -rf ~/.setup_backup*

# 3. Fresh install
./setup.sh
```

## Getting More Help

### Diagnostic information

Collect system info for bug reports:
```bash
# System info
sw_vers
uname -a

# Tool versions
brew --version
node --version
python --version

# Health check
./scripts/health-check.sh > diagnostic.txt

# Recent errors
tail -n 50 setup.log
```

### Debug mode

Run scripts with debug output:
```bash
bash -x ./setup.sh --verbose --log debug.log
```

### Community support

1. Check existing issues on GitHub
2. Create detailed bug report with:
   - macOS version
   - Hardware type (M1/M2/Intel)
   - Complete error messages
   - Steps to reproduce

### Emergency contacts

If the setup completely breaks your system:
1. Boot into Recovery Mode (Cmd+R during startup)
2. Use Time Machine to restore
3. Reinstall macOS if necessary

## Prevention Tips

1. **Always use dry-run first**:
   ```bash
   ./setup.sh --dry-run
   ```

2. **Create restore points**:
   ```bash
   # Before major changes
   source lib/common.sh
   create_restore_point "before_experiment"
   ```

3. **Keep backups**:
   - Time Machine
   - Cloud backups
   - Git repositories

4. **Test in isolation**:
   - Use a separate user account
   - Test in a VM if possible

Remember: The health check script is your friend! Run it regularly:
```bash
./scripts/health-check.sh
```