---
name: voice-check
description: Run Marvin's voice gate on any prose — memos, emails, drafts, mojwang.tech content. Same checks /vault-publish Gate 1 runs but standalone and applicable beyond the vault.
user-invocable: true
allowed-tools: Read, Bash
---

# Voice Check

Run the voice gate on any prose, not just vault notes. Voice discipline is too valuable to be vault-locked.

## When to use

- Before sending leadership memos, internal write-ups, performance reviews
- Before publishing to mojwang.tech (perspectives posts, /how-i-lead edits, MDX content)
- Before posting public talks, slack standups, conference proposals
- Whenever voice consistency matters and the artifact isn't a vault note

## What this does

Dispatches the **writer** agent (via the Task tool with `subagent_type: writer`) with the same voice constraints used by `/vault-publish` Gate 1:

- No clinical jargon — see `JARGON_TOKENS` in `scripts/vault.py` (the source-of-truth)
- Em-dash discipline — periods, commas, semicolons preferred (per `feedback_no_em_dash_overuse.md`)
- TCK shorthand defined inline if used
- L1 → L2 → kernel → L3 structure where applicable (per `docs/specs/vault-schema.md`)
- Reads like Marvin: terse, specific, lived-in. Not abstract, not consultant-speak

Returns a verdict: **pass** | **fail with N specific edits** | **iterate**.

`$ARGUMENTS` formats:
- File path: `path/to/draft.md`
- Quoted text: `"the prose to check"`
- Stdin via `--stdin` flag

DRY guarantee: this skill and `/vault-publish` Gate 1 read from the same `JARGON_TOKENS` source-of-truth, so voice rules can't drift between the two surfaces.

Arguments: $ARGUMENTS
