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
EXTENSIONS_DIR="${EXTENSIONS_DIR:-$HOME/.config/macbook-dev-setup.d}"
TEMPLATE_VERSION="2.1.0"
TEMPLATE_DIR="$HOME/.claude/templates/agentic"
VERSION_FILE="$TEMPLATE_DIR/.version"
REPO_DIR="$ROOT_DIR"
SYMLINK_DIR="$HOME/.local/bin"
SYMLINK_NAME="claude-init-agentic"

# Plugins to install (name@registry format)
PLUGINS=(
    # Core integrations
    "github@claude-plugins-official"
    "slack@claude-plugins-official"
    "playwright@claude-plugins-official"
    "context7@claude-plugins-official"
    # Code review & quality
    "pr-review-toolkit@claude-plugins-official"
    "security-guidance@claude-plugins-official"
    "commit-commands@claude-plugins-official"
    # Development workflows
    "feature-dev@claude-plugins-official"
    "frontend-design@claude-plugins-official"
    "figma@claude-plugins-official"
    # LSP plugins
    "typescript-lsp@claude-plugins-official"
    "swift-lsp@claude-plugins-official"
    "pyright-lsp@claude-plugins-official"
    "kotlin-lsp@claude-plugins-official"
    # Meta / authoring
    "claude-code-setup@claude-plugins-official"
    "claude-md-management@claude-plugins-official"
    "plugin-dev@claude-plugins-official"
    "skill-creator@claude-plugins-official"
    "hookify@claude-plugins-official"
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

    # Scan extension packs for additional plugins
    if [[ -d "$EXTENSIONS_DIR" ]]; then
        for ext_plugins_conf in "$EXTENSIONS_DIR"/*/claude/plugins.conf; do
            [[ -f "$ext_plugins_conf" ]] || continue
            local ext_name
            ext_name=$(basename "$(dirname "$(dirname "$ext_plugins_conf")")")
            print_info "Scanning extension plugins: $ext_name"
            while IFS= read -r line || [[ -n "$line" ]]; do
                # Skip comments and empty lines
                line="${line%%#*}"
                line="${line// /}"
                [[ -z "$line" ]] && continue

                local plugin_name="${line%%@*}"
                if echo "$installed_plugins" | grep -q "^${plugin_name}$" 2>/dev/null; then
                    ((skipped++)) || true
                    continue
                fi
                print_info "Installing extension plugin: $line"
                if claude plugin install "$line" 2>/dev/null; then
                    ((installed++)) || true
                else
                    print_warning "Failed to install extension plugin: $line (continuing)"
                fi
            done < "$ext_plugins_conf"
        done
    fi

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
    local web_skills=("typescript-conventions" "web-review" "design-review" "design-elevation" "init-design-system" "competitive-audit")
    for skill_name in "${web_skills[@]}"; do
        if [[ -f "$web_skill_src/$skill_name/SKILL.md" ]]; then
            mkdir -p "$TEMPLATE_DIR/skills/web/$skill_name"
            cp "$web_skill_src/$skill_name/"*.md "$TEMPLATE_DIR/skills/web/$skill_name/"
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

    # Copy CI workflow templates and scripts
    mkdir -p "$TEMPLATE_DIR/ci"
    for ci_file in "$REPO_DIR/config/ci"/*.yml "$REPO_DIR/config/ci"/*.sh; do
        [[ -f "$ci_file" ]] || continue
        cp "$ci_file" "$TEMPLATE_DIR/ci/"
    done
    print_success "Deployed CI workflow templates"

    # Copy .gitignore templates
    mkdir -p "$TEMPLATE_DIR/gitignore"
    for gi_file in "$REPO_DIR/config/gitignore"/gitignore-*; do
        [[ -f "$gi_file" ]] || continue
        cp "$gi_file" "$TEMPLATE_DIR/gitignore/"
    done
    print_success "Deployed .gitignore templates"

    # Copy GitHub templates (PR template)
    mkdir -p "$TEMPLATE_DIR/github"
    for gh_file in "$REPO_DIR/config/github"/*; do
        [[ -f "$gh_file" ]] || continue
        cp "$gh_file" "$TEMPLATE_DIR/github/"
    done
    print_success "Deployed GitHub templates"

    # Copy editor config templates
    mkdir -p "$TEMPLATE_DIR/editor"
    for ed_file in "$REPO_DIR/config/editor"/*; do
        [[ -f "$ed_file" ]] || continue
        cp "$ed_file" "$TEMPLATE_DIR/editor/"
    done
    print_success "Deployed editor config templates"

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

create_scaffold_symlink() {
    print_step "Creating scaffold-extension symlink..."

    mkdir -p "$SYMLINK_DIR"

    local target="$REPO_DIR/scripts/scaffold-extension.sh"
    local link="$SYMLINK_DIR/scaffold-extension"

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
}

# ─────────────────────────────────────────────────────────────────────────────
# Project init mode functions
# ─────────────────────────────────────────────────────────────────────────────

# macOS security -w returns hex-encoded output for non-ASCII or binary-stored passwords
read_keychain_password() {
    local raw
    raw=$(security find-generic-password -s "$1" -a "$2" -w 2>/dev/null || true)
    [[ -z "$raw" ]] && return
    # Detect hex encoding: all hex chars + even length
    if [[ "$raw" =~ ^[0-9a-fA-F]+$ ]] && (( ${#raw} % 2 == 0 )); then
        local decoded
        decoded=$(printf '%s' "$raw" | xxd -r -p 2>/dev/null || true)
        if [[ -n "$decoded" ]] && [[ "$decoded" == sk-* ]]; then
            printf '%s' "$decoded"
            return
        fi
    fi
    printf '%s' "$raw"
}

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
            for src_file in "$skill_dir"*.md; do
                [[ -f "$src_file" ]] || continue
                local file_name
                file_name=$(basename "$src_file")
                local dest="$claude_dir/skills/$skill_name/$file_name"
                if [[ -f "$dest" ]]; then
                    if ! diff -q "$src_file" "$dest" >/dev/null 2>&1; then
                        print_warning "Skill differs: $skill_name/$file_name"
                        diff -u "$dest" "$src_file" || true
                        if [[ -t 0 ]]; then
                            if ui_confirm "Update $skill_name/$file_name?" "n"; then
                                cp "$src_file" "$dest"
                            fi
                        fi
                    fi
                else
                    cp "$src_file" "$dest"
                fi
            done
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

    # Deploy CI workflow (type-specific, only if not present)
    mkdir -p "$target_dir/.github/workflows"
    local ci_dest="$target_dir/.github/workflows/ci.yml"
    if [[ ! -f "$ci_dest" ]]; then
        local ci_template=""
        if [[ -n "$project_type" ]] && [[ -f "$TEMPLATE_DIR/ci/ci-${project_type}.yml" ]]; then
            ci_template="$TEMPLATE_DIR/ci/ci-${project_type}.yml"
        fi
        if [[ -n "$ci_template" ]]; then
            cp "$ci_template" "$ci_dest"
            print_success "Created .github/workflows/ci.yml (type: $type_label)"
        fi
    fi

    # Deploy Claude review workflow (only if not present)
    local review_dest="$target_dir/.github/workflows/claude-review.yml"
    if [[ ! -f "$review_dest" ]] && [[ -f "$TEMPLATE_DIR/ci/claude-review.yml" ]]; then
        cp "$TEMPLATE_DIR/ci/claude-review.yml" "$review_dest"
        print_success "Created .github/workflows/claude-review.yml"
    fi

    # Auto-set CLAUDE_CODE_OAUTH_TOKEN if repo has a GitHub remote and token is in Keychain
    local keychain_service="claude-code-oauth-token"
    local keychain_account="github-actions"
    local repo_nwo=""
    repo_nwo=$(git -C "$target_dir" remote get-url origin 2>/dev/null | sed -n 's|.*github\.com[:/]\(.*\)\.git$|\1|p; s|.*github\.com[:/]\(.*\)$|\1|p' || true)

    if [[ -n "$repo_nwo" ]] && command -v security &>/dev/null && command -v gh &>/dev/null; then
        local existing_secret
        existing_secret=$(gh secret list -R "$repo_nwo" 2>/dev/null | grep "^CLAUDE_CODE_OAUTH_TOKEN" || true)

        if [[ -n "$existing_secret" ]]; then
            print_success "CLAUDE_CODE_OAUTH_TOKEN already set on $repo_nwo"
        else
            local token
            token=$(read_keychain_password "$keychain_service" "$keychain_account")

            if [[ -n "$token" ]]; then
                if echo "$token" | gh secret set CLAUDE_CODE_OAUTH_TOKEN -R "$repo_nwo" --body - 2>/dev/null; then
                    print_success "CLAUDE_CODE_OAUTH_TOKEN set on $repo_nwo from Keychain"
                else
                    print_warning "Failed to set CLAUDE_CODE_OAUTH_TOKEN on $repo_nwo"
                fi
            else
                print_info "No CLAUDE_CODE_OAUTH_TOKEN in Keychain — run .github/setup-github-repo.sh to configure"
            fi
        fi
    fi

    # Deploy Claude interactive workflow (@claude trigger, only if not present)
    local claude_dest="$target_dir/.github/workflows/claude.yml"
    if [[ ! -f "$claude_dest" ]] && [[ -f "$TEMPLATE_DIR/ci/claude.yml" ]]; then
        cp "$TEMPLATE_DIR/ci/claude.yml" "$claude_dest"
        print_success "Created .github/workflows/claude.yml (@claude trigger)"
    fi

    # Deploy reviewer request workflow (only if not present)
    local reviewers_dest="$target_dir/.github/workflows/request-reviewers.yml"
    if [[ ! -f "$reviewers_dest" ]] && [[ -f "$TEMPLATE_DIR/ci/request-reviewers.yml" ]]; then
        cp "$TEMPLATE_DIR/ci/request-reviewers.yml" "$reviewers_dest"
        print_success "Created .github/workflows/request-reviewers.yml"
    fi

    # Deploy CI health check workflow (only if not present)
    local health_dest="$target_dir/.github/workflows/ci-health.yml"
    if [[ ! -f "$health_dest" ]] && [[ -f "$TEMPLATE_DIR/ci/ci-health.yml" ]]; then
        cp "$TEMPLATE_DIR/ci/ci-health.yml" "$health_dest"
        print_success "Created .github/workflows/ci-health.yml (weekly secret check)"
    fi

    # Deploy Lighthouse CI workflow for web projects (only if not present)
    if [[ "$project_type" == "web" ]]; then
        local lh_dest="$target_dir/.github/workflows/lighthouse.yml"
        if [[ ! -f "$lh_dest" ]] && [[ -f "$TEMPLATE_DIR/ci/lighthouse-web.yml" ]]; then
            cp "$TEMPLATE_DIR/ci/lighthouse-web.yml" "$lh_dest"
            print_success "Created .github/workflows/lighthouse.yml"
        fi
    fi

    # Deploy repo setup script (only if not present)
    local repo_setup_dest="$target_dir/.github/setup-github-repo.sh"
    if [[ ! -f "$repo_setup_dest" ]] && [[ -f "$TEMPLATE_DIR/ci/setup-github-repo.sh" ]]; then
        mkdir -p "$target_dir/.github"
        cp "$TEMPLATE_DIR/ci/setup-github-repo.sh" "$repo_setup_dest"
        chmod +x "$repo_setup_dest"
        print_success "Created .github/setup-github-repo.sh (run after gh repo create)"
    fi

    # Deploy .gitignore (type-specific, only if not present)
    local gitignore_dest="$target_dir/.gitignore"
    if [[ ! -f "$gitignore_dest" ]]; then
        local gi_template=""
        if [[ -n "$project_type" ]] && [[ -f "$TEMPLATE_DIR/gitignore/gitignore-${project_type}" ]]; then
            gi_template="$TEMPLATE_DIR/gitignore/gitignore-${project_type}"
        elif [[ -f "$TEMPLATE_DIR/gitignore/gitignore-shell" ]]; then
            # Shell gitignore works as a minimal default
            gi_template="$TEMPLATE_DIR/gitignore/gitignore-shell"
        fi
        if [[ -n "$gi_template" ]]; then
            cp "$gi_template" "$gitignore_dest"
            print_success "Created .gitignore (type: $type_label)"
        fi
    fi

    # Deploy PR template (only if not present)
    local pr_template_dest="$target_dir/.github/pull_request_template.md"
    if [[ ! -f "$pr_template_dest" ]] && [[ -f "$TEMPLATE_DIR/github/pull_request_template.md" ]]; then
        mkdir -p "$target_dir/.github"
        cp "$TEMPLATE_DIR/github/pull_request_template.md" "$pr_template_dest"
        print_success "Created .github/pull_request_template.md"
    fi

    # Deploy .editorconfig (only if not present)
    local editorconfig_dest="$target_dir/.editorconfig"
    if [[ ! -f "$editorconfig_dest" ]] && [[ -f "$TEMPLATE_DIR/editor/editorconfig" ]]; then
        cp "$TEMPLATE_DIR/editor/editorconfig" "$editorconfig_dest"
        print_success "Created .editorconfig"
    fi

    # Deploy .nvmrc for web projects (only if not present)
    if [[ "$project_type" == "web" ]]; then
        local nvmrc_dest="$target_dir/.nvmrc"
        if [[ ! -f "$nvmrc_dest" ]] && [[ -f "$TEMPLATE_DIR/editor/nvmrc" ]]; then
            cp "$TEMPLATE_DIR/editor/nvmrc" "$nvmrc_dest"
            print_success "Created .nvmrc"
        fi
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
    web         Web/TypeScript projects — tsc hook, typescript-conventions + web-review + design skills
    (omitted)   Base only — universal skills (security-review, commit-review, deep-research)

System setup installs:
    Plugins:  19 total (integrations, review, workflows, LSPs, meta)
    LSP deps: typescript-language-server, pyright, kotlin-language-server, sourcekit-lsp
    Templates: agents, skills (base + shell + web), settings → ~/.claude/templates/agentic/
    CLI:      Symlinks as ~/.local/bin/claude-init-agentic

Project init creates:
    git repo                            (initialized if not present)
    CLAUDE.md                           project template (customize for your stack)
    README.md                           minimal skeleton (if not present)
    .claude/agents/                     product-tactician, researcher, planner, implementer, reviewer, designer
    .claude/skills/                     base skills + type-specific skills
    .claude/settings.json               type-specific hooks (merged with existing)
    .claude-agents.json                 (only if not present)
    .github/workflows/ci.yml              type-specific CI pipeline (with All Checks Pass gate)
    .github/workflows/claude-review.yml   Claude auto-review + Copilot reconciliation + auto-merge
    .github/workflows/request-reviewers.yml  auto-request repo owner as reviewer
    .github/setup-github-repo.sh           configure ruleset + repo settings (run after gh repo create)
    .github/pull_request_template.md      standardized PR format
    .gitignore                          type-specific ignore patterns
    .editorconfig                       consistent formatting
    .nvmrc                              Node.js version (web only)

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
        create_scaffold_symlink
        print_success "Claude agentic workflow setup complete!"
        ;;
esac
