#!/usr/bin/env bash
# sync-agentic.sh — Symlink-based agentic infrastructure sync
# macbook-dev-setup is the single source of truth for agents, skills, and commands.
# This script creates symlinks from target projects to the canonical source.

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MACBOOK="$SCRIPT_DIR"

# Source personal config if available
# shellcheck disable=SC1091
source "$MACBOOK/.personal/config.sh" 2>/dev/null || true

# Shared agents (canonical source: .claude/agents/)
SHARED_AGENTS=(researcher planner implementer reviewer product-strategist product-tactician designer writer)

# Core skills (canonical source: .claude/skills/)
CORE_SKILLS=(commit-review product-lab deep-research security-review shell-conventions)

# Web project skills (canonical source: config/skills/)
WEB_SKILLS=(doc-garden design-review design-elevation web-review typescript-conventions entropy-scan init-design-system competitive-audit)

# Shared commands (canonical source: .claude/commands/)
SHARED_COMMANDS=(deep-research product-lab)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

ok() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}!${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; }

usage() {
  cat <<EOF
Usage: $(basename "$0") <target-path> [--type shell|web|workspace] [--verify] [--fix]

Modes:
  <target-path>              Create symlinks from target project to macbook-dev-setup
  <target-path> --verify     Check all symlinks resolve correctly
  <target-path> --fix        Repair broken symlinks
  --verify                   Verify all known targets

Options:
  --type shell    Core skills only (default)
  --type web      Core + web project skills
  --type workspace  Core + web skills + shared commands

Examples:
  $(basename "$0") \$SECOND_BRAIN_HOME --type workspace
  $(basename "$0") \$SECOND_BRAIN_HOME/repos/personal/ihw --type web
  $(basename "$0") --verify
EOF
  exit 1
}

detect_type() {
  local target="$1"
  if [[ -f "$target/.claude/project.json" ]]; then
    jq -r '.type // "shell"' "$target/.claude/project.json" 2>/dev/null || echo "shell"
  else
    echo "shell"
  fi
}

create_symlinks() {
  local target="$1"
  local type="${2:-shell}"

  echo "Syncing $target (type: $type)"
  echo "Source: $MACBOOK"
  echo ""

  # Agents
  mkdir -p "$target/.claude/agents"
  for agent in "${SHARED_AGENTS[@]}"; do
    local src="$MACBOOK/.claude/agents/$agent.md"
    local dst="$target/.claude/agents/$agent.md"
    if [[ ! -f "$src" ]]; then
      warn "Source agent missing: $src"
      continue
    fi
    if [[ -L "$dst" ]]; then
      local current
      current=$(readlink "$dst")
      if [[ "$current" == "$src" ]]; then
        ok "agents/$agent.md (already linked)"
        continue
      fi
      rm "$dst"
    elif [[ -f "$dst" ]]; then
      rm "$dst"
    fi
    ln -s "$src" "$dst"
    ok "agents/$agent.md → macbook-dev-setup"
  done

  # Core skills
  mkdir -p "$target/.claude/skills"
  for skill in "${CORE_SKILLS[@]}"; do
    local src="$MACBOOK/.claude/skills/$skill"
    local dst="$target/.claude/skills/$skill"
    if [[ ! -d "$src" ]]; then
      warn "Source skill missing: $src"
      continue
    fi
    if [[ -L "$dst" ]]; then
      local current
      current=$(readlink "$dst")
      if [[ "$current" == "$src" ]]; then
        ok "skills/$skill (already linked)"
        continue
      fi
      rm "$dst"
    elif [[ -d "$dst" ]]; then
      rm -rf "$dst"
    fi
    ln -s "$src" "$dst"
    ok "skills/$skill → macbook-dev-setup/.claude/skills/"
  done

  # Web skills (for web and workspace types)
  if [[ "$type" == "web" || "$type" == "workspace" ]]; then
    for skill in "${WEB_SKILLS[@]}"; do
      local src="$MACBOOK/config/skills/$skill"
      local dst="$target/.claude/skills/$skill"
      if [[ ! -d "$src" ]]; then
        warn "Source web skill missing: $src"
        continue
      fi
      if [[ -L "$dst" ]]; then
        local current
        current=$(readlink "$dst")
        if [[ "$current" == "$src" ]]; then
          ok "skills/$skill (already linked)"
          continue
        fi
        rm "$dst"
      elif [[ -d "$dst" ]]; then
        rm -rf "$dst"
      fi
      ln -s "$src" "$dst"
      ok "skills/$skill → macbook-dev-setup/config/skills/"
    done
  fi

  # Commands (for workspace type)
  if [[ "$type" == "workspace" ]]; then
    mkdir -p "$target/.claude/commands"
    for cmd in "${SHARED_COMMANDS[@]}"; do
      local src="$MACBOOK/.claude/commands/$cmd.md"
      local dst="$target/.claude/commands/$cmd.md"
      if [[ ! -f "$src" ]]; then
        warn "Source command missing: $src"
        continue
      fi
      if [[ -L "$dst" ]]; then
        local current
        current=$(readlink "$dst")
        if [[ "$current" == "$src" ]]; then
          ok "commands/$cmd.md (already linked)"
          continue
        fi
        rm "$dst"
      elif [[ -f "$dst" ]]; then
        rm "$dst"
      fi
      ln -s "$src" "$dst"
      ok "commands/$cmd.md → macbook-dev-setup"
    done
  fi

  echo ""
  echo "Sync complete."
}

verify_target() {
  local target="$1"
  local errors=0

  echo "Verifying: $target"

  # Check agent symlinks
  for agent in "${SHARED_AGENTS[@]}"; do
    local dst="$target/.claude/agents/$agent.md"
    if [[ -L "$dst" ]]; then
      if [[ -e "$dst" ]]; then
        ok "agents/$agent.md"
      else
        fail "agents/$agent.md (broken symlink → $(readlink "$dst"))"
        errors=$((errors+1))
      fi
    elif [[ -f "$dst" ]]; then
      warn "agents/$agent.md is a regular file (not symlinked)"
      errors=$((errors+1))
    else
      fail "agents/$agent.md missing"
      errors=$((errors+1))
    fi
  done

  # Check skill symlinks
  local all_skills=("${CORE_SKILLS[@]}" "${WEB_SKILLS[@]}")
  for skill in "${all_skills[@]}"; do
    local dst="$target/.claude/skills/$skill"
    if [[ -L "$dst" ]]; then
      if [[ -e "$dst" ]]; then
        ok "skills/$skill"
      else
        fail "skills/$skill (broken symlink → $(readlink "$dst"))"
        errors=$((errors+1))
      fi
    fi
  done

  echo ""
  if [[ "$errors" -eq 0 ]]; then
    ok "All symlinks valid"
    return 0
  else
    fail "$errors issues found"
    return 1
  fi
}

verify_all() {
  local ws="${SECOND_BRAIN_HOME:-}"
  local all_ok=0

  if [[ -z "$ws" ]]; then
    fail "SECOND_BRAIN_HOME not set. Run setup-claude-agentic.sh or set it in .personal/config.sh"
    return 1
  fi

  local targets=("$ws")

  # Auto-discover: any repo with a .claude/ dir under repos/, any depth
  while IFS= read -r d; do
    targets+=("$d")
  done < <(find "$ws/repos" -name ".claude" -type d -exec dirname {} \; 2>/dev/null)

  for target in "${targets[@]}"; do
    # Skip the canonical source — its agents are regular files by design
    [[ "$(cd "$target" 2>/dev/null && pwd)" == "$(cd "$MACBOOK" 2>/dev/null && pwd)" ]] && continue
    if [[ -d "$target/.claude" ]]; then
      verify_target "$target" || all_ok=1
    fi
  done

  return "$all_ok"
}

# Parse arguments
TARGET=""
TYPE="shell"
MODE="sync"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --type) TYPE="$2"; shift 2 ;;
    --verify)
      if [[ -z "$TARGET" ]]; then
        verify_all
        exit $?
      fi
      MODE="verify"; shift ;;
    --fix) MODE="fix"; shift ;;
    --help|-h) usage ;;
    *)
      if [[ -z "$TARGET" ]]; then
        TARGET="$1"
      fi
      shift ;;
  esac
done

if [[ -z "$TARGET" && "$MODE" != "verify" ]]; then
  usage
fi

case "$MODE" in
  sync) create_symlinks "$TARGET" "$TYPE" ;;
  verify) verify_target "$TARGET" ;;
  fix) create_symlinks "$TARGET" "$TYPE" ;;
esac
