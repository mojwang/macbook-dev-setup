#!/usr/bin/env bash

# Configure GitHub repository settings and rulesets for CI/CD workflow
# Run after creating a repo with: gh repo create --source=. --push
#
# Usage: ./setup-github-repo.sh [REPO] [--type shell|web]
#   REPO defaults to the current git remote origin
#   --type determines which CI job names to require (default: base)
#
# What this configures:
#   - Repository ruleset "PR quality gates" with:
#     - Squash-only merges, no required approvals (solo dev)
#     - Required status checks (type-specific CI jobs + All Checks Pass)
#     - Branch deletion and force-push protection
#     - Admin bypass for emergency merges
#   - Copilot code review enabled (auto-reviews, non-blocking)
#
# Prerequisites:
#   - gh CLI authenticated with admin access
#   - Repository must already exist on GitHub

set -e

# ─────────────────────────────────────────────────────────────────────────────
# Parse arguments
# ─────────────────────────────────────────────────────────────────────────────

REPO=""
PROJECT_TYPE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --type) PROJECT_TYPE="${2:-}"; shift 2 ;;
        --help|-h)
            echo "Usage: $0 [REPO] [--type shell|web]"
            echo ""
            echo "Configure GitHub repo ruleset and settings."
            echo "REPO defaults to current git remote origin."
            echo ""
            echo "Types:"
            echo "  shell  — requires: test, shellcheck, security-scan, All Checks Pass"
            echo "  web    — requires: test, lint, typecheck, build, All Checks Pass"
            echo "  (none) — requires: All Checks Pass only"
            exit 0
            ;;
        *) REPO="$1"; shift ;;
    esac
done

# Auto-detect repo from git remote
if [[ -z "$REPO" ]]; then
    REPO=$(gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null || true)
    if [[ -z "$REPO" ]]; then
        echo "Error: Could not detect repository. Pass REPO as argument or run from a git repo." >&2
        exit 1
    fi
fi

echo "Configuring repository: $REPO (type: ${PROJECT_TYPE:-base})"

# ─────────────────────────────────────────────────────────────────────────────
# Build required status checks based on project type
# ─────────────────────────────────────────────────────────────────────────────

build_status_checks() {
    local checks='[{"context": "All Checks Pass"}'

    case "$PROJECT_TYPE" in
        shell)
            checks="$checks"',{"context":"test"},{"context":"shellcheck"},{"context":"security-scan"}'
            ;;
        web)
            checks="$checks"',{"context":"test"},{"context":"lint"},{"context":"typecheck"},{"context":"build"}'
            ;;
    esac

    echo "${checks}]"
}

STATUS_CHECKS=$(build_status_checks)

# ─────────────────────────────────────────────────────────────────────────────
# Check for existing ruleset
# ─────────────────────────────────────────────────────────────────────────────

EXISTING_RULESET_ID=""
SKIP_RULESETS=false
if ! EXISTING_RULESET_ID=$(gh api "repos/$REPO/rulesets" --jq '.[] | select(.name == "PR quality gates") | .id' 2>/dev/null); then
    echo "⚠ Rulesets not available (private repos require GitHub Pro). Skipping."
    echo "  To fix: make the repo public, or upgrade to GitHub Pro."
    SKIP_RULESETS=true
fi

# ─────────────────────────────────────────────────────────────────────────────
# Create or update ruleset
# ─────────────────────────────────────────────────────────────────────────────

RULESET_BODY=$(cat <<ENDJSON
{
  "name": "PR quality gates",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "exclude": [],
      "include": ["~DEFAULT_BRANCH"]
    }
  },
  "rules": [
    {
      "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 0,
        "dismiss_stale_reviews_on_push": false,
        "required_reviewers": [],
        "require_code_owner_review": false,
        "require_last_push_approval": false,
        "required_review_thread_resolution": false,
        "allowed_merge_methods": ["squash"]
      }
    },
    {
      "type": "required_status_checks",
      "parameters": {
        "strict_required_status_checks_policy": true,
        "required_status_checks": $STATUS_CHECKS
      }
    },
    {
      "type": "deletion"
    },
    {
      "type": "non_fast_forward"
    }
  ],
  "bypass_actors": [
    {
      "actor_id": 5,
      "actor_type": "RepositoryRole",
      "bypass_mode": "always"
    }
  ]
}
ENDJSON
)

if [[ "$SKIP_RULESETS" == "false" ]]; then
    if [[ -n "$EXISTING_RULESET_ID" ]]; then
        echo "Updating existing ruleset (ID: $EXISTING_RULESET_ID)..."
        echo "$RULESET_BODY" | gh api "repos/$REPO/rulesets/$EXISTING_RULESET_ID" -X PUT --input - > /dev/null
    else
        echo "Creating ruleset..."
        echo "$RULESET_BODY" | gh api "repos/$REPO/rulesets" -X POST --input - > /dev/null
    fi

    echo "✓ Ruleset 'PR quality gates' configured"
    echo "  - Squash-only merges"
    echo "  - Required checks: $(echo "$STATUS_CHECKS" | grep -o '"context"' | wc -l | tr -d ' ') job(s)"
    echo "  - Admin bypass enabled"
    echo "  - No required approvals (solo dev)"

    # Remove legacy branch protection if present (conflicts with rulesets)
    if gh api "repos/$REPO/branches/main/protection" > /dev/null 2>&1; then
        echo "Removing legacy branch protection (conflicts with rulesets)..."
        gh api "repos/$REPO/branches/main/protection" -X DELETE > /dev/null 2>&1 || true
        echo "✓ Legacy branch protection removed"
    fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# Configure CLAUDE_CODE_OAUTH_TOKEN secret
# ─────────────────────────────────────────────────────────────────────────────

KEYCHAIN_SERVICE="claude-code-oauth-token"
KEYCHAIN_ACCOUNT="github-actions"

# macOS security -w returns hex-encoded output for non-ASCII or binary-stored passwords
read_keychain_password() {
    local raw
    raw=$(security find-generic-password -s "$1" -a "$2" -w 2>/dev/null || true)
    [[ -z "$raw" ]] && return
    # Detect hex encoding: all hex chars + even length
    if [[ "$raw" =~ ^[0-9a-fA-F]+$ ]] && (( ${#raw} % 2 == 0 )); then
        local decoded
        decoded=$(printf '%s' "$raw" | xxd -r -p 2>/dev/null || true)
        if [[ -n "$decoded" ]] && [[ "$decoded" == sk-* ]]; then
            printf '%s' "$decoded"
            return
        fi
    fi
    printf '%s' "$raw"
}

# Check if secret already exists on the repo
EXISTING_SECRET=$(gh secret list -R "$REPO" 2>/dev/null | grep "^CLAUDE_CODE_OAUTH_TOKEN" || true)

if [[ -n "$EXISTING_SECRET" ]]; then
    echo "✓ CLAUDE_CODE_OAUTH_TOKEN already set on $REPO"
else
    # Try to read token from macOS Keychain
    TOKEN=""
    if command -v security &>/dev/null; then
        TOKEN=$(read_keychain_password "$KEYCHAIN_SERVICE" "$KEYCHAIN_ACCOUNT")
    fi

    if [[ -n "$TOKEN" ]]; then
        echo "$TOKEN" | gh secret set CLAUDE_CODE_OAUTH_TOKEN -R "$REPO" --body -
        echo "✓ CLAUDE_CODE_OAUTH_TOKEN set from Keychain"
    elif [[ -t 0 ]]; then
        # Interactive — prompt for token
        echo ""
        echo "CLAUDE_CODE_OAUTH_TOKEN not found in Keychain."
        echo "  Generate one: claude setup-token"
        echo ""
        read -r -p "Paste token (or press Enter to skip): " TOKEN
        if [[ -n "$TOKEN" ]]; then
            echo "$TOKEN" | gh secret set CLAUDE_CODE_OAUTH_TOKEN -R "$REPO" --body -
            echo "✓ CLAUDE_CODE_OAUTH_TOKEN set on $REPO"

            # Offer to save to Keychain for future repos
            read -r -p "Save to Keychain for future repos? [Y/n] " SAVE_CHOICE
            if [[ "${SAVE_CHOICE:-Y}" =~ ^[Yy]$ ]]; then
                security add-generic-password -s "$KEYCHAIN_SERVICE" -a "$KEYCHAIN_ACCOUNT" -w "$TOKEN" -U
                echo "✓ Token saved to Keychain (service: $KEYCHAIN_SERVICE)"
            fi
        else
            echo "⚠ Skipped — Claude review workflow will fail until token is set"
            echo "  Run: gh secret set CLAUDE_CODE_OAUTH_TOKEN -R $REPO"
        fi
    else
        # Non-interactive (piped/CI) — warn only
        echo "⚠ CLAUDE_CODE_OAUTH_TOKEN not set (no Keychain entry, non-interactive)"
        echo "  Store token: security add-generic-password -s $KEYCHAIN_SERVICE -a $KEYCHAIN_ACCOUNT -w <TOKEN> -U"
        echo "  Then re-run this script, or: gh secret set CLAUDE_CODE_OAUTH_TOKEN -R $REPO"
    fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# Remaining manual steps
# ─────────────────────────────────────────────────────────────────────────────

echo ""
echo "Optional manual steps:"
echo "  • Enable Copilot auto-review (non-blocking):"
echo "    → Settings > Code review > Copilot Code Review > Enable"
echo "    Note: Do NOT use copilot_code_review in rulesets — it's a hard merge gate"
