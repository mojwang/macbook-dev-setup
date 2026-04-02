#!/usr/bin/env bash
set -e

# Verify project builds and lints after design system changes.
# Usage: verify-build.sh [target-dir]

DIR="${1:-.}"
cd "$DIR"

echo "Running build..."
if npm run build 2>&1; then
  echo "  ✓ Build passed"
else
  echo "  ✗ Build failed"
  exit 1
fi

echo "Running lint..."
if npm run lint 2>&1; then
  echo "  ✓ Lint passed"
else
  echo "  ✗ Lint failed (non-blocking)"
fi
