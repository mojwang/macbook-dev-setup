#!/usr/bin/env bash

# Setup Claude agentic workflow: plugins, LSP deps, templates, and project init
# Two modes:
#   System mode (no flags): install plugins, LSP deps, deploy templates
#   Project init (--init): bootstrap .claude/agents/, .claude/skills/ in a project

set -e

# Resolve symlinks so the script works when invoked via ~/.local/bin symlink
SCRIPT_PATH="${BASH_SOURCE[0]}"
while [[ -L "$SCRIPT_PATH" ]]; do
    SCRIPT_PATH=$(readlink "$SCRIPT_PATH")
done

# Load common library
source "$(dirname "$SCRIPT_PATH")/../lib/common.sh"

# Load signal safety library
source "$ROOT_DIR/lib/signal-safety.sh"

# Load UI presentation layer
source "$ROOT_DIR/lib/ui.sh"

# Cleanup
cleanup_agentic() {
    default_cleanup
}
setup_cleanup "cleanup_agentic"

# Configuration
TEMPLATE_VERSION="2.0.0"
TEMPLATE_DIR="$HOME/.claude/templates/agentic"
VERSION_FILE="$TEMPLATE_DIR/.version"
REPO_DIR="$ROOT_DIR"
SYMLINK_DIR="$HOME/.local/bin"
SYMLINK_NAME="claude-init-agentic"

# Plugins to install (name@registry format)
PLUGINS=(
    "github@claude-plugins-official"
    "slack@claude-plugins-official"
    "playwright@claude-plugins-official"
    "pr-review-toolkit@claude-plugins-official"
    "typescript-lsp@claude-plugins-official"
    "swift-lsp@claude-plugins-official"
    "pyright-lsp@claude-plugins-official"
    "kotlin-lsp@claude-plugins-official"
)

# LSP binaries to check/install via brew
BREW_LSPS=(
    "typescript-language-server"
    "pyright"
    "kotlin-language-server"
)

# ─────────────────────────────────────────────────────────────────────────────
# System mode functions
# ─────────────────────────────────────────────────────────────────────────────

check_prerequisites() {
    if ! command -v jq &>/dev/null; then
        print_error "jq is required for settings merge but not found"
        print_info "Install with: brew install jq"
        exit 1
    fi
}

install_plugins() {
    if ! command -v claude &>/dev/null; then
        print_warning "Claude Code CLI not found — skipping plugin install"
        return 0
    fi

    print_step "Installing Claude Code plugins..."

    # Read existing plugins from settings to skip already-installed ones
    local settings_file="$HOME/.claude/settings.json"
    local installed_plugins=""
    if [[ -f "$settings_file" ]]; then
        installed_plugins=$(jq -r '.plugins // [] | .[].name // empty' "$settings_file" 2>/dev/null || true)
    fi

    local installed=0
    local skipped=0
    for plugin in "${PLUGINS[@]}"; do
        local plugin_name="${plugin%%@*}"
        if echo "$installed_plugins" | grep -q "^${plugin_name}$" 2>/dev/null; then
            ((skipped++)) || true
            continue
        fi
        print_info "Installing plugin: $plugin"
        if claude plugin install "$plugin" 2>/dev/null; then
            ((installed++)) || true
        else
            print_warning "Failed to install plugin: $plugin (continuing)"
        fi
    done

    if [[ $installed -gt 0 ]]; then
        print_success "Installed $installed plugin(s), $skipped already present"
    else
        print_success "All ${#PLUGINS[@]} plugins already installed"
    fi
}

install_lsp_deps() {
    if ! command -v brew &>/dev/null; then
        print_warning "Homebrew not found — skipping LSP dependency install"
        return 0
    fi

    print_step "Checking LSP dependencies..."

    local installed=0
    for lsp in "${BREW_LSPS[@]}"; do
        if command -v "$lsp" &>/dev/null || brew list "$lsp" &>/dev/null 2>&1; then
            continue
        fi
        print_info "Installing $lsp..."
        if brew install "$lsp" 2>/dev/null; then
            ((installed++)) || true
        else
            print_warning "Failed to install $lsp (continuing)"
        fi
    done

    # sourcekit-lsp comes with Xcode — just verify
    if command -v sourcekit-lsp &>/dev/null || xcrun --find sourcekit-lsp &>/dev/null 2>&1; then
        print_success "sourcekit-lsp: available via Xcode"
    else
        print_info "sourcekit-lsp: requires Xcode (install from App Store)"
    fi

    if [[ $installed -gt 0 ]]; then
        print_success "Installed $installed LSP dependency(ies)"
    else
        print_success "All LSP dependencies available"
    fi
}

deploy_templates() {
    print_step "Deploying agentic workflow templates..."

    # Create template directory structure
    mkdir -p "$TEMPLATE_DIR/agents"
    mkdir -p "$TEMPLATE_DIR/skills/base"
    mkdir -p "$TEMPLATE_DIR/skills/shell"
    mkdir -p "$TEMPLATE_DIR/skills/web"
    mkdir -p "$TEMPLATE_DIR/settings"

    # Copy agents
    local agent_src="$REPO_DIR/.claude/agents"
    if [[ -d "$agent_src" ]]; then
        for agent_file in "$agent_src"/*.md; do
            [[ -f "$agent_file" ]] || continue
            cp "$agent_file" "$TEMPLATE_DIR/agents/"
        done
        print_success "Deployed agent templates"
    else
        print_warning "No agent definitions found at $agent_src"
    fi

    # Copy base skills (universal — deployed to every project)
    local skill_src="$REPO_DIR/.claude/skills"
    local base_skills=("security-review" "commit-review" "deep-research")
    for skill_name in "${base_skills[@]}"; do
        if [[ -f "$skill_src/$skill_name/SKILL.md" ]]; then
            mkdir -p "$TEMPLATE_DIR/skills/base/$skill_name"
            cp "$skill_src/$skill_name/SKILL.md" "$TEMPLATE_DIR/skills/base/$skill_name/"
        fi
    done

    # Copy shell-specific skills
    local shell_skills=("shell-conventions")
    for skill_name in "${shell_skills[@]}"; do
        if [[ -f "$skill_src/$skill_name/SKILL.md" ]]; then
            mkdir -p "$TEMPLATE_DIR/skills/shell/$skill_name"
            cp "$skill_src/$skill_name/SKILL.md" "$TEMPLATE_DIR/skills/shell/$skill_name/"
        fi
    done

    # Copy web-specific skills from config/skills/
    local web_skill_src="$REPO_DIR/config/skills"
    local web_skills=("typescript-conventions" "web-review")
    for skill_name in "${web_skills[@]}"; do
        if [[ -f "$web_skill_src/$skill_name/SKILL.md" ]]; then
            mkdir -p "$TEMPLATE_DIR/skills/web/$skill_name"
            cp "$web_skill_src/$skill_name/SKILL.md" "$TEMPLATE_DIR/skills/web/$skill_name/"
        fi
    done

    print_success "Deployed skill templates (base + shell + web)"

    # Copy type-specific settings templates
    local settings_dir="$REPO_DIR/config/settings"
    for settings_file in "$settings_dir"/settings-*.json; do
        [[ -f "$settings_file" ]] || continue
        cp "$settings_file" "$TEMPLATE_DIR/settings/"
    done
    # Also copy existing settings as the base/default
    local settings_src="$REPO_DIR/.claude/settings.json"
    if [[ -f "$settings_src" ]]; then
        cp "$settings_src" "$TEMPLATE_DIR/settings/settings-base.json"
    fi
    print_success "Deployed settings templates"

    # Copy agent metadata template
    local agents_json_src="$REPO_DIR/.claude-agents.json"
    if [[ -f "$agents_json_src" ]]; then
        cp "$agents_json_src" "$TEMPLATE_DIR/claude-agents.json.template"
        print_success "Deployed agent metadata template"
    fi

    # Copy project CLAUDE.md template
    local claude_md_template="$REPO_DIR/config/project-claude.md.template"
    if [[ -f "$claude_md_template" ]]; then
        cp "$claude_md_template" "$TEMPLATE_DIR/project-claude.md.template"
        print_success "Deployed project CLAUDE.md template"
    fi

    # Write version stamp
    echo "$TEMPLATE_VERSION" > "$VERSION_FILE"
    print_success "Templates deployed to $TEMPLATE_DIR (v$TEMPLATE_VERSION)"
}

create_symlink() {
    print_step "Creating CLI symlink..."

    mkdir -p "$SYMLINK_DIR"

    local target="$REPO_DIR/scripts/setup-claude-agentic.sh"
    local link="$SYMLINK_DIR/$SYMLINK_NAME"

    if [[ -L "$link" ]]; then
        local current_target
        current_target=$(readlink "$link")
        if [[ "$current_target" == "$target" ]]; then
            print_success "Symlink already exists: $link"
            return 0
        fi
        rm "$link"
    fi

    ln -s "$target" "$link"
    print_success "Created symlink: $link -> $target"

    # Check if symlink dir is in PATH
    if ! echo "$PATH" | tr ':' '\n' | grep -q "^${SYMLINK_DIR}$"; then
        print_info "Add to your shell config: export PATH=\"$SYMLINK_DIR:\$PATH\""
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Project init mode functions
# ─────────────────────────────────────────────────────────────────────────────

init_project() {
    local target_dir="${1:-.}"
    local project_type="${2:-}"
    target_dir=$(cd "$target_dir" && pwd)

    if [[ ! -d "$TEMPLATE_DIR" ]]; then
        print_error "Templates not found at $TEMPLATE_DIR"
        print_info "Run setup.sh first or: setup-claude-agentic.sh (system mode)"
        exit 1
    fi

    # Validate project type if specified
    local valid_types=("shell" "web")
    if [[ -n "$project_type" ]]; then
        local type_valid=false
        for t in "${valid_types[@]}"; do
            [[ "$project_type" == "$t" ]] && type_valid=true
        done
        if [[ "$type_valid" == "false" ]]; then
            print_error "Unknown project type: $project_type"
            print_info "Valid types: ${valid_types[*]}"
            exit 1
        fi
    fi

    local type_label="${project_type:-base}"
    print_info "Initializing agentic workflow in: $target_dir (type: $type_label)"

    # Initialize git repo if not already one
    if [[ ! -d "$target_dir/.git" ]]; then
        git -C "$target_dir" init
        print_success "Initialized git repository"
    fi

    # Generate CLAUDE.md from template if not present
    local claude_md="$target_dir/CLAUDE.md"
    if [[ ! -f "$claude_md" ]]; then
        local claude_md_template="$TEMPLATE_DIR/project-claude.md.template"
        if [[ -f "$claude_md_template" ]]; then
            cp "$claude_md_template" "$claude_md"
            print_success "Created CLAUDE.md template — customize for your project"
        fi
    fi

    # Generate minimal README.md if not present
    local readme="$target_dir/README.md"
    if [[ ! -f "$readme" ]]; then
        local project_name
        project_name=$(basename "$target_dir")
        cat > "$readme" << EOF
# $project_name

## Getting Started

TODO: Add setup instructions.

## Development

This project uses the Claude agentic workflow. See \`CLAUDE.md\` for details.
EOF
        print_success "Created README.md — customize for your project"
    fi

    local claude_dir="$target_dir/.claude"

    # Deploy agents
    mkdir -p "$claude_dir/agents"
    local agents_updated=0
    for agent_file in "$TEMPLATE_DIR/agents"/*.md; do
        [[ -f "$agent_file" ]] || continue
        local dest="$claude_dir/agents/$(basename "$agent_file")"
        if [[ -f "$dest" ]]; then
            if ! diff -q "$agent_file" "$dest" >/dev/null 2>&1; then
                print_warning "Agent differs: $(basename "$agent_file")"
                diff -u "$dest" "$agent_file" || true
                if [[ -t 0 ]]; then
                    if ui_confirm "Update $(basename "$agent_file")?" "n"; then
                        cp "$agent_file" "$dest"
                        ((agents_updated++)) || true
                    fi
                fi
            fi
        else
            cp "$agent_file" "$dest"
            ((agents_updated++)) || true
        fi
    done

    # Deploy skills: base + type-specific
    # Build list of skill source directories to deploy
    local skill_sources=("$TEMPLATE_DIR/skills/base")
    if [[ -n "$project_type" ]] && [[ -d "$TEMPLATE_DIR/skills/$project_type" ]]; then
        skill_sources+=("$TEMPLATE_DIR/skills/$project_type")
    fi

    for skill_source in "${skill_sources[@]}"; do
        for skill_dir in "$skill_source"/*/; do
            [[ -d "$skill_dir" ]] || continue
            local skill_name
            skill_name=$(basename "$skill_dir")
            mkdir -p "$claude_dir/skills/$skill_name"
            local dest="$claude_dir/skills/$skill_name/SKILL.md"
            local src="$skill_dir/SKILL.md"
            [[ -f "$src" ]] || continue
            if [[ -f "$dest" ]]; then
                if ! diff -q "$src" "$dest" >/dev/null 2>&1; then
                    print_warning "Skill differs: $skill_name/SKILL.md"
                    diff -u "$dest" "$src" || true
                    if [[ -t 0 ]]; then
                        if ui_confirm "Update $skill_name/SKILL.md?" "n"; then
                            cp "$src" "$dest"
                        fi
                    fi
                fi
            else
                cp "$src" "$dest"
            fi
        done
    done

    # Deploy settings: type-specific if available, else base
    local settings_dest="$claude_dir/settings.json"
    local settings_template=""
    if [[ -n "$project_type" ]] && [[ -f "$TEMPLATE_DIR/settings/settings-${project_type}.json" ]]; then
        settings_template="$TEMPLATE_DIR/settings/settings-${project_type}.json"
    elif [[ -f "$TEMPLATE_DIR/settings/settings-base.json" ]]; then
        settings_template="$TEMPLATE_DIR/settings/settings-base.json"
    fi

    if [[ -n "$settings_template" ]]; then
        if [[ -f "$settings_dest" ]]; then
            # Additive merge: template provides defaults, existing keys win
            local merged
            merged=$(jq -s '.[0] * .[1]' "$settings_template" "$settings_dest" 2>/dev/null || true)
            if [[ -n "$merged" ]]; then
                if ! echo "$merged" | diff -q "$settings_dest" - >/dev/null 2>&1; then
                    print_warning "Settings merge adds new keys"
                    echo "$merged" | diff -u "$settings_dest" - || true
                    if [[ -t 0 ]]; then
                        if ui_confirm "Apply settings merge?" "n"; then
                            echo "$merged" | jq '.' > "$settings_dest"
                            print_success "Merged settings.json"
                        fi
                    fi
                fi
            fi
        else
            cp "$settings_template" "$settings_dest"
            print_success "Created settings.json (type: $type_label)"
        fi
    fi

    # Copy .claude-agents.json (only if not present)
    local agents_json_template="$TEMPLATE_DIR/claude-agents.json.template"
    local agents_json_dest="$target_dir/.claude-agents.json"
    if [[ -f "$agents_json_template" ]] && [[ ! -f "$agents_json_dest" ]]; then
        cp "$agents_json_template" "$agents_json_dest"
        print_success "Created .claude-agents.json"
    fi

    if [[ $agents_updated -gt 0 ]]; then
        print_success "Updated $agents_updated agent(s)"
    fi
    print_success "Agentic workflow initialized in $target_dir (type: $type_label)"
}

# ─────────────────────────────────────────────────────────────────────────────
# Check/update mode functions
# ─────────────────────────────────────────────────────────────────────────────

check_templates() {
    if [[ ! -f "$VERSION_FILE" ]]; then
        exit 1
    fi
    local installed_version
    installed_version=$(cat "$VERSION_FILE")
    if [[ "$installed_version" == "$TEMPLATE_VERSION" ]]; then
        exit 0
    else
        exit 1
    fi
}

update_templates() {
    print_info "Updating agentic templates..."
    deploy_templates

    # Re-deploy to current project if we're in one with .claude/
    if [[ -d "./.claude/agents" ]]; then
        print_info "Re-deploying to current project..."
        init_project "."
    fi
}

show_help() {
    cat << 'EOF'
Usage: setup-claude-agentic.sh [OPTIONS]

Setup Claude agentic workflow: plugins, LSP deps, templates, and project init.

Modes:
    (none)                      System setup: install plugins, LSP deps, deploy templates
    --init [DIR] [--type TYPE]  Initialize agentic workflow in a project (default: current dir)
    --check                     Exit 0 if templates up-to-date, exit 1 if stale
    --update                    Update templates and re-deploy to current project
    --help                      Show this help message

Project types (--type):
    shell       Shell/bash projects — shellcheck hook, shell-conventions skill
    web         Web/TypeScript projects — tsc hook, typescript-conventions + web-review skills
    (omitted)   Base only — universal skills (security-review, commit-review, deep-research)

System setup installs:
    Plugins:  github, slack, playwright, pr-review-toolkit, *-lsp (8 total)
    LSP deps: typescript-language-server, pyright, kotlin-language-server, sourcekit-lsp
    Templates: agents, skills (base + shell + web), settings → ~/.claude/templates/agentic/
    CLI:      Symlinks as ~/.local/bin/claude-init-agentic

Project init creates:
    git repo            (initialized if not present)
    CLAUDE.md           project template (customize for your stack)
    README.md           minimal skeleton (if not present)
    .claude/agents/     researcher, planner, implementer, reviewer
    .claude/skills/     base skills + type-specific skills
    .claude/settings.json  type-specific hooks (merged with existing)
    .claude-agents.json    (only if not present)

Examples:
    claude-init-agentic --init .                  # Base skills only
    claude-init-agentic --init . --type shell     # + shellcheck, shell-conventions
    claude-init-agentic --init . --type web       # + tsc, typescript-conventions, web-review
    claude-init-agentic --init ~/new-project --type web
EOF
}

# ─────────────────────────────────────────────────────────────────────────────
# Main execution
# ─────────────────────────────────────────────────────────────────────────────

parse_init_args() {
    # Parse: --init [DIR] [--type TYPE]
    INIT_DIR="."
    INIT_TYPE=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --type) INIT_TYPE="${2:-}"; shift 2 ;;
            *) INIT_DIR="$1"; shift ;;
        esac
    done
}

case "${1:-}" in
    --init)
        check_prerequisites
        shift  # consume --init
        parse_init_args "$@"
        init_project "$INIT_DIR" "$INIT_TYPE"
        ;;
    --check)
        check_templates
        ;;
    --update)
        check_prerequisites
        update_templates
        ;;
    --help|-h)
        show_help
        ;;
    *)
        # System mode: full setup
        check_prerequisites
        install_plugins
        install_lsp_deps
        deploy_templates
        create_symlink
        print_success "Claude agentic workflow setup complete!"
        ;;
esac
