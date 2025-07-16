# 🛠️ macOS Development Setup

Automated setup for a modern macOS development environment on Apple Silicon.

## Quick Start

```bash
# Clone and run
git clone https://github.com/mojwang/macbook-dev-setup.git
cd macbook-dev-setup

# Preview what will be installed
./setup.sh --dry-run

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

## Common Tasks

```bash
./setup.sh --sync            # Install new tools added to config
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