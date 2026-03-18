---
name: init-project
description: Bootstrap agentic workflow in a project directory. Supports project types (shell, web) for type-specific skills and hooks.
disable-model-invocation: true
argument-hint: "[target-directory] [--type shell|web]"
allowed-tools: Bash, Read, Write
---

# Initialize Agentic Workflow

Bootstrap a full agentic project: git repo, CLAUDE.md, README, agents, skills, CI, and settings.

## Steps

1. Run the init command (try in order until one works):
```bash
# Option 1: symlink in PATH
claude-init-agentic --init $ARGUMENTS

# Option 2: symlink at known location
~/.local/bin/claude-init-agentic --init $ARGUMENTS

# Option 3: resolve from symlink target's repo
"$(dirname "$(readlink ~/.local/bin/claude-init-agentic)")/setup-claude-agentic.sh" --init $ARGUMENTS
```

2. Report what was created or updated:
   - Git repository (initialized if new)
   - `CLAUDE.md` (from template — enforced git workflow, CI section)
   - `README.md` (skeleton if not present)
   - `.claude/agents/` (product-tactician, researcher, planner, implementer, reviewer, designer)
   - `.claude/skills/` (base + type-specific skills)
   - `.claude/settings.json` (type-specific hooks, merged with existing)
   - `.claude-agents.json` (only if not present)
   - `.github/workflows/ci.yml` (type-specific CI with All Checks Pass gate)
   - `.github/workflows/claude-review.yml` (Claude review + Copilot reconciliation + auto-merge)
   - `.github/workflows/request-reviewers.yml` (auto-request repo owner as reviewer)
   - `.github/workflows/ci-health.yml` (weekly secret validity check)
   - `.github/setup-github-repo.sh` (configure ruleset after repo creation)
   - `.github/pull_request_template.md` (standardized PR format)
   - `.gitignore` (type-specific ignore patterns)
   - `.editorconfig` (consistent formatting)
   - `.nvmrc` (Node.js version, web only)

3. Remind the user to:
   - Customize `CLAUDE.md` for their project (fill in `{{PLACEHOLDER}}` values)
   - After `gh repo create --source=. --push`, run: `.github/setup-github-repo.sh [--type shell|web]`
   - Add `ANTHROPIC_API_KEY` or `CLAUDE_CODE_OAUTH_TOKEN` secret in GitHub repo settings
   - Enable Copilot auto-review in GitHub: Settings > Code review > Copilot (non-blocking)

## Project Types

| Type | Skills | Hook | CI Jobs |
|---|---|---|---|
| (none) | security-review, commit-review, deep-research | base settings | — |
| `--type shell` | + shell-conventions | shellcheck on .sh edits | test, shellcheck, security-scan, All Checks Pass |
| `--type web` | + typescript-conventions, web-review, design-review, design-elevation | tsc --noEmit on .ts/.tsx edits | test, lint, typecheck, build, All Checks Pass |

## Claude Review Auth Options

| Secret | Billing | Use when |
|---|---|---|
| `ANTHROPIC_API_KEY` | Per-project API billing | Dedicated budget per repo |
| `CLAUDE_CODE_OAUTH_TOKEN` | Managed via claude.ai | Shared billing across repos |
