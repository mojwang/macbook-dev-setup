# Claude Global Config v2.3.0

## Core Principles
- Be direct and concise
- Specification-first testing (test behavior, not implementation)
- Security-first approach
- Match existing project patterns

## Git Workflow
- Feature branches only (never commit to main)
- Small commits (<200 LOC diffs)
- Conventional commit format: `<type>(<scope>): <subject>` (types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert)
- Squash-only merges for clean linear history
- Auto-merge: PRs auto-merge when CI + Claude review pass
- Create PR unless told otherwise
- Git pager is `delta` with side-by-side diff enabled

## Development Standards
- Shell scripts: Use `#!/usr/bin/env bash` (NOT `#!/bin/bash`)
- Fail-fast: `set -e` in shell scripts
- Write and update comments explaining *why*, not *what* — they serve both human readers and future agent sessions
- Clean up after interruptions
- Backup before system changes
- Follow project conventions

## Boundaries

**Always** (do without asking):
- Run tests after changes
- Follow project conventions and naming patterns
- Use feature branches, checkpoint commits

**Ask first**:
- Adding new dependencies
- Schema or architecture changes
- Deleting files or removing features

**Never**:
- Commit to main
- Commit secrets, .env, or API keys
- Remove failing tests without approval
- Force push or skip CI checks

## Behavior
- Do only what's asked
- Prefer editing over creating files
- Never create docs unless requested
- Ask for clarification when blocked
- For complex tasks (3+ files), use Research→Plan→Implement sub-agent pattern
- Write findings and plans to persistent markdown before implementing
- Write tests BEFORE implementation when agents implement autonomously
- Git revert is the safety net; move fast and break nothing
- If something goes sideways during implementation, STOP and re-plan — don't push through a failing approach
- After receiving a correction, save the lesson to memory to prevent repeating the same mistake

## Workflow Orchestration

### Plan Mode
- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- Write detailed specs upfront to reduce ambiguity
- If something goes sideways, STOP and re-plan immediately
- Use plan mode for verification steps, not just building

### Subagent Strategy
- Use subagents liberally to keep main context window clean
- Offload research, exploration, and parallel analysis to subagents
- One task per subagent for focused execution
- For complex problems, throw more compute at it via subagents

### Autonomous Bug Fixing
- When given a bug report: just fix it — don't ask for hand-holding
- Point at logs, errors, failing tests — then resolve them
- Zero context switching required from the user
- Go fix failing CI tests without being told how

## Task Management
1. **Plan First**: Write plan with checkable items before implementing
2. **Verify Plan**: Check in with user before starting implementation
3. **Track Progress**: Mark items complete as you go
4. **Explain Changes**: High-level summary at each step
5. **Document Results**: Add review notes to the plan
6. **Capture Lessons**: After ANY correction, save the lesson to memory so the mistake isn't repeated

## Quality Standards
- **Simplicity First**: Make every change as simple as possible. Minimal code impact.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.
- **Minimal Impact**: Only touch what's necessary. No side effects or new bugs.
- **Verification Before Done**: Never consider a task complete without proving it works — run tests, check logs, diff against main when relevant
- **Demand Elegance**: For non-trivial changes, pause and ask "is there a more elegant way?" Challenge your own work before presenting it. Skip this for simple, obvious fixes.
- **Resist Homogenization**: Push back on generic AI-flavored patterns. Favor distinctive, intentional design choices over safe defaults.
- **Dual-Tier Evaluation**: Regression tests must always pass (behavioral correctness). Frontier checks explore new capabilities and edge cases — run these when adding novel features.

## Environment
- macOS Apple Silicon, zsh with modular config in `~/.config/zsh/`
- Dev setup managed by `~/repos/personal/macbook-dev-setup/`
- Language managers: nvm (Node.js, lazy-loaded), pyenv (Python), rbenv (Ruby), sdkman (Java/JVM)
- Java: SDKMAN (`$SDKMAN_DIR = $HOME/.sdkman`)
- Modern CLI tools: eza (ls), bat (cat), fd (find), fzf (fuzzy finder), zoxide (cd), delta (diff), starship (prompt), ripgrep (grep), tokei (loc), hyperfine (bench), ast-grep
- Editor: nvim (default `$EDITOR`), VS Code available

## Important
When global CLAUDE.md updates, sync to macbook-dev-setup project.
