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
1. Shell scripts: `set -e`, 30s timeouts, signal-safe cleanup
2. Test new features with TDD (see docs/TESTING.md)
3. Backup before system changes
4. Use modular zsh config in `.config/zsh/`

## Git Workflow
- **Worktrees**: Siblings with `.purpose` suffix (e.g., `macbook-dev-setup.review`)
- **Quick switch**: `gw main`, `gw review`, `gw hotfix`, or `gwcd` for interactive
- **Stacked PRs**: `gt` (Graphite CLI) for dependent changes
- **Commits**: `gc*` aliases for conventional format
- See `docs/GIT-WORKFLOW.md` for details

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

## Important
- Do only what's asked; nothing more
- Check CI before merging: requires passing tests
- Version tracked in `VERSION` file