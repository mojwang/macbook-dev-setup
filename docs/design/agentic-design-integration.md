# Agentic Design Integration

How the designer agent collaborates with engineering agents as a first-class peer.

## Architecture

The designer is the 5th agent in `.claude/agents/`, at the same level as researcher, planner, implementer, and reviewer. It produces design artifacts; engineering agents consume them.

Key principle: **agents are execution roles, skills are deployment units**. The designer agent *uses* design skills (design-review, init-design-system, competitive-audit) the same way the reviewer uses security-review.

## Collaboration Protocol

### New Feature Flow
1. **Research phase** — Designer runs competitive/pattern research in parallel with researcher's codebase exploration
2. **Design spec** — Designer produces `design-spec.md` with component specs, token usage, layout guidance
3. **Plan phase** — Planner reads both `research.md` and `design-spec.md` to create implementation plan
4. **Implement phase** — Implementer executes the plan (designer not involved)
5. **Verify phase** — Designer runs deep design QA in parallel with reviewer's engineering QA

### Design Review Flow
- **Reviewer** (lightweight): 4 engineering-observable checks — token compliance, component consistency, image optimization, CTA hierarchy
- **Designer** (deep): Experiential accessibility, cross-page consistency, pattern compliance, interaction quality

### Design System Evolution
1. `/init-design-system` bootstraps the initial system (shadcn/ui + domain customizations)
2. Designer agent specs new components as features are added
3. `/competitive-audit` informs design direction with market research
4. Design review catches drift from the system over time

## Artifact Contract

| Artifact | Producer | Consumers | Location |
|----------|----------|-----------|----------|
| `design-spec.md` | Designer | Planner, Implementer | Working directory |
| Design review | Designer | Orchestrator | Inline (pass/fail) |
| Audit reports | Designer | Team (reference) | `docs/design/` |
| `research.md` | Researcher | Planner, Designer | Working directory |
| `plan.md` | Planner | Implementer | Working directory |

All working-directory artifacts are ephemeral — cleaned up after PR merge.

## Workflow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│  Agentic Workflow (design-aware)                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Phase 1: Research (parallel)                               │
│    ├── researcher → research.md                             │
│    └── designer   → design-spec.md                          │
│                                                             │
│  Phase 2: Plan                                              │
│    └── planner (reads research.md + design-spec.md)         │
│        → plan.md                                            │
│                                                             │
│  Phase 3: Implement                                         │
│    └── implementer(s) in worktree isolation                 │
│                                                             │
│  Phase 4: Verify (parallel)                                 │
│    ├── reviewer → engineering QA (tests, security, quality) │
│    └── designer → design QA (tokens, consistency, a11y)     │
│                                                             │
│  Standalone:                                                │
│    /competitive-audit  → docs/design/                       │
│    /init-design-system → shadcn bootstrap                   │
└─────────────────────────────────────────────────────────────┘
```

## Skills

The designer agent uses three skills deployed with `--type web`:

- **design-review** (auto-invoked) — Token compliance, component consistency, visual hierarchy, responsive checks, domain-specific UX patterns. Activates on component/style file changes.
- **init-design-system** (user-invoked) — Bootstraps shadcn/ui with domain customizations. Detects setup, maps tokens, installs components, applies domain variants.
- **competitive-audit** (user-invoked) — Structured competitive website analysis with Playwright. Site selection, per-site audit, pattern matrix, gap analysis, recommendations.

## Engineering Integration

### Implementer reads design-spec.md
The implementer receives `design-spec.md` alongside `plan.md`. It references token names, component variants, and layout specs directly — no interpretation needed.

### Reviewer does lightweight checks
The reviewer's `### Design` section runs 4 quick checks (token compliance, component consistency, image optimization, CTA hierarchy) when a design system is detected. Deep review is the designer's responsibility.

### Orchestrator coordinates
The orchestrator decides when to dispatch the designer based on task classification:
- UI components, styles, pages, layouts → dispatch designer
- Backend, CI/CD, tests-only → skip designer
- See `design_aware` workflow in `.claude-agents.json`
