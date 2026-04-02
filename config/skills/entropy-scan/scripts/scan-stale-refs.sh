#!/usr/bin/env bash
set -e

# Scan markdown files for internal file path references that don't resolve.
# Usage: scan-stale-refs.sh [root-dir]

DIR="${1:-.}"

echo "Scanning for stale internal references in ${DIR}/..."

# Find all markdown files
find "$DIR" -name "*.md" -not -path "*/node_modules/*" -not -path "*/.next/*" | while read -r mdfile; do
  # Extract file path references (backtick-wrapped paths and markdown links)
  grep -oE '`[a-zA-Z0-9_./-]+\.(ts|tsx|js|jsx|md|mdx|sh|json|css)`' "$mdfile" 2>/dev/null | tr -d '`' | while read -r ref; do
    # Check if the referenced file exists (relative to repo root)
    if [[ ! -f "${DIR}/${ref}" && ! -f "${ref}" ]]; then
      echo "  ✗ ${mdfile}: references ${ref} (not found)"
    fi
  done
done

echo "Done."
