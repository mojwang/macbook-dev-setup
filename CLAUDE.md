# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a macOS development environment setup repository designed for Apple Silicon (ARM64) MacBooks. It provides automated, reproducible setup scripts with a focus on performance and safety.

## Key Commands

### Testing and Validation
```bash
./setup-validate.sh          # Run validation without system modifications
./setup.sh --dry-run         # Preview installation (delegates to setup-validate.sh)
./setup-validate.sh --verbose # Detailed validation output
```

### Full Setup
```bash
./setup.sh                   # Run full environment setup
./setup.sh --verbose         # Verbose output during setup
./setup.sh --log setup.log   # Log all operations to file
./setup.sh --minimal         # Install essential packages only
```

### Package Management
```bash
./setup.sh --sync            # Sync new packages from config files
./setup.sh --update          # Update existing packages
./setup.sh --sync --update   # Sync new packages then update all
brew update && brew upgrade  # Manual Homebrew update
```

### Package Synchronization
The `--sync` flag detects and installs new packages added to configuration files:
- Checks `homebrew/Brewfile` for new formulae/casks
- Syncs VS Code extensions from `vscode/extensions.txt`
- Installs missing global npm packages from `node/global-packages.txt`
- Updates Python packages from `python/requirements.txt`
- Use `--sync --minimal` to sync only essential packages from `Brewfile.minimal`

## Architecture Overview

### Performance Design
- The repository uses a **dual-script architecture** for optimal performance:
  - `setup.sh`: Production script with parallel processing (uses system CPU cores)
  - `setup-validate.sh`: Validation script optimized for dry-runs (6x faster I/O)
- Smart delegation: `setup.sh --dry-run` automatically delegates to `setup-validate.sh`
- Parallel execution for package installations
- No-auto-update flags for Homebrew operations to reduce overhead

### Script Organization
- **Main Scripts**: `setup.sh` (production) and `setup-validate.sh` (validation/dry-run)
- **Component Scripts** in `/scripts/`:
  - `install-homebrew.sh`: Installs Homebrew package manager
  - `install-packages.sh`: Installs packages from Brewfile
  - `setup-dotfiles.sh`: Deploys dotfiles with automatic backups
  - `setup-applications.sh`: Installs macOS desktop applications
  - `setup-macos.sh`: Configures macOS system preferences

### Key Configuration Files
- `homebrew/Brewfile`: Package definitions (formulae, casks, VS Code extensions)
- `homebrew/Brewfile.minimal`: Essential packages only (use with --minimal flag)
- `dotfiles/.zshrc`: Modular shell configuration loader
- `dotfiles/.config/zsh/`: Modular zsh configuration files:
  - `00-homebrew.zsh`: Homebrew setup and initialization
  - `10-languages.zsh`: Language version managers (NVM, pyenv, rbenv)
  - `20-tools.zsh`: Modern CLI tools configuration
  - `30-aliases.zsh`: Git, Docker, and utility aliases
  - `40-functions.zsh`: Custom shell functions
  - `50-environment.zsh`: Environment variables and settings
  - `99-local.zsh`: Local customizations (gitignored)
- `dotfiles/.gitconfig`: Git configuration with diff-so-fancy integration
- `node/global-packages.txt`: Global npm packages to install
- `python/requirements.txt`: Python packages to install
- `vscode/settings.json`: VS Code user settings
- `vscode/extensions.txt`: VS Code extensions list

### Safety Features
- Comprehensive prerequisite validation before any system changes
- Automatic backup of existing dotfiles before replacement
- Dry-run mode for previewing all changes
- Detailed error handling with recovery options
- Optional logging for troubleshooting

## Development Notes

- The codebase follows shell scripting best practices with consistent error handling
- Color-coded output for different message types (success, warning, error, dry-run)
- All scripts use `set -e` for fail-fast behavior
- Timeout protection (30s) for potentially hanging commands
- Git is configured with security-conscious settings (fsckObjects enabled)