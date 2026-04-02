#!/usr/bin/env bash
set -e

# Scan for hardcoded color values in component/style files.
# Usage: scan-hardcoded-colors.sh [src-dir]

DIR="${1:-src}"

echo "Scanning for hardcoded colors in ${DIR}/..."

# Hex colors (#xxx, #xxxxxx, #xxxxxxxx)
echo "--- Hex colors ---"
grep -rn '#[0-9a-fA-F]\{3,8\}\b' "$DIR" \
  --include="*.tsx" --include="*.ts" --include="*.css" --include="*.jsx" \
  2>/dev/null | grep -v 'node_modules' | grep -v '.test.' || echo "  None found"

# rgb/rgba/hsl values
echo "--- rgb/rgba/hsl values ---"
grep -rn 'rgb\(a\?\)\s*(' "$DIR" \
  --include="*.tsx" --include="*.ts" --include="*.css" --include="*.jsx" \
  2>/dev/null | grep -v 'node_modules' | grep -v '.test.' || echo "  None found"
