---
name: init-project
description: Bootstrap agentic workflow in a project directory. Supports project types (shell, web) for type-specific skills and hooks.
disable-model-invocation: true
argument-hint: "[target-directory] [--type shell|web]"
allowed-tools: Bash, Read, Write
---

# Initialize Agentic Workflow

Bootstrap a full agentic project: git repo, CLAUDE.md, README, agents, skills, and settings.

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
   - `CLAUDE.md` (from template if not present)
   - `README.md` (skeleton if not present)
   - `.claude/agents/` (researcher, planner, implementer, reviewer)
   - `.claude/skills/` (base + type-specific skills)
   - `.claude/settings.json` (type-specific hooks, merged with existing)
   - `.claude-agents.json` (only if not present)

3. Remind the user to customize `CLAUDE.md` for their project.

## Project Types

| Type | Skills | Hook |
|---|---|---|
| (none) | security-review, commit-review, deep-research | base settings |
| `--type shell` | + shell-conventions | shellcheck on .sh edits |
| `--type web` | + typescript-conventions, web-review | tsc --noEmit on .ts/.tsx edits |
