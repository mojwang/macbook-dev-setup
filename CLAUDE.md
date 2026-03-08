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

## Agentic Workflow (Default)
The main Claude session acts as orchestrator. It never implements directly for complex tasks — it dispatches sub-agents from `.claude/agents/` and synthesizes results.

### Task Classification (decide first)
- **Async/autonomous**: Peripheral features, prototyping, tests, refactors → full agent workflow, let it run
- **Sync/supervised**: Core logic, critical fixes, security-sensitive → work interactively, supervise closely
- **Trivial**: Single-file edits, quick fixes → skip workflow, implement directly

### Phase 1: Research
Dispatch `researcher` sub-agent to explore affected code areas.
- Run multiple researchers in parallel for independent areas
- Output: `research.md` with findings
- Skip for trivial tasks or well-understood areas

### Phase 2: Plan
Dispatch `planner` sub-agent to create `plan.md` from research.
- Annotation cycle: user adds `NOTE:` or `Q:` inline → re-run planner to address
- Iterate 1-3 rounds until plan is approved
- Each task in the plan should be scoped for a single implementer

### Phase 3: Implement (Agent Teams)
Dispatch `implementer` sub-agents with the approved plan.
- **Parallel execution**: Split independent tasks across multiple implementers
  - Example: one implements feature code, another writes tests
  - Each works in worktree isolation on its own branch
- **Self-sufficient loops**: Each implementer runs tests after every change
- **Checkpoint commits**: Commit after each completed task (enables rollback)
- **Slot machine rule**: If an implementer goes off track, revert and restart fresh rather than fixing
- **Always worktree-isolated**: Every implementer runs in its own worktree, no exceptions

### Phase 4: Verify
Dispatch `reviewer` sub-agent to validate implementation.
- Must pass before creating PR
- Can run security + quality reviewers in parallel

### Orchestration Rules
- Main session = orchestrator. Dispatches agents, never implements complex tasks itself.
- Subagents cannot spawn other subagents — all coordination flows through orchestrator
- Persistent artifacts (research.md, plan.md) survive context compaction
- Clean up artifacts after PR merge
- **End-of-session improvement**: Before session ends, Claude must suggest CLAUDE.md improvements based on what worked/didn't. User decides whether to apply.

## Key Directories
- `/lib`: Core libraries (common.sh, signal-safety.sh)
- `/scripts`: Component installers and utilities
- `/dotfiles`: Shell configs and dotfiles
- `/docs`: Detailed documentation
- `/.claude/agents`: Native sub-agent definitions

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

## Agent Architecture
- `.claude/agents/`: Native sub-agents (researcher, planner, implementer, reviewer)
- `.claude-agents.json`: Declarative config (capabilities, triggers, quality gates, workflows)
- `scripts/claude-agents/`: Helper scripts (which-agent, benchmarks, demo)
- `docs/CLAUDE_AGENTS.md`: Full agent documentation

## Important
- Do only what's asked; nothing more
- Check CI before merging: requires passing tests
- Version tracked in `VERSION` file
- Use specialized agents for complex tasks (see docs/CLAUDE_AGENTS.md)