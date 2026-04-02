#!/usr/bin/env bash
set -e

# Verify current branch is not a protected branch.
# Usage: verify-branch.sh

PROTECTED_BRANCHES=("main" "master" "develop" "staging" "production")

CURRENT=$(git branch --show-current 2>/dev/null || echo "")

if [[ -z "$CURRENT" ]]; then
  echo "✗ Not on any branch (detached HEAD)"
  exit 1
fi

for branch in "${PROTECTED_BRANCHES[@]}"; do
  if [[ "$CURRENT" == "$branch" ]]; then
    echo "✗ On protected branch: ${CURRENT}. Create a feature branch first."
    exit 1
  fi
done

echo "✓ On branch: ${CURRENT}"
