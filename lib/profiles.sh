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

# Profile state (set by resolve_profile)
PROFILE_EXCLUDES=()
PROFILE_ADDS=()
PROFILE_SKIP_MCP="false"

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

    # Reset state
    PROFILE_EXCLUDES=()
    PROFILE_ADDS=()
    PROFILE_SKIP_MCP="false"

    # Check for inheritance
    local parent
    parent=$(parse_profile_value "$conf_file" "inherit")

    if [[ -n "$parent" ]]; then
        local parent_file="$PROFILES_DIR/${parent}.conf"

        if [[ ! -f "$parent_file" ]]; then
            print_warning "Parent profile not found: $parent_file (ignoring inheritance)"
        else
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

    echo "$filtered"
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

    if [[ "$PROFILE_SKIP_MCP" == "true" ]]; then
        print_info "MCP setup: skipped"
    fi
    echo ""
}
