#!/usr/bin/env bash

# Integration tests for project init (setup-claude-agentic.sh --init)

set +e

export ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
source "$(dirname "$0")/../test_framework.sh"

SCRIPT="$ROOT_DIR/scripts/setup-claude-agentic.sh"
TEMPLATE_DIR="$HOME/.claude/templates/agentic"

# Ensure templates are deployed
if [[ ! -d "$TEMPLATE_DIR" ]]; then
    echo "Skipping: templates not deployed (run setup-claude-agentic.sh first)"
    exit 0
fi

# ─────────────────────────────────────────────────────────────────────────────
# Web project init
# ─────────────────────────────────────────────────────────────────────────────

describe "Project init: web type"

WEB_DIR=$(mktemp -d)
bash "$SCRIPT" --init "$WEB_DIR" --type web &>/dev/null

# Core files
assert_file_exists "$WEB_DIR/CLAUDE.md" "CLAUDE.md created"
assert_file_exists "$WEB_DIR/README.md" "README.md created"
assert_file_exists "$WEB_DIR/.claude-agents.json" ".claude-agents.json created"
assert_directory_exists "$WEB_DIR/.git" "Git repo initialized"

# Agents
for agent in product researcher planner implementer reviewer designer; do
    assert_file_exists "$WEB_DIR/.claude/agents/${agent}.md" "Agent: $agent"
done

# Skills: base + web
assert_file_exists "$WEB_DIR/.claude/skills/security-review/SKILL.md" "Skill: security-review"
assert_file_exists "$WEB_DIR/.claude/skills/commit-review/SKILL.md" "Skill: commit-review"
assert_file_exists "$WEB_DIR/.claude/skills/deep-research/SKILL.md" "Skill: deep-research"
assert_file_exists "$WEB_DIR/.claude/skills/typescript-conventions/SKILL.md" "Skill: typescript-conventions"
assert_file_exists "$WEB_DIR/.claude/skills/web-review/SKILL.md" "Skill: web-review"

# Settings
assert_file_exists "$WEB_DIR/.claude/settings.json" "Settings created"

# New template files
assert_file_exists "$WEB_DIR/.github/workflows/ci.yml" "CI workflow created"
assert_file_exists "$WEB_DIR/.github/workflows/claude-review.yml" "Claude review workflow created"
assert_file_exists "$WEB_DIR/.github/workflows/request-reviewers.yml" "Reviewer request workflow created"
assert_file_exists "$WEB_DIR/.github/pull_request_template.md" "PR template created"
assert_file_exists "$WEB_DIR/.gitignore" ".gitignore created"
assert_file_exists "$WEB_DIR/.editorconfig" ".editorconfig created"
assert_file_exists "$WEB_DIR/.nvmrc" ".nvmrc created (web only)"

# Content validation
assert_contains "$(cat "$WEB_DIR/.github/workflows/ci.yml")" "npm test" "Web CI runs npm test"
assert_contains "$(cat "$WEB_DIR/.github/workflows/ci.yml")" "tsc --noEmit" "Web CI runs typecheck"
assert_contains "$(cat "$WEB_DIR/.gitignore")" "node_modules" "Web gitignore excludes node_modules"
assert_contains "$(cat "$WEB_DIR/CLAUDE.md")" "NEVER commit to main" "CLAUDE.md has git rules"
assert_contains "$(cat "$WEB_DIR/.github/workflows/claude-review.yml")" "anthropics/claude-code-action" "Claude review uses action"
assert_contains "$(cat "$WEB_DIR/.github/workflows/claude-review.yml")" "auto-merge" "Claude review has auto-merge"
assert_contains "$(cat "$WEB_DIR/.github/workflows/request-reviewers.yml")" "repository_owner" "Reviewer workflow uses repo owner"

rm -rf "$WEB_DIR"

# ─────────────────────────────────────────────────────────────────────────────
# Shell project init
# ─────────────────────────────────────────────────────────────────────────────

describe "Project init: shell type"

SHELL_DIR=$(mktemp -d)
bash "$SCRIPT" --init "$SHELL_DIR" --type shell &>/dev/null

# Core files
assert_file_exists "$SHELL_DIR/CLAUDE.md" "CLAUDE.md created"
assert_file_exists "$SHELL_DIR/.github/workflows/ci.yml" "CI workflow created"
assert_file_exists "$SHELL_DIR/.github/workflows/claude-review.yml" "Claude review workflow created"
assert_file_exists "$SHELL_DIR/.github/workflows/request-reviewers.yml" "Reviewer request workflow created"
assert_file_exists "$SHELL_DIR/.gitignore" ".gitignore created"
assert_file_exists "$SHELL_DIR/.editorconfig" ".editorconfig created"

# Shell-specific skill
assert_file_exists "$SHELL_DIR/.claude/skills/shell-conventions/SKILL.md" "Skill: shell-conventions"

# No web-specific files
assert_true "[[ ! -f '$SHELL_DIR/.nvmrc' ]]" "No .nvmrc for shell projects"
assert_true "[[ ! -f '$SHELL_DIR/.claude/skills/typescript-conventions/SKILL.md' ]]" "No typescript-conventions for shell"

# Content validation
assert_contains "$(cat "$SHELL_DIR/.github/workflows/ci.yml")" "shellcheck" "Shell CI runs shellcheck"
assert_not_contains "$(cat "$SHELL_DIR/.gitignore")" "node_modules" "Shell gitignore has no node_modules"

rm -rf "$SHELL_DIR"

# ─────────────────────────────────────────────────────────────────────────────
# Idempotency test
# ─────────────────────────────────────────────────────────────────────────────

describe "Project init: idempotency"

IDEM_DIR=$(mktemp -d)
bash "$SCRIPT" --init "$IDEM_DIR" --type web &>/dev/null

# Modify CLAUDE.md to prove it won't be overwritten
echo "# My Custom Project" > "$IDEM_DIR/CLAUDE.md"

# Re-run init
bash "$SCRIPT" --init "$IDEM_DIR" --type web &>/dev/null

# Verify customization preserved
assert_contains "$(cat "$IDEM_DIR/CLAUDE.md")" "My Custom Project" "CLAUDE.md not overwritten on re-run"

rm -rf "$IDEM_DIR"

# ─────────────────────────────────────────────────────────────────────────────
# Base (no type) init
# ─────────────────────────────────────────────────────────────────────────────

describe "Project init: base (no type)"

BASE_DIR=$(mktemp -d)
bash "$SCRIPT" --init "$BASE_DIR" &>/dev/null

# Core files exist
assert_file_exists "$BASE_DIR/CLAUDE.md" "CLAUDE.md created"
assert_file_exists "$BASE_DIR/.claude/skills/security-review/SKILL.md" "Base skill: security-review"

# Claude review + reviewers deployed even for base type
assert_file_exists "$BASE_DIR/.github/workflows/claude-review.yml" "Claude review for base type"
assert_file_exists "$BASE_DIR/.github/workflows/request-reviewers.yml" "Reviewer request for base type"

# No type-specific CI
assert_true "[[ ! -f '$BASE_DIR/.github/workflows/ci.yml' ]]" "No CI for base type"
assert_true "[[ ! -f '$BASE_DIR/.nvmrc' ]]" "No .nvmrc for base type"

rm -rf "$BASE_DIR"

print_test_summary
