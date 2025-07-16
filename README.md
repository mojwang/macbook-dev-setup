# 🛠️ macOS Development Setup

Automated setup for a modern macOS development environment on Apple Silicon.

## Quick Start

```bash
# Clone and run
git clone https://github.com/mojwang/macbook-dev-setup.git
cd macbook-dev-setup

# Preview what will be installed
./setup.sh preview

# Run setup
./setup.sh

# Reload shell after completion
source ~/.zshrc
```

## What's Included

Essential development tools for:
- **Languages**: Node.js (NVM), Python (pyenv), Ruby, Go, Rust
- **Containers**: Docker, Kubernetes tools
- **Databases**: PostgreSQL, MySQL, Redis
- **Cloud**: AWS, Azure, GCP CLIs
- **Modern CLI**: Enhanced terminal tools (bat, eza, fzf, ripgrep)

[See full tool list →](docs/tools.md)

## Setup Commands

```bash
./setup.sh               # Standard installation
./setup.sh preview       # Preview changes without installing
./setup.sh minimal       # Install essential tools only
./setup.sh fix           # Run diagnostics and fix common issues
./setup.sh warp          # Configure Warp terminal optimizations
./setup.sh backup        # View backups
./setup.sh backup clean  # Clean old backups
./setup.sh help          # Show help message
```

## Power User Options

```bash
# Use environment variables for advanced control
SETUP_VERBOSE=1 ./setup.sh        # Verbose output
SETUP_JOBS=8 ./setup.sh           # Custom parallel jobs (default: CPU count)
SETUP_LOG=setup.log ./setup.sh    # Log output to file
SETUP_NO_WARP=true ./setup.sh     # Skip Warp terminal detection
```

## Common Tasks

```bash
./scripts/health-check.sh    # Verify installation
./scripts/update.sh          # Update everything
./scripts/pre-push-check.sh  # Run before pushing
./scripts/organize-tests.sh  # Organize test files by category
```

## Documentation

- [**Getting Started**](docs/getting-started.md) - Detailed setup guide
- [**Tools & Features**](docs/tools.md) - Complete tool list
- [**Configuration**](docs/configuration.md) - Customization options
- [**Maintenance**](docs/maintenance.md) - Updates, health checks, rollbacks
- [**Architecture**](docs/architecture.md) - Technical details
- [**Troubleshooting**](docs/troubleshooting.md) - Common issues

## Requirements

- macOS Sequoia 15.5+ (optimized for Apple Silicon)
- Administrator access
- Internet connection
- Xcode Command Line Tools (install with: `xcode-select --install`)

## Contributing

See [Contributing Guide](CONTRIBUTING.md) | [Commit Guide](docs/commit-guide.md) | [Branch Protection](docs/branch-protection.md)

## License

MIT - See [LICENSE](LICENSE) file