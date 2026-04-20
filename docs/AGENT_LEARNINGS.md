# Agent Learnings

Persistent cross-session knowledge extracted from `claude-progress.md` after each PR merge.
Unlike ephemeral artifacts, this file lives in the repo permanently and is read at session startup.

## Grading Rubric (for `/grade-session`)

`/log-session` writes rows with an optional `outcome` field. `/grade-session` walks ungraded rows and fills them in retroactively. These are the enum values — pick the one that best describes the session's end state.

### `shipped`
- PR merged, feature live, no regressions within 24h.
- User-visible outcome (code, config, or docs).
- Follow-ups may exist, but the core work landed.
- Use for: standard feature work that completed cleanly.

### `partial`
- Part of the stated scope landed; at least one follow-up is queued.
- Not a failure — genuine scope trim, or a breakdown into multiple PRs.
- Distinguish from `shipped`: if you had to defer work to a *future* PR that isn't already open, it's partial.
- Use for: any session where the original ask has remaining work.

### `reverted`
- Shipped and rolled back within 7 days (by revert commit, re-implementation, or feature-flag disable).
- Reason doesn't matter for the grade — the signal is the revert itself.
- Follow-up note should name the root cause in the commit/PR body so meta-agent can find the pattern.
- Use for: any post-ship rollback, regardless of who initiated.

### `blocked`
- External dependency, missing info, or non-reproducible bug killed the session.
- No code shipped; would have shipped if not for the block.
- Different from `plan-only`: `blocked` is involuntary, `plan-only` is intentional.
- Use for: waiting on upstream fix, missing access, ambiguous spec, or flaky repro.

### `plan-only`
- User explicitly asked for a plan, research, or recommendation — not a ship.
- No code outcome was expected; the deliverable was a document.
- Don't use this as a fallback for "I couldn't finish" — that's `partial` or `blocked`.
- Use for: overnight research, exec-plan writing, architecture review.

### `skip` (not a grade — leaves the row ungraded)
- Use when you genuinely don't remember the session or need to grade it later.
- The row stays ungraded and reappears next run of `/grade-session`.

## Failure Patterns
<!-- Format: - [Pattern]: [What went wrong] → [What works instead] (PR #XX) -->

## Workflow Insights
<!-- Format: - [Observation about agent effectiveness] (date) -->

## Model Routing Outcomes
<!-- Format: - [Task type]: [Model used] → [Result: sufficient/insufficient] (PR #XX) -->

## Deferred Design Decisions

### P2.1 — Agent-frontmatter `provider:` field deferred (2026-04-19)

**What:** Roadmap P2.1 originally planned to add `provider: local-gemma4` (or similar) to agent frontmatter so `vault-curator`, `inbox-processor`, `writer` etc. could route through a local MLX server instead of Anthropic.

**Why deferred:** Claude Code CLI's agent dispatch reads `name`, `description`, `model`, `tools` from frontmatter. Unknown fields (like a hypothetical `provider:`) are silently ignored — the dispatch always hits Anthropic regardless. A `provider:` field today would be no-op.

**What shipped instead:** Command-level integration. `/ask-gemma` as an escape hatch plus `--provider=local|claude|compare` flag added to `/vault-ask`, `/process-inbox`, `/graduate-notes`, `/vault-brief`. Each is additive and flag-gated; Claude defaults preserve existing behavior.

**Unblocker:** When Claude Code CLI supports provider routing (or when we add a dispatch shim that reads agent md ourselves and routes externally), the existing skill-level `--provider` plumbing extracts cleanly into an agent-level field.

**Router as shared utility — also deferred:** Each of the 5 integrations duplicates ~15 lines of provider-routing logic. Tempting to extract into `scripts/model-route.sh` immediately. Deliberately NOT done — we want a week of per-integration usage data first to know which integrations are reached for and which routing patterns stabilize. Premature abstraction is the risk; 5 concrete integrations are cheap to maintain short-term.
