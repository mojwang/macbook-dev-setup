# Stacked PRs — ship with Graphite

## Why this doc exists

When a plan produces **multiple dependent PRs** — each branched off the last, each building on the previous — shipping them as separate `gh pr create` calls creates painful merge choreography:

- Each parent merge forces the child to rebase (sometimes GitHub auto-retargets the base, often it doesn't)
- CI re-runs on every rebase
- Reviewers see the wrong diff (child PR includes parent's commits until the parent merges)
- **Silent failure mode**: if a child PR's base isn't retargeted before merging, it merges into the parent's feature branch instead of main (see [2026-04-18 post-mortem](#2026-04-18-incident) below)

Graphite (`gt`) is purpose-built for this pattern. It tracks the stack, auto-rebases as parents merge, and shows reviewers each PR's incremental diff.

## Install

```bash
brew install withgraphite/tap/graphite
gt auth
```

Bootstrap script (`setup-macos.sh`) adds this alongside `gh`, `delta`, `fzf`, etc.

## The stacked workflow

```bash
# Start a stack from main
gt branch create feat/phase-1
# ... make changes, commit ...

gt branch create feat/phase-2
# ... make changes, commit ...

gt branch create feat/phase-3
# ... make changes, commit ...

# Submit the whole stack as coordinated PRs
gt stack submit
```

Graphite opens one PR per branch, sets each PR's base to its parent branch, and maintains that topology as things move.

## When a parent merges

```bash
gt sync
```

Graphite rebases your downstream branches onto the new main, updates the PRs' bases to `main`, and force-pushes. No manual retargeting.

## Common commands

| Task | Command |
|------|---------|
| Create a branch on top of the current one | `gt branch create <name>` |
| Commit + continue up the stack | `gt modify --commit -m "..."` |
| Show the current stack | `gt log short` |
| Push the whole stack | `gt stack submit` |
| Sync after a parent merges | `gt sync` |
| Jump between stack branches | `gt up` / `gt down` |

## When Graphite isn't installed yet — manual retarget pattern

If you're mid-stack without `gt`, **always retarget each downstream PR's base to `main` before the parent merges**. GitHub doesn't do this automatically unless "Auto-delete head branches" is on AND the parent's head gets deleted via the merge.

```bash
gh pr edit <child-pr-number> --base main
```

Do this proactively for every downstream PR as soon as the parent is approved. Otherwise the merge silently lands the child into the parent's feature branch, not main — and you'll need a recovery PR to cherry-pick the squash commits onto main.

## 2026-04-18 incident

A 4-PR stack on `mojwang/mojwang.tech` (Phase 4 → Phase 6 → Phase 7 → Phase 8 of the `/mind` composition arc) was shipped as separate `gh pr create` PRs. PRs #64 and #65 squash-merged into their parent feature branches instead of `main` because the parent's head hadn't been deleted yet (auto-delete-head-branches was off). Recovery required PR #66 — cherry-picking the two squash commits directly onto main.

**The fix for next time**: `gt stack submit` from the start. Root cause wasn't git — it was the missing stack-awareness tooling.

## Repo hygiene defaults

Two settings every new repo should have to make stacks safer:

1. **GitHub → Settings → Pull Requests → Automatically delete head branches**: ON. Enables auto-retargeting of downstream PRs when the parent merges.
2. **Vercel → Settings → Integrations → Neon → "Delete Neon database branch when Vercel preview is deleted"**: ON. Keeps preview-DB branches from accumulating toward the 10-branch ceiling (free tier).

See `./maintenance.md` for the repo-setup checklist.
