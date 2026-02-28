# Claude Global Config v2.0

## Core Principles
- Be direct and concise
- Test-driven development by default
- Security-first approach
- Match existing project patterns

## Git Workflow
- Feature branches only
- Small commits (<200 LOC diffs)
- Conventional commit format: `<type>(<scope>): <subject>` (types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert)
- Create PR unless told otherwise
- Git pager is `delta` with side-by-side diff enabled

## Development Standards
- Shell scripts: Use `#!/usr/bin/env bash` (NOT `#!/bin/bash`)
- Fail-fast: `set -e` in shell scripts
- Clean up after interruptions
- Backup before system changes
- Follow project conventions

## Behavior
- Do only what's asked
- Prefer editing over creating files
- Never create docs unless requested
- Ask for clarification when blocked

## Environment
- macOS Apple Silicon, zsh with modular config in `~/.config/zsh/`
- Projects live in `~/repos/netflix/` (work) and `~/repos/personal/` (personal)
- Dev setup managed by `~/repos/personal/macbook-dev-setup/`
- Language managers: nvm (Node.js, lazy-loaded), pyenv (Python), rbenv (Ruby), sdkman (Java/JVM)
- Java: OpenJDK via Homebrew (`$JAVA_HOME = $HOMEBREW_PREFIX/opt/openjdk`)
- Modern CLI tools: eza (ls), bat (cat), fd (find), fzf (fuzzy finder), zoxide (cd), delta (diff), starship (prompt), ripgrep (grep), tokei (loc), hyperfine (bench), ast-grep
- Editor: nvim (default `$EDITOR`), VS Code available
- Netflix tooling: Metatron (auth/certs), Newt (build tool), gh CLI with corporate wrapper (`ghrepo`)

## Important
When global CLAUDE.md updates, sync to macbook-dev-setup project.
