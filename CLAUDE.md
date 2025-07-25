# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a macOS development environment setup repository designed for Apple Silicon (ARM64) MacBooks. It provides automated, reproducible setup scripts with a focus on performance and safety.

## Key Commands

### Simple Setup Commands (v2.0)
```bash
./setup.sh              # Smart setup - detects what needs to be done
./setup.sh preview      # Show what would be installed/updated
./setup.sh minimal      # Install essential tools only  
./setup.sh fix          # Run diagnostics and fix common issues
./setup.sh warp         # Configure Warp terminal optimizations
./setup.sh info         # Learn about installed tools, aliases & features
./setup.sh help         # Show help message

# Backup management (automatic - runs during setup)
./setup.sh backup       # List all backups
./setup.sh backup clean # Manually remove old backups (also automatic)
```

### For Power Users
```bash
# Use environment variables instead of flags
SETUP_VERBOSE=1 ./setup.sh      # Verbose output
SETUP_JOBS=8 ./setup.sh         # Custom parallel jobs
SETUP_LOG=file.log ./setup.sh   # Log to file
SETUP_NO_WARP=true ./setup.sh   # Skip Warp auto-detection

# Advanced interactive mode
./setup.sh advanced     # Interactive menu for all options
```

### Learning About Your Environment
The `info` command provides comprehensive documentation about installed tools:
```bash
./setup.sh info              # Show help categories
./setup.sh info tools        # List all installed tools with descriptions
./setup.sh info aliases      # Show all shell aliases
./setup.sh info functions    # Show custom shell functions
./setup.sh info features     # Show special features and enhancements
./setup.sh info examples     # Show usage examples for common tasks
./setup.sh info search fd    # Search for specific tool/command
./setup.sh info all          # Show everything (paginated)

# After setup, use the alias:
devhelp                      # Quick access to info command
devhelp tools                # Show tools
devhelp search ripgrep       # Search for ripgrep
```

### Automatic Warp Detection
The setup script now automatically detects Warp Terminal and offers to optimize your setup:
- Detects if you're using Warp or have it installed
- Only installs safe, non-intrusive enhancements by default
- Asks permission before making changes
- Enhances git diffs, adds useful workflows, and improves developer experience

### Organized Backup System
All backups are now centrally organized in `~/.setup-backups/`:
- **Categorized Structure**: dotfiles, restore-points, configs, scripts
- **Automatic Cleanup**: Keeps only the 10 most recent backups per category
- **Migration Support**: Automatically migrates old scattered backups
- **Latest Symlinks**: Quick access to most recent backups
- **Metadata Tracking**: Each backup includes timestamp and description

### Claude MCP Servers
```bash
./scripts/setup-claude-mcp.sh        # Install and configure MCP servers
./scripts/setup-claude-mcp.sh --check   # Check MCP server status
./scripts/setup-claude-mcp.sh --update  # Update MCP servers
./scripts/setup-claude-mcp.sh --remove  # Remove MCP configuration

# After setup, use MCP servers in Claude Code:
/mcp                         # Access MCP servers in Claude Code
claude mcp list              # List configured MCP servers
```

MCP servers installed:
- **filesystem**: Secure file operations with configurable access controls
- **memory**: In-memory key-value storage for temporary data
- **git**: Tools to read, search, and manipulate Git repositories
- **fetch**: Web content fetching and conversion for efficient LLM usage

### Git Commit Helpers
```bash
./scripts/setup-git-hooks.sh # Set up conventional commit hooks
./scripts/commit-helper.sh   # Interactive commit message creator
./scripts/commit-helper.sh --quick # Quick mode with fewer prompts

# Shell aliases (after running setup):
gci                          # Interactive commit helper
gcft "message"               # Quick feat commit
gcfs scope "message"         # Scoped feat commit
commit-help                  # Show commit format reference
```

### Package Synchronization
The `--sync` flag detects and installs new packages added to configuration files:
- Checks `homebrew/Brewfile` for new formulae/casks
- Syncs VS Code extensions from `vscode/extensions.txt`
- Installs missing global npm packages from `nodejs-config/global-packages.txt`
- Updates Python packages from `python/requirements.txt`
- Use `--sync --minimal` to sync only essential packages from `Brewfile.minimal`

## Architecture Overview

### Performance Design
- The repository uses a **dual-script architecture** for optimal performance:
  - `setup.sh`: Production script with parallel processing (uses system CPU cores)
  - `setup-validate.sh`: Validation script optimized for dry-runs (6x faster I/O)
- Smart delegation: `setup.sh preview` automatically delegates to `setup-validate.sh`
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
  - `setup-git-hooks.sh`: Configures conventional commit hooks
  - `commit-helper.sh`: Interactive conventional commit creator

### Key Configuration Files
- `homebrew/Brewfile`: Package definitions (formulae, casks, VS Code extensions)
- `homebrew/Brewfile.minimal`: Essential packages only (use with --minimal flag)
- `dotfiles/.zshrc`: Modular shell configuration loader
- `dotfiles/.config/zsh/`: Modular zsh configuration files:
  - `00-homebrew.zsh`: Homebrew setup and initialization
  - `10-languages.zsh`: Language version managers (NVM, pyenv, rbenv)
  - `20-tools.zsh`: Modern CLI tools configuration
  - `30-aliases.zsh`: Git, Docker, and utility aliases
  - `35-commit-aliases.zsh`: Conventional commit shortcuts
  - `40-functions.zsh`: Custom shell functions
  - `50-environment.zsh`: Environment variables and settings
  - `99-local.zsh`: Local customizations (gitignored)
- `dotfiles/.gitconfig`: Git configuration with diff-so-fancy integration
- `nodejs-config/global-packages.txt`: Global npm packages to install
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

## Setup Script Maintenance

When adding new functionality or capabilities to this project, always check if the setup script needs updating:

1. **New tools/packages**: Add to `homebrew/Brewfile` (or `Brewfile.minimal` for essentials)
2. **Configuration files**: Update relevant scripts in `/scripts/` directory
3. **Shell integrations**: Add to appropriate `.config/zsh/` module
4. **Claude MCP servers**: Update `setup-claude-mcp.sh` for new MCP servers
5. **Test changes**: Run `./setup.sh preview` to verify changes
6. **Update documentation**: Document new features in this file if needed

After any changes, run the setup script to ensure everything works correctly.
