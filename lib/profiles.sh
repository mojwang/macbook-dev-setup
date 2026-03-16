#!/usr/bin/env bash

# Profile-based Brewfile filtering library
# Allows different environments (personal, work, work-acme) to customize
# which packages are installed without maintaining duplicate Brewfiles.
# Note: set -e is not used here to allow sourcing from various scripts
# (consistent with lib/common.sh pattern)

# Prevent multiple sourcing
if [[ -n "${PROFILES_LIB_LOADED:-}" ]]; then
    return 0
fi
PROFILES_LIB_LOADED=true

# Source dependencies
PROFILES_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$PROFILES_LIB_DIR/common.sh" 2>/dev/null || true
source "$PROFILES_LIB_DIR/signal-safety.sh" 2>/dev/null || true

# Profile directory
PROFILES_DIR="${PROFILES_DIR:-$(cd "$PROFILES_LIB_DIR/../homebrew/profiles" && pwd)}"

# Extension pack directory
EXTENSIONS_DIR="${EXTENSIONS_DIR:-$HOME/.config/macbook-dev-setup.d}"

# Profile state (set by resolve_profile)
PROFILE_EXCLUDES=()
PROFILE_ADDS=()
PROFILE_SKIP_MCP="false"
PROFILE_SKIP_AGENTIC="false"
PROFILE_MODULES=()
PROFILE_REPOS_DIR=""
PROFILE_WORKSPACE=""

# Parse a key=value from a profile conf file
# Usage: parse_profile_value <file> <key>
# Returns the value on stdout, empty string if not found
parse_profile_value() {
    local file="$1"
    local key="$2"

    if [[ ! -f "$file" ]]; then
        return 0
    fi

    local line
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip comments and blank lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// /}" ]] && continue

        # Match key=value
        if [[ "$line" =~ ^[[:space:]]*"$key"[[:space:]]*=[[:space:]]*(.*) ]]; then
            local value="${BASH_REMATCH[1]}"
            # Trim trailing whitespace
            value="${value%"${value##*[![:space:]]}"}"
            echo "$value"
            return 0
        fi
    done < "$file"
}

# Resolve a profile by name, handling single-level inheritance
# Sets globals: PROFILE_EXCLUDES[], PROFILE_ADDS[], PROFILE_SKIP_MCP
# Usage: resolve_profile <name>
resolve_profile() {
    local name="$1"
    local conf_file="$PROFILES_DIR/${name}.conf"

    if [[ ! -f "$conf_file" ]]; then
        print_error "Profile not found: $conf_file"
        return 1
    fi

    # Validate profile syntax before processing
    if ! validate_profile "$name"; then
        return 1
    fi

    [[ "${VERBOSE:-false}" == true ]] && print_info "Loading profile: $conf_file"

    # Reset state
    PROFILE_EXCLUDES=()
    PROFILE_ADDS=()
    PROFILE_SKIP_MCP="false"
    PROFILE_SKIP_AGENTIC="false"
    PROFILE_MODULES=()
    PROFILE_MODULES_STR=""
    PROFILE_REPOS_DIR=""
    PROFILE_WORKSPACE=""

    # Check for inheritance
    local parent
    parent=$(parse_profile_value "$conf_file" "inherit")

    if [[ -n "$parent" ]]; then
        local parent_file="$PROFILES_DIR/${parent}.conf"

        if [[ ! -f "$parent_file" ]]; then
            print_warning "Parent profile not found: $parent_file (ignoring inheritance)"
        else
            [[ "${VERBOSE:-false}" == true ]] && print_info "Inheriting from parent: $parent ($parent_file)"

            # Check for deep inheritance (grandparent)
            local grandparent
            grandparent=$(parse_profile_value "$parent_file" "inherit")
            if [[ -n "$grandparent" ]]; then
                print_warning "Deep inheritance detected: $name -> $parent -> $grandparent (only single-level supported, ignoring grandparent)"
            fi

            # Load parent values first
            _load_profile_values "$parent_file"
        fi
    fi

    # Load child values (merges excludes/adds, overrides options)
    _load_profile_values "$conf_file" "child"

    [[ "${VERBOSE:-false}" == true ]] && print_info "Resolved ${#PROFILE_EXCLUDES[@]} excludes, ${#PROFILE_ADDS[@]} adds, ${#PROFILE_MODULES[@]} modules"

    export PROFILE_MODULES
    # Bash arrays can't cross process boundaries; export as delimited string for subprocesses
    PROFILE_MODULES_STR=$(IFS=','; echo "${PROFILE_MODULES[*]}")
    export PROFILE_MODULES_STR
    return 0
}

# Internal: load values from a profile conf file into globals
# When mode is "child", options override rather than set defaults
_load_profile_values() {
    local file="$1"
    local mode="${2:-parent}"

    # Parse excludes (comma-separated)
    local excludes_str
    excludes_str=$(parse_profile_value "$file" "exclude")
    if [[ -n "$excludes_str" ]]; then
        IFS=',' read -ra new_excludes <<< "$excludes_str"
        for item in "${new_excludes[@]}"; do
            # Trim whitespace
            item="${item#"${item%%[![:space:]]*}"}"
            item="${item%"${item##*[![:space:]]}"}"
            [[ -n "$item" ]] && PROFILE_EXCLUDES+=("$item")
        done
    fi

    # Parse adds (comma-separated, prefix with brew: or cask:)
    local adds_str
    adds_str=$(parse_profile_value "$file" "add")
    if [[ -n "$adds_str" ]]; then
        IFS=',' read -ra new_adds <<< "$adds_str"
        for item in "${new_adds[@]}"; do
            item="${item#"${item%%[![:space:]]*}"}"
            item="${item%"${item##*[![:space:]]}"}"
            [[ -n "$item" ]] && PROFILE_ADDS+=("$item")
        done
    fi

    # Parse skip_mcp_setup (child overrides parent)
    local skip_mcp
    skip_mcp=$(parse_profile_value "$file" "skip_mcp_setup")
    if [[ -n "$skip_mcp" ]]; then
        PROFILE_SKIP_MCP="$skip_mcp"
    fi

    # Parse skip_agentic_setup (child overrides parent)
    local skip_agentic
    skip_agentic=$(parse_profile_value "$file" "skip_agentic_setup")
    if [[ -n "$skip_agentic" ]]; then
        PROFILE_SKIP_AGENTIC="$skip_agentic"
    fi

    # Parse repos_dir (child overrides parent)
    local repos_dir
    repos_dir=$(parse_profile_value "$file" "repos_dir")
    if [[ -n "$repos_dir" ]]; then
        PROFILE_REPOS_DIR="$repos_dir"
    fi

    # Parse workspace (child overrides parent)
    local workspace
    workspace=$(parse_profile_value "$file" "workspace")
    if [[ -n "$workspace" ]]; then
        PROFILE_WORKSPACE="$workspace"
    fi

    # Parse modules (comma-separated, child merges with parent)
    local modules_str
    modules_str=$(parse_profile_value "$file" "modules")
    if [[ -n "$modules_str" ]]; then
        IFS=',' read -ra new_modules <<< "$modules_str"
        for item in "${new_modules[@]}"; do
            item="${item#"${item%%[![:space:]]*}"}"
            item="${item%"${item##*[![:space:]]}"}"
            if [[ -n "$item" ]]; then
                local duplicate=false
                for existing in ${PROFILE_MODULES[@]+"${PROFILE_MODULES[@]}"}; do
                    [[ "$existing" == "$item" ]] && duplicate=true && break
                done
                [[ "$duplicate" == false ]] && PROFILE_MODULES+=("$item")
            fi
        done
    fi
}

# Filter a Brewfile based on current profile state
# Creates a filtered temp file and prints its path
# Usage: filter_brewfile <source_path>
filter_brewfile() {
    local source_path="$1"

    if [[ ! -f "$source_path" ]]; then
        print_error "Brewfile not found: $source_path"
        return 1
    fi

    # If no excludes and no adds, return original path
    if [[ ${#PROFILE_EXCLUDES[@]} -eq 0 ]] && [[ ${#PROFILE_ADDS[@]} -eq 0 ]]; then
        echo "$source_path"
        return 0
    fi

    local filtered
    filtered=$(safe_mktemp "brewfile-filtered.XXXXXX")

    local line
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Always preserve comments, blank lines, and tap lines
        if [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "${line// /}" ]] || [[ "$line" =~ ^tap[[:space:]] ]]; then
            echo "$line" >> "$filtered"
            continue
        fi

        # Check if this line matches any exclude pattern
        local excluded=false
        if [[ "$line" =~ ^(brew|cask)[[:space:]]+\"([^\"]+)\" ]]; then
            local pkg_name="${BASH_REMATCH[2]}"
            for exclude in "${PROFILE_EXCLUDES[@]}"; do
                if [[ "$pkg_name" == "$exclude" ]] || [[ "$pkg_name" == *"/$exclude" ]]; then
                    excluded=true
                    break
                fi
            done
        fi

        if [[ "$excluded" == "false" ]]; then
            echo "$line" >> "$filtered"
        fi
    done < "$source_path"

    # Append add entries
    if [[ ${#PROFILE_ADDS[@]} -gt 0 ]]; then
        echo "" >> "$filtered"
        echo "# Added by profile" >> "$filtered"
        for add_entry in "${PROFILE_ADDS[@]}"; do
            if [[ "$add_entry" =~ ^cask: ]]; then
                echo "cask \"${add_entry#cask:}\"" >> "$filtered"
            elif [[ "$add_entry" =~ ^brew: ]]; then
                echo "brew \"${add_entry#brew:}\"" >> "$filtered"
            else
                # Default to brew
                echo "brew \"$add_entry\"" >> "$filtered"
            fi
        done
    fi

    [[ "${VERBOSE:-false}" == true ]] && print_info "Filtered Brewfile: $filtered"

    echo "$filtered"
}

# List available profiles
# Usage: list_profiles
list_profiles() {
    echo "Available profiles:"
    echo ""

    local found=false
    for conf_file in "$PROFILES_DIR"/*.conf; do
        [[ ! -f "$conf_file" ]] && continue
        found=true
        local name
        name=$(basename "$conf_file" .conf)
        # Extract first comment line as description
        local description
        description=$(grep -m1 '^#' "$conf_file" | sed 's/^#[[:space:]]*//')
        printf "  %-20s %s\n" "$name" "$description"
    done

    if [[ "$found" == false ]]; then
        echo "  (none found in $PROFILES_DIR)"
    fi

    echo ""
    echo "Usage: ./setup.sh --profile <name>"
}

# Validate a profile config file for syntax errors
# Checks: file exists, valid keys, parent exists, no deep inheritance
# Usage: validate_profile <name>
# Returns 0 on success, 1 on error (with error messages on stderr)
validate_profile() {
    local name="$1"
    local conf_file="$PROFILES_DIR/${name}.conf"
    local errors=0

    if [[ ! -f "$conf_file" ]]; then
        print_error "Profile not found: $conf_file"
        return 1
    fi

    # Check for unknown keys
    local valid_keys="inherit exclude add skip_mcp_setup skip_agentic_setup modules repos_dir workspace"
    local line_num=0
    while IFS= read -r line || [[ -n "$line" ]]; do
        ((line_num++))
        # Skip comments and blank lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// /}" ]] && continue

        # Extract key from key=value
        if [[ "$line" =~ ^[[:space:]]*([a-zA-Z_]+)[[:space:]]*= ]]; then
            local key="${BASH_REMATCH[1]}"
            local key_valid=false
            for vk in $valid_keys; do
                if [[ "$key" == "$vk" ]]; then
                    key_valid=true
                    break
                fi
            done
            if [[ "$key_valid" == false ]]; then
                print_error "Unknown key '$key' at line $line_num in $conf_file"
                ((errors++))
            fi
        else
            print_error "Invalid syntax at line $line_num in $conf_file: $line"
            ((errors++))
        fi
    done < "$conf_file"

    # Check inheritance
    local parent
    parent=$(parse_profile_value "$conf_file" "inherit")
    if [[ -n "$parent" ]]; then
        local parent_file="$PROFILES_DIR/${parent}.conf"
        if [[ ! -f "$parent_file" ]]; then
            print_error "Parent profile '$parent' not found: $parent_file"
            ((errors++))
        else
            # Check for deep inheritance
            local grandparent
            grandparent=$(parse_profile_value "$parent_file" "inherit")
            if [[ -n "$grandparent" ]]; then
                print_warning "Deep inheritance: $name -> $parent -> $grandparent (only single-level supported)"
            fi
        fi
    fi

    if [[ $errors -gt 0 ]]; then
        print_error "Profile '$name' has $errors error(s)"
        return 1
    fi

    return 0
}

# Print a summary of what the profile does
# Usage: print_profile_summary <name>
print_profile_summary() {
    local name="$1"

    echo ""
    print_info "Profile: $name"

    if [[ ${#PROFILE_EXCLUDES[@]} -gt 0 ]]; then
        print_info "Excluding: ${PROFILE_EXCLUDES[*]}"
    else
        print_info "Excluding: (none)"
    fi

    if [[ ${#PROFILE_ADDS[@]} -gt 0 ]]; then
        print_info "Adding: ${PROFILE_ADDS[*]}"
    fi

    if [[ ${#PROFILE_MODULES[@]} -gt 0 ]]; then
        print_info "Modules: ${PROFILE_MODULES[*]}"
    fi

    if [[ "$PROFILE_SKIP_MCP" == "true" ]]; then
        print_info "MCP setup: skipped"
    fi

    if [[ "$PROFILE_SKIP_AGENTIC" == "true" ]]; then
        print_info "Agentic setup: skipped"
    fi
    echo ""
}

# ── Extension Pack Support ──────────────────────────────────────────

# Extension pack state (set by discover_extensions / load_extension_profile)
EXTENSION_PACKS=()

# Discover all extension packs in EXTENSIONS_DIR
# Each subdirectory with a profile.conf is an extension pack
# Sets: EXTENSION_PACKS[] (list of pack directory paths)
# Usage: discover_extensions
discover_extensions() {
    EXTENSION_PACKS=()

    if [[ ! -d "$EXTENSIONS_DIR" ]]; then
        return 0
    fi

    local pack_dir
    for pack_dir in "$EXTENSIONS_DIR"/*/; do
        [[ ! -d "$pack_dir" ]] && continue
        # Must have at least a profile.conf or scripts/ directory
        if [[ -f "${pack_dir}profile.conf" ]] || [[ -d "${pack_dir}scripts" ]]; then
            EXTENSION_PACKS+=("$pack_dir")
        fi
    done
}

# Load an extension pack's profile.conf and merge into current profile state
# Merges excludes/adds/modules additively (same as child profile behavior)
# Usage: load_extension_profile <pack_directory>
load_extension_profile() {
    local pack_dir="$1"
    local conf_file="${pack_dir}profile.conf"

    if [[ ! -f "$conf_file" ]]; then
        return 0
    fi

    local pack_name
    pack_name=$(basename "$pack_dir")

    [[ "${VERBOSE:-false}" == true ]] && print_info "Loading extension pack profile: $pack_name ($conf_file)"

    # Merge extension values into existing profile state (additive)
    _load_profile_values "$conf_file" "child"
}

# Print summary of discovered extension packs
# Usage: print_extensions_summary
print_extensions_summary() {
    if [[ ${#EXTENSION_PACKS[@]} -eq 0 ]]; then
        return 0
    fi

    echo ""
    print_info "Extension packs:"
    local pack_dir
    for pack_dir in "${EXTENSION_PACKS[@]}"; do
        local pack_name
        pack_name=$(basename "$pack_dir")
        local components=()
        [[ -f "${pack_dir}profile.conf" ]] && components+=("profile")
        [[ -d "${pack_dir}scripts" ]] && components+=("scripts")
        [[ -d "${pack_dir}dotfiles" ]] && components+=("dotfiles")
        print_info "  $pack_name (${components[*]})"
    done
    echo ""
}
