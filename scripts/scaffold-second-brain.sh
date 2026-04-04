#!/usr/bin/env bash
set -e

# scaffold-second-brain.sh — Create an empty second brain workspace
# Sets up directory structure, clones macbook-dev-setup, runs initial sync.
# Does NOT include vault methodology, templates, or custom skills — that's your IP.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MACBOOK_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source personal config if available
# shellcheck disable=SC1091
source "$MACBOOK_DIR/.personal/config.sh" 2>/dev/null || true

usage() {
  cat <<EOF
Usage: $(basename "$0") <path> [--github-user USER]

Creates an empty second brain workspace at <path> with:
  - vault/          Empty Obsidian vault
  - _inbox/         Capture staging area
  - repos/          Project directory (organize as you wish)
  - scripts/        Your custom automation
  - .claude/        Agentic infrastructure (symlinked from macbook-dev-setup)
  - CLAUDE.md       Starter instructions
  - .gitignore      Sensible defaults

macbook-dev-setup is cloned into repos/<user>/macbook-dev-setup/ automatically.

Examples:
  $(basename "$0") ~/ai/workspace/claude
  $(basename "$0") ~/second-brain --github-user myuser
EOF
  exit 1
}

# Parse args
TARGET=""
GH_USER="${GITHUB_USER:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --github-user) GH_USER="$2"; shift 2 ;;
    --help|-h) usage ;;
    *) TARGET="$1"; shift ;;
  esac
done

[[ -z "$TARGET" ]] && usage

# Resolve ~ and relative paths
TARGET="${TARGET/#\~/$HOME}"
TARGET="$(mkdir -p "$TARGET" && cd "$TARGET" && pwd)"

if [[ -z "$GH_USER" ]]; then
  if command -v gh &>/dev/null; then
    GH_USER=$(gh api user -q .login 2>/dev/null) || true
  fi
  if [[ -z "$GH_USER" ]]; then
    read -p "GitHub username: " GH_USER
  fi
fi

echo "Scaffolding second brain at: $TARGET"
echo "GitHub user: $GH_USER"
echo ""

# Create directory structure
mkdir -p "$TARGET/vault/.obsidian"
mkdir -p "$TARGET/_inbox/notes"
mkdir -p "$TARGET/_inbox/documents"
mkdir -p "$TARGET/_inbox/screenshots"
mkdir -p "$TARGET/repos/$GH_USER"
mkdir -p "$TARGET/scripts"
mkdir -p "$TARGET/.claude/agents"
mkdir -p "$TARGET/.claude/skills"
mkdir -p "$TARGET/.claude/commands"

# Minimal Obsidian config
cat > "$TARGET/vault/.obsidian/core-plugins.json" <<'OBSIDIAN'
["file-explorer","global-search","switcher","graph","backlink","outgoing-link","tag-pane","page-preview","daily-notes","templates","command-palette","editor-status","starred","outline","word-count"]
OBSIDIAN

cat > "$TARGET/vault/.obsidian/community-plugins.json" <<'OBSIDIAN'
["obsidian-git"]
OBSIDIAN

# Starter CLAUDE.md — layout and boundaries only, NO methodology
cat > "$TARGET/CLAUDE.md" <<'CLAUDEMD'
# CLAUDE.md — Second Brain Workspace

## Workspace Layout
- `vault/` — Obsidian vault (your knowledge base)
- `_inbox/` — Staging area for unprocessed content
- `repos/` — Git repositories managed by this workspace
- `scripts/` — Custom automation scripts
- `.claude/` — Agents, skills, and commands (symlinked from macbook-dev-setup)

## Git Workflow
- Feature branches only (never commit to main)
- Conventional commit format: `<type>(<scope>): <subject>`
- Small commits (<200 LOC diffs)

## Boundaries

**Always**: Use feature branches, follow project conventions

**Ask first**: Deleting vault notes, restructuring directories, adding dependencies

**Never**: Commit to main, commit secrets or .env files, force push

## Next Steps
- Open `vault/` in Obsidian
- Add your first note
- Customize this CLAUDE.md with your own workflow and methodology
- Create custom skills in `.claude/skills/` for your vault
- Add hooks in `.claude/settings.json` for automation
CLAUDEMD

# Starter .gitignore
cat > "$TARGET/.gitignore" <<'GITIGNORE'
# Capture inbox (symlinked to cloud storage)
_inbox/

# Nested git repos
repos/

# macOS
.DS_Store

# Ephemeral agentic artifacts
research.md
plan.md
design-spec.md
product-brief.md

# Local overrides
.claude/settings.local.json
.claude/.nudge-state/

# Embedding caches
scripts/.vault-embeddings.json
GITIGNORE

# Starter settings.json — basic hooks only
cat > "$TARGET/.claude/settings.json" <<'SETTINGS'
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash -c 'vault=\"$SECOND_BRAIN_HOME/vault\"; if [ -d \"$vault\" ]; then total=$(find \"$vault\" -name \"*.md\" -not -path \"*/.obsidian/*\" -not -path \"*/.git/*\" 2>/dev/null | wc -l | tr -d \" \"); echo \"Vault: $total notes\"; fi'",
            "timeout": 5,
            "statusMessage": "Checking vault..."
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash -c 'cmd=$(jq -r \".tool_input.command\" 2>/dev/null); if echo \"$cmd\" | grep -qE \"git commit|git merge|git push\"; then branch=$(git branch --show-current 2>/dev/null); for b in main master; do if [ \"$branch\" = \"$b\" ]; then echo \"BLOCKED: Cannot commit to protected branch $branch. Create a feature branch first.\"; exit 2; fi; done; fi; exit 0'"
          }
        ]
      }
    ]
  }
}
SETTINGS

# README
cat > "$TARGET/README.md" <<'README'
# Second Brain Workspace

Your AI-augmented knowledge management workspace. Claude Code runs from here with full visibility into your vault and projects.

## Structure
- `vault/` — Open in Obsidian. Your knowledge base.
- `repos/` — Your git repositories. Organize however you want.
- `scripts/` — Custom automation.
- `.claude/` — Agentic infrastructure (agents, skills, hooks).

## Getting Started
1. Open `vault/` in Obsidian
2. Add your first note
3. Customize `CLAUDE.md` with your workflow
4. Run `claude` from this directory

## Customization
- Add vault-specific skills in `.claude/skills/`
- Add automation scripts in `scripts/`
- Configure hooks in `.claude/settings.json`
- Your methodology is yours — build it over time.
README

# Clone macbook-dev-setup into the workspace
MACBOOK_TARGET="$TARGET/repos/$GH_USER/macbook-dev-setup"
if [[ -d "$MACBOOK_TARGET" ]]; then
  echo "macbook-dev-setup already exists at $MACBOOK_TARGET"
else
  echo "Cloning macbook-dev-setup into workspace..."
  if command -v gh &>/dev/null; then
    gh repo clone "$GH_USER/macbook-dev-setup" "$MACBOOK_TARGET" 2>/dev/null || \
      git clone "https://github.com/$GH_USER/macbook-dev-setup.git" "$MACBOOK_TARGET"
  else
    git clone "https://github.com/$GH_USER/macbook-dev-setup.git" "$MACBOOK_TARGET"
  fi
fi

# Run initial sync
if [[ -x "$MACBOOK_TARGET/scripts/sync-agentic.sh" ]]; then
  echo "Syncing agentic infrastructure..."
  "$MACBOOK_TARGET/scripts/sync-agentic.sh" "$TARGET" --type workspace
fi

# Init git repo
if [[ ! -d "$TARGET/.git" ]]; then
  cd "$TARGET"
  git init
  git add -A
  git commit -m "feat: scaffold second brain workspace"
fi

echo ""
echo "Second brain created at: $TARGET"
echo ""
echo "Next steps:"
echo "  1. cd $TARGET"
echo "  2. Open vault/ in Obsidian"
echo "  3. Customize CLAUDE.md with your workflow"
echo "  4. Run: claude"
