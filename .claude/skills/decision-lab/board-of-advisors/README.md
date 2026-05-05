# Board of Advisors — Session Logs

Convention reference for the boardroom agent + future-Marvin reading past sessions.

## Path

Session logs live in the **working directory** at `decision-lab/board-of-advisors/` (not in this skill directory). This README is the schema doc; actual session files accumulate per project.

## Filename

`YYYY-MM-DD-<slug>-<mode>.md`

- Date is the session date (not the topic date)
- Slug is a kebab-case shorthand for the topic (e.g., `ihw-pricing`, `mojwang-tech-pmf`)
- Mode is one of: `explore`, `stress`, `debate`

Examples:
- `2026-04-28-mojwang-tech-pmf-explore.md`
- `2026-05-01-ihw-house-call-pricing-stress.md`
- `2026-05-15-consulting-llc-vs-s-corp-debate.md`

## Schema

```markdown
---
title: "<topic statement>"
mode: <explore|stress|debate>
date: YYYY-MM-DD
council:
  - id: <advisor-id>
    role: "<one-line role this session>"
  - ...
tension-pairs: ["<id1> ↔ <id2>"]
decision-drafted: <path to _inbox/notes/decision-*.md or null>
grades:
  <id>: <1-3 or null>
---

## Topic
<topic statement, framed in user's own words>

## Council selection rationale
<why these advisors were proposed; what was swapped from the orchestrator's initial proposal>

## Session

### Turn 1
**<advisor-id>**: ...

### Turn 2
**<advisor-id>**: ...

...

## Synthesis
<orchestrator synthesis; for stress/debate: explicit verdict>

## Decision-record draft
<path to draft if any>
```

## Voice attribution rule

Within session logs and live boardroom output, advisors are introduced by their **source thinker name** (e.g. **Bezos**, **Naval**, **Cagan**) as the conversational marker — it's how Marvin recognizes who's speaking and grades the session. The advisor `id` still anchors structured metadata: frontmatter `council:` block, `track-record:` updates in COUNCIL.md, `natural-tensions:` cross-references.

```markdown
### Turn 1
**Bezos**: Write the press release. Headline, sub-head, customer quote. Who is the customer in that quote?

### Turn 2
**Naval**: Slow down. The press-release frame assumes you already know the product...
```

The no-brand-attribution rule still binds when session insights are graduated to vault notes or published externally. At that point the synthesis becomes Marvin's voice — the boardroom output is the working draft, not the final artifact.

## Track-record updates

After each session, the orchestrator updates the `track-record:` block in `COUNCIL.md` (sibling file) per advisor based on user grades. Sessions where the user skipped grading still count for `summon-count` and `last-summoned`.
