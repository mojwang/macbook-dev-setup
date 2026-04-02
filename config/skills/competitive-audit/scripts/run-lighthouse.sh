#!/usr/bin/env bash
set -e

# Run Lighthouse audits on a list of URLs.
# Usage: run-lighthouse.sh <output-dir> url1 url2 ...
# Requires: npm install -g lighthouse

OUTPUT_DIR="${1:?Usage: run-lighthouse.sh <output-dir> url1 url2 ...}"
shift

mkdir -p "$OUTPUT_DIR"

for url in "$@"; do
  slug=$(echo "$url" | sed 's|https\?://||;s|/|_|g;s|[^a-zA-Z0-9_.-]||g')
  echo "Running Lighthouse on ${url}..."
  npx lighthouse "$url" \
    --output=json,html \
    --output-path="${OUTPUT_DIR}/${slug}" \
    --chrome-flags="--headless --no-sandbox" \
    --only-categories=accessibility,performance,best-practices,seo \
    --quiet 2>/dev/null || echo "  ⚠ Lighthouse failed for ${url}"
  echo "  → ${OUTPUT_DIR}/${slug}.report.html"
done
