# Branch Protection & Merge Strategy

## Overview

This project uses a **solo developer + AI agent** workflow optimized for velocity. Branch protection is enforced conventionally through CI checks and Claude Code review rather than GitHub branch protection rules (which require paid plans for private repos).

## Merge Strategy: Squash-Only

All PRs merge via **squash merge** only. This is enforced at the GitHub repo level.

- **Why squash**: Clean linear history on main. Feature branch commits (WIP, fixups, checkpoint commits from agents) get collapsed into one meaningful commit.
- **Squash message source**: PR title becomes the commit message, PR body becomes the extended description.
- **Branch cleanup**: Feature branches auto-delete after merge (GitHub repo setting).

## PR Lifecycle

```
feature branch → push → CI runs → Claude reviews → auto-merge (squash)
```

### 1. CI Pipeline (`.github/workflows/ci.yml`)
All status checks must pass:
- `test` — Full test suite
- `validate-documentation` — Markdown validation
- `security-scan` — Secret detection
- `agent-tests` — Agent definition validation
- `all-checks-pass` — Summary gate

### 2. Claude Review (`.github/workflows/claude-review.yml`)
Triggered on `pull_request: [opened, synchronize]`:
- Reviews code quality, security, shell best practices
- Pushes fix commits directly if issues are auto-fixable
- Comments "LGTM — ready to merge" if clean

### 3. Auto-Merge
After Claude review passes, the `auto-merge` job runs:
```yaml
gh pr merge ${{ github.event.pull_request.number }} --auto --squash
```

No manual approval needed. CI + Claude review are the quality gates.

## Conventional Enforcement (No GitHub Branch Protection)

Since GitHub branch protection requires paid plans for private repos, these rules are enforced by convention:

| Rule | Enforcement |
|------|-------------|
| No direct commits to main | `git-safe-commit.sh` pre-commit hook |
| Feature branches required | CLAUDE.md rules + hook |
| CI must pass | Required status checks (when configured) |
| Squash-only merge | GitHub repo setting (merge commit/rebase disabled) |
| No force pushes to main | CLAUDE.md rules (agents obey) |
| Code review | Claude Code Action (automated) |

## Rebase Strategy

- **Feature branches**: Rebase onto main before merge to keep history clean. The squash merge makes this less critical since commits get collapsed anyway.
- **Stacked PRs (Graphite)**: Graphite manages the rebase chain automatically.
- **Conflict resolution**: Rebase feature branch onto main, resolve conflicts, force-push the feature branch (never force-push main).

## Emergency Procedures

### Revert a Bad Merge
```bash
# Create a revert commit (never force-push main)
git revert HEAD
git push origin main
```

### Fix Broken Main
```bash
git checkout -b fix/broken-main
# Fix the issue
git push origin fix/broken-main
# Create PR — CI + Claude will review
```

## GitHub Repo Settings

Configured via `gh api`:
- Squash merge only (merge commit and rebase disabled)
- Squash commit message: PR title + body
- Auto-delete head branches after merge
- Wiki and projects disabled (not needed)

## Authentication

### SSH (Recommended)
```bash
ssh -T git@github.com
```

### GitHub CLI
```bash
gh auth login
gh auth status
```
