---
name: init-project
description: Bootstrap agentic workflow in a project directory. Creates .claude/agents/, .claude/skills/, settings.json, and .claude-agents.json from templates.
disable-model-invocation: true
argument-hint: "[target-directory]"
allowed-tools: Bash, Read, Write
---

# Initialize Agentic Workflow

Bootstrap the agentic workflow (agents, skills, settings) in a project directory.

## Steps

1. Run the init command:
```bash
claude-init-agentic --init $ARGUMENTS
```

If `claude-init-agentic` is not in PATH, fall back to:
```bash
~/.local/bin/claude-init-agentic --init $ARGUMENTS
```

If neither exists, run directly from the macbook-dev-setup repo:
```bash
~/repos/personal/macbook-dev-setup/scripts/setup-claude-agentic.sh --init $ARGUMENTS
```

2. Report what was created or updated.

3. Remind the user to review `.claude/settings.json` and customize for their project.
