# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a macOS development environment setup repository designed for Apple Silicon (ARM64) MacBooks. It provides automated, reproducible setup scripts with a focus on performance and safety.

## Key Commands

### Testing and Validation
```bash
./setup-test.sh              # Run validation without system modifications
./setup.sh --dry-run         # Preview installation (delegates to setup-test.sh)
./setup-test.sh --verbose    # Detailed validation output
```

### Full Setup
```bash
./setup.sh                   # Run full environment setup
./setup.sh --verbose         # Verbose output during setup
./setup.sh --log setup.log   # Log all operations to file
./setup.sh --update          # Update existing packages
```

### Package Management
```bash
brew update && brew upgrade  # Update Homebrew packages
```

## Architecture Overview

### Performance Design
- The repository uses a **dual-script architecture** for optimal performance:
  - `setup.sh`: Production script with parallel processing (uses system CPU cores)
  - `setup-test.sh`: Testing script optimized for validation (6x faster I/O)
- Smart delegation: `setup.sh --dry-run` automatically delegates to `setup-test.sh`
- Parallel execution for package installations
- No-auto-update flags for Homebrew operations to reduce overhead

### Script Organization
- **Main Scripts**: `setup.sh` (production) and `setup-test.sh` (testing/validation)
- **Component Scripts** in `/scripts/`:
  - `install-homebrew.sh`: Installs Homebrew package manager
  - `install-packages.sh`: Installs packages from Brewfile
  - `setup-dotfiles.sh`: Deploys dotfiles with automatic backups
  - `setup-applications.sh`: Installs macOS desktop applications
  - `setup-macos.sh`: Configures macOS system preferences

### Key Configuration Files
- `homebrew/Brewfile`: Package definitions (formulae, casks, VS Code extensions)
- `dotfiles/.zshrc`: Shell configuration with custom aliases and functions
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