#!/usr/bin/env bash
set -e

# Scan for exported symbols that have no importers.
# Usage: scan-unused-exports.sh [src-dir]

DIR="${1:-src}"

echo "Scanning for potentially unused exports in ${DIR}/..."

# Find all named exports
grep -rn 'export \(function\|const\|class\|type\|interface\|enum\) ' "$DIR" \
  --include="*.ts" --include="*.tsx" \
  2>/dev/null | grep -v 'node_modules' | grep -v '.test.' | while IFS= read -r line; do
  # Extract the symbol name
  symbol=$(echo "$line" | sed -E 's/.*export (function|const|class|type|interface|enum) ([a-zA-Z0-9_]+).*/\2/')
  file=$(echo "$line" | cut -d: -f1)

  if [[ -n "$symbol" && "$symbol" != "$line" ]]; then
    # Count how many files import this symbol (excluding the defining file)
    importers=$(grep -rl "$symbol" "$DIR" \
      --include="*.ts" --include="*.tsx" \
      2>/dev/null | grep -v "$file" | grep -vc 'node_modules')

    if [[ "$importers" -eq 0 ]]; then
      echo "  ? ${file}: export ${symbol} (0 importers)"
    fi
  fi
done

echo "Done. Review results — some exports may be used dynamically or by external consumers."
