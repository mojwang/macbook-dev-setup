# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Common Library** (`lib/common.sh`): Centralized shared functions to eliminate code duplication
- **Configuration Support** (`config/setup.yaml`): YAML-based configuration for customizing installations
- **Health Check Script** (`scripts/health-check.sh`): Comprehensive system verification with 50+ checks
- **Update Script** (`scripts/update.sh`): One-command update for all tools and dependencies
- **Uninstall Script** (`scripts/uninstall.sh`): Clean removal with automatic backups
- **Rollback Script** (`scripts/rollback.sh`): Restore from previous restore points
- **Test Framework** (`tests/`): Automated testing with unit tests for common functions
- **CI/CD Pipeline** (`.github/workflows/ci.yml`): GitHub Actions for automated testing
- **Database Tools**: PostgreSQL, MySQL, Redis, SQLite with CLI and GUI tools
- **Cloud Tools**: AWS CLI, Azure CLI, Google Cloud SDK, kubectl, Terraform
- **API Tools**: HTTPie, Postman, Insomnia, mkcert
- **Performance Tools**: htop, btop, ncdu, duf, procs
- **Shell Reload Guidance**: Prominent warning with clear instructions after setup completion

### Changed
- **Enhanced Security**: Added download verification, input validation, and secure temp files
- **Better Error Handling**: Improved error messages with actionable solutions
- **Network Resilience**: Added retry logic with exponential backoff for downloads
- **Git Configuration**: Intelligent handling that preserves existing configurations
- **System Checks**: Added disk space and network connectivity validation
- **Homebrew Installation**: Enhanced with better verification and error recovery
- **Setup Completion Message**: Added visual emphasis with yellow warning box for shell reload instructions

### Fixed
- Git configuration no longer overwrites existing valid configurations
- Improved handling of non-interactive mode
- Better cleanup of temporary files
- Fixed shell compatibility issues

## [1.0.0] - 2024-01-12

### Added
- Initial release with basic setup functionality
- Homebrew installation and package management
- Dotfiles configuration
- VS Code setup with extensions
- Python and Node.js environment setup
- macOS system preferences configuration
- Performance optimizations with parallel processing
- Dry-run mode for testing
- Comprehensive documentation

### Features
- Modular script architecture
- Error handling and validation
- Automatic backups of existing configurations
- Support for both Apple Silicon and Intel Macs
- Modern development tools and CLI enhancements

[Unreleased]: https://github.com/YOUR_USERNAME/macbook-dev-setup/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/YOUR_USERNAME/macbook-dev-setup/releases/tag/v1.0.0