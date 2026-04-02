#!/usr/bin/env bash
set -e

# Check staged files for secrets, credentials, and large binaries.
# Usage: check-staged-files.sh

ISSUES=0

# Check for sensitive file patterns
SENSITIVE_PATTERNS=(".env" ".env.local" ".env.production" "*.key" "*.pem" "*.p12" "*.pfx" "credentials.json" "service-account.json")

for pattern in "${SENSITIVE_PATTERNS[@]}"; do
  matches=$(git diff --cached --name-only -- "$pattern" 2>/dev/null || true)
  if [[ -n "$matches" ]]; then
    echo "✗ Sensitive file staged: ${matches}"
    ISSUES=$((ISSUES + 1))
  fi
done

# Check for large files (>1MB)
while IFS= read -r file; do
  if [[ -n "$file" ]]; then
    size=$(git cat-file -s ":${file}" 2>/dev/null || echo "0")
    if [[ "$size" -gt 1048576 ]]; then
      size_mb=$(echo "scale=1; ${size}/1048576" | bc)
      echo "✗ Large file staged: ${file} (${size_mb}MB)"
      ISSUES=$((ISSUES + 1))
    fi
  fi
done < <(git diff --cached --name-only 2>/dev/null)

if [[ "$ISSUES" -eq 0 ]]; then
  echo "✓ No sensitive files or large binaries detected"
else
  echo "⚠ Found ${ISSUES} issue(s) in staged files"
  exit 1
fi
