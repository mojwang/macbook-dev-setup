# macbook-dev-setup

Automated macOS dev environment setup for Apple Silicon.

## Quick Start
```bash
./setup.sh              # Full setup
./setup.sh preview      # Dry run
./setup.sh minimal      # Essentials only
./setup.sh help         # All options
```

## Project Rules
1. Shell scripts: Use `#!/usr/bin/env bash` shebang (NOT `#!/bin/bash`), `set -e`, 30s timeouts, signal-safe cleanup
2. Test new features with TDD (see docs/TESTING.md)
3. Backup before system changes
4. Use modular zsh config in `.config/zsh/`

## Git Workflow
- **Worktrees**: Siblings with `.purpose` suffix (e.g., `macbook-dev-setup.review`)
- **Quick switch**: `gw main`, `gw review`, `gw hotfix`, or `gwcd` for interactive
- **Stacked PRs**: `gt` (Graphite CLI) for dependent changes
- **Commits**: `gc*` aliases for conventional format
- See `docs/GIT-WORKFLOW.md` for details

## Git Rules
- **Auto-commit complete work**: Automatically add and commit when finishing logical units (features, fixes, refactors)
- **Descriptive messages**: Capture full scope of changes, not just the main change
- **Smart commit timing**: 
  - ✅ Commit: Complete features, verified fixes, finished refactors, finalized configs
  - ❌ Wait: Sub-tasks, failing tests, incomplete changes, experimental work
- **Conventional format**: Use `type(scope): description` for this project (feat, fix, docs, etc.)
- **Message examples**:
  - `feat(setup): add Homebrew installation with retry logic and error handling`
  - `fix(git): resolve worktree navigation for non-existent directories`

## Key Directories
- `/lib`: Core libraries (common.sh, signal-safety.sh)
- `/scripts`: Component installers and utilities
- `/dotfiles`: Shell configs and dotfiles
- `/docs`: Detailed documentation

## Commands Overview
- **Setup**: preview, minimal, fix, warp, backup, info
- **Git**: gci (interactive commit), gcft (feat commit)
- **Info**: devhelp (tools/aliases reference)

## Testing
```bash
./tests/run_tests.sh [unit|integration|ci]
```

## Documentation
- [Commands](docs/COMMANDS.md) - All commands and options
- [Testing](docs/TESTING.md) - Testing philosophy and guide
- [Architecture](docs/architecture.md) - System design
- [Git Workflow](docs/GIT-WORKFLOW.md) - Worktrees & Graphite
- [MCP Servers](docs/MCP_SERVERS.md) - Claude integrations
- [Claude Agents](docs/CLAUDE_AGENTS.md) - Sub-agent architecture

## Agent Workflows for This Project

### Shell Script Development:
1. **Create/Modify** → Shell Script Agent (validation)
2. **Security Check** → Security Agent (scan for vulnerabilities)  
3. **Test** → Quality Agent (run tests)
4. **Optimize** → Performance Agent (if needed)

### Dependency Updates:
1. **Scan** → Dependency Agent (check for updates)
2. **Apply** → Development Agent (update files)
3. **Validate** → Configuration Agent (check compatibility)
4. **Test** → Quality Agent (ensure nothing breaks)

### MCP Server Issues:
1. **Debug** → MCP Integration Agent (diagnose issues)
2. **Fix** → Development Agent (apply fixes)
3. **Test** → Quality Agent (verify connections)

### Performance Issues:
1. **Profile** → Performance Agent (identify bottlenecks)
2. **Optimize** → Shell Script Agent (improve code)
3. **Benchmark** → Performance Agent (verify improvements)

## Important
- Do only what's asked; nothing more
- Check CI before merging: requires passing tests
- Version tracked in `VERSION` file
- Use specialized agents for complex tasks (see docs/CLAUDE_AGENTS.md)