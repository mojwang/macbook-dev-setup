---
description: Append a row to scripts/.session-cost.log capturing this session's directional cost signal (topic, dispatches, models, outcome). Auto-captures timestamp + agent_sha. Outcome can be left empty to grade retroactively via /grade-session.
allowed-tools: Bash
---

# Log Session

Run the session logger script, forwarding any user-supplied args:

```
./scripts/log-session.sh $ARGUMENTS
```

## Usage

All flags are optional — the script prompts for missing required fields:

```
/log-session --topic "<one-liner>" --dispatches "<agent x tier or —>" --models "<comma-sep>" --outcome "<enum or empty>"
```

Example:

```
/log-session --topic "P0.2 session-logger infra" --dispatches "—" --models "sonnet" --outcome "shipped"
```

`--outcome ""` is valid — a blank outcome means "grade later." Use `/grade-session` (forthcoming in P0.3) to fill in retroactively.

## Fields

- **topic**: one-line session summary
- **dispatches**: agent count × tier (e.g. `Explore x3, Plan x1` or `—` for direct work)
- **models**: comma-separated as provided (e.g. `haiku,sonnet`) — logged as-is, no dedup
- **outcome**: one of `shipped | partial | reverted | blocked | plan-only` — or empty to grade later

Captured automatically:
- **timestamp**: ISO 8601 local time
- **agent_sha**: short SHA of the most recent commit that touched `.claude/agents/` as of logging time (correlates outcomes with prompt versions; reflects end-of-session state if agents were edited mid-session)
