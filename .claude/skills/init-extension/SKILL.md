---
name: init-extension
description: Scaffold a new macbook-dev-setup extension pack with install.sh, profile.conf, CI, tests, and CLAUDE.md.
disable-model-invocation: true
argument-hint: "<name> [target-dir]"
allowed-tools: Bash, Read
---

# Scaffold Extension Pack

Create a new macbook-dev-setup extension pack with full directory structure.

## Steps

1. Run the scaffold command (try in order until one works):
```bash
# Option 1: symlink in PATH
scaffold-extension $ARGUMENTS

# Option 2: symlink at known location
~/.local/bin/scaffold-extension $ARGUMENTS

# Option 3: resolve from symlink target's repo
"$(dirname "$(readlink ~/.local/bin/scaffold-extension)")/../scripts/scaffold-extension.sh" $ARGUMENTS
```

2. Report what was created:
   - Git repository (initialized)
   - `install.sh` (symlinks to `~/.config/macbook-dev-setup.d/<name>/`)
   - `profile.conf` (package adds/excludes, inherits from base profile)
   - `CLAUDE.md` (project rules and conventions)
   - `scripts/setup.sh` (extension-specific tool installation)
   - `dotfiles/.config/zsh/` (modular zsh config)
   - `claude/global-claude-overlay.md` (Claude environment overlay)
   - `claude/plugins.conf` (additional Claude plugins)
   - `tests/run_tests.sh` + `tests/test_framework.sh` (test runner and assertions)
   - `.github/workflows/ci.yml` (shellcheck + test + security-scan + all-checks-pass)

3. Remind the user to:
   - Edit `profile.conf` to configure package adds/excludes
   - Add setup logic to `scripts/setup.sh`
   - Add zsh config files to `dotfiles/.config/zsh/`
   - Create a remote repo and push
   - Run `./setup.sh` to activate the extension
