# Claude Sub-Agents

Orchestrator pattern with 7 native sub-agents. The main Claude session dispatches agents — it never implements complex tasks directly. See `CLAUDE.md` for the authoritative workflow reference (Phase -1 through Phase 5).

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

## Orchestration Pattern

### Task Classification (decide first)
- **Trivial** (single-file edits, quick fixes): Skip workflow, implement directly
- **Async/autonomous** (prototyping, tests, refactors): Full agent workflow
- **Sync/supervised** (core logic, security-sensitive): Work interactively

### Phase Flow
-1. **Strategy** (optional) → Dispatch product-strategist for "should we build this?" questions. Output: `product-lab/` artifacts.
0. **Define** (optional) → Dispatch product-tactician for per-feature scoping.
1. **Research** → Dispatch researcher + designer (parallel for UI tasks).
2. **Plan** → Dispatch planner (reads `research.md` + `design-spec.md` + `product-brief.md`).
3. **Implement** → Dispatch implementer(s) in worktree isolation. Parallel for independent tasks.
4. **Verify** → Dispatch reviewer + designer (parallel for design-system projects).
5. **Evaluate** (optional) → Dispatch product-tactician to assess outcomes.

### Key Rules
- Orchestrator never implements complex tasks itself
- Subagents cannot spawn other subagents — all coordination through orchestrator
- Slot machine rule: if an implementer goes off track, revert and restart fresh
- Every implementer runs in its own worktree (no exceptions)

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
