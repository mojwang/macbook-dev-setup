---
name: entropy-scan
description: Run to detect pattern drift and inconsistencies across the codebase. User-invoked via /entropy-scan. Produces a prioritized report with file:line references.
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash
---

# Entropy Scan

Detect drift, inconsistencies, and accumulating technical debt before they compound. Run the mechanical scans first, then interpret results.

## Scan Sequence

### 1. Run scripts
Execute available scan scripts to collect raw data:
- `scripts/scan-hardcoded-colors.sh` — hex/rgb values in component files where tokens exist
- `scripts/scan-stale-refs.sh` — file paths and URLs that don't resolve
- `scripts/scan-unused-exports.sh` — exported symbols with no importers

### 2. Interpret results
For each finding from the scripts, the model:
- Determines if it's a real issue or a false positive (e.g., hex in a test fixture is fine)
- Assigns priority: P0 (fix now), P1 (fix this sprint), P2 (track for later)
- Groups related issues (e.g., 12 hardcoded grays = one migration task, not 12 issues)

### 3. Additional checks (model-driven)
Scan for patterns scripts can't catch:
- Inconsistent spacing values that don't match the project's rhythm
- Components using raw HTML where UI primitives exist
- Duplicate component patterns across files
- Stale TODO/FIXME comments older than 30 days

### 4. Produce report
Output format:
```
## Entropy Report — [date]

### P0 (fix now)
- [file:line] description — fix: remediation

### P1 (fix this sprint)
- [file:line] description — fix: remediation

### P2 (track)
- [file:line] description
```

### 5. Offer fixes
For P0 items, offer to open a fix-up PR. For P1/P2, log in `docs/AGENT_LEARNINGS.md` if the pattern is novel.

## Rules
- Never flag test fixtures or mock data as real issues
- Group related findings — 10 instances of the same pattern = one finding with count
- If the scan finds nothing, say so. An empty report is a good report.
