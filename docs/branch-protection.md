# Branch Protection Guide

This document explains the branch protection rules for the `macbook-dev-setup` repository and how to work with them effectively.

## Overview

The `main` branch is protected to ensure code quality and prevent accidental damage. All changes must pass automated tests before being merged.

## Protection Rules

### For the `main` branch:

1. **No Force Pushes**: Force pushing is disabled for everyone (including admins)
2. **No Deletions**: The main branch cannot be deleted
3. **Status Checks Required**: All CI checks must pass before changes can be merged
4. **Pull Request Reviews**: Non-admin contributors must get approval before merging

### Required Status Checks

The following checks must pass:
- `test` - Runs the full test suite
- `validate-documentation` - Validates markdown files and links
- `security-scan` - Scans for hardcoded secrets
- `All Checks Pass` - Summary check that ensures all others passed

## Workflows

### For Repository Admin (mojwang)

As the repository admin, you have additional privileges:

1. **Direct Push to Main**:
   ```bash
   # Make your changes
   git add .
   git commit -m "fix: Update configuration"
   
   # Optional: Run tests locally first
   ./scripts/pre-push-check.sh
   
   # Push directly to main
   git push origin main
   ```

2. **Important**: Even as admin, your pushes must pass all status checks. If tests fail after pushing, you'll need to push a fix.

3. **Using with Claude Code**:
   - Claude Code can push directly using your credentials
   - Ensure you're using SSH authentication or a properly configured PAT
   - The tool will respect the same rules (no force push, tests must pass)

### For Contributors

Contributors must use the pull request workflow:

1. **Create a feature branch**:
   ```bash
   git checkout -b feature/my-feature
   ```

2. **Make changes and test locally**:
   ```bash
   # Make your changes
   ./tests/run_tests.sh
   ./setup.sh --dry-run
   ```

3. **Push to your branch**:
   ```bash
   git push origin feature/my-feature
   ```

4. **Create a pull request**:
   - Go to GitHub and create a PR
   - Fill out the PR template
   - Wait for CI checks to pass
   - Get approval from a reviewer

## Setting Up Branch Protection

To configure branch protection for this repository:

### Automated Setup (Recommended)

```bash
# Ensure GitHub CLI is installed and authenticated
brew install gh
gh auth login

# Run the setup script
./scripts/setup-branch-protection.sh
```

### Manual Setup

1. Go to Settings → Branches in GitHub
2. Add rule for branch pattern: `main`
3. Configure these settings:
   - ✅ Require a pull request before merging
     - Require 1 approval
     - Dismiss stale reviews
     - Do NOT include administrators
   - ✅ Require status checks to pass
     - Add required checks: test, validate-documentation, security-scan, All Checks Pass
     - Require branches to be up to date
     - Include administrators
   - ✅ Require conversation resolution
   - ✅ Do not allow force pushes
   - ✅ Do not allow deletions

## Best Practices

### Before Pushing to Main (Admin)

1. **Always run tests locally first**:
   ```bash
   ./scripts/pre-push-check.sh
   ```

2. **Keep commits atomic**: Each commit should be a complete, working change

3. **Write clear commit messages**: Follow conventional commits format

### Emergency Procedures

If you need to fix a broken main branch:

1. **Quick Fix**:
   ```bash
   # Fix the issue
   git add .
   git commit -m "fix: Resolve CI failure"
   git push origin main
   ```

2. **If you accidentally need to revert**:
   ```bash
   # Create a revert commit (safer than force push)
   git revert HEAD
   git push origin main
   ```

## Troubleshooting

### "Protected branch update failed"

This means one or more required checks didn't pass. Check the GitHub Actions tab to see which check failed.

### "Push declined due to branch protections"

Non-admins cannot push directly to main. Create a pull request instead.

### "Updates were rejected because the tip of your current branch is behind"

Pull the latest changes first:
```bash
git pull origin main
```

## GitHub Authentication

### For SSH (Recommended)

Ensure your SSH key is added to GitHub:
```bash
ssh -T git@github.com
```

### For HTTPS with Token

Create a Personal Access Token with `repo` scope and use it in your remote URL:
```bash
git remote set-url origin https://<token>@github.com/mojwang/macbook-dev-setup.git
```

## Status Check Details

### test
- Runs `./tests/run_tests.sh`
- Validates all shell scripts work correctly
- Must pass for any merge

### validate-documentation  
- Checks markdown files for issues
- Validates internal links
- Ensures documentation is up to date

### security-scan
- Scans for hardcoded secrets
- Checks for security vulnerabilities
- Prevents accidental credential commits

### All Checks Pass
- Summary job that depends on all others
- Only passes if all other checks succeed
- This is the primary required check

## Questions?

If you have questions about branch protection or encounter issues, please open an issue in the repository.