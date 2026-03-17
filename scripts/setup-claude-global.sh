#!/usr/bin/env bash

# Setup global CLAUDE.md configuration
# This provides baseline Claude Code instructions across all projects

set -e

# Load common library
source "$(dirname "$0")/../lib/common.sh"

# Load signal safety library
# ROOT_DIR is already set by common.sh
source "$ROOT_DIR/lib/signal-safety.sh"

# Load UI presentation layer
source "$ROOT_DIR/lib/ui.sh"

# Claude global setup specific cleanup
cleanup_claude_global() {
    # Clean up any temporary files
    [[ -n "${backup_file:-}" ]] && [[ -f "${backup_file}.tmp" ]] && rm -f "${backup_file}.tmp" 2>/dev/null || true
    
    # Clean up incomplete installations
    [[ -n "${CLAUDE_GLOBAL_MD:-}" ]] && [[ -f "${CLAUDE_GLOBAL_MD}.tmp" ]] && rm -f "${CLAUDE_GLOBAL_MD}.tmp" 2>/dev/null || true

    # Call default cleanup (also cleans safe_mktemp files)
    default_cleanup
}

# Set up cleanup trap
setup_cleanup "cleanup_claude_global"

# Configuration
CLAUDE_DIR="$HOME/.claude"
CLAUDE_GLOBAL_MD="$CLAUDE_DIR/CLAUDE.md"
CONFIG_DIR="$(dirname "$0")/../config"
TEMPLATE_FILE="$CONFIG_DIR/global-claude.md"
EXTENSIONS_DIR="${EXTENSIONS_DIR:-$HOME/.config/macbook-dev-setup.d}"

# Version information
TEMPLATE_VERSION="2.2.0"
VERSION_MARKER="# Claude Global Config Version:"

# Resolve the effective template by concatenating base + profile overlay.
#
# When SETUP_PROFILE is set, concatenates $TEMPLATE_FILE (base) with the
# matching overlay at $CONFIG_DIR/global-claude-${profile}.md.
# On success, updates TEMPLATE_FILE to point to the assembled temp file.
# Returns 0 on success (including graceful fallback), 1 if base is missing.
resolve_template() {
    local profile="${SETUP_PROFILE:-}"

    # No profile requested — use base only
    if [[ -z "$profile" ]]; then
        return 0
    fi

    # Validate base template exists before any file operations
    if [[ ! -f "$TEMPLATE_FILE" ]]; then
        print_error "Base template not found: $TEMPLATE_FILE"
        return 1
    fi

    local overlay_file="$CONFIG_DIR/global-claude-${profile}.md"
    if [[ ! -f "$overlay_file" ]]; then
        print_warning "Profile overlay not found: $overlay_file — using base only"
        return 0
    fi

    # Validate overlay format (should contain a markdown heading)
    if ! grep -q '^## ' "$overlay_file" 2>/dev/null; then
        print_warning "Profile overlay '$profile' has no ## heading — expected '## Environment' section"
    fi

    local assembled
    assembled=$(safe_mktemp "claude-global-assembled.XXXXXX")
    cat "$TEMPLATE_FILE" "$overlay_file" > "$assembled"
    TEMPLATE_FILE="$assembled"
    print_info "Using profile overlay: global-claude-${profile}.md"
}

# Append extension pack CLAUDE.md overlays from $EXTENSIONS_DIR/*/claude/global-claude-overlay.md.
#
# Scans all installed extension packs for optional Claude overlays and appends
# them to the assembled template. Updates EXTENSION_OVERLAYS_APPLIED with the
# list of applied overlay names (for metadata tracking).
# Requires TEMPLATE_FILE to already point to a valid file (base or assembled).
EXTENSION_OVERLAYS_APPLIED=()
append_extension_overlays() {
    [[ -d "$EXTENSIONS_DIR" ]] || return 0

    local overlay
    for overlay in "$EXTENSIONS_DIR"/*/claude/global-claude-overlay.md; do
        [[ -f "$overlay" ]] || continue

        local ext_name
        ext_name=$(basename "$(dirname "$(dirname "$overlay")")")

        # Validate overlay has a markdown heading
        if ! grep -q '^## ' "$overlay" 2>/dev/null; then
            print_warning "Extension overlay '$ext_name' has no ## heading — skipping"
            continue
        fi

        # If TEMPLATE_FILE is still the original (not yet assembled), create a temp copy
        if [[ "$TEMPLATE_FILE" == "$CONFIG_DIR/"* ]]; then
            local assembled
            assembled=$(safe_mktemp "claude-global-assembled.XXXXXX")
            cat "$TEMPLATE_FILE" > "$assembled"
            TEMPLATE_FILE="$assembled"
        fi

        # Append with a blank separator
        printf '\n' >> "$TEMPLATE_FILE"
        cat "$overlay" >> "$TEMPLATE_FILE"
        EXTENSION_OVERLAYS_APPLIED+=("$ext_name")
        print_info "Appended extension overlay: $ext_name"
    done
}

setup_global_claude() {
    print_info "Setting up global Claude Code configuration..."

    # Assemble base + profile overlay + extension overlays
    resolve_template
    append_extension_overlays

    # Validate template file exists
    if [[ ! -f "$TEMPLATE_FILE" ]]; then
        print_error "Template file not found: $TEMPLATE_FILE"
        exit 1
    fi
    
    # Create .claude directory if it doesn't exist
    if [[ ! -d "$CLAUDE_DIR" ]]; then
        print_step "Creating $CLAUDE_DIR directory..."
        if ! mkdir -p "$CLAUDE_DIR"; then
            print_error "Failed to create directory: $CLAUDE_DIR"
            exit 1
        fi
        print_success "Created $CLAUDE_DIR"
    fi
    
    # Check if global CLAUDE.md already exists
    if [[ -f "$CLAUDE_GLOBAL_MD" ]]; then
        print_warning "Global CLAUDE.md already exists at $CLAUDE_GLOBAL_MD"
        
        # Get current version if it exists
        local current_version=""
        if grep -q "^$VERSION_MARKER" "$CLAUDE_GLOBAL_MD" 2>/dev/null; then
            current_version=$(grep "^$VERSION_MARKER" "$CLAUDE_GLOBAL_MD" | sed "s/^$VERSION_MARKER *//")
        fi
        
        # Cache diff result to avoid running twice (compare stripped content)
        local diff_output=""
        if ! diff -q "$TEMPLATE_FILE" <(strip_metadata_header "$CLAUDE_GLOBAL_MD") >/dev/null 2>&1; then
            diff_output=$(diff -u <(strip_metadata_header "$CLAUDE_GLOBAL_MD") "$TEMPLATE_FILE" || true)

            # Count added/removed lines
            local lines_added lines_removed
            lines_added=$(echo "$diff_output" | grep -c '^+[^+]' || true)
            lines_removed=$(echo "$diff_output" | grep -c '^-[^-]' || true)

            ui_section_header "CLAUDE.md Update Available"
            echo "  Version: ${current_version:-unknown} → ${TEMPLATE_VERSION}"
            echo "  Changes: +${lines_added} added, -${lines_removed} removed"
            echo ""
            ui_diff_style_select
            local stripped_tmp
            stripped_tmp=$(safe_mktemp "claude-global-stripped.XXXXXX")
            strip_metadata_header "$CLAUDE_GLOBAL_MD" > "$stripped_tmp"
            ui_diff "$stripped_tmp" "$TEMPLATE_FILE"
            rm -f "$stripped_tmp"

            # Check if we're in CI or non-interactive mode
            if [[ "${CI:-false}" == "true" ]] || [[ ! -t 0 ]]; then
                print_info "Running in non-interactive mode, keeping existing file"
                if [[ -n "$current_version" ]] && [[ "$current_version" != "$TEMPLATE_VERSION" ]]; then
                    print_warning "Note: Template version ($TEMPLATE_VERSION) differs from installed version ($current_version)"
                fi
            else
                if ui_confirm "Update global CLAUDE.md to version ${TEMPLATE_VERSION}?" "n"; then
                    # Backup existing file with PID to prevent collisions
                    backup_file="$CLAUDE_GLOBAL_MD.backup.$(date +%Y%m%d_%H%M%S)_$$"
                    cp "$CLAUDE_GLOBAL_MD" "$backup_file"
                    print_info "Backed up existing file to: $backup_file"
                    
                    # Copy new template with version metadata
                    install_template_with_metadata
                    print_success "Updated global CLAUDE.md"
                else
                    print_info "Keeping existing global CLAUDE.md"
                fi
            fi
        else
            # Check version even if content is identical
            if [[ -n "$current_version" ]] && [[ "$current_version" != "$TEMPLATE_VERSION" ]]; then
                print_info "Content is identical but version metadata differs"
                print_info "Installed: ${current_version:-unknown}, Template: $TEMPLATE_VERSION"
            else
                print_success "Global CLAUDE.md is up to date (version $TEMPLATE_VERSION)"
            fi
        fi
    else
        # Copy template to global location
        print_step "Installing global CLAUDE.md..."
        install_template_with_metadata
        print_success "Installed global CLAUDE.md at $CLAUDE_GLOBAL_MD (version $TEMPLATE_VERSION)"
    fi
    
    # Set appropriate permissions
    chmod 644 "$CLAUDE_GLOBAL_MD"
    
    print_success "Global Claude Code configuration complete!"
}

# Function to install template with version metadata
install_template_with_metadata() {
    local temp_file="${CLAUDE_GLOBAL_MD}.tmp.$$"
    
    # Write to temporary file first for atomic operation
    {
        echo "$VERSION_MARKER $TEMPLATE_VERSION"
        echo "# Last Updated: $(date '+%Y-%m-%d %H:%M:%S')"
        local source_line="macbook-dev-setup/config/global-claude.md"
        [[ -n "${SETUP_PROFILE:-}" ]] && source_line+=" + global-claude-${SETUP_PROFILE}.md"
        for _ext in "${EXTENSION_OVERLAYS_APPLIED[@]}"; do
            source_line+=" + ext:${_ext}"
        done
        echo "# Source: $source_line"
        echo ""
        cat "$TEMPLATE_FILE"
    } > "$temp_file"
    
    # Atomically move the file
    mv -f "$temp_file" "$CLAUDE_GLOBAL_MD"
}

# Strip the 3-line metadata header + blank separator from an installed CLAUDE.md.
# This allows content comparison against the raw template without timestamp noise.
# Input: path to a file that may have metadata (Version, Last Updated, Source).
# Output: file contents on stdout, with metadata lines removed if present.
strip_metadata_header() {
    local file="$1"
    if head -1 "$file" | grep -q "^# Claude Global Config Version:"; then
        tail -n +5 "$file"  # Skip 3 metadata lines + 1 blank separator
    else
        cat "$file"          # No metadata — return as-is
    fi
}

# Main execution
case "${1:-}" in
    --check)
        # Assemble base + profile overlay + extension overlays for comparison
        resolve_template
        append_extension_overlays

        # Validate template exists first
        if [[ ! -f "$TEMPLATE_FILE" ]]; then
            print_error "Base template not found: $CONFIG_DIR/global-claude.md"
            exit 2
        fi

        # Check if installed config exists
        if [[ ! -f "$CLAUDE_GLOBAL_MD" ]]; then
            print_error "Global CLAUDE.md not installed at $CLAUDE_GLOBAL_MD"
            exit 1
        fi

        # Check content differences (strip metadata before comparing)
        content_matches=true
        if ! diff -q "$TEMPLATE_FILE" <(strip_metadata_header "$CLAUDE_GLOBAL_MD") >/dev/null 2>&1; then
            content_matches=false
        fi

        # Check version
        current_version=""
        if grep -q "^$VERSION_MARKER" "$CLAUDE_GLOBAL_MD" 2>/dev/null; then
            current_version=$(grep "^$VERSION_MARKER" "$CLAUDE_GLOBAL_MD" | sed "s/^$VERSION_MARKER *//")
        fi

        if [[ "$content_matches" == "true" ]] && [[ "$current_version" == "$TEMPLATE_VERSION" ]]; then
            exit 0  # Up to date
        else
            if [[ "$content_matches" == "false" ]]; then
                print_info "Content differs from template${SETUP_PROFILE:+ (profile: $SETUP_PROFILE)}"
            fi
            if [[ "$current_version" != "$TEMPLATE_VERSION" ]]; then
                print_info "Version mismatch: installed=${current_version:-unknown}, template=$TEMPLATE_VERSION"
            fi
            exit 1  # Needs update
        fi
        ;;
    --version)
        echo "Template version: $TEMPLATE_VERSION"
        if [[ -f "$CLAUDE_GLOBAL_MD" ]]; then
            current_version=""
            if grep -q "^$VERSION_MARKER" "$CLAUDE_GLOBAL_MD" 2>/dev/null; then
                current_version=$(grep "^$VERSION_MARKER" "$CLAUDE_GLOBAL_MD" | sed "s/^$VERSION_MARKER *//")
            fi
            echo "Installed version: ${current_version:-unknown}"
        else
            echo "Not installed"
        fi
        ;;
    --list-profiles)
        echo "Available profiles:"
        _found=false
        for overlay in "$CONFIG_DIR"/global-claude-*.md; do
            [[ -f "$overlay" ]] || continue
            _pname=$(basename "$overlay" | sed 's/^global-claude-//; s/\.md$//')
            echo "  $_pname"
            _found=true
        done
        if [[ "$_found" == "false" ]]; then
            echo "  (none)"
        fi
        ;;
    --help)
        echo "Usage: $0 [OPTIONS]"
        echo "Setup global CLAUDE.md configuration for Claude Code"
        echo ""
        echo "Options:"
        echo "  --check           Check if global config exists and is up to date"
        echo "  --version         Show template and installed versions"
        echo "  --list-profiles   List available profile overlays"
        echo "  --help            Show this help message"
        echo ""
        echo "Environment variables:"
        echo "  SETUP_PROFILE    Profile name to apply (e.g., 'personal', 'work')"
        echo "                   Concatenates config/global-claude-\$SETUP_PROFILE.md onto base"
        echo "  EXTENSIONS_DIR   Extension packs directory (default: ~/.config/macbook-dev-setup.d)"
        echo "                   Appends */claude/global-claude-overlay.md from each extension"
        echo "  CI               Set to 'true' to run in non-interactive mode"
        ;;
    *)
        setup_global_claude
        ;;
esac