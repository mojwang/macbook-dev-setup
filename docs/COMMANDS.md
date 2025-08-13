# Command Reference

## Setup Commands

### Basic Usage
```bash
./setup.sh              # Smart setup - detects what needs to be done
./setup.sh preview      # Show what would be installed/updated
./setup.sh minimal      # Install essential tools only  
./setup.sh fix          # Run diagnostics and fix common issues
./setup.sh warp         # Configure Warp terminal optimizations
./setup.sh info         # Learn about installed tools, aliases & features
./setup.sh help         # Show help message

# Backup management (automatic - runs during setup)
./setup.sh backup         # List all backups
./setup.sh backup clean   # Manually remove old backups (also automatic)
./setup.sh backup migrate # Migrate legacy backups to new structure
```

### Advanced Options
```bash
# Use environment variables instead of flags
SETUP_VERBOSE=1 ./setup.sh      # Verbose output
SETUP_JOBS=8 ./setup.sh         # Custom parallel jobs
SETUP_LOG=file.log ./setup.sh   # Log to file
SETUP_NO_WARP=true ./setup.sh   # Skip Warp auto-detection

# Advanced interactive mode
./setup.sh advanced     # Interactive menu for all options

# Git configuration
git config --global core.editor # Automatically set to vim/nvim if available
```

### Information Commands
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

## Git Helpers

### Conventional Commits
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

### Branch Cleanup
```bash
# Clean up stale remote-tracking branches
gclean                       # Interactive cleanup of gone branches
gclean --force               # Skip confirmation prompts
git-cleanup-branches         # Full function name (same as gclean)
gprune                       # Just prune remote branches

# Manual cleanup (what gclean does automatically):
git remote prune origin
git branch -vv | grep ": gone]" | awk '{print $1}' | xargs git branch -d
```

## MCP Server Management

### Claude Desktop
```bash
./scripts/setup-claude-mcp.sh           # Install and configure MCP servers
./scripts/setup-claude-mcp.sh --check   # Check MCP server status
./scripts/setup-claude-mcp.sh --update  # Update MCP servers
./scripts/setup-claude-mcp.sh --remove  # Remove MCP configuration

./scripts/fix-mcp-servers.sh            # Fix/repair MCP configuration
./scripts/fix-mcp-servers.sh --no-api-keys  # Only setup servers without API keys
./scripts/fix-mcp-servers.sh --servers filesystem,memory,git  # Setup specific servers
./scripts/debug-mcp-servers.sh          # Test and debug MCP installations
```

### Claude Code CLI
```bash
./scripts/setup-claude-code-mcp.sh      # Add MCP servers to user scope (global)
./scripts/setup-claude-code-mcp.sh --scope project  # Add to project scope (.mcp.json)
./scripts/setup-claude-code-mcp.sh --scope user     # Add to user scope (default)

# After setup, use MCP servers in Claude Code:
claude mcp list              # List configured MCP servers
claude mcp add <server>      # Add a new MCP server
claude mcp remove <server>   # Remove an MCP server

# Update Exa MCP server specifically
./scripts/update-exa-mcp.sh              # Update the Exa search server
```

## Package Synchronization
The `--sync` flag detects and installs new packages added to configuration files:
- Checks `homebrew/Brewfile` for new formulae/casks
- Syncs VS Code extensions from `vscode/extensions.txt`
- Installs missing global npm packages from `nodejs-config/global-packages.txt`
- Updates Python packages from `python/requirements.txt`
- Use `--sync --minimal` to sync only essential packages from `Brewfile.minimal`

## Other Scripts
```bash
./scripts/cleanup-artifacts.sh  # Periodic maintenance and cleanup
./scripts/health-check.sh       # System health verification
./scripts/setup-terminal-fonts.sh  # Install Nerd Fonts for terminal
./scripts/benchmark-vscode-extensions.sh  # Benchmark VS Code extension install times
./scripts/update.sh             # Update all tools and dependencies
./scripts/uninstall.sh          # Clean removal with backups
./scripts/rollback.sh           # Restore from previous backups
```