#!/usr/bin/env bash

# UI presentation layer with graceful fallback
# Provides rich TUI when gum/delta/fzf/bat are available,
# falls back to plain ANSI output when they're not.
#
# Source this file after common.sh:
#   source "$(dirname "$0")/lib/ui.sh"

# Prevent multiple sourcing
if [[ -n "${UI_LIB_LOADED:-}" ]]; then
    return 0
fi
UI_LIB_LOADED=true

# =============================================================================
# Tool detection (re-checked at call time since gum may get installed mid-setup)
# =============================================================================

_ui_has() {
    command -v "$1" &>/dev/null
}

_ui_is_interactive() {
    [[ -t 0 ]] && [[ -t 1 ]] && [[ "${CI:-false}" != "true" ]]
}

# =============================================================================
# ui_section_header "title"
# =============================================================================

ui_section_header() {
    local title="$1"

    if _ui_is_interactive && _ui_has gum; then
        gum style --border rounded --bold --padding "0 2" --border-foreground 4 "$title"
    else
        # ANSI fallback
        echo ""
        echo -e "${BLUE:-\033[0;34m}== ${title} ==${NC:-\033[0m}"
    fi
}

export -f ui_section_header

# =============================================================================
# ui_confirm "prompt" [default: n]
# Returns 0 for yes, 1 for no
# =============================================================================

ui_confirm() {
    local prompt="$1"
    local default="${2:-n}"

    if ! _ui_is_interactive; then
        [[ "$default" =~ ^[Yy]$ ]] && return 0 || return 1
    fi

    if _ui_has gum; then
        local gum_args=("--prompt.foreground" "4")
        if [[ "$default" =~ ^[Yy]$ ]]; then
            gum_args+=("--default=yes")
        else
            gum_args+=("--default=no")
        fi
        gum confirm "$prompt" "${gum_args[@]}"
        return $?
    fi

    # Fall back to existing confirm() from common.sh if available
    if declare -f confirm &>/dev/null; then
        confirm "$prompt" "$default"
        return $?
    fi

    # Bare fallback
    local suffix="[y/N]"
    [[ "$default" =~ ^[Yy]$ ]] && suffix="[Y/n]"
    read -r -p "$prompt $suffix: " response
    response="${response,,}"
    case "$response" in
        y|yes) return 0 ;;
        n|no) return 1 ;;
        "") [[ "$default" =~ ^[Yy]$ ]] && return 0 || return 1 ;;
        *) return 1 ;;
    esac
}

export -f ui_confirm

# =============================================================================
# ui_choose "prompt" option1 option2 ...
# Prints selected option to stdout
# =============================================================================

ui_choose() {
    local prompt="$1"
    shift
    local opts=("$@")

    if [[ ${#opts[@]} -eq 0 ]]; then
        return 1
    fi

    if _ui_is_interactive && _ui_has gum; then
        gum choose --header "$prompt" "${opts[@]}"
        return $?
    fi

    if _ui_is_interactive && _ui_has fzf; then
        printf '%s\n' "${opts[@]}" | fzf --header "$prompt" --height=~10 --reverse
        return $?
    fi

    # Numbered list fallback
    echo "$prompt" >&2
    local i=1
    for opt in "${opts[@]}"; do
        echo "  $i) $opt" >&2
        ((i++))
    done
    read -r -p "Choose (1-${#opts[@]}): " choice >&2
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#opts[@]} )); then
        echo "${opts[$((choice - 1))]}"
    else
        return 1
    fi
}

export -f ui_choose

# =============================================================================
# ui_filter "prompt" option1 option2 ...
# Prints selected options (newline-separated) to stdout
# =============================================================================

ui_filter() {
    local prompt="$1"
    shift
    local opts=("$@")

    if _ui_is_interactive && _ui_has gum; then
        printf '%s\n' "${opts[@]}" | gum filter --no-limit --header "$prompt"
        return $?
    fi

    if _ui_is_interactive && _ui_has fzf; then
        printf '%s\n' "${opts[@]}" | fzf --multi --header "$prompt" --height=~10 --reverse
        return $?
    fi

    # Comma-separated input fallback
    echo "$prompt" >&2
    local i=1
    for opt in "${opts[@]}"; do
        echo "  $i) $opt" >&2
        ((i++))
    done
    read -r -p "Enter numbers (comma-separated): " selection >&2
    IFS=',' read -ra indices <<< "$selection"
    for idx in "${indices[@]}"; do
        idx=$(echo "$idx" | tr -d ' ')
        if [[ "$idx" =~ ^[0-9]+$ ]] && (( idx >= 1 && idx <= ${#opts[@]} )); then
            echo "${opts[$((idx - 1))]}"
        fi
    done
}

export -f ui_filter

# =============================================================================
# ui_spinner "message" command [args...]
# Runs command with a spinner, shows success/failure
# =============================================================================

ui_spinner() {
    local message="$1"
    shift

    if _ui_is_interactive && _ui_has gum; then
        gum spin --spinner dot --title "$message" -- "$@"
        local rc=$?
        if [[ $rc -eq 0 ]]; then
            echo -e "${GREEN:-\033[0;32m}✓ ${message}${NC:-\033[0m}"
        else
            echo -e "${RED:-\033[0;31m}✗ ${message}${NC:-\033[0m}"
        fi
        return $rc
    fi

    # Fallback: use show_progress from common.sh if available, else just run
    if declare -f show_progress &>/dev/null; then
        "$@" &
        local pid=$!
        show_progress "$pid" "$message"
        wait "$pid"
        local rc=$?
        printf "\r\033[K"
        if [[ $rc -eq 0 ]]; then
            echo -e "${GREEN:-\033[0;32m}✓ ${message}${NC:-\033[0m}"
        else
            echo -e "${RED:-\033[0;31m}✗ ${message}${NC:-\033[0m}"
        fi
        return $rc
    fi

    # Bare fallback
    echo -e "${BLUE:-\033[0;34m}→ ${message}...${NC:-\033[0m}"
    "$@"
    local rc=$?
    if [[ $rc -eq 0 ]]; then
        echo -e "${GREEN:-\033[0;32m}✓ ${message}${NC:-\033[0m}"
    else
        echo -e "${RED:-\033[0;31m}✗ ${message}${NC:-\033[0m}"
    fi
    return $rc
}

export -f ui_spinner

# =============================================================================
# ui_diff_style_select
# Prompts for diff style when SETUP_DIFF_STYLE is unset and delta is available.
# Sets and exports SETUP_DIFF_STYLE for the session.
# =============================================================================

ui_diff_style_select() {
    # Already set — nothing to do
    if [[ -n "${SETUP_DIFF_STYLE:-}" ]]; then
        return 0
    fi

    # No delta — nothing to configure
    if ! _ui_has delta; then
        return 0
    fi

    # Non-interactive — use default
    if ! _ui_is_interactive; then
        export SETUP_DIFF_STYLE="diff-so-fancy"
        return 0
    fi

    local style
    style=$(ui_choose "Select diff display style:" \
        "diff-so-fancy" \
        "side-by-side" \
        "unified" \
        "color-only") || true

    export SETUP_DIFF_STYLE="${style:-diff-so-fancy}"
}

export -f ui_diff_style_select

# =============================================================================
# ui_diff "file_a" "file_b"
# Shows a pretty diff between two files.
# Respects SETUP_DIFF_STYLE: diff-so-fancy (default), side-by-side,
# unified, color-only.
# =============================================================================

ui_diff() {
    local file_a="$1"
    local file_b="$2"
    local style="${SETUP_DIFF_STYLE:-diff-so-fancy}"

    if _ui_has delta; then
        local delta_args=()
        case "$style" in
            side-by-side)  delta_args+=(--side-by-side) ;;
            unified)       ;; # no extra flags
            color-only)    delta_args+=(--color-only) ;;
            *)             delta_args+=(--diff-so-fancy) ;; # default
        esac
        diff -u "$file_a" "$file_b" | delta "${delta_args[@]}" 2>/dev/null || \
        diff -u "$file_a" "$file_b" | delta 2>/dev/null || \
        diff -u "$file_a" "$file_b"
    elif _ui_has bat; then
        diff -u "$file_a" "$file_b" | bat --language diff --style plain --paging never
    else
        diff -u "$file_a" "$file_b" || true
    fi
}

export -f ui_diff

# =============================================================================
# ui_summary_box "title" lines...
# Displays a bordered summary box
# =============================================================================

ui_summary_box() {
    local title="$1"
    shift
    local lines=("$@")

    if _ui_is_interactive && _ui_has gum; then
        local body=""
        for line in "${lines[@]}"; do
            if [[ -n "$body" ]]; then
                body+=$'\n'
            fi
            body+="$line"
        done
        gum style --border double --bold --padding "0 2" --border-foreground 2 \
            "$title" "" "$body"
    else
        # Simple ASCII box fallback
        local max_len=${#title}
        for line in "${lines[@]}"; do
            (( ${#line} > max_len )) && max_len=${#line}
        done
        local border
        border=$(printf '=%.0s' $(seq 1 $((max_len + 4))))

        echo ""
        echo -e "${GREEN:-\033[0;32m}${border}${NC:-\033[0m}"
        echo -e "${GREEN:-\033[0;32m}  ${title}${NC:-\033[0m}"
        echo -e "${GREEN:-\033[0;32m}${border}${NC:-\033[0m}"
        for line in "${lines[@]}"; do
            echo "  $line"
        done
        echo -e "${GREEN:-\033[0;32m}${border}${NC:-\033[0m}"
    fi
}

export -f ui_summary_box

# =============================================================================
# ui_table (reads CSV from stdin)
# =============================================================================

ui_table() {
    if _ui_has gum; then
        gum table
    else
        column -t -s,
    fi
}

export -f ui_table

# Export helper functions for subshell use
export -f _ui_has
export -f _ui_is_interactive
