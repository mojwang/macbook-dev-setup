# Agentic Design Integration

How the design layer fits into the agentic workflow.

## Design Skills

Three new skills extend the agentic system for design-aware development:

### design-review (auto-invoked)
Activates automatically on component/style file changes in web projects. Checks:
- **Token compliance** — hardcoded colors/spacing → use design tokens
- **Component consistency** — raw HTML → use `src/components/ui/` primitives
- **Visual hierarchy** — competing CTAs, heading gaps, small body text
- **Responsive** — fixed widths, missing image dimensions
- **Healthcare UX** — credentials, trust signals, `tel:` links, disclaimers

Complements `web-review` (accessibility, SEO, performance) — no overlap.

### init-design-system (user-invoked)
Bootstraps shadcn/ui with domain-specific customizations:
```bash
/init-design-system ./my-project --domain healthcare
```
Steps: detect setup → init shadcn → map tokens → install components → apply domain variants → generate docs.

### competitive-audit (user-invoked)
Structured competitive website analysis:
```bash
/competitive-audit "integrative medicine" --sites clinic1.com,clinic2.com
```
Phases: site selection → per-site Playwright audit → pattern matrix → gap analysis → prioritized recommendations.

## Reviewer Integration

The reviewer agent (`/.claude/agents/reviewer.md`) conditionally runs design checks when a design system is detected (`src/components/ui/` or `components.json` exists):
- Token compliance
- Component consistency
- Image optimization
- CTA hierarchy

## Deployment

Design skills deploy as web-type skills via `setup-claude-agentic.sh`:
```bash
claude-init-agentic --init . --type web
# Deploys: typescript-conventions, web-review, design-review, init-design-system, competitive-audit
```

## Workflow Integration

```
┌─────────────────────────────────────────────────┐
│  Agentic Workflow                               │
├─────────────────────────────────────────────────┤
│  Research → Plan → Implement → Verify           │
│                       │            │            │
│                       ▼            ▼            │
│              design-review    reviewer.md       │
│              (auto on edit)   (design section)  │
│                                                 │
│  Standalone:                                    │
│    /competitive-audit  → docs/design/           │
│    /init-design-system → shadcn bootstrap        │
└─────────────────────────────────────────────────┘
```
