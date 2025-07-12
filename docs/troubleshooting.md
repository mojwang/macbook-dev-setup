# Troubleshooting Guide

Common issues and solutions for the development setup.

## 🍺 Homebrew Issues

### Homebrew Command Not Found
```bash
# For Apple Silicon Macs
eval "$(/opt/homebrew/bin/brew shellenv)"

# For Intel Macs
eval "$(/usr/local/bin/brew shellenv)"
```

### Permission Errors
```bash
# Fix Homebrew permissions
sudo chown -R $(whoami) $(brew --prefix)/*
```

### Outdated Formulae
```bash
brew update
brew doctor
brew cleanup
```

## 🟢 Node.js & NVM Issues

### NVM Command Not Found
Add to your shell profile (`.zshrc` or `.bash_profile`):
```bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
```

### Node Version Not Switching
```bash
# Reload shell configuration
source ~/.zshrc

# Or restart terminal
```

### Global Package Installation Issues
```bash
# Check npm permissions
npm config get prefix

# Fix if needed
npm config set prefix ~/.npm-global
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.zshrc
```

## 🐍 Python & Pyenv Issues

### Pyenv Command Not Found
Add to your shell profile:
```bash
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init -)"
```

### Python Build Dependencies (macOS)
```bash
# Install Xcode command line tools
xcode-select --install

# Install additional dependencies
brew install openssl readline sqlite3 xz zlib
```

### SSL Certificate Issues
```bash
# Update certificates
brew upgrade ca-certificates
```

## 🔧 Git Issues

### Authentication Problems
```bash
# Check Git credentials
git config --list

# Reset credentials
git credential-manager-core erase

# Or use SSH keys
ssh-keygen -t ed25519 -C "your.email@example.com"
```

### Diff-so-fancy Not Working
```bash
# Reinstall diff-so-fancy
brew reinstall diff-so-fancy

# Check Git pager configuration
git config --global core.pager
```

## 🆚 VS Code Issues

### Extensions Not Installing
```bash
# Check VS Code CLI
code --version

# Install extensions manually
code --install-extension extensionName
```

### Settings Not Syncing
1. Enable Settings Sync in VS Code
2. Sign in with GitHub or Microsoft account
3. Manual import from `vscode/settings.json`

## 🤖 Claude CLI Issues

### Authentication Failures
```bash
# Re-authenticate
claude setup-token

# Check token environment variable
echo $CLAUDE_CODE_OAUTH_TOKEN
```

### Command Not Found
```bash
# Reinstall Claude CLI
npm install -g @anthropic-ai/claude-code

# Check PATH
echo $PATH
```

## 🔄 Shell Configuration Issues

### Zsh Not Loading Configuration
```bash
# Check shell
echo $SHELL

# Change to Zsh if needed
chsh -s /bin/zsh

# Reload configuration
source ~/.zshrc
```

### Command Aliases Not Working
```bash
# Check if alias is defined
alias ls

# Reload shell configuration
source ~/.zshrc
```

## 🐳 Docker Issues

### Docker Desktop Not Starting
1. Check system requirements
2. Restart Docker Desktop
3. Reset Docker Desktop if needed

### Permission Errors
```bash
# Add user to docker group (Linux)
sudo usermod -aG docker $USER

# On macOS, use Docker Desktop
```

## 🌐 Network Issues

### Homebrew Download Failures
```bash
# Try different mirror
export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles

# Or reset to default
unset HOMEBREW_BOTTLE_DOMAIN
```

### NVM Download Issues
```bash
# Use different mirror
export NVM_NODEJS_ORG_MIRROR=https://nodejs.org/dist
```

## 💾 Disk Space Issues

### Clean Up Homebrew
```bash
brew cleanup --prune=all
brew autoremove
```

### Clean Up Node Modules
```bash
# Find large node_modules directories
find . -name "node_modules" -type d -prune -exec du -chs {} +

# Clean npm cache
npm cache clean --force
```

### Clean Up Docker
```bash
docker system prune -a
```

## 🆘 General Debugging

### Check System Information
```bash
# macOS version
sw_vers

# Hardware information
system_profiler SPHardwareDataType

# Disk usage
df -h
```

### Environment Variables
```bash
# List all environment variables
printenv

# Check specific paths
echo $PATH
echo $HOME
echo $SHELL
```

### Process Management
```bash
# Check running processes
ps aux | grep [process_name]

# Kill stuck processes
kill -9 [PID]
```

## 🔧 Reset Strategies

### Nuclear Option: Fresh Start
If all else fails:

1. **Backup important data**
2. **Remove Homebrew**:
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
   ```
3. **Remove Node/NVM**:
   ```bash
   rm -rf ~/.nvm
   ```
4. **Remove Python/Pyenv**:
   ```bash
   rm -rf ~/.pyenv
   ```
5. **Reset shell configuration**:
   ```bash
   mv ~/.zshrc ~/.zshrc.backup
   ```
6. **Run setup script again**

## 📞 Getting Help

1. **Check official documentation** for each tool
2. **Search GitHub issues** for similar problems
3. **Ask on Stack Overflow** with specific error messages
4. **Check tool-specific forums** and communities
5. **Open an issue** in this repository for setup-specific problems
