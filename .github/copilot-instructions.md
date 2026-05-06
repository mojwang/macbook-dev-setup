# Copilot instructions

Applies to Copilot code review, Chat, and inline generation. Canonical: `macbook-dev-setup/.github/copilot-instructions.md`; synced to sibling repos via `macbook-dev-setup/scripts/sync-copilot-instructions.sh`. Edit the canonical, then re-sync downstream — the `## Canonical source` section below has the full rationale.

## Project context

For repo-specific context (stack, conventions, architectural decisions, voice), read the repo's own `CLAUDE.md`, `README.md`, or equivalent. Review guidance below applies universally — review each PR against the *repo's* stated conventions, not patterns from other sibling repos.

## Canonical source

This file is synced from `macbook-dev-setup/.github/copilot-instructions.md` via `macbook-dev-setup/scripts/sync-copilot-instructions.sh`. Edit the canonical; re-sync downstream. Don't edit the copy in a sibling repo without also editing the canonical, or the next sync overwrites the local change.

## Review focus

When reviewing a PR, prioritize these concerns in roughly this order.

### Silent or cached failure modes
- A `catch` that returns an empty / default value inside anything wrapped in `unstable_cache`, React `cache()`, or similar memoization. Once cached, the empty state persists until explicit invalidation. Flag it — suggest a cache-boundary split (throw on error from the cached layer; handle fallback uncached).
- Swallowed errors without logging, or logging without enough context to distinguish sources.
- `try/catch` around code that probably shouldn't fail — often papers over a real bug.

### Cache correctness
- Two cache layers keyed on different normalizations of the same input (e.g. React cache on raw string, `unstable_cache` on sliced string). Both layers must key on the same normalized value.
- Heavy fields (embeddings, large blobs) in a cached projection when consumers don't read them. Flag as cache-payload bloat; suggest explicit column selection.
- Tags referenced in `revalidateTag(...)` with no queries that actually set the tag — dead code.

### Docs ↔ code drift
- Comments / docstrings / PR descriptions that misdescribe actual behavior. Call out specific divergences: "doc says X, code does Y — pick one."
- Stale references to functions, files, or line numbers that have moved. Cite the current location.
- Claims of "deduped," "normalized," "validated," etc. that aren't actually enforced in code.

### Defense-in-depth on user-facing paths
- `useSearchParams().get()` already returns decoded values; calling `decodeURIComponent` again is redundant AND throws `URIError` on malformed percent-encoding.
- Bash scripts without `set -euo pipefail` or equivalent.
- Bash flag parsing that references `$2` without guarding against end-of-args (crashes with `set -u`).
- Shell command construction where user input flows into `eval`, `path.resolve`, or subshell args without validation.

### Duplication and magic numbers
- Literal numbers that appear in multiple files (`3600`, `2000`, etc.) — usually belong in a named constant.
- Patterns copy-pasted across files with identical bodies — usually belong in a shared helper.
- Config scattered across files when one module could own it (e.g., cache timings).
- **Hotfix discipline:** when a PR fixes a bug in file A, check whether the same pattern exists in neighbor files B and C. Flag the scope.

### Security + safety
- Secrets or API keys in client-bundled code, committed `.env` files, or agent frontmatter.
- `Bash` commands that touch paid services (Stripe, x402, Browserbase, parallel.ai, tempo) without the `CLAUDE_ALLOW_PAYMENTS=1` escape valve — the payment-safety hook exists for a reason.
- Secrets (API keys, DB admin creds) in committed `.env.local` or any checked-in env file. Repo-specific env-file conventions live in that repo's CLAUDE.md.

## Universal discipline (applies to every repo this file is synced to)

- **Commit format:** Conventional Commits — `type(scope): description`. Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert.
- **Small commits:** aim for <200 LOC per diff. Larger is sometimes right, but call out the reason in the commit body.
- **No `Co-Authored-By` Claude tags** in commits or PRs. No "Generated with Claude Code" footers.
- **PR titles** are the TL;DR; detail goes in the body.
- **PR bodies** include a Test plan with specific, runnable checks — not "verified locally" without saying what was verified.

## Project-specific voice and style

This file does not prescribe voice. Each repo owns its own tone:
- Writing / comments / PR bodies should match the repo's existing CLAUDE.md or equivalent style guide.
- If a repo's style is silent on a point, follow the surrounding code's idiom, not a preference from another repo.
- Don't suggest style edits purely on voice grounds when the surrounding code is consistent with itself.

## Skip (don't suggest these)

- **Known, repo-specific deferrals** (e.g., "migrate to X", "adopt Y provider"). If a repo has an active deferral, it lives in that repo's CLAUDE.md or a TODO file — do not re-flag it here from a general stance.
- **Generic "consider adding tests"** without naming the specific behavior gap the new test would close.
- **Style-only nits** in files the PR didn't change.
- **Renaming for taste** unless it prevents a future conflict or bug.
- **Introducing new runtime dependencies** to replace a small amount of custom code.
- **Vercel-specific "migrate to X" advice** unless X is a current, non-deprecated product.

## What good feedback looks like

Concrete, cites file + line, suggests a specific fix, explains the failure mode it prevents. Example: *"`getNoteBySlugCached` uses `.select()` (all columns) including the 1536-dim embedding vector — ~12KB per cached row. Consider selecting only the 8 fields `/mind/[slug]/page.tsx` reads, because the embedding is never consumed by callers."*

Not: *"Consider narrowing the column selection."*

## When in doubt

If you can't decide whether to flag something, err toward naming the specific concrete risk and letting the author judge. Vague concerns ("this could be clearer") create review noise; specific ones ("line 47 swallows a network error that was previously surfaced") earn their place.
