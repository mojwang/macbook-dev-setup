#!/usr/bin/env bash
set -e

# Skip if only non-visual files changed (both previews and production)
# CACHED_COMMIT_REF = last deployed commit, so diffs accumulate correctly
CHANGED=$(git diff --name-only "$CACHED_COMMIT_REF" "$COMMIT_REF")

if [ -z "$CHANGED" ]; then
  echo "No changes detected — building (safety fallback)"
  exit 1
fi

while IFS= read -r file; do
  case "$file" in
    # Docs and metadata
    CLAUDE.md|README.md|LICENSE*) ;;
    # Tooling and CI
    .github/*|.claude/*|e2e/*|tests/*) ;;
    # Test files
    *.test.ts|*.test.tsx|*.spec.ts) ;;
    # Non-content markdown (content MDX is .mdx, not .md)
    *.md) ;;
    # Everything else is build-affecting — proceed with build
    *) echo "Build-affecting file changed: $file" && exit 1 ;;
  esac
done <<< "$CHANGED"

echo "No build-affecting changes — skipping deploy"
exit 0  # exit 0 = skip build
