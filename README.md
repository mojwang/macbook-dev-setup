# 🛠️ Development Setup - MacBook Pro (Apple Silicon)

A comprehensive, reproducible development environment setup for macOS with modern tools and workflows.

## 📋 System Overview

- **Hardware**: Apple Silicon (ARM64) MacBook Pro
- **OS**: macOS Sequoia 15.5+
- **Shell**: Zsh with custom configurations
- **Package Manager**: Homebrew (primary)

## 🚀 Quick Setup

```bash
# Clone this repository
git clone https://github.com/YOUR_USERNAME/dev-setup.git
cd dev-setup

# Preview what will be installed (fast dry run)
./setup.sh --dry-run

# Run the high-performance setup script
./setup.sh

# Run with verbose output and logging
./setup.sh --verbose --log setup.log

# IMPORTANT: After setup completes, reload your shell:
source ~/.zshrc  # Or open a new terminal
```

## ⚡ Performance-Optimized Scripts

This repository includes two scripts optimized for different use cases:

### 🚀 `setup.sh` - High-Performance Environment Setup
- **Use for**: Actual environment setup, production deployments, CI/CD
- **Features**: Parallel processing (16 cores), optimized package management
- **Performance**: 6x faster I/O operations, 30-50% faster overall setup
- **Dry-run**: Automatically delegates to `setup-validate.sh` for optimal performance
- **Safety**: Never runs in dry-run mode, always performs real setup

### 🧪 `setup-validate.sh` - Testing & Validation Only
- **Use for**: Testing, validation, dry-runs, development iteration
- **Features**: Never performs actual setup, pure validation mode
- **Performance**: 6x faster execution, minimal overhead
- **Safety**: Never modifies your system, always safe to run
- **Purpose**: Validate prerequisites, test configurations, preview changes

### Performance Comparison

| Operation | Original | Optimized | Improvement |
|-----------|----------|-----------|-------------|
| Dry-run execution | 23ms | Delegates to test script (6x faster) | Smart delegation |
| I/O operations | 1.1s | 0.18s | 83% faster (6x) |
| Command execution | 1.06s | 0.18s | 82% faster (6x) |
| Full setup | Sequential | Parallel (16 cores) | 30-50% faster |

### 🔄 Shell Reload After Setup

After running the setup script, you'll see a prominent yellow warning that your shell configuration has been updated. You have three options to apply the changes:

1. **Recommended**: Close your terminal and open a new one (cleanest approach)
2. **Quick reload**: Run `source ~/.zshrc` (reloads config in current shell)
3. **Full reload**: Run `exec zsh` (replaces current shell with new one)

## 📦 What's Included

### Core Development Tools
- **Node.js**: Multiple versions managed via NVM
- **Bun**: Modern JavaScript runtime and package manager
- **Python**: Latest version via Pyenv
- **uv**: Modern Python package manager
- **Docker**: Container runtime
- **Git**: Version control with custom aliases
- **Neovim**: Primary terminal editor (replaces vim)
- **VS Code**: Primary IDE

### Database & Cloud Tools
- **Databases**: PostgreSQL, MySQL, Redis, SQLite
- **Database CLIs**: pgcli, mycli (with auto-completion)
- **Database GUIs**: TablePlus, Postico, Sequel Ace
- **Cloud CLIs**: AWS CLI, Azure CLI, Google Cloud SDK
- **Container Tools**: kubectl, helm, minikube, Docker Compose
- **Infrastructure**: Terraform, Ansible

### CLI Enhancements
- **bat**: Enhanced `cat` with syntax highlighting
- **eza**: Modern `ls` replacement with custom wrapper
- **fzf**: Fuzzy finder for files and commands
- **zoxide**: Smart directory navigation
- **diff-so-fancy**: Beautiful git diffs
- **gping**: Ping with a graph
- **htop/btop**: Process viewers
- **ripgrep**: Fast file search

### Applications
- **Browsers**: Chrome, Firefox, Safari, Brave, Edge
- **Communication**: Slack, Discord
- **Design**: Figma
- **AI**: Claude (Desktop + CLI)
- **Terminal**: Warp
- **API Testing**: Postman, Insomnia
- **Container Management**: OrbStack

## 🔧 Manual Configuration

Some tools require manual setup:

1. **Claude CLI**: Run `claude setup-token` to authenticate
2. **Git**: Update your name and email in `~/.gitconfig`
3. **Neovim**: Basic configuration is included; customize `~/.config/nvim/init.lua` as needed
4. **VS Code**: Extensions are automatically installed; settings are configured
5. **Applications**: Some apps may require manual App Store installation

## 🚀 Additional Scripts

### Health Check
Verify your development environment health:
```bash
./scripts/health-check.sh
```
- Checks 50+ tools and configurations
- Validates Git configuration
- Reports health score percentage
- Provides fix suggestions

### Update Everything
Keep all tools up to date with one command:
```bash
./scripts/update.sh
```
- Updates Homebrew packages and casks
- Updates npm global packages
- Updates Python packages
- Updates VS Code extensions
- Creates restore point before updates

### Uninstall
Cleanly remove the development environment:
```bash
./scripts/uninstall.sh
```
- Creates final backup before removal
- Selective uninstall with confirmations
- Preserves system tools and personal data

### Rollback
Restore from a previous state:
```bash
./scripts/rollback.sh --list     # Show available restore points
./scripts/rollback.sh --latest   # Restore from most recent point
./scripts/rollback.sh            # Interactive mode
```

### Configuration
Customize your installation with `config/setup.yaml`:
- Enable/disable specific tools
- Add custom packages
- Configure installation behavior
- Use predefined profiles

## ⚙️ Command Line Options

The setup script supports several options:

- `--dry-run` or `-d`: Preview what would be installed without making changes
- `--verbose` or `-v`: Enable detailed output
- `--log FILE` or `-l FILE`: Write detailed logs to a file
- `--help` or `-h`: Show help message

Examples:
```bash
./setup.sh --dry-run                    # Preview installation
./setup.sh --verbose                    # Verbose output
./setup.sh --log setup.log              # Log to file
./setup.sh -d -v -l setup.log          # Combine options
```

## 📁 Repository Structure

```
dev-setup/
├── README.md                   # This file
├── setup.sh                    # Main setup script
├── setup-validate.sh           # Fast validation script
├── lib/
│   └── common.sh               # Shared functions library
├── scripts/
│   ├── install-homebrew.sh     # Homebrew installation
│   ├── install-packages.sh     # Package installation
│   ├── setup-dotfiles.sh       # Dotfile configuration
│   ├── setup-applications.sh   # Application installation
│   ├── setup-macos.sh          # macOS preferences
│   ├── health-check.sh         # System health verification
│   ├── update.sh               # Update all tools
│   └── uninstall.sh            # Clean removal
├── dotfiles/
│   ├── .zshrc                  # Zsh configuration
│   ├── .gitconfig              # Git configuration
│   ├── .vimrc                  # Vim configuration
│   ├── .fzf.zsh                # FZF configuration
│   ├── .config/
│   │   └── nvim/
│   │       └── init.lua        # Neovim configuration
│   └── scripts/
│       └── exa-wrapper.sh      # Custom eza wrapper
├── homebrew/
│   └── Brewfile                # Homebrew dependencies
├── node/
│   ├── .nvmrc                  # Node version specification
│   └── global-packages.txt     # Global npm packages
├── python/
│   ├── .python-version         # Python version specification
│   └── requirements.txt        # Python packages
├── vscode/
│   ├── extensions.txt          # VS Code extensions
│   └── settings.json           # VS Code settings
└── docs/
    ├── manual-setup.md         # Manual configuration steps
    ├── troubleshooting.md      # Common issues and solutions
    └── improvements.md         # Recent improvements
```

## 🎯 Features

- **Reproducible**: Consistent setup across multiple machines
- **Modular**: Individual scripts for different components
- **Documented**: Comprehensive documentation and troubleshooting
- **Modern**: Latest tools and best practices
- **Customizable**: Easy to modify for personal preferences
- **Safe**: Dry-run mode and automatic backups
- **Robust**: Error handling and validation throughout
- **Logged**: Optional detailed logging for troubleshooting
- **Health Monitoring**: Built-in health check script
- **Easy Updates**: One-command update for all tools
- **Clean Uninstall**: Safe removal with backups
- **Restore Points**: Automatic backup before major operations
- **Network Resilient**: Retry logic for downloads
- **Security Focused**: Download verification and input validation

## 🔄 Keeping It Updated

Use the update script to update everything at once:
```bash
./scripts/update.sh
```

Or update individual components:
```bash
# Update Homebrew packages
brew update && brew upgrade

# Update Node.js via NVM
nvm install node --reinstall-packages-from=node

# Update Python packages
pip install --upgrade pip
pip install --upgrade -r python/requirements.txt

# Update VS Code extensions
code --update-extensions
```

## 💡 Useful Aliases

Add these to your `.zshrc` for quick access:
```bash
# Development environment management
alias devhealth="~/repos/personal/macbook-dev-setup/scripts/health-check.sh"
alias devupdate="~/repos/personal/macbook-dev-setup/scripts/update.sh"
alias devuninstall="~/repos/personal/macbook-dev-setup/scripts/uninstall.sh"

# Quick health check
alias checkhealth="devhealth | grep -E '(✅|❌|Score:)'"
```

## 📞 Support

If you encounter issues:

1. Check the [troubleshooting guide](docs/troubleshooting.md)
2. Review the [manual setup steps](docs/manual-setup.md)
3. Open an issue on GitHub

## 🤝 Contributing

Feel free to submit improvements via pull requests! Please review our:
- [Contributing Guide](CONTRIBUTING.md) - How to contribute
- [Branch Protection](docs/branch-protection.md) - Repository workflow and protection rules

## 📄 License

MIT License - see LICENSE file for details
