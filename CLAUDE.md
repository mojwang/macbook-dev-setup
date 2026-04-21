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
2. Test new features with specification-first tests (see docs/TESTING.md)
3. Backup before system changes
4. Use modular zsh config in `.config/zsh/`

## Git Workflow (ENFORCED)
- **Feature branches required**: ALL changes, no exceptions
- **Worktrees mandatory**: Complex features (3+ files or multi-step)
- **Auto-commit allowed**: Only on feature branches
- **PR creation**: Manual after feature complete
- **Auto-merge**: PRs auto-merge when CI + Claude review pass (no manual approval needed)
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

## Output Formatting (Executive Brief Style)
- Plain text for synthesized answers — no blockquote prefix, 2-3 sentences max
- Emoji section labels: 📌 Sources/Findings, 🔗 Patterns/Recommendations, ⚠️ Tensions/Blocking, 🕳️ Gaps, 🎯 Active
- Sources/findings as indented **bold-dash pairs** (no bullets)
- Patterns/Tensions/Gaps as emoji label + bullet points
- **Bold titles** for references in conversation (not `[[wikilinks]]`)
- Tables only for 4+ items across 3+ columns (Scope, Assumptions tables are fine)
- Horizontal rules between major sections

## Boundaries

**Always** (do without asking):
- Run tests after changes, run shellcheck on .sh files
- For web projects: launch dev server and provide links for visual verification before committing — verify in both light and dark mode for themed projects
- Follow naming conventions and project patterns
- Use feature branches, checkpoint commits on feature branches
- Self-sufficient loops: implement → test → fix → commit

**Ask first**:
- Adding new dependencies or dev tools
- Schema or architecture changes
- Deleting files or removing features
- Changes to CI/CD workflows or GitHub Actions

**Never**:
- Commit to main
- Commit secrets, .env files, or API keys
- Remove failing tests without explicit approval
- Force push to any shared branch
- Skip pre-commit hooks or CI checks

## Agentic Workflow (Default)
The main Claude session acts as orchestrator. It never implements directly for complex tasks — it dispatches sub-agents from `.claude/agents/` and synthesizes results.

### Task Classification + Phase Dispatch (ENFORCED)
Classify first, then follow the dispatch table. Do not run phases the task doesn't need.

| Classification | Phases | Skip | Rationale |
|---------------|--------|------|-----------|
| **Trivial** | Implement only | All others | Single-file, obvious fix |
| **Sync/supervised** | Research → Implement → Review | Plan, Product | Core logic, needs human eyes |
| **Async/autonomous** | Research → Plan → Implement → Review | Product | Standard feature work (3+ files) |
| **Design-aware** | Research + Designer → Plan → Implement → Review + Designer | Product | UI/UX changes |
| **Product-first** | Tactician → Research → Plan → Implement → Review | — | Unclear scope, competing priorities |
| **Strategy-first** | Strategist → Tactician → Full pipeline | — | "Should we build this?" |
| **Cross-layer** | Research → Plan (+ api-contract.md) → Implement → Review | — | Frontend + API + DB changes |

### Execution Modes
Two modes available depending on coordination needs:

**Subagents (default)** — focused workers that report back to orchestrator
- Best for: sequential phases, tasks where only the result matters
- Lower token cost (results summarized back)
- Orchestrator manages all coordination

**Agent Teams (experimental)** — independent Claude instances with shared task list
- Best for: parallel implementation, competing hypotheses, cross-layer changes
- Teammates message each other directly, self-claim tasks
- tmux split panes for live visibility (`teammateMode: "tmux"` in `.claude/settings.json`)
- Enable: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` (set in project settings)
- Require plan approval for risky teammates before they implement
- 3-5 teammates max, 5-6 tasks per teammate

See `docs/CLAUDE_AGENTS.md` for the full agentic workflow: phases (-1 through 5), session startup checklist, orchestration rules, and agent definitions.

### Effort Scaling
| Complexity | Agents | Tool calls/agent | Example |
|-----------|--------|-----------------|---------|
| Simple | 1 | 3-10 | Find a function, check a config |
| Medium | 2-4 in parallel | 10-15 | Compare implementations, multi-file research |
| Complex | 5+ subagents | 15-30 | Architecture analysis, cross-repo investigation |
| Massive | Agent teams | Unlimited | Full feature implementation, major refactor |

Start with the minimum. Only scale up when the simpler approach demonstrably fails.

### Post-Merge Cleanup (ENFORCED)
After every PR merge, orchestrator must:
1. **Remove worktrees**: `git worktree remove <path>` for all worktrees created during the task
2. **Delete local branches**: `git branch -D <branch>` for branches whose PRs are merged
3. **Prune remote refs**: `git remote prune origin`
4. **Extract learnings**: Before deleting `claude-progress.md`, review its "Failed approaches" section. Append non-obvious findings to `docs/AGENT_LEARNINGS.md` with the PR number. Skip trivial or project-specific failures.
5. **Version plans**: Move `plan.md` to `docs/exec-plans/completed/[feature-name].md` (add Outcome section). Delete other ephemeral artifacts: `research.md`, `design-spec.md`, `product-brief.md`, `claude-progress.md`, `claude-decisions.md`. Do NOT delete persistent artifacts (`docs/design/decisions.md`, `docs/AGENT_LEARNINGS.md`, audit reports in `docs/design/`).
6. **For agent teams**: Lead shuts down teammates first, then cleans up all worktrees

Shortcut: `gclean` handles steps 2-3 for branches with deleted remotes.

### Integrated Scripts (available to agents)
These scripts have `--agent-mode` or `--force` flags for non-interactive agent use:
- `./scripts/health-check.sh --agent-mode` — concise pre-flight check (critical tools, git identity, MCP health)
- `./scripts/pre-push-check.sh --agent-mode` — pre-merge validation (tests, shellcheck, debugging code, branch safety)
- `./scripts/git-safe-commit.sh` — branch protection enforcement (used by PreToolUse hook)
- `./scripts/cleanup-mcp-processes.sh --force` — kill orphaned MCP processes without confirmation
- `./scripts/cleanup.sh` — disk space cleanup (interactive, for manual use or orchestrator-guided sessions)

## Remote Control
Continue sessions from phone/tablet via [claude.ai/code](https://claude.ai/code) or the Claude mobile app.
- **Enable for this session**: `/remote-control <name>` (or `/rc`)
- **New detached session**: `claude remote-control "<name>"`
- **Always on**: `/config` → "Enable Remote Control for all sessions" → `true`
- Terminal must stay open; reconnects automatically after sleep/network drops
- QR code: press spacebar in `claude remote-control` mode, or scan from `/rc` output

## Plugins
<!-- Agents: discover installed plugins via /plugin list. Only non-obvious notes below. -->
- **TODO**: Evaluate `compound-engineering` plugin for structured multi-agent workflows

## Hooks
Configured in `.claude/settings.json`:

**SessionStart**:
- Git hygiene check: warns about stale branches (remote deleted) and active worktrees
- Environment health check: `./scripts/health-check.sh --agent-mode` — verifies critical tools (git, gh, node, npm, shellcheck, jq), git identity, Homebrew PATH, and MCP process count

**PreToolUse (Bash)**:
- Branch safety gate: blocks `git commit` on protected branches (main, master, develop, staging, production) — exit code 2 prevents the tool call

**PostToolUse (Write|Edit)**:
- Auto-runs `shellcheck` on `.sh` files after every edit
- Supports self-sufficient loops — implementer agents get immediate lint feedback

## Skills
Skills in `.claude/skills/` (core) and `config/skills/` (web, deployed via `/init-project --type web`). Each skill's `description` frontmatter specifies WHEN it activates.

**Core** (always available):
- security-review, shell-conventions, commit-review — auto-invoked
- /init-project, /deep-research, /init-design-system, /competitive-audit, /product-lab, /entropy-scan — user-invoked

**Web** (deployed to web projects):
- design-review, design-elevation, typescript-conventions, web-review, doc-garden — auto-invoked

## Skill Triggers
- If changes affect `src/components/` or style files → design-review
- If changes affect `src/app/` pages or content → web-review
- If changes affect `.ts` or `.tsx` files → typescript-conventions
- If designer produces `design-spec.md` → design-elevation
- If changes affect `.sh` files → shell-conventions
- If creating a commit or PR → commit-review
- If changes affect `docs/`, `CLAUDE.md`, or `*.md` in skill directories → doc-garden


### Skill & Tool Quality
- Invest in tool descriptions and parameter names — quality here outweighs prompt optimization
- Consolidate related operations into fewer tools; minimize overlap
- Error messages should steer toward correct usage, not just report failure
- **Clarity test**: Would the description be obvious to a junior developer? If not, rewrite it
- **Eval-driven iteration**: After a skill misfires or isn't triggered, review the transcript, refine the description, and test again
- **Periodic review**: When adding new skills, audit existing ones for overlap, ambiguity, or stale guidance

### Context Management
- **Survive compaction**: Anything critical must be in a file (plan.md, claude-progress.md), not just in conversation history
- **Just-in-time retrieval**: Don't pre-load entire codebases into context. Keep file paths as lightweight references, read on demand
- **Progress checkpoints**: Implementers update claude-progress.md at each completed task so context compaction doesn't erase progress
- **Subagent compression**: Subagents explore extensively but return condensed summaries to the orchestrator

### Model Routing (ENFORCED)
Agent frontmatter specifies the model. The orchestrator MUST use the specified model unless explicitly overriding for a stated reason.

| Agent | Model | Rationale |
|-------|-------|-----------|
| researcher | Sonnet | Research is the highest-leverage step; compounds into plan and code quality. Haiku is an explicit override for broad scans. |
| planner | Sonnet | Structured reasoning, good balance |
| implementer | Sonnet | Code generation, standard tasks |
| reviewer | Sonnet | Skeptical evaluation |
| designer | Sonnet | Design reasoning |
| product-strategist | Opus | Market analysis needs strongest reasoning |
| product-tactician | Sonnet | Feature scoping |
| writer | Sonnet | Writing quality |

**Override examples** (state the reason when overriding):
- Researcher doing broad keyword sweep across dozens of files → downgrade to Haiku (breadth > depth)
- Simple code review → downgrade reviewer to Haiku
- Architecture-critical planning → upgrade planner to Opus

### Local tier (Gemma 4 31B IT via MLX)

Free local inference on the M4 Max for cost-insensitive, sovereignty-sensitive, or throughput-heavy work. Model: `mlx-community/gemma-4-31b-it-4bit` (~18GB resident RAM, ~40–80 tok/s, ~2–5s first-token).

**Surfaces today:**
- `/ask-gemma "<prompt>"` — escape hatch for ad-hoc queries. Flags: `--file <path>`, `--system "..."`, `--max-tokens N`. See `.claude/commands/ask-gemma.md`.
- Critical-path integrations in workspace commands (`/vault-ask`, `/process-inbox`, `/graduate-notes`, `/vault-brief`) via `--provider=local|claude|compare` flag. Claude-preserving defaults — opt-in for local/compare.

**Reach-for-it cases:**
- Short ad-hoc queries (rephrasing, classification, quick lookups)
- Summaries of private/vault content (sovereignty — nothing leaves the machine)
- Bulk repetitive work (tagging, scoring, first-pass classification)
- Second opinion on Claude's answer via `/vault-ask --provider=compare`
- Anthropic rate-limited or unavailable

**Operational:**
- Server starts automatically on login via the `com.mojwang.mlx-server` LaunchAgent (`config/launchd/com.mojwang.mlx-server.plist`).
- Manual start: `./scripts/mlx-server-start.sh`
- Verify: `./scripts/local-model-check.sh` — fast-fails with actionable error if unreachable.
- Logs: `~/Library/Logs/mlx-server.log`

**NOT yet supported:**
- `provider: local` on agent frontmatter. Claude Code CLI doesn't honor that field today, so agent dispatches still route through Anthropic regardless. Command-level integration (above) is the current surface. Shared router (`scripts/model-route.sh`) is a future roadmap item — extract once a week of per-integration usage data tells us which integrations are reached for.

## Testing
**Write tests BEFORE implementation** — especially when agents implement autonomously.
Red-green-refactor: failing test first, minimal code to pass, then clean up.

```bash
./tests/run_tests.sh [unit|integration|ci]
```

### Test Quality Rules
- Tests must run code and check outcomes (behavioral), not grep source files
- Never `cat script.sh | assert_contains` — run the script instead
- Use `create_sandbox` for tests that modify files
- Label file-existence checks as "Repo Inventory", not "Unit Tests"
- See docs/TESTING.md for anti-patterns and templates

## MCP Server Priority
1. **Context7** (plugin): Library docs, code examples, API references (check first)
2. **Taskmaster**: Direct task management commands via MCP (`task-master list`, `task-master next`). Task tracking and breakdown only — product thinking is handled by the native `product-tactician` and `product-strategist` agents.
3. **Exa**: General web research (fallback for non-code queries)

## Important
- Do only what's asked; nothing more
- Check CI before merging: requires passing tests
- Version tracked in `VERSION` file
- Use specialized agents for complex tasks (see docs/CLAUDE_AGENTS.md)