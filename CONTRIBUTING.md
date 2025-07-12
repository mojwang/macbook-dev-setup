# Contributing to macOS Development Setup

Thank you for your interest in contributing! This guide will help you get started.

## 🤝 How to Contribute

### Reporting Issues

1. **Check existing issues** first to avoid duplicates
2. Use the issue templates when available
3. Include relevant information:
   - macOS version
   - Hardware (Apple Silicon or Intel)
   - Error messages or logs
   - Steps to reproduce

### Suggesting Features

1. Open an issue with the `enhancement` label
2. Describe the feature and its benefits
3. Include examples of how it would work

### Submitting Pull Requests

1. **Fork the repository** and create your branch from `main`
2. **Follow the coding standards** (see below)
3. **Add tests** for new functionality
4. **Update documentation** as needed
5. **Test your changes** thoroughly

## 📋 Development Process

### 1. Setting Up Your Development Environment

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/macbook-dev-setup.git
cd macbook-dev-setup

# Add upstream remote
git remote add upstream https://github.com/ORIGINAL_OWNER/macbook-dev-setup.git

# Create a feature branch
git checkout -b feature/your-feature-name
```

### 2. Making Changes

- Keep commits focused and atomic
- Write clear commit messages
- Follow the existing code style
- Add comments for complex logic

### 3. Testing Your Changes

```bash
# Run the test suite
./tests/run_tests.sh

# Test dry-run mode
./setup.sh --dry-run

# Run health check
./scripts/health-check.sh

# Validate scripts with shellcheck
shellcheck scripts/*.sh
```

### 4. Submitting Your Changes

```bash
# Push to your fork
git push origin feature/your-feature-name

# Create a pull request via GitHub
```

## 🎨 Coding Standards

### Shell Scripts

1. **Use bash** with `#!/bin/bash` shebang
2. **Source common library** for shared functions:
   ```bash
   source "$(dirname "$0")/../lib/common.sh"
   ```
3. **Use meaningful variable names** in UPPER_CASE for globals
4. **Quote variables** to prevent word splitting: `"$variable"`
5. **Check command existence** before using:
   ```bash
   if command_exists brew; then
       # use brew
   fi
   ```
6. **Handle errors gracefully** with appropriate messages
7. **Use color output functions** from common.sh:
   - `print_step` for actions
   - `print_success` for success
   - `print_error` for errors
   - `print_warning` for warnings
   - `print_info` for information

### Documentation

1. **Update README.md** for user-facing changes
2. **Add inline comments** for complex logic
3. **Document functions** with usage examples
4. **Update CHANGELOG.md** following Keep a Changelog format

### Testing

1. **Write tests** for new functions in `tests/`
2. **Use the test framework** functions:
   ```bash
   describe "Feature Name"
   it "should do something"
   assert_equals "expected" "$actual" "Test description"
   ```
3. **Test edge cases** and error conditions
4. **Ensure tests pass** before submitting PR

## 🏗️ Project Structure

```
├── lib/              # Shared libraries
│   ├── common.sh     # Common functions
│   └── config.sh     # Configuration parser
├── scripts/          # Individual setup scripts
├── tests/            # Test suite
├── config/           # Configuration files
├── docs/             # Documentation
└── homebrew/         # Package definitions
```

## 🔍 Code Review Process

1. **Automated checks** run via GitHub Actions
2. **Manual review** by maintainers
3. **Feedback addressed** through commits
4. **Approval required** before merging

## 📜 Guidelines

### Do's
- ✅ Test on both Apple Silicon and Intel Macs if possible
- ✅ Keep backward compatibility in mind
- ✅ Update documentation alongside code
- ✅ Be respectful and constructive in discussions
- ✅ Follow the existing patterns and conventions

### Don'ts
- ❌ Don't commit sensitive information
- ❌ Don't break existing functionality
- ❌ Don't add unnecessary dependencies
- ❌ Don't ignore CI/CD failures
- ❌ Don't submit incomplete work

## 🎯 Priority Areas

Current areas where contributions are especially welcome:

1. **Additional tool integrations**
2. **Performance improvements**
3. **Test coverage expansion**
4. **Documentation improvements**
5. **Accessibility enhancements**
6. **Apple Silicon optimizations**

## 📮 Getting Help

- Open an issue for questions
- Check existing documentation
- Review similar PRs for examples

## 🙏 Recognition

Contributors will be acknowledged in:
- The project README
- Release notes
- Git history

Thank you for helping make this project better! 🎉