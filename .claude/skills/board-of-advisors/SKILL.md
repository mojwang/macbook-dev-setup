---
name: board-of-advisors
description: Stress-test ideas, decisions, and exploratory thinking with a curated council of operating wisdom. Three modes — /boardroom explore (Socratic kernel work), /boardroom stress (structured pressure-test), /boardroom debate (multi-voice adversarial). Dispatches the boardroom orchestrator agent.
---

# Board of Advisors

Use this skill when Marvin invokes `/boardroom` or asks to:
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

The boardroom is **interactive by design** — the orchestrator (you) facilitates the dialogue directly, not via subagent dispatch. Read `repos/personal/macbook-dev-setup/.claude/agents/boardroom.md` to internalize the role for this session.

**Phase 1 — Council proposal (orchestrator, inline)**:
1. Read `repos/personal/macbook-dev-setup/.claude/skills/decision-lab/COUNCIL.md`
2. Load 2-3 most relevant vault notes for the topic (via `VAULT_MANIFEST.md`)
3. Propose a per-session council per the Council Selection logic — one-line reasoning per pick, named tension pair
4. Surface to user for approval / swap / custom
5. Wait for user response

**Phase 2 — Dialogue session (orchestrator-facilitated)**:
After approval, open Round 1: each advisor asks ONE pointed question to the CEO. Wait for the CEO to answer. Then channel Round 2 reactions based on what they said. Iterate 3-5 rounds until the kernel + recommendation are stable, or until the CEO signals done. See agent definition § Dialogue Pattern for round mechanics.

The dialogue IS the session. The orchestrator does not dispatch a subagent for this phase — it would break the closed feedback loop.

**Phase 3 — Synthesis + persistence (orchestrator)**:
When dialogue concludes, write the session log to `decision-lab/board-of-advisors/YYYY-MM-DD-<slug>-<mode>.md` per the schema in `decision-lab/board-of-advisors/README.md`. Capture the full dialogue transcript with **Bezos** / **Naval** / **Cagan** turn markers + **You** for CEO turns. Then synthesize, recommend, and offer optional grading + commit.

## Notes

- COUNCIL.md is the IP. It lives at `repos/personal/macbook-dev-setup/.claude/skills/decision-lab/COUNCIL.md`.
- Session logs land in working-dir `decision-lab/board-of-advisors/` (per project, not in this skill).
- Decision drafts land in workspace `_inbox/notes/`.
- For session-log schema, see `decision-lab/board-of-advisors/README.md` in the decision-lab skill directory.
