#!/usr/bin/env bash
set -e

# Detect project type and readiness for design system bootstrap.
# Usage: detect-project.sh [target-dir]

DIR="${1:-.}"

echo "Checking project at: ${DIR}"

check_file() {
  if [[ -f "${DIR}/$1" ]]; then
    echo "  ✓ $1"
    return 0
  else
    echo "  ✗ $1 (missing)"
    return 1
  fi
}

READY=true
check_file "package.json" || READY=false

# Tailwind config (multiple possible names)
if [[ -f "${DIR}/tailwind.config.ts" || -f "${DIR}/tailwind.config.js" || -f "${DIR}/tailwind.config.mjs" ]]; then
  echo "  ✓ tailwind.config.*"
else
  # Tailwind v4 may use @config in CSS instead of a config file
  if grep -rq "@tailwindcss" "${DIR}/package.json" 2>/dev/null; then
    echo "  ✓ Tailwind v4 (via package.json)"
  else
    echo "  ✗ tailwind.config.* (missing)"
    READY=false
  fi
fi

if check_file "src/components/ui" 2>/dev/null || check_file "components.json" 2>/dev/null; then
  echo "  ⚠ shadcn/ui may already be initialized"
fi

if [[ "$READY" == "true" ]]; then
  echo "Project is ready for design system bootstrap."
else
  echo "Project is missing prerequisites."
  exit 1
fi
