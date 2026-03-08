# Commit Review Skill

Auto-invoked when preparing commits, creating PRs, or reviewing diffs.

## When to Activate
- Before creating a git commit
- Before creating a pull request
- When reviewing staged changes

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
- Add reviewer: `mojwang`
- Add Copilot reviewer via GitHub UI
- Include test plan in PR description
- Reference related issues if applicable
- Ensure CI passes before requesting review
