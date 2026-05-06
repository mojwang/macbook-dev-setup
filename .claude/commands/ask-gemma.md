---
description: Ad-hoc query to the local Gemma 4 31B IT server (mlx_lm.server on localhost:8080). $0/query, ~2-5s first-token, sovereignty-friendly — content never leaves the machine. Escape hatch for quick queries; critical-path integrations live inside /vault-ask, /process-inbox, /graduate-notes, /vault-brief.
allowed-tools: Bash
---

# Ask Gemma

Run the local Gemma query helper, forwarding any user-supplied args:

```
./scripts/ask-gemma.sh $ARGUMENTS
```

## Usage

```
/ask-gemma "<prompt>"
/ask-gemma --file <path> "Summarize in one paragraph"
/ask-gemma --system "You are a terse reviewer." "Fact-check: <claim>"
/ask-gemma --max-tokens 20 "Count to 100"
```

## Flags

- **`--file <path>`** — inject file content as a user-message prefix (the prompt becomes the question about that file).
- **`--system "..."`** — explicit system prompt. Default is a terse, no-filler assistant.
- **`--max-tokens N`** — cap output length. Default 1024.

## Reach-for-it cases

1. **Quick standalone query** — no vault, no context needed.
2. **Summarize / rephrase a file** — `--file` pipes the file in.
3. **Diverse second opinion on Claude's answer** — paste Claude's conclusion, ask Gemma for counter-argument.
4. **Bulk/repetitive classification** — cheap to run 50× in a loop.
5. **Sovereignty-sensitive drafts** — health/wealth/IHW content stays local.
6. **When Anthropic is rate-limited or down** — degraded-mode fallback.

## What it's NOT for

- Multi-file code edits (Claude Code is better)
- Vault-ask-class queries needing multi-round retrieval (use `/vault-ask`)
- Decision triggers needing full vault context (use `/vault-ask`)
- Anything that needs tool use (Bash, Read, Edit)

## Prerequisites

- mlx-lm installed (`pip3 install mlx mlx-lm`)
- Model downloaded (`mlx-community/gemma-4-31b-it-4bit`)
- Server running at `localhost:8080` — started via `./scripts/mlx-server-start.sh` or the `com.mojwang.mlx-server` LaunchAgent.
- `./scripts/local-model-check.sh` passes.
