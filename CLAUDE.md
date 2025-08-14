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

## Git Workflow (ENFORCED)
- **Feature branches required**: ALL changes, no exceptions
- **Worktrees mandatory**: Complex features (3+ files or multi-step)
- **Auto-commit allowed**: Only on feature branches
- **PR creation**: Manual after feature complete
- **Branch protection**: Main branch is read-only for Claude
- **Quick switch**: `gw main`, `gw review`, `gw hotfix`, or `gwcd` for interactive
- **Stacked PRs**: `gt` (Graphite CLI) for dependent changes
- See `docs/GIT-WORKFLOW.md` for details

## Git Rules (STRICT)
- **NEVER commit to main**: Always check branch first with `git branch --show-current`
- **Branch naming**: feat/, fix/, docs/, chore/, refactor/, test/
- **Auto-commit complete work**: Only on feature branches
- **Descriptive messages**: Capture full scope of changes
- **Smart commit timing**: 
  - ✅ Commit: Complete features, verified fixes, finished refactors
  - ❌ Wait: Sub-tasks, failing tests, incomplete changes
- **Conventional format**: Use `type(scope): description`
- **Examples**:
  - `feat(agents): evolve TaskMaster into Product Manager with discovery workflows`
  - `fix(git): enforce feature branch workflow for all commits`

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

## MCP Server Priority
1. **Context7**: Library docs, code examples, API references (check first)
2. **Taskmaster**: Direct task management commands via MCP
3. **Exa**: General web research (fallback for non-code queries)

Note: For product discovery and PRD workflows, use "Product Manager" as a sub-agent via the Task tool

## Taskmaster/Product Manager Configuration
- **As "taskmaster" MCP Server**: Direct task commands (`task-master list`, `task-master next`)
- **As "Product Manager" Sub-Agent**: Product discovery, PRD parsing, customer validation via Task tool
- **Research**: Enabled if PERPLEXITY_API_KEY set, gracefully disabled otherwise
- To enable research: Add `export PERPLEXITY_API_KEY="your-key"` to `~/.config/zsh/51-api-keys.zsh`
- **Naming Convention**: "taskmaster" for MCP operations, "Product Manager" for agent workflows

## Agent Workflows for This Project

### Complex Project Implementation:
1. **Product Manager Agent** → Discovery, validate, prioritize
2. **Development Agent** → Implement features
3. **Quality Agent** → Test implementation
4. **Documentation Agent** → Update docs

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