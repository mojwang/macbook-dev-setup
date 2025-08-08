# Git Workflow Guide

## Overview

This project uses an enhanced Git workflow with:
- **Git Worktrees** for parallel development
- **Graphite CLI** for stacked pull requests
- **Conventional Commits** for clear history

## Git Worktrees

### What are Worktrees?
Git worktrees allow you to have multiple branches checked out simultaneously in different directories. Perfect for:
- Working on features while reviewing PRs
- Quick hotfixes without stashing work
- Testing changes in isolation
- Parallel development

### Recommended Worktree Setup: Siblings Approach
Keep worktrees as siblings in the same parent directory for easy navigation:

```bash
~/repos/personal/
├── macbook-dev-setup/          # Main working copy
├── macbook-dev-setup.review/   # Worktree for PR reviews
├── macbook-dev-setup.hotfix/   # Worktree for urgent fixes
└── macbook-dev-setup.test/     # Worktree for testing
```

### Basic Worktree Commands
```bash
# Create a new worktree as a sibling
gwa ../macbook-dev-setup.review pr-123
# Or: git worktree add ../macbook-dev-setup.review pr-123

# Quick setup of standard worktrees
setup_worktrees  # Creates .review and .hotfix worktrees

# List all worktrees
gwl
# Or: git worktree list

# Remove a worktree
gwr ../macbook-dev-setup.review
# Or: git worktree remove ../macbook-dev-setup.review

# Clean up stale worktrees
gwp
# Or: git worktree prune
```

### Quick Navigation
```bash
# Switch to specific worktrees
gw main    # Go to main repo (no suffix)
gw review  # Go to .review worktree
gw hotfix  # Go to .hotfix worktree
gw test    # Go to .test worktree

# Interactive switcher (requires fzf)
gwcd       # Shows all sibling worktrees with their branches
```

### Worktree Best Practices
1. **Sibling Structure**: Keep worktrees as siblings with `.purpose` suffix
2. **Clear Purpose**: Name worktrees by their use (review, hotfix, test)
3. **Clean Up**: Remove worktrees when done to avoid clutter
4. **One Task Per Worktree**: Don't mix unrelated work

## Branch Cleanup

### Cleaning Up Stale Branches
After merging PRs or when remote branches are deleted, you'll accumulate local branches that track non-existent remotes. Clean them up with:

```bash
# Interactive cleanup (recommended)
gclean              # Shows branches to delete, asks for confirmation
gclean --force      # Skip confirmation (careful!)

# Just prune remote references
gprune              # Same as: git remote prune origin

# The manual way (what gclean does for you)
git remote prune origin
git branch -vv | grep ": gone]" | awk '{print $1}' | xargs git branch -d
```

### When to Clean Branches
- After merging pull requests
- When switching between projects
- As part of weekly maintenance
- Before creating new features

### Branch Cleanup Best Practices
1. **Regular Maintenance**: Run `gclean` weekly to keep your repo tidy
2. **Safe by Default**: `gclean` tries safe delete first, prompts for force delete
3. **Review Before Delete**: Always check what will be deleted
4. **Keep Important Work**: Don't force delete unmerged branches with uncommitted work

### VS Code Tip
Create a workspace file to see all worktrees at once:
```json
{
    "folders": [
        { "path": "macbook-dev-setup", "name": "Main" },
        { "path": "macbook-dev-setup.review", "name": "Review" },
        { "path": "macbook-dev-setup.test", "name": "Test" }
    ]
}
```

## Graphite CLI (Stacked PRs)

### What is Graphite?
Graphite enables "stacked pull requests" - breaking large changes into small, reviewable pieces that depend on each other.

### Core Graphite Commands
```bash
# Create a new branch in the stack
gt create -m "feat: add user API"

# Submit current branch (or stack) as PR(s)
gt submit              # Current branch only
gt submit --stack      # Entire stack (alias: gt ss)

# Sync with remote (pull, rebase, cleanup)
gt sync

# Modify any branch in the stack
gt modify --commit -m "fix: address review feedback"

# Navigate the stack
gt up                  # Go to parent branch
gt down                # Go to child branch
gt log                 # Visualize the stack
```

**Note**: Graphite provides git passthrough - commands like `gt add` or `gt status` work even though they're not native Graphite commands. They're automatically passed to git.

### Stacked PR Example
```bash
# Start from main
gt sync

# Create first PR: Database changes
gt create -m "feat: add user table migration"
# Make changes...
git add .
gt modify --commit -m "feat: add user table migration"

# Create second PR: Backend API (depends on first)
gt create -m "feat: add user CRUD API"
# Make changes...
git add .
gt modify --commit -m "feat: add user CRUD API"

# Create third PR: Frontend (depends on second)
gt create -m "feat: add user management UI"
# Make changes...
git add .
gt modify --commit -m "feat: add user management UI"

# Submit all as stacked PRs
gt submit --stack

# If reviewer requests changes to the database PR
gt checkout add-user-table-migration
# Make changes...
gt modify --commit -m "fix: add index to user email"
gt submit --stack  # Updates all affected PRs
```

### Benefits of Stacked PRs
- **Smaller Reviews**: Each PR is focused and easy to review
- **Faster Iteration**: Don't wait for entire feature to be ready
- **Clear Dependencies**: Graphite manages the rebase chain
- **Parallel Reviews**: Multiple PRs can be reviewed simultaneously

## Combining Worktrees with Graphite

### Advanced Workflow Example
```bash
# Main development in primary worktree
cd ~/repos/personal/macbook-dev-setup
gt create -m "feat: add docker support"
# Working on your stacked PRs...

# Need to review a PR? Switch to review worktree
gw review  # Or: cd ../macbook-dev-setup.review
gh pr checkout 123
# Review and test the PR

# Urgent hotfix needed? Switch to hotfix worktree
gw hotfix  # Or: cd ../macbook-dev-setup.hotfix
git checkout -b fix/critical-bug
# Fix the bug, push, create PR

# Back to feature development
gw main  # Or: cd ../macbook-dev-setup
# Your feature stack is still there, untouched
```

### Real Example with This Project
```bash
# Setup worktrees first
cd ~/repos/personal/macbook-dev-setup
setup_worktrees

# Main: Working on new feature with stacked PRs
gt create -m "feat: add terraform support"
# ... work on feature ...

# Review: Team member's PR needs testing
gw review
gh pr checkout 156
./setup.sh preview  # Test their changes

# Test: Verify setup works on clean system
gw test
git checkout main
./setup.sh minimal  # Test minimal install

# Back to feature work
gw main
gt submit --stack  # Submit your stack
```

## Conventional Commits

### Quick Reference
```bash
# Interactive commit helper
gci

# Quick commits with type
gcft "add user authentication"     # feat: add user authentication
gcfx "resolve login bug"           # fix: resolve login bug

# Scoped commits
gcfs auth "add JWT validation"     # feat(auth): add JWT validation
gcxs api "handle null response"     # fix(api): handle null response
```

### Commit Types
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Code style (formatting)
- `refactor`: Code refactoring
- `perf`: Performance improvement
- `test`: Test changes
- `build`: Build system changes
- `ci`: CI/CD changes
- `chore`: Maintenance tasks

## Tips & Tricks

### 1. Always Sync First
```bash
gt sync  # Start your day with this
```

### 2. Keep Stacks Small
- Aim for 2-4 PRs per stack
- Each PR should be <200 lines

### 3. Use Worktrees for Context Switching
- Don't stash/unstash constantly
- Keep separate worktrees for different contexts

### 4. Name Branches Clearly
```bash
# Good
feat/user-authentication
fix/login-redirect-bug
chore/update-dependencies

# Bad
feature1
fix-stuff
my-branch
```

### 5. Clean Up Regularly
```bash
gwl          # Check active worktrees
gwp          # Prune stale ones
gt sync      # Clean merged branches
```
