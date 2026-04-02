#!/usr/bin/env bash
set -e

# Initialize shadcn/ui with standard settings.
# Usage: init-shadcn.sh [target-dir]

DIR="${1:-.}"
cd "$DIR"

echo "Initializing shadcn/ui..."
npx shadcn@latest init \
  --defaults \
  --src-dir \
  2>&1

echo "shadcn/ui initialized."
