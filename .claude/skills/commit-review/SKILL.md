---
name: commit-review
description: Commit and PR review checks for conventional commit format, diff size limits, branch verification, and secret detection. Use before creating git commits, pull requests, or when reviewing staged changes.
user-invocable: false
allowed-tools: Read, Grep, Glob, Bash
---

# Commit Review Skill

## Scripts
Run mechanical checks before review:
- `scripts/verify-branch.sh` — reject commits on protected branches (main, master, etc.)
- `scripts/check-staged-files.sh` — detect secrets, credentials, and large binaries in staged files

## Checks

### Conventional Commit Format
Commit messages MUST follow: `type(scope): description`

Valid types: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `style`, `perf`, `ci`, `build`

Examples:
- `feat(agents): add agent teams support with tmux visibility`
- `fix(git): enforce feature branch workflow for all commits`
- `docs(mcp): update server configuration guide`

### Diff Size
- Warn if staged diff exceeds 200 LOC
- Suggest splitting into smaller, focused commits
- Each commit should be a single logical change

### Branch Verification
- NEVER commit to `main` — verify with `git branch --show-current`
- Branch must use valid prefix: `feat/`, `fix/`, `docs/`, `chore/`, `refactor/`, `test/`

### Content Checks
- No secrets, API keys, or credentials in diff
- No `.env` files or private keys staged
- No large binaries or generated files
- No commented-out code blocks (delete instead)

### PR Checklist
When creating a PR, remind to:
- Add reviewer (repo owner or REVIEWER from `.personal/config.sh`)
- Add Copilot reviewer via GitHub UI
- Include test plan in PR description
- Reference related issues if applicable
- Ensure CI passes before requesting review

### Decision-record detection (Pillar 12)

Conservative heuristic — fires only when the diff matches one of these signals. Defaults to silent. Skip the prompt for typo fixes, formatting passes, dependency security patches.

**Signals (any one fires):**
- New runtime dependency: addition in `dependencies` (or `dev-dependencies`) block of `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `Gemfile`
- Removed feature: deletion of files under `src/`, `lib/`, vault `_meta/`, vault domain dirs (`vault/career/`, `vault/wealth/`, `vault/health/`)
- Infrastructure change: edits to `Dockerfile`, `.github/workflows/*`, `vercel.ts`, `next.config.ts`, `vercel.json`
- Refactor with diff size >200 LOC across ≥3 files

**When a signal fires, surface to Marvin:**

> *This commit looks like a non-trivial decision (signal: `<which pattern matched>`). Capture a decision-record so the outcome can be tracked.*
>
> *One-liner from your CLAUDE.md (workspace § Cross-repo decision capture):*
> ```bash
> WS="${SECOND_BRAIN_HOME:-$HOME/ai/workspace/claude}"
> slug="<short-kebab-slug>"
> date=$(date +%Y%m%d)
> # ... (point to full snippet)
> ```
>
> *Skip if this isn't actually a decision (refactor for clarity, dep update for security patch).*

The check is non-blocking. Marvin acknowledges or skips. Closes Pillar 6's final mile by making the capture trigger automatic at commit time rather than relying on memory.
