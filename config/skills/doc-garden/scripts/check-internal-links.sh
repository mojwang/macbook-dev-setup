#!/usr/bin/env bash
set -e

# Check markdown files for internal file path references that don't resolve.
# Usage: check-internal-links.sh [root-dir]

DIR="${1:-.}"
ISSUES=0

find "$DIR" -name "*.md" -not -path "*/node_modules/*" -not -path "*/.next/*" -not -path "*/out/*" | while read -r mdfile; do
  # Extract markdown link targets that look like relative paths
  grep -oE '\]\([^)]+\)' "$mdfile" 2>/dev/null | sed 's/\](\(.*\))/\1/' | grep -v '^http' | grep -v '^#' | grep -v '^mailto:' | while read -r ref; do
    # Strip any anchor
    path="${ref%%#*}"
    if [[ -n "$path" && ! -f "${DIR}/${path}" && ! -d "${DIR}/${path}" ]]; then
      echo "  ✗ ${mdfile}: links to ${ref} (not found)"
      ISSUES=$((ISSUES + 1))
    fi
  done

  # Extract backtick-wrapped file paths
  grep -oE '`[a-zA-Z0-9_./-]+\.(ts|tsx|js|jsx|md|mdx|sh|json|css|toml)`' "$mdfile" 2>/dev/null | tr -d '`' | while read -r ref; do
    if [[ ! -f "${DIR}/${ref}" && ! -f "${ref}" ]]; then
      echo "  ? ${mdfile}: references \`${ref}\` (may not exist)"
    fi
  done
done

echo "Internal link check complete."
