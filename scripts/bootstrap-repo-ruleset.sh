#!/usr/bin/env bash
# Bootstrap a repo with fleet-standard governance:
#   1. Enable allow_auto_merge (required for --auto merge workflow)
#   2. Create the 'PR quality gates' branch ruleset from the canonical
#      template at config/rulesets/pr-quality-gates.json
#   3. Inject required_status_checks based on a preset
#
# Presets are status-check-list choices. Every preset uses the same
# pull_request / deletion / non_fast_forward / copilot_code_review /
# code_quality rules from the template — only the required-checks list
# differs per repo.
#
# IMPORTANT: required_status_checks context strings MUST match the
# check-run "name:" field GitHub emits (display name), NOT the workflow
# job ID. A job with `all-checks-pass:` / `name: All Checks Pass` emits
# a check named "All Checks Pass" — the ruleset context must say
# "All Checks Pass" or merges silently stay BLOCKED.
#
# Lesson source: mojwang/ihw#34 and mojwang/mojwang.tech#85 (Apr 2026)
# both BLOCKED until the four PATCHed rulesets converged to this shape.
#
# Usage:
#   ./scripts/bootstrap-repo-ruleset.sh <owner/repo> --preset <name>
#
# Presets:
#   repo-generic    No required status checks (vault / docs repos).
#   full-next       Standard Next.js CI: lint, typecheck, test, build,
#                   review, All Checks Pass, Lighthouse CI.
#   static-next     Static Next.js (output: export): lint, typecheck,
#                   test, review, All Checks Pass.
#   macbook-setup   macbook-dev-setup convention: test,
#                   validate-documentation, security-scan,
#                   All Checks Pass.
#
# Requires: gh (authenticated), jq.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE="$REPO_ROOT/config/rulesets/pr-quality-gates.json"

usage() {
    cat <<EOF
Usage: $(basename "$0") <owner/repo> --preset <repo-generic|full-next|static-next|macbook-setup>

Enables allow_auto_merge on the repo and creates a 'PR quality gates'
ruleset from $TEMPLATE, injecting required_status_checks based on the
preset.

Flags:
  --preset <name>   Required. One of: repo-generic, full-next,
                    static-next, macbook-setup.
  --dry-run         Print the ruleset payload that would be POSTed;
                    skip the API calls.
EOF
}

repo=""
preset=""
dry_run=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --preset)
            shift
            if [[ $# -lt 1 || "$1" == -* ]]; then
                echo "Error: --preset requires a value" >&2
                usage >&2
                exit 2
            fi
            preset="$1"; shift ;;
        --dry-run) dry_run=1; shift ;;
        -h|--help) usage; exit 0 ;;
        -*) echo "Unknown flag: $1" >&2; usage >&2; exit 2 ;;
        *)
            if [[ -z "$repo" ]]; then
                repo="$1"
            else
                echo "Unexpected extra argument: $1" >&2
                usage >&2
                exit 2
            fi
            shift ;;
    esac
done

if [[ -z "$repo" || -z "$preset" ]]; then
    echo "Error: both <owner/repo> and --preset are required" >&2
    usage >&2
    exit 2
fi

if [[ ! -f "$TEMPLATE" ]]; then
    echo "Error: template not found at $TEMPLATE" >&2
    exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
    echo "Error: gh CLI is required" >&2
    exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is required" >&2
    exit 1
fi

# Preset → required_status_checks list. Display names only (see header).
case "$preset" in
    repo-generic)
        checks_json='[]' ;;
    full-next)
        checks_json='[{"context":"lint"},{"context":"typecheck"},{"context":"test"},{"context":"build"},{"context":"review"},{"context":"All Checks Pass"},{"context":"Lighthouse CI"}]' ;;
    static-next)
        checks_json='[{"context":"lint"},{"context":"typecheck"},{"context":"test"},{"context":"review"},{"context":"All Checks Pass"}]' ;;
    macbook-setup)
        checks_json='[{"context":"test"},{"context":"validate-documentation"},{"context":"security-scan"},{"context":"All Checks Pass"}]' ;;
    *)
        echo "Error: unknown preset '$preset'" >&2
        usage >&2
        exit 2 ;;
esac

# Build the payload: load the template, then either insert or merge the
# required_status_checks rule. For repo-generic (empty list) we omit the
# rule entirely — a rule with zero checks still requires branches to be
# up-to-date with main, which is stricter than "no check gate at all."
#
# jq expressions:
#   - del(._comment) strips the top-level comment field (GitHub rejects it).
#   - The rules-array walk adds required_status_checks only when the preset
#     ships one, and does so idempotently (no duplicates on re-run).
if [[ "$checks_json" == "[]" ]]; then
    payload=$(jq 'del(._comment)' "$TEMPLATE")
else
    payload=$(jq --argjson checks "$checks_json" '
        del(._comment) |
        .rules += [{
            "type": "required_status_checks",
            "parameters": {
                "strict_required_status_checks_policy": true,
                "do_not_enforce_on_create": false,
                "required_status_checks": $checks
            }
        }]
    ' "$TEMPLATE")
fi

echo "Repo: $repo"
echo "Preset: $preset"
echo "Required checks: $(echo "$checks_json" | jq -c '.')"

if [[ "$dry_run" -eq 1 ]]; then
    echo ""
    echo "--- Dry-run payload ---"
    echo "$payload" | jq .
    exit 0
fi

echo ""
echo "Step 1/2: enabling allow_auto_merge on $repo…"
GH_FORCE_TTY=0 NO_COLOR=1 gh api --method PATCH "repos/$repo" \
    -F allow_auto_merge=true \
    --jq '{repo: "'"$repo"'", allow_auto_merge}'

echo ""
echo "Step 2/2: creating 'PR quality gates' ruleset on $repo…"
tmp=$(mktemp)
printf '%s' "$payload" > "$tmp"
response=$(GH_FORCE_TTY=0 NO_COLOR=1 gh api --method POST "repos/$repo/rulesets" --input "$tmp")
rm -f "$tmp"

echo "$response" | jq '{id, name, enforcement, updated_at, rules_count: (.rules | length)}'

echo ""
echo "Done. Open a PR against the default branch to verify:"
echo "  - Copilot auto-request fires on push"
echo "  - All required status checks gate the merge"
echo "  - Conversation resolution gates the merge"
