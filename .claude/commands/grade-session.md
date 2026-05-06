---
description: Walk ungraded rows in scripts/.session-cost.log, prompt for an outcome grade per row, and atomically rewrite the log with grades filled in. Grades are from the enum shipped | partial | reverted | blocked | plan-only.
allowed-tools: Bash
---

# Grade Session (retroactive)

Backfill missing `outcome` values on past `/log-session` rows. Each row the logger writes without an outcome gets `| | <sha>` at the tail — those are the rows this command walks.

## Run

```bash
./scripts/grade-session.sh $ARGUMENTS
```

## Behavior

1. Scans `scripts/.session-cost.log` for rows whose 5th field (outcome) is empty (i.e. `| <whitespace> | <sha>` at the tail).
2. For each ungraded row, prints it and prompts for a grade: `shipped | partial | reverted | blocked | plan-only` (or `skip` to leave it ungraded for now).
3. Writes updates to `scripts/.session-cost.log.tmp` then atomically renames — the live log is never in a half-edited state.
4. Skipped rows remain ungraded.

## Usage

```
/grade-session              # walk all ungraded rows interactively
/grade-session --count      # just report how many are ungraded, don't prompt
```

## Rubric (from docs/AGENT_LEARNINGS.md)

- **shipped** — PR merged, feature live, no regressions. User-visible outcome.
- **partial** — Got part of the way; ≥1 follow-up queued. Not a failure but not done.
- **reverted** — Shipped and rolled back (within 7 days) for any reason.
- **blocked** — External dependency, missing info, or repro-needed killed the session.
- **plan-only** — Intentional: user asked for a plan/research, not a ship. No code outcome expected.

Grades feed the P5.1 meta-agent (deferred +90 days) and weekly reviews. Grade within 24h for highest signal.
