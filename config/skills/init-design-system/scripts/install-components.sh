#!/usr/bin/env bash
set -e

# Install baseline shadcn/ui components.
# Usage: install-components.sh [target-dir]

DIR="${1:-.}"
cd "$DIR"

COMPONENTS=(
  button
  card
  input
  label
  badge
  separator
)

echo "Installing baseline components: ${COMPONENTS[*]}"
npx shadcn@latest add "${COMPONENTS[@]}" 2>&1

echo "Baseline components installed."
