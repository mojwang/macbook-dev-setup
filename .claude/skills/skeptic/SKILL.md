---
name: skeptic
description: Adversarial critique on demand. Returns the strongest case AGAINST a draft, plan, or decision before it ships. Forbids generic mush.
user-invocable: true
allowed-tools: Read, Bash, Grep
---

# Skeptic

Get the strongest case against an artifact before you ship it. The skeptic agent argues the opposite position — counter-thesis, concrete failure modes, hidden assumptions — drawn from the artifact itself, vault counterweights, and past decision-records of similar shape.

## When to use

- Before /vault-publish on a non-trivial vault note (Gate 6 fires automatically on hub-importance notes; for lower-stakes notes that still matter, fire manually)
- Before committing a major decision-record
- Before sending an external memo or talk
- Before locking in a plan that has compounding consequences
- Whenever the existing pipeline (researcher → planner → implementer → reviewer) is starting to feel like an echo chamber

## What this does

Dispatches the **skeptic** agent (via the Task tool with `subagent_type: skeptic`) with $ARGUMENTS as the artifact.

`$ARGUMENTS` formats:
- File path: `vault/career/development/<slug>.md`
- Quoted text: `"the proposition to argue against"`
- PR reference: `--pr 88`

Output is structured: Counter-thesis / Failure modes / Hidden assumptions. Each item is artifact-specific and concrete; the agent prompt explicitly bans "on the other hand," "it depends," and unspecified-mechanism risks.

You decide if the objections land. The agent argues; you arbitrate.

Arguments: $ARGUMENTS
