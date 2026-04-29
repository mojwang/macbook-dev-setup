---
name: board-of-advisors
description: Stress-test ideas, decisions, and exploratory thinking with a curated council of operating wisdom. Three modes — /advisors explore (Socratic kernel work), /advisors stress (structured pressure-test), /advisors debate (multi-voice adversarial). Dispatches the boardroom orchestrator agent.
---

# Board of Advisors

Use this skill when Marvin invokes `/advisors` or asks to:
- "stress-test this idea"
- "what would the board say about..."
- "I'm thinking about X — pressure-test it"
- "convene the advisors"
- any request involving multi-voice critique on a product / business / career decision

## Invocation

Parse arguments: `<mode> <topic> [--live | --synth] [--custom]`

**Modes:**
- `explore <kernel>` — Socratic, drop-in
- `stress <idea-or-decision>` — structured pressure-test
- `debate <contested-decision>` — multi-voice adversarial

**Defaults:**
- explore: `--synth`
- stress: `--synth`
- debate: `--live`

## Action

Dispatch the **boardroom** agent via the Task tool with this prompt template:

```
Mode: <mode>
Topic: <topic>
Synthesis: <--synth | --live>
Custom roster: <true|false>

Run the boardroom protocol:
1. Read decision-lab/COUNCIL.md
2. Load relevant vault context for the topic
3. Propose a per-session council (with reasoning per pick + named tension pair)
4. Await user approval / swap / custom
5. Run the session in <mode> mode
6. Persist session log to decision-lab/board-of-advisors/
7. Offer grading
8. Draft decision-record if applicable
```

The boardroom agent owns the rest of the lifecycle.

## Notes

- COUNCIL.md is the IP. It lives at `repos/personal/macbook-dev-setup/.claude/skills/decision-lab/COUNCIL.md`.
- Session logs land in working-dir `decision-lab/board-of-advisors/` (per project, not in this skill).
- Decision drafts land in workspace `_inbox/notes/`.
- For session-log schema, see `decision-lab/board-of-advisors/README.md` in the decision-lab skill directory.
