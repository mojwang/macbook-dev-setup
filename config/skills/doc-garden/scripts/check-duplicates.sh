#!/usr/bin/env bash
set -e

# Find duplicate paragraphs across markdown files.
# Usage: check-duplicates.sh [root-dir]

DIR="${1:-.}"

echo "Scanning for duplicate content across markdown files..."

# Extract paragraphs (3+ consecutive non-empty lines) and look for duplicates
# This is a simple heuristic — the model does the real dedup analysis
TEMP=$(mktemp)
trap 'rm -f "$TEMP"' EXIT

find "$DIR" -name "*.md" -not -path "*/node_modules/*" -not -path "*/.next/*" | while read -r mdfile; do
  # Extract lines that are substantial (>40 chars, not headings, not code fences)
  grep -n '^[^#`|>-].\{40,\}' "$mdfile" 2>/dev/null | while IFS=: read -r linenum content; do
    # Normalize whitespace for comparison
    normalized=$(echo "$content" | tr -s ' ' | sed 's/^ *//;s/ *$//')
    echo "${normalized}	${mdfile}:${linenum}" >> "$TEMP"
  done
done

# Find duplicates
if [[ -s "$TEMP" ]]; then
  sort "$TEMP" | uniq -d -f0 | cut -f1 | while IFS= read -r dup; do
    echo "  Duplicate content found:"
    grep -F "$dup" "$TEMP" | cut -f2 | while read -r loc; do
      echo "    - ${loc}"
    done
    echo ""
  done
fi

echo "Done."
