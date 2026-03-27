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

### Task Classification (decide first)
- **Async/autonomous**: Peripheral features, prototyping, tests, refactors → full agent workflow, let it run
- **Sync/supervised**: Core logic, critical fixes, security-sensitive → work interactively, supervise closely
- **Trivial**: Single-file edits, quick fixes → skip workflow, implement directly
- **Design-aware**: Tasks touching UI components, styles, pages, or layouts → dispatch designer in Phase 1 (parallel with researcher) and Phase 4 (parallel with reviewer). Designer produces `design-spec.md` which planner and implementer consume as required input.
- **Product-first**: New features, competing priorities, unclear scope → dispatch product-tactician agent before research
- **Strategy-first**: "Should we build this?" questions, new product ideas, market validation → dispatch product-strategist (directly or via `/product-lab`) before any other phase

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

### Phase -1: Strategy (optional)
Dispatch `product-strategist` sub-agent when the question is "should we build this" — not "what to build."
- Use for new product ideas, market validation, or when product-market fit is uncertain
- Orchestrator dispatches directly as sub-agent, or conductor invokes via `/product-lab [mode]`
- Pass mode as part of the prompt when dispatching (e.g., "evaluate hyper-personalized-product-design")
- Output: persistent artifacts in `product-lab/` (evaluation, discovery, MVP scope, positioning, etc.)
- These artifacts are NOT ephemeral — they persist across sessions and feed downstream agents
- `product-lab/positioning.md` → designer (audience, tone); `product-lab/discovery.md` → product-tactician (evidence); `product-lab/mvp-scope.md` → planner (boundaries)

### Phase 0: Define (optional)
Dispatch `product-tactician` sub-agent to frame the problem and scope the solution for a specific feature.
- Use for new features, competing priorities, or when "what to build" is unclear
- Skip for bug fixes, refactors, or well-defined tasks
- Consumes `product-lab/` artifacts (if present) for strategic context
- Output: `product-brief.md` with problem, scope, success criteria
- Orchestrator reviews brief before proceeding. Annotation cycle: add `NOTE:` or `Q:` inline → re-run product-tactician

### Phase 1: Research
Dispatch `researcher` sub-agent to explore affected code areas.
- Researcher reads `product-brief.md` (if present) to focus exploration
- Run multiple researchers in parallel for independent areas
- For UI tasks, dispatch `designer` in parallel with researcher for competitive/pattern research
- Output: `research.md` with findings (+ `design-spec.md` from designer if applicable)
- Skip for trivial tasks or well-understood areas

### Phase 2: Plan
Dispatch `planner` sub-agent to create `plan.md` from research.
- Planner reads `product-brief.md` (if present) for scope boundaries
- Planner reads both `research.md` and `design-spec.md` (if present)
- Annotation cycle: user adds `NOTE:` or `Q:` inline → re-run planner to address
- Iterate 1-3 rounds until plan is approved
- Each task in the plan should be scoped for a single implementer
- Size tasks appropriately: self-contained units with clear deliverables

### Phase 3: Implement
Dispatch implementers with the approved plan. Choose mode based on task:

**Subagent implementers** (worktree-isolated):
- Each works in worktree isolation on its own branch
- Self-sufficient loops: run tests after every change
- Checkpoint commits after each completed task (enables rollback)
- Slot machine rule: if off track, revert and restart fresh

**Agent team implementers** (for complex parallel work):
- Split independent tasks so each teammate owns different files (avoid conflicts)
- Require plan approval before implementation for risky changes
- Monitor via tmux split panes — redirect approaches that aren't working
- Lead waits for teammates to finish before synthesizing

### Phase 4: Verify
Dispatch `reviewer` sub-agent to validate implementation.
- Must pass before creating PR
- For design-system projects, dispatch `designer` alongside reviewer for parallel QA
- Can run security + quality reviewers in parallel
- For agent teams: use `TaskCompleted` hooks to enforce quality gates

### Phase 5: Evaluate (optional)
Dispatch `product-tactician` sub-agent to assess outcomes against success criteria.
- Run after implementation is shipped and has had time to produce results
- Output: evaluation addendum to `product-brief.md`
- Skip for refactors, infra work, or tasks without user-facing outcomes

### Session Startup (every session)
Before dispatching agents or doing work, the orchestrator runs:
1. `git branch --show-current` — verify not on main
2. Read `claude-progress.md` if present — understand where last session left off
3. `git log --oneline -10` — review recent changes
4. Run smoke test (build/test) — confirm nothing is broken
5. Review plan.md or task list — identify next priority
6. Only then: dispatch agents or begin work

### Orchestration Rules
- Main session = orchestrator. Dispatches agents, never implements complex tasks itself.
- Subagents cannot spawn other subagents — all coordination flows through orchestrator
- Persistent artifacts (research.md, plan.md, claude-progress.md) survive context compaction
- Designer agent is a peer, not a subordinate. It produces specs and reviews; implementer produces code.
- Product agents are advisory — orchestrator reviews briefs and can override scope/priority decisions
- Product-strategist artifacts (`product-lab/`) are persistent; product-tactician artifacts (`product-brief.md`) are ephemeral
- **Constraint focus**: Before dispatching agents in parallel, identify which phase is the current bottleneck. The system's throughput equals the bottleneck's throughput — invest orchestrator attention there, not on phases that are already flowing.
- **WIP discipline**: Never dispatch more parallel agents than can be synthesized in one pass. Unfinished artifacts from prior phases (unapproved `product-brief.md`, unreviewed `research.md`) block new dispatches.
- **Multiplier behavior**: Guide agents through questions and annotation cycles before overriding their work. The orchestrator's output is the team's output — amplify agents rather than replace them.
- Design artifacts (`design-spec.md`) are ephemeral like `research.md`/`plan.md` — cleaned up after PR merge.
- **End-of-session improvement**: Before session ends, Claude must suggest CLAUDE.md improvements based on what worked/didn't. User decides whether to apply.

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
4. **Delete ephemeral artifacts**: `research.md`, `plan.md`, `design-spec.md`, `product-brief.md`, `claude-progress.md`
5. **For agent teams**: Lead shuts down teammates first, then cleans up all worktrees

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
Skills in `.claude/skills/` with YAML frontmatter for invocation control:

**Auto-invoked** (Claude loads when relevant, `user-invocable: false`):
- **security-review** — shell injection, secrets, OWASP checks (activates on code review/PRs)
- **shell-conventions** — enforces shebang, set -e, timeouts, quoting (activates on .sh edits)
- **commit-review** — conventional commits, <200 LOC, branch checks (activates on commits/PRs)

**User-invocable** (manual `/command` only):
- **/init-project [dir] [--type shell|web]** — bootstrap agentic workflow with type-specific skills (`disable-model-invocation: true`)
- **/deep-research [topic]** — forked explorer agent for codebase research (`context: fork`, `agent: researcher`)
- **/init-design-system [dir] [--domain healthcare|saas|ecommerce]** — bootstrap shadcn/ui with domain customizations (`disable-model-invocation: true`)
- **/competitive-audit [vertical] [--sites ...]** — structured competitive website audit framework (`disable-model-invocation: true`)
- **/product-lab [mode] [idea-name]** — Product lifecycle co-pilot: evaluate ideas, run discovery, scope MVPs, assess PMF (`agent: product-strategist`)

**Web auto-invoked** (deployed with `--type web`):
- **design-review** — token compliance, component consistency, visual hierarchy, typography/spacing rhythm, animation quality, cross-page consistency, healthcare UX (activates on component/style changes)
- **design-elevation** — interrogation framework (5 lenses), technique selection (~83 techniques), reference library (19 exemplars). Auto-invoked when designer produces `design-spec.md`. Includes TECHNIQUES.md and REFERENCES.md companion files.
- **typescript-conventions** — strict types, React/Next.js patterns, error handling, async patterns, state management, testing (activates on .ts/.tsx edits)
- **web-review** — accessibility, SEO, Core Web Vitals, structured data, mobile/viewport, social sharing (activates on page/component changes)


### Skill & Tool Quality
- Invest in tool descriptions and parameter names — quality here outweighs prompt optimization
- Consolidate related operations into fewer tools; minimize overlap
- Error messages should steer toward correct usage, not just report failure

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