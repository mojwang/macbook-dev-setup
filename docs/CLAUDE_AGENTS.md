# Claude Sub-Agents

Orchestrator pattern with 4 native sub-agents. The main Claude session dispatches agents — it never implements complex tasks directly. See `CLAUDE.md` for the authoritative workflow reference (Phase 1-4).

## Native Sub-Agents

All agent definitions live in `.claude/agents/`. Each file uses YAML frontmatter for metadata.

### Researcher (`.claude/agents/researcher.md`)
- **Purpose**: Deep codebase exploration before planning
- **Model**: haiku | **Tools**: Read, Grep, Glob, Bash
- **When**: Any task touching 3+ files, or unfamiliar code areas
- **Input**: Task description from orchestrator
- **Output**: `research.md` — current state, patterns, dependencies, risks, open questions
- **Key behavior**: Read-only. References `.claude-agents.json` for project capabilities.

### Planner (`.claude/agents/planner.md`)
- **Purpose**: Create detailed implementation plans from research
- **Tools**: Read, Grep, Glob
- **When**: After research phase, or directly for well-understood tasks
- **Input**: `research.md` (if present), task description
- **Output**: `plan.md` — summary, files to change, checkbox tasks, testing strategy, rollback plan
- **Key behavior**: Supports annotation cycles — user adds `NOTE:` or `Q:` inline, planner addresses them on re-run.

### Implementer (`.claude/agents/implementer.md`)
- **Purpose**: Execute implementation plans step by step
- **Isolation**: worktree | **Tools**: Read, Write, Edit, Bash, Grep, Glob
- **When**: After plan is approved
- **Input**: `plan.md` with assigned tasks
- **Output**: Code changes with checkpoint commits
- **Key behavior**: Self-sufficient loop — run tests after each change, shellcheck `.sh` files, commit per task. Never commits to main.

### Reviewer (`.claude/agents/reviewer.md`)
- **Purpose**: Verify implementation quality, security, and test coverage
- **Tools**: Read, Grep, Glob, Bash
- **When**: After implementation, before PR creation
- **Input**: Branch with implementation commits
- **Output**: Review summary (PASSED/FAILED) with sections for tests, security, code quality, documentation, performance, and recommendations
- **Key behavior**: Objective — reports facts, distinguishes blocking issues from suggestions. References specific file paths and line numbers.

## Orchestration Pattern

### Task Classification (decide first)
- **Trivial** (single-file edits, quick fixes): Skip workflow, implement directly
- **Async/autonomous** (prototyping, tests, refactors): Full agent workflow
- **Sync/supervised** (core logic, security-sensitive): Work interactively

### Phase Flow
1. **Research** → Dispatch researcher(s). Run in parallel for independent areas.
2. **Plan** → Dispatch planner. Iterate 1-3 annotation cycles until approved.
3. **Implement** → Dispatch implementer(s) in worktree isolation. Parallel for independent tasks.
4. **Verify** → Dispatch reviewer. Must pass before PR creation.

### Key Rules
- Orchestrator never implements complex tasks itself
- Subagents cannot spawn other subagents — all coordination through orchestrator
- Slot machine rule: if an implementer goes off track, revert and restart fresh
- Every implementer runs in its own worktree (no exceptions)

## Artifacts

- **`research.md`** and **`plan.md`**: Ephemeral, gitignored. Created per-task, cleaned up after PR merge.
- Survive context compaction — persistent reference for orchestrator and agents.
- Annotation cycles: user adds `NOTE:`/`Q:` to `plan.md`, re-runs planner to address.

## Supplementary Config

**`.claude-agents.json`** contains structured metadata about agent capabilities (roles, triggers, quality gates, workflows). Referenced by the researcher agent for project context — not a runtime config that drives agent selection.

## Helper Scripts

```bash
scripts/claude-agents/
├── agent-benchmarks.sh       # Benchmark agent execution patterns
├── demo-agents.sh            # Demo agent workflow coordination
└── test-agent-workflows.sh   # Test agent workflow integration (simulated — tech debt)
```

> **Note**: `test-agent-workflows.sh` exercises the 4-agent workflow architecture with simulated execution (validates definitions, orchestration flow, worktree isolation, artifacts, and config).
