# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 1.0.0 (2025-07-14)


### ⚠ BREAKING CHANGES

* Documentation has been reorganized. Users should now refer to docs/ directory for detailed guides instead of README.md

### Features

* Add adaptive color configuration system ([4e94d47](https://github.com/mojwang/macbook-dev-setup/commit/4e94d47e0e974bcd5ff87fcf88d2ac9c55ed3953))
* Add GitHub branch protection and CI/CD enhancements ([2923bb4](https://github.com/mojwang/macbook-dev-setup/commit/2923bb400d052ae6a1a7f46ea6ad5c0b3c213833))
* Add prominent shell reload guidance after setup ([d348a05](https://github.com/mojwang/macbook-dev-setup/commit/d348a05f49000f07ae49cccecbec7776c116e3c9))
* restructure docs and add comprehensive commit tooling ([57669c7](https://github.com/mojwang/macbook-dev-setup/commit/57669c7f7e69d20fa5b3c26002ca0e3743cd56b1))


### Bug Fixes

* add label: false to disable PR labeling ([5b79208](https://github.com/mojwang/macbook-dev-setup/commit/5b7920879916512f3224bd08b8172cd6d263deda))
* Add package.json to satisfy release-please Node.js detection ([8b02df3](https://github.com/mojwang/macbook-dev-setup/commit/8b02df38293f8b59e60ceb0f954bfbc53f369704))
* Cap progress bar percentage at 100% to handle edge cases ([7ba660a](https://github.com/mojwang/macbook-dev-setup/commit/7ba660a2119998146d3725175c3ef8709dfe7a76))
* Change release type from 'simple' to 'generic' to fix package.json error ([0145bee](https://github.com/mojwang/macbook-dev-setup/commit/0145bee43787aac36257dd12b4400b222b261a1c))
* correct extraFile type from plain-text to plain ([0ffba85](https://github.com/mojwang/macbook-dev-setup/commit/0ffba858e458851809e3de08ad17a4fe3def3342))
* Disable label creation in release-please to fix permission error ([813f203](https://github.com/mojwang/macbook-dev-setup/commit/813f2030068a6248c120c01494135382959b1427))
* Ensure git configuration prompts during setup ([3b2cff1](https://github.com/mojwang/macbook-dev-setup/commit/3b2cff13bea20cf463757f395a9fd9e9dd06f0ac))
* Fix release-please GitHub Actions permissions error ([78da4ae](https://github.com/mojwang/macbook-dev-setup/commit/78da4ae37cfc76e7420139d100282a7a17dcef04))
* Improve NVM loading in .zshrc for Homebrew installations ([c984aae](https://github.com/mojwang/macbook-dev-setup/commit/c984aaea863ff5e069933f77672d21c618910056))
* Improve package installation with better formula/cask detection ([03c80dc](https://github.com/mojwang/macbook-dev-setup/commit/03c80dc2302932afb576ca4a077704b457151189))
* Rename node/ to nodejs-config/ to prevent release-please auto-detection ([64d93b0](https://github.com/mojwang/macbook-dev-setup/commit/64d93b09ba0f6cca01e464a51d42aa87c9e5f3f2))
* simplify release-please config to avoid glob pattern bug ([aab299a](https://github.com/mojwang/macbook-dev-setup/commit/aab299a5b4b9d8feb8723498a1cbf0b1caacd791))
* Switch to config-based release-please setup to avoid label permission errors ([e1920cb](https://github.com/mojwang/macbook-dev-setup/commit/e1920cb9f951e6ddcf76d2fb3cacd80d391e93e5))
* switch to inline release-please configuration to avoid manifest error ([b449645](https://github.com/mojwang/macbook-dev-setup/commit/b449645e45da99f8b0af824306969aed99899e38))
* update glob pattern for VERSION in setup.sh ([344eb16](https://github.com/mojwang/macbook-dev-setup/commit/344eb160272a53dbe4058a58453a0bab357f850f))
* Update release-please to fix deprecated action and node detection ([b387e19](https://github.com/mojwang/macbook-dev-setup/commit/b387e19e45e1bc8155d68a6323629ef9ae8e9072))
* Update tests to handle gitignored 99-local.zsh file ([9df0893](https://github.com/mojwang/macbook-dev-setup/commit/9df0893c77ee173dde3649cd7c09d35fc582d7b4))
* use string format for VERSION in extra-files ([7ba1297](https://github.com/mojwang/macbook-dev-setup/commit/7ba12977147a5ab882c67b039370c4f6a276fe77))

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
