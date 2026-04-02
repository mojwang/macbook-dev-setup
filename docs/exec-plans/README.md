# Execution Plans

Versioned plans that create institutional memory. Future agents reference completed plans to understand past decisions and avoid re-deriving settled choices.

## Structure

```
docs/exec-plans/
├── README.md          (this file)
├── _template.md       (plan template)
├── [feature-name].md  (active plans)
└── completed/         (merged plans)
```

## Workflow

1. After `plan.md` is approved, copy it to `docs/exec-plans/[feature-name].md`
2. Update it as implementation progresses (decisions, pivots, learnings)
3. After PR merges, move to `docs/exec-plans/completed/`
4. Add an **Outcome** section documenting what shipped and what was learned

## When to use

- Standard and Parallel tasks (3+ files, architectural decisions)
- Skip for trivial tasks (single-file edits, quick fixes)
