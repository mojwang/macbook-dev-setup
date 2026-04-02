#!/usr/bin/env bash
set -e

# Find TODO/FIXME comments with dates older than 30 days.
# Usage: find-stale-todos.sh [root-dir]

DIR="${1:-.}"
THRESHOLD_DAYS=30
NOW=$(date +%s)

echo "Scanning for stale TODOs (>${THRESHOLD_DAYS} days)..."

grep -rn 'TODO\|FIXME\|HACK\|XXX' "$DIR" \
  --include="*.md" --include="*.ts" --include="*.tsx" --include="*.sh" --include="*.js" \
  2>/dev/null | grep -v 'node_modules' | grep -v '.next' | while IFS= read -r line; do
  # Try to extract a date (YYYY-MM-DD format)
  date_match=$(echo "$line" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1)
  if [[ -n "$date_match" ]]; then
    todo_date=$(date -j -f "%Y-%m-%d" "$date_match" +%s 2>/dev/null || date -d "$date_match" +%s 2>/dev/null || echo "0")
    if [[ "$todo_date" -gt 0 ]]; then
      age_days=$(( (NOW - todo_date) / 86400 ))
      if [[ "$age_days" -gt "$THRESHOLD_DAYS" ]]; then
        echo "  ⚠ ${line%% *} (${age_days} days old)"
      fi
    fi
  fi
done

# Also report undated TODOs (can't track staleness without dates)
echo ""
echo "Undated TODOs (consider adding dates):"
grep -rn 'TODO\|FIXME' "$DIR" \
  --include="*.md" --include="*.ts" --include="*.tsx" --include="*.sh" \
  2>/dev/null | grep -v 'node_modules' | grep -v '.next' | grep -vE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -20 || echo "  None found"

echo "Done."
