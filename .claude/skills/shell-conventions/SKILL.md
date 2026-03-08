---
name: shell-conventions
description: Shell script conventions for bash and zsh. Enforces shebang, set -e, timeouts, signal-safe cleanup, and variable quoting. Use when creating, editing, or reviewing .sh, .bash, or .zsh files.
user-invocable: false
allowed-tools: Read, Grep, Glob
---

# Shell Conventions Skill

## Required Conventions

### Script Header
Every bash script MUST start with:
```bash
#!/usr/bin/env bash
set -e
```
- Use `#!/usr/bin/env bash` — NEVER `#!/bin/bash`
- `set -e` for fail-fast behavior

### Timeouts
- External commands (curl, wget, git clone): 30s timeout
- Example: `curl --max-time 30` or `timeout 30 command`

### Signal-Safe Cleanup
Scripts that create temp files or acquire resources MUST use cleanup traps:
```bash
cleanup() {
  # cleanup logic
}
trap cleanup EXIT INT TERM
```

### Variable Quoting
- Always quote variables: `"$var"` not `$var`
- Use `"${var:-default}"` for defaults
- Arrays: `"${array[@]}"` not `${array[@]}`

### Zsh Config
- Modular zsh config lives in `.config/zsh/`
- Numbered prefix for load order (e.g., `01-path.zsh`, `51-api-keys.zsh`)
- Never modify `~/.zshrc` directly — add modules to `.config/zsh/`

### Error Handling
- Check command existence: `command -v tool >/dev/null 2>&1`
- Validate inputs before use
- Provide clear error messages to stderr: `echo "Error: ..." >&2`

### Style
- Use `[[ ]]` for conditionals (not `[ ]`)
- Use `$(command)` for substitution (not backticks)
- Functions: `func_name() {` format
- Local variables in functions: `local var="value"`
