# Troubleshooting Guide

This guide covers common issues and their solutions when using the macOS Development Setup.

## Table of Contents

1. [Installation Issues](#installation-issues)
2. [Script Errors](#script-errors)
3. [Homebrew Problems](#homebrew-problems)
4. [Git Configuration](#git-configuration)
5. [MCP Server Issues](#mcp-server-issues)
6. [Permission Issues](#permission-issues)
7. [Network Problems](#network-problems)
8. [Tool-Specific Issues](#tool-specific-issues)
9. [Shell Configuration](#shell-configuration)
10. [Recovery Options](#recovery-options)

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

**Solution**: This setup is specifically designed for macOS only. It is not compatible with other operating systems.

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

### Bash version errors in CI

**Problem**: CI environment has bash 3.2, scripts require bash 4+

**Solutions**:
1. Scripts automatically detect CI mode and adjust:
   ```bash
   CI=true ./setup.sh
   ```

2. Use fallback syntax for older bash:
   ```bash
   # Modern bash 4+ syntax
   declare -A map=()
   
   # Fallback for bash 3.2
   declare -a keys=()
   declare -a values=()
   ```

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

3. Use correct shebang:
   ```bash
   #!/usr/bin/env bash  # Correct
   #!/bin/bash         # May fail in some environments
   ```

### Signal handling not working

**Problem**: Cleanup not happening on script interruption.

**Solution**: Ensure proper signal traps:
```bash
# Check if script has proper traps
grep "trap.*INT TERM" script.sh

# Should see something like:
trap cleanup EXIT INT TERM HUP
```

See [Signal Safety Guide](SIGNAL_SAFETY.md) for details.

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

### Git editor not set properly

**Problem**: Git opens wrong editor or nano.

**Solution**: Script auto-configures vim/nvim:
```bash
# Check current editor
git config --global core.editor

# Manually set if needed
git config --global core.editor "nvim"  # or "vim"
```

## MCP Server Issues

### MCP servers not found in Claude Desktop

**Problem**: Claude Desktop doesn't recognize installed servers.

**Solutions**:
1. Restart Claude Desktop after configuration
2. Check config file:
   ```bash
   cat ~/Library/Application\ Support/Claude/claude_desktop_config.json | jq
   ```
3. Fix configuration:
   ```bash
   ./scripts/fix-mcp-servers.sh
   ```

### MCP servers not working in Claude Code CLI

**Problem**: Claude Code can't access MCP servers.

**Solutions**:
1. List current servers:
   ```bash
   claude mcp list
   ```

2. Re-add servers:
   ```bash
   claude mcp remove <server>
   ./scripts/setup-claude-code-mcp.sh
   ```

3. Check configuration:
   ```bash
   claude settings show
   ```

### API keys not working for MCP servers

**Problem**: Figma or Exa servers fail with auth errors.

**Solutions**:
1. Ensure API keys are set:
   ```bash
   # Check if keys are exported
   echo $FIGMA_API_KEY
   echo $EXA_API_KEY
   ```

2. Add to shell config:
   ```bash
   echo 'export FIGMA_API_KEY="your-key-here"' >> ~/.config/zsh/51-api-keys.zsh
   echo 'export EXA_API_KEY="your-key-here"' >> ~/.config/zsh/51-api-keys.zsh
   source ~/.zshrc
   ```

3. Verify with debug script:
   ```bash
   ./scripts/debug-mcp-servers.sh
   ```

### MCP server installation fails

**Problem**: Servers fail to install or build.

**Solutions**:
1. Check Node.js version:
   ```bash
   node --version  # Should be 18+
   ```

2. Clean and reinstall:
   ```bash
   rm -rf ~/repos/mcp-servers
   ./scripts/setup-claude-mcp.sh
   ```

3. Install specific servers:
   ```bash
   ./scripts/fix-mcp-servers.sh --servers filesystem,memory,git
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

### Docker Desktop issues

**Problem**: Docker commands fail.

**Solutions**:
1. Ensure Docker Desktop is running
2. Check Docker context:
   ```bash
   docker context ls
   docker context use default
   ```
3. Reset Docker:
   ```bash
   # In Docker Desktop: Preferences → Reset → Reset to factory defaults
   ```

## Shell Configuration

### Slow shell startup

**Problem**: Terminal takes long to open.

**Solutions**:
1. Profile startup time:
   ```bash
   time zsh -i -c exit
   ```

2. Check for slow commands:
   ```bash
   zsh -xv 2>&1 | ts -i "%.s"
   ```

3. Optimize NVM loading (already done by setup):
   ```bash
   # Lazy load NVM
   export NVM_LAZY_LOAD=true
   ```

### Aliases not working

**Problem**: Custom aliases not available.

**Solutions**:
1. Check if aliases are loaded:
   ```bash
   alias | grep your_alias
   ```

2. Reload configuration:
   ```bash
   source ~/.zshrc
   ```

3. Check modular config files:
   ```bash
   ls ~/.config/zsh/
   # Should see numbered files like 10-aliases.zsh
   ```

### Git worktree commands not found

**Problem**: `gw`, `gwcd` commands not working.

**Solution**: Ensure functions are loaded:
```bash
# Check if loaded
type gw

# Manually source if needed
source ~/.config/zsh/40-git-helpers.zsh
```

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

Restore specific point:
```bash
./scripts/rollback.sh --restore "2024-01-15_10-30-45"
```

### Using backup system

View backups:
```bash
./setup.sh backup
```

Migrate old backups:
```bash
./setup.sh backup migrate
```

Clean old backups:
```bash
./setup.sh backup clean
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
   
   # Just MCP servers
   ./scripts/setup-claude-mcp.sh
   ```

### Complete reset

**Warning**: This removes everything!

```bash
# 1. Uninstall everything
./scripts/uninstall.sh

# 2. Clean up
rm -rf ~/.setup-backups
rm -rf ~/.setup_restore

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
# Verbose mode
SETUP_VERBOSE=1 ./setup.sh

# With logging
SETUP_LOG=debug.log ./setup.sh

# Bash debug mode
bash -x ./setup.sh
```

### Test specific components

```bash
# Test MCP servers
./scripts/debug-mcp-servers.sh

# Test signal handling
./tests/test_signal_handling.sh

# Test backup system
./tests/test_backup_system.sh

# Run all tests
./tests/run_tests.sh
```

### Community support

1. Check existing issues on GitHub
2. Create detailed bug report with:
   - macOS version
   - Hardware type (M1/M2/M3/Intel)
   - Complete error messages
   - Steps to reproduce
   - Output from health check

### Emergency contacts

If the setup completely breaks your system:
1. Boot into Recovery Mode (Cmd+R during startup)
2. Use Time Machine to restore
3. Reinstall macOS if necessary

## Prevention Tips

1. **Always use preview first**:
   ```bash
   ./setup.sh preview
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
   - Run tests before committing

5. **Use the fix command**:
   ```bash
   ./setup.sh fix
   ```

Remember: The health check script is your friend! Run it regularly:
```bash
./scripts/health-check.sh
```

## Common Error Messages

### "Failed to create backup directory"
- Check disk space: `df -h`
- Check permissions: `ls -la ~/`
- Manually create: `mkdir -p ~/.setup-backups`

### "MCP server command not found"
- Rebuild servers: `./scripts/setup-claude-mcp.sh`
- Check Node modules: `ls ~/repos/mcp-servers/*/node_modules`

### "Parallel execution failed"
- Reduce parallel jobs: `SETUP_JOBS=2 ./setup.sh`
- Run sequentially: `SETUP_JOBS=1 ./setup.sh`

### "Trap already set"
- Check for duplicate traps: `trap -p`
- Source issue: Don't source setup scripts, execute them

### "Python version mismatch"
- List versions: `pyenv versions`
- Set global: `pyenv global 3.12.8`
- Rehash: `pyenv rehash`