---
name: init-project
description: Bootstrap agentic workflow in a project directory. Initializes git, creates CLAUDE.md and README.md from templates, and deploys .claude/agents/, .claude/skills/, settings.json, and .claude-agents.json.
disable-model-invocation: true
argument-hint: "[target-directory]"
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
# (the symlink points to the actual repo, so readlink resolves across machines)
"$(dirname "$(readlink ~/.local/bin/claude-init-agentic)")/setup-claude-agentic.sh" --init $ARGUMENTS
```

2. Report what was created or updated:
   - Git repository (initialized if new)
   - `CLAUDE.md` (from template if not present)
   - `README.md` (skeleton if not present)
   - `.claude/agents/` (researcher, planner, implementer, reviewer)
   - `.claude/skills/` (security-review, shell-conventions, commit-review)
   - `.claude/settings.json` (merged with existing)
   - `.claude-agents.json` (only if not present)

3. Remind the user to customize `CLAUDE.md` for their project:
   - Replace `{{PROJECT_NAME}}` with the actual project name
   - Fill in `{{DESCRIPTION}}`, `{{STACK_DESCRIPTION}}`, `{{LANGUAGE_CONVENTIONS}}`
   - Update `{{DIRECTORY_MAP}}` and `{{TEST_COMMAND}}`
   - Review `.claude/settings.json` for project-specific needs
