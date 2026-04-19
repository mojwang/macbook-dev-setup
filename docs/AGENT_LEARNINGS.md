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
