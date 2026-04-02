#!/usr/bin/env bash
set -e

# Capture screenshots at 3 viewport sizes using Playwright.
# Usage: capture-screenshots.sh <url> <output-dir>
# Requires: npx playwright install chromium

URL="${1:?Usage: capture-screenshots.sh <url> <output-dir>}"
OUTPUT_DIR="${2:-.}"

VIEWPORTS=("1440x900" "768x1024" "390x844")

for vp in "${VIEWPORTS[@]}"; do
  width="${vp%x*}"
  height="${vp#*x}"
  filename="${OUTPUT_DIR}/screenshot-${width}x${height}.png"
  echo "Capturing ${URL} at ${vp}..."
  npx playwright screenshot --viewport-size="${width},${height}" "$URL" "$filename" 2>/dev/null
  echo "  → ${filename}"
done
