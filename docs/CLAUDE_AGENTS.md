# Claude Sub-Agents

Orchestrator pattern with 7 native sub-agents. The main Claude session dispatches agents — it never implements complex tasks directly. This file is the authoritative workflow reference (Phase -1 through Phase 5).

## Native Sub-Agents

All agent definitions live in `.claude/agents/`. Each file uses YAML frontmatter for metadata.

### Product Strategist (`.claude/agents/product-strategist.md`)
- **Purpose**: Full-lifecycle product strategy — idea validation, discovery, MVP scoping, PMF assessment, positioning, growth
- **Tools**: Read, Write, Edit, Bash, Grep, Glob, WebSearch, WebFetch
- **When**: New product ideas, "should we build this?" questions, market validation, PMF assessment
- **Input**: Raw idea, conversation context, `product-lab/stage.json` for state
- **Output**: Persistent artifacts in `product-lab/` — evaluation, discovery, MVP scope, positioning, growth engine
- **Key behavior**: Questions over statements, facts over opinions, pushback over validation. Guides founders through 7 lifecycle stages with evidence gates.
- **Invocation**: `/product-lab [mode] [idea-name]` or directly as sub-agent
- **Companion files**: `FRAMEWORKS.md`, `STAGE-PLAYBOOKS.md`, `ARTIFACTS.md` in `.claude/skills/product-lab/`

### Product Tactician (`.claude/agents/product-tactician.md`)
- **Purpose**: Per-feature product thinking — problem definition, scoping, prioritization, outcome evaluation
- **Tools**: Read, Grep, Glob, Bash
- **When**: New features within an existing project, competing priorities, unclear scope, post-launch evaluation
- **Input**: Task description, user context, project goals, `product-lab/` artifacts (if present)
- **Output**: `product-brief.md` — problem, JTBD, solution hypothesis, scope, success criteria, assumptions
- **Key behavior**: Advisory peer to all agents. Opinionated but transparent. Orchestrator makes final calls.
- **Structured frameworks**: opportunity mapping, hypothesis framing, strategy coherence

**Strategist vs. Tactician**: The strategist decides whether to build the product at all (lifecycle-level). The tactician scopes individual features within a validated product. Strategist outputs (positioning, discovery, MVP scope) feed into the tactician's problem framing.

### Researcher (`.claude/agents/researcher.md`)
- **Purpose**: Deep codebase exploration before planning
- **Model**: haiku | **Tools**: Read, Grep, Glob, Bash
- **When**: Any task touching 3+ files, or unfamiliar code areas
- **Input**: Task description from orchestrator
- **Output**: `research.md` — current state, patterns, dependencies, risks, open questions
- **Key behavior**: Read-only. References `.claude-agents.json` for project capabilities.
- **Investigation method**: tracer bullet first, blast radius mapping, complexity assessment

### Planner (`.claude/agents/planner.md`)
- **Purpose**: Create detailed implementation plans from research
- **Tools**: Read, Grep, Glob
- **When**: After research phase, or directly for well-understood tasks
- **Input**: `research.md` (if present), task description
- **Output**: `plan.md` — summary, files to change, checkbox tasks, testing strategy, rollback plan
- **Key behavior**: Supports annotation cycles — user adds `NOTE:` or `Q:` inline, planner addresses them on re-run.
- **Scoping discipline**: appetite-based sizing, coherent actions, module-aligned task boundaries

### Implementer (`.claude/agents/implementer.md`)
- **Purpose**: Execute implementation plans step by step
- **Isolation**: worktree | **Tools**: Read, Write, Edit, Bash, Grep, Glob
- **When**: After plan is approved
- **Input**: `plan.md` with assigned tasks
- **Output**: Code changes with checkpoint commits
- **Key behavior**: Self-sufficient loop — run tests after each change, shellcheck `.sh` files, commit per task. Never commits to main.
- **Craft principles**: single representation, broken windows, deep modules, end-to-end first

### Reviewer (`.claude/agents/reviewer.md`)
- **Purpose**: Verify implementation quality, security, and test coverage
- **Tools**: Read, Grep, Glob, Bash
- **When**: After implementation, before PR creation
- **Input**: Branch with implementation commits
- **Output**: Review summary (PASSED/FAILED) with sections for tests, security, code quality, documentation, performance, and recommendations
- **Key behavior**: Objective — reports facts, distinguishes blocking issues from suggestions. References specific file paths and line numbers.
- **Health checks**: delivery risk, cognitive load, reversibility assessment

### Designer (`.claude/agents/designer.md`)
- **Purpose**: Design system specialist — produces specs, audits, and visual QA
- **Tools**: Read, Write, Edit, Bash, Grep, Glob
- **When**: UI tasks (components, styles, pages), new feature specs, pre-PR design QA
- **Input**: Task description, project design tokens, existing component inventory
- **Output**: `design-spec.md` — component specs, token usage, layout guidance; design review feedback
- **Key behavior**: Peer to engineering agents. Never writes implementation code. Artifacts consumed by planner and implementer.
- **Design principles**: visual hierarchy, progressive disclosure, affordances, composition levels

## Orchestration Detail

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

### Phase 4: Verify (iterative)
Dispatch `reviewer` sub-agent to validate implementation.
- Must pass before creating PR
- If NEEDS_REVISION: send review feedback to implementer → implementer fixes and re-commits → re-dispatch reviewer (max 3 rounds, then escalate to user)
- For design-system projects, dispatch `designer` alongside reviewer for parallel QA
- For web projects: reviewer uses Playwright MCP for browser-based verification
- Can run security + quality reviewers in parallel
- For agent teams: use `TaskCompleted` hooks to enforce quality gates

### Phase 5: Evaluate (recommended when success criteria exist)
Dispatch `product-tactician` sub-agent to assess outcomes against success criteria.
- Run after implementation is shipped and has had time to produce results
- Output: evaluation addendum to `product-brief.md`
- Skip for refactors, infra work, or tasks without user-facing outcomes
- If `product-brief.md` defines success criteria, evaluation is expected — don't silently skip it

### Session Startup (every session)
Before dispatching agents or doing work, the orchestrator runs:
1. `git branch --show-current` — verify not on main
2. Read `claude-progress.md` if present — understand where last session left off
3. Read `docs/AGENT_LEARNINGS.md` — check for relevant failure patterns and workflow insights from prior PRs
4. `git log --oneline -10` — review recent changes
5. Run smoke test (build/test) — confirm nothing is broken
6. Review plan.md or task list — identify next priority
7. Only then: dispatch agents or begin work

### Orchestration Rules
- Main session = orchestrator. Dispatches agents, never implements complex tasks itself.
- Subagents cannot spawn other subagents — all coordination flows through orchestrator
- **Decision log**: Write `claude-decisions.md` at task start with classification, agent dispatch rationale, and scope decisions. Update when decisions change. This enables post-mortem tracing when features fail.
- **Artifact visibility**: After each phase completes, update the Artifacts table in `claude-progress.md` so every agent knows what exists and who should read it (see implementer.md for table format).
- Persistent artifacts (research.md, plan.md, claude-progress.md) survive context compaction
- Designer agent is a peer, not a subordinate. It produces specs and reviews; implementer produces code.
- Product agents are advisory — orchestrator reviews briefs and can override scope/priority decisions
- Product-strategist artifacts (`product-lab/`) are persistent; product-tactician artifacts (`product-brief.md`) are ephemeral
- **Constraint focus**: Before dispatching agents in parallel, identify which phase is the current bottleneck. The system's throughput equals the bottleneck's throughput — invest orchestrator attention there, not on phases that are already flowing.
- **WIP discipline**: Never dispatch more parallel agents than can be synthesized in one pass. Unfinished artifacts from prior phases (unapproved `product-brief.md`, unreviewed `research.md`) block new dispatches.
- **Multiplier behavior**: Guide agents through questions and annotation cycles before overriding their work. The orchestrator's output is the team's output — amplify agents rather than replace them.
- Design artifacts (`design-spec.md`) are ephemeral like `research.md`/`plan.md` — cleaned up after PR merge. Do NOT delete persistent artifacts (`docs/design/decisions.md`, `docs/AGENT_LEARNINGS.md`, audit reports in `docs/design/`).
- **End-of-session improvement**: Before session ends, Claude must suggest CLAUDE.md improvements based on what worked/didn't. User decides whether to apply.
- **End-of-session evaluation check**: If the session produced a shipped feature with success criteria (from `product-brief.md`), prompt: "Phase 5 evaluation is due — dispatch product-tactician to assess outcomes?" Don't silently skip evaluation.

## Artifacts

- **`research.md`**, **`plan.md`**, **`design-spec.md`**, and **`product-brief.md`**: Ephemeral, gitignored. Created per-task, cleaned up after PR merge.
- **`product-lab/`**: Persistent artifacts from product-strategist. NOT cleaned up after PR merge — they represent ongoing product strategy state across sessions.
- Survive context compaction — persistent reference for orchestrator and agents.
- Annotation cycles: user adds `NOTE:`/`Q:` to `plan.md`, re-runs planner to address.

## Supplementary Config

**`.claude-agents.json`** contains structured metadata about agent capabilities (roles, triggers, quality gates, workflows). Referenced by the researcher agent for project context — not a runtime config that drives agent selection.

## Helper Scripts

```bash
scripts/claude-agents/
├── agent-benchmarks.sh       # Benchmark agent execution patterns
├── demo-agents.sh            # Demo agent workflow coordination
└── test-agent-workflows.sh   # Validate agent definitions, orchestration flow, and config
```
