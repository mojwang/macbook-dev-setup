#!/usr/bin/env bash
# sync-copilot-instructions.sh — Copy the canonical copilot-instructions.md
# to a target repo's .github/ directory.
#
# Unlike sync-agentic.sh (which symlinks), this script COPIES because
# GitHub reads .github/copilot-instructions.md server-side from each
# repo's own blob — symlinks outside the repo don't resolve. Each target
# repo commits its own copy.
#
# Usage:
#   sync-copilot-instructions.sh                   # auto-discover siblings
#   sync-copilot-instructions.sh /path/to/repo     # single target
#
# Auto-discovery walks $SECOND_BRAIN_HOME/repos/personal/*/ and copies
# the canonical into any repo that has a .github/ directory. Skips
# macbook-dev-setup itself (it IS the canonical).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MACBOOK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CANONICAL="$MACBOOK_ROOT/.github/copilot-instructions.md"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

if [[ ! -f "$CANONICAL" ]]; then
    echo -e "${RED}Canonical not found: $CANONICAL${NC}" >&2
    exit 1
fi

# Repo-leak lint: the canonical is synced to sibling repos, so any
# repo-specific path referenced here will appear — and confuse — in
# every sibling. Copilot caught this on mojwang/ihw#33 when the
# canonical referenced '.env.sync-vault.local' (a mojwang.tech-only
# convention) and 'src/db/queries/related.ts' (a mojwang.tech-only
# file). Fail fast before syncing if any such pattern leaks back in.
#
# Patterns intentionally narrow — they target known mojwang.tech
# project paths that showed up historically. Extend if new leaks
# surface during review.
LEAK_PATTERNS=(
    '\.env\.sync-vault'
    'src/db/queries/'
    'scripts/sync-vault\.'
)
leak_hits=""
for pattern in "${LEAK_PATTERNS[@]}"; do
    if hits=$(grep -nE "$pattern" "$CANONICAL" 2>/dev/null); then
        leak_hits+="  pattern: ${pattern}"$'\n'"${hits}"$'\n'
    fi
done
if [[ -n "$leak_hits" ]]; then
    {
        echo -e "${RED}Repo-specific paths detected in canonical — refusing to sync.${NC}"
        echo "These paths don't exist in sibling repos and will confuse Copilot on their PRs."
        echo "Canonical: $CANONICAL"
        echo ""
        echo "Matches:"
        echo "$leak_hits"
        echo "Fix: replace with repo-generic wording (e.g. 'secrets in committed .env.* files — repo-specific conventions live in that repo's CLAUDE.md')."
    } >&2
    exit 1
fi

# Allow override of the sibling-discovery root. Defaults match the same
# env var sync-agentic.sh uses, so both scripts share one config point.
# shellcheck disable=SC1091
source "$MACBOOK_ROOT/.personal/config.sh" 2>/dev/null || true
ROOT="${SECOND_BRAIN_HOME:-$HOME/ai/workspace/claude}/repos/personal"

copy_to() {
    local target_repo="$1"
    local target_dir="$target_repo/.github"
    local target_file="$target_dir/copilot-instructions.md"

    if [[ ! -d "$target_repo" ]]; then
        echo -e "${RED}✗ $target_repo — not a directory${NC}" >&2
        return 1
    fi

    if [[ "$(cd "$target_repo" && pwd)" = "$MACBOOK_ROOT" ]]; then
        # Canonical lives here; nothing to copy.
        return 0
    fi

    mkdir -p "$target_dir"

    if [[ -f "$target_file" ]] && cmp -s "$CANONICAL" "$target_file"; then
        echo -e "${GREEN}✓${NC} $target_repo (unchanged)"
        return 0
    fi

    cp "$CANONICAL" "$target_file"
    echo -e "${GREEN}✓${NC} $target_repo (copied)"
}

if [[ $# -gt 0 ]]; then
    # Explicit target(s): copy to each and exit.
    rc=0
    for target in "$@"; do
        copy_to "$target" || rc=$?
    done
    exit "$rc"
fi

# Auto-discover: any repo with .github/ directory under personal/
if [[ ! -d "$ROOT" ]]; then
    echo -e "${YELLOW}Discovery root not found: $ROOT${NC}" >&2
    echo "Set SECOND_BRAIN_HOME or pass an explicit target." >&2
    exit 1
fi

echo "Syncing copilot-instructions.md from: $CANONICAL"
echo "Discovery root: $ROOT"
echo

rc=0
for repo in "$ROOT"/*/; do
    repo="${repo%/}"
    if [[ -d "$repo/.github" ]]; then
        copy_to "$repo" || rc=$?
    fi
done

if [[ $rc -ne 0 ]]; then
    echo -e "${RED}Some copies failed.${NC}" >&2
fi
exit "$rc"
