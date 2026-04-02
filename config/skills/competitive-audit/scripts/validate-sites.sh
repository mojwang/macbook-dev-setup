#!/usr/bin/env bash
set -e

# Validate that competitor sites are reachable before auditing.
# Usage: validate-sites.sh site1.com site2.com ...

TIMEOUT=30

for site in "$@"; do
  url="https://${site}"
  status=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$TIMEOUT" "$url" 2>/dev/null || echo "000")
  if [[ "$status" == "200" || "$status" == "301" || "$status" == "302" ]]; then
    echo "✓ $url ($status)"
  else
    echo "✗ $url (HTTP $status — skipping)"
  fi
done
