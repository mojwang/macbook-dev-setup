---
name: reflect
description: Capture non-obvious lessons from recent activity. Dispatches the reflector agent to scan commits, edits, and dispatches in scope and propose memory-entry candidates ready to accept.
user-invocable: true
allowed-tools: Read, Bash, Grep, Glob
---

# Reflect

Catch lessons before they evaporate. The reflector agent scans recent activity, finds non-obvious moments worth carrying forward, and proposes structured memory-entry candidates per the workspace's feedback-memory format.

## When to use

- After a PR merges and you noticed something non-obvious during the work
- After multi-step debugging where a pattern emerged
- At end of session when the work was substantive (not routine)
- Whenever you corrected the system on something specific — the correction is the lesson

Skip when the session was routine. Most sessions don't produce lessons; that's fine.

## What this does

1. Parses `$ARGUMENTS` for scope:
   - No arg → last session (recent commits + recent edits + recent agent dispatches)
   - `--pr <N>` → activity scoped to PR N
   - `--last <N> commits` → last N commits on current branch
   - `--since YYYY-MM-DD` → activity since date

2. Dispatches the **reflector** agent (via the Task tool with `subagent_type: reflector`) with the scoped context.

3. The agent returns 0-N memory-entry candidates with triggering moments, lessons, and ready-to-paste MEMORY.md pointer lines.

4. You accept / reject / edit each candidate. Files are written only after your acceptance.

Arguments: $ARGUMENTS
