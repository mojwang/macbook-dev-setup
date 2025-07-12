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

# Preview what will be installed (dry run)
./setup.sh --dry-run

# Run the setup script
./setup.sh

# Run with verbose output and logging
./setup.sh --verbose --log setup.log
```

## 📦 What's Included

### Core Development Tools
- **Node.js**: Multiple versions managed via NVM
- **Python**: Latest version via Pyenv
- **Docker**: Container runtime
- **Git**: Version control with custom aliases
- **Neovim**: Primary terminal editor (replaces vim)
- **VS Code**: Primary IDE

### CLI Enhancements
- **bat**: Enhanced `cat` with syntax highlighting
- **eza**: Modern `ls` replacement with custom wrapper
- **fzf**: Fuzzy finder for files and commands
- **zoxide**: Smart directory navigation
- **diff-so-fancy**: Beautiful git diffs
- **gping**: Ping with a graph

### Applications
- **Browsers**: Chrome, Firefox, Safari, Brave, Edge
- **Communication**: Slack, Discord
- **Design**: Figma
- **AI**: Claude (Desktop + CLI)
- **Terminal**: Warp

## 🔧 Manual Configuration

Some tools require manual setup:

1. **Claude CLI**: Run `claude setup-token` to authenticate
2. **Git**: Update your name and email in `~/.gitconfig`
3. **Neovim**: Basic configuration is included; customize `~/.config/nvim/init.lua` as needed
4. **VS Code**: Extensions are automatically installed; settings are configured
5. **Applications**: Some apps may require manual App Store installation

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
├── scripts/
│   ├── install-homebrew.sh     # Homebrew installation
│   ├── install-packages.sh     # Package installation
│   ├── setup-dotfiles.sh       # Dotfile configuration
│   └── setup-applications.sh   # Application installation
├── dotfiles/
│   ├── .zshrc                  # Zsh configuration
│   ├── .gitconfig              # Git configuration
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
    └── troubleshooting.md      # Common issues and solutions
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

## 🔄 Keeping It Updated

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

## 📞 Support

If you encounter issues:

1. Check the [troubleshooting guide](docs/troubleshooting.md)
2. Review the [manual setup steps](docs/manual-setup.md)
3. Open an issue on GitHub

## 🤝 Contributing

Feel free to submit improvements via pull requests!

## 📄 License

MIT License - see LICENSE file for details
