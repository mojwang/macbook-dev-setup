# Getting Started

This guide will walk you through setting up your macOS development environment.

## Prerequisites

- **macOS**: Sequoia 15.5+ (optimized for Apple Silicon)
- **Admin Access**: Required for installing some tools
- **Internet Connection**: For downloading packages
- **Xcode Command Line Tools**: Required for git, compilers, and dev tools
- **Time**: ~15-30 minutes for full setup

### Installing Xcode Command Line Tools

If not already installed, run:
```bash
xcode-select --install
```

This provides essential development tools including git, make, gcc, and more.

## Installation Steps

### 1. Clone the Repository

```bash
git clone https://github.com/mojwang/macbook-dev-setup.git
cd macbook-dev-setup
```

### 2. Preview Installation (Recommended)

See what will be installed without making changes:

```bash
./setup.sh --dry-run
```

### 3. Run Setup

```bash
# Standard installation
./setup.sh

# With detailed output
./setup.sh --verbose

# With logging
./setup.sh --log setup.log

# Minimal installation (essential tools only)
./setup.sh --minimal
```

### 4. Reload Your Shell

After setup completes, reload your shell configuration:

```bash
# Option 1: Source the config (quickest)
source ~/.zshrc

# Option 2: Start a new shell
exec zsh

# Option 3: Close and reopen your terminal (cleanest)
```

## Post-Installation Setup

### Required Configuration

1. **Git Configuration**
   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "your.email@example.com"
   ```

2. **Claude CLI Authentication**
   ```bash
   claude setup-token
   ```

### Optional Configuration

1. **SSH Keys for GitHub**
   ```bash
   ssh-keygen -t ed25519 -C "your.email@example.com"
   eval "$(ssh-agent -s)"
   ssh-add ~/.ssh/id_ed25519
   # Copy public key to GitHub
   pbcopy < ~/.ssh/id_ed25519.pub
   ```

2. **VS Code Settings Sync**
   - Sign in to GitHub in VS Code
   - Enable Settings Sync

3. **Node.js Version**
   ```bash
   # Install specific Node version
   nvm install 20
   nvm use 20
   nvm alias default 20
   ```

## Verify Installation

Run the health check to ensure everything is properly installed:

```bash
./scripts/health-check.sh
```

Expected output:
- ✅ for properly installed tools
- ❌ for missing tools (with fix suggestions)
- Health score percentage

## Common Issues

### Command Not Found

If commands aren't found after installation:
1. Ensure you've reloaded your shell
2. Check that `/opt/homebrew/bin` is in your PATH
3. Run `brew doctor` for diagnostics

### Permission Errors

Some installations may require admin access:
```bash
sudo ./setup.sh  # Not recommended
# Better: Fix specific permission issues as they arise
```

### Slow Installation

To speed up installation:
- Use `--minimal` flag for essential tools only
- Close other applications to free up resources
- Ensure stable internet connection

## Next Steps

- [Explore available tools](tools.md)
- [Customize your setup](configuration.md)
- [Learn maintenance commands](maintenance.md)
- [Read troubleshooting guide](troubleshooting.md)

## Quick Reference

| Command | Description |
|---------|-------------|
| `./setup.sh --dry-run` | Preview changes |
| `./setup.sh --sync` | Install newly added tools |
| `./scripts/health-check.sh` | Verify installation |
| `./scripts/update.sh` | Update all tools |
| `./scripts/pre-push-check.sh` | Pre-commit validation |

## For Contributors

Set up git hooks for conventional commits:
```bash
./scripts/setup-git-hooks.sh
```

This enables:
- Commit message validation
- Git commit template
- Interactive commit helper (`./scripts/commit-helper.sh`)

See [Commit Guide](commit-guide.md) for details.