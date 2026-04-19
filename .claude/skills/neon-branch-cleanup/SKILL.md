---
name: neon-branch-cleanup
description: List and safely delete stale Neon database branches via the Neon MCP. Use when Vercel deploys fail with "Branch limit exceeded," when `describe_project` shows a swarm of preview branches from merged PRs, or proactively when a Neon project has many stale branches. Cross-references each branch's name with its matching GitHub PR state to avoid deleting branches that still back open PRs.
---

# Neon Branch Cleanup

## When to invoke

- **Vercel deploy error**: "Branch limit exceeded" (free tier caps at 10 branches, Launch at 500)
- **Proactive hygiene**: `mcp__Neon__describe_project` shows >5 non-production branches
- **After a batch of PRs merge** if auto-cleanup isn't enabled on the Vercel-Neon integration
- **User says**: "clean up Neon branches", "prune Neon", "delete old database branches"

## Preconditions

1. Neon MCP server is connected (tools `mcp__Neon__list_projects`, `mcp__Neon__describe_project`, `mcp__Neon__delete_branch` are available).
2. `gh` CLI is authenticated (used for PR-state cross-reference).
3. User is in a repo where the Neon project's previews correspond to git branches (Vercel-Neon integration convention: branch name mirrors git branch, often prefixed `preview/`).

## Procedure

### Step 1 — Identify the project

```
mcp__Neon__list_projects()
```
If multiple projects, ask the user which to clean up. Pick the one whose name matches the active git repo if unambiguous.

### Step 2 — Enumerate branches

```
mcp__Neon__describe_project(projectId: <id>)
```
Capture: `id`, `name`, `primary`, `default`, `updated_at` for each branch. **Never** delete a branch where `primary: true` or `default: true`.

### Step 3 — Classify against GitHub PR state

For each non-primary branch, derive the git branch name (strip `preview/` prefix if present, or treat `vercel-dev` as a Vercel-system branch safe to delete). Then:

```bash
gh pr list --state all --head "<git-branch-name>" --json state --jq '.[0].state // "none"'
```

Classification:
- **MERGED** or **CLOSED** or **none** (no PR exists) → safe to delete
- **OPEN** or **DRAFT** → skip; active deploy may still target this branch
- **Vercel-system branch** (name doesn't match any git branch, e.g., `vercel-dev`) → safe to delete; Vercel will recreate on demand

### Step 4 — Present the cleanup plan

Output a markdown table with columns: Branch ID, Name, Last Updated, PR State, Disposition. Highlight any skipped branches. Get user confirmation before the first deletion **unless** invocation context is explicitly "auto-clean" or similar.

### Step 5 — Delete

For each safe-to-delete branch:
```
mcp__Neon__delete_branch(projectId: <id>, branchId: <branch-id>)
```
Collect failures (e.g., branch has active compute blocking deletion). Retry once, then surface to user.

### Step 6 — Verify + remind

After deletion:
```
mcp__Neon__describe_project(projectId: <id>)  # confirm count
```

**Always remind** the user to enable the Vercel-Neon integration's auto-cleanup toggle so this doesn't recur:
- Vercel dashboard → Project → Settings → Integrations → Neon → Configure → "Delete Neon database branch when Vercel preview is deleted"

## Invariants

- **Never delete the primary/default branch.**
- **Never delete a branch with active OPEN or DRAFT PRs.**
- **Always cross-reference with `gh` before deletion** — the PR state is the source of truth for "is this branch still needed."
- **Soft-prefer auto-cleanup over manual cleanup** — if the toggle isn't on, recommend enabling it as part of the same conversation.

## Known gotchas

- **The Vercel-Neon integration doesn't enable auto-cleanup by default.** New projects accumulate branches until a ceiling hit.
- **Some Neon branches have names that don't match any git branch** — e.g., `vercel-dev` is created by the Vercel integration, not a PR preview. Safe to delete.
- **`forced update` on a branch** in `git fetch` output is not a sign of a problem — it just means origin rebased that branch.
- **Free tier ceiling**: 10 branches. Launch tier: 500.

## Reference — flow used successfully on 2026-04-18

On the `mojwang/mojwang.tech` project, 10 branches at ceiling. 9 deleted (1 production kept), all cross-referenced against merged/closed GitHub PRs first. See `~/.claude/plans/let-s-revert-to-status-concurrent-clock.md` for the full incident record.
