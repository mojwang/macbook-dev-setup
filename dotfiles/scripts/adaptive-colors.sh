#!/bin/bash

# Adaptive Color Configuration for Terminal Tools
# This script dynamically configures colors based on terminal capabilities and theme

# Function to detect if we're in dark mode
detect_dark_mode() {
    if command -v osascript &> /dev/null; then
        local appearance=$(osascript -e 'tell application "System Events" to tell appearance preferences to get dark mode')
        [[ "$appearance" == "true" ]] && return 0 || return 1
    else
        # Default to dark mode if we can't detect
        return 0
    fi
}

# Function to detect terminal type and capabilities
detect_terminal() {
    local terminal_type=""
    
    # Check for Warp
    if [[ "$TERM_PROGRAM" == "WarpTerminal" ]]; then
        terminal_type="warp"
    # Check for iTerm2
    elif [[ "$TERM_PROGRAM" == "iTerm.app" ]]; then
        terminal_type="iterm2"
    # Check for Apple Terminal
    elif [[ "$TERM_PROGRAM" == "Apple_Terminal" ]]; then
        terminal_type="terminal"
    # Check for VS Code integrated terminal
    elif [[ "$TERM_PROGRAM" == "vscode" ]]; then
        terminal_type="vscode"
    # Default fallback
    else
        terminal_type="generic"
    fi
    
    echo "$terminal_type"
}

# Function to get appropriate color scheme based on terminal and theme
get_color_scheme() {
    local terminal_type="$1"
    local is_dark_mode="$2"
    
    case "$terminal_type" in
        "warp")
            if [[ "$is_dark_mode" == "true" ]]; then
                # Warp dark theme colors - modern, vibrant but not harsh
                echo "di=1;34:fi=0;37:ln=1;36:pi=1;33:so=1;35:bd=1;33;40:cd=1;33;40:or=1;31;40:ex=1;32:*.tar=1;31:*.tgz=1;31:*.zip=1;31:*.gz=1;31:*.bz2=1;31:*.json=0;33:*.yml=0;33:*.yaml=0;33:*.md=1;36:*.txt=0;37:*.log=0;90:*.rs=0;33:*.go=0;32:*.py=0;33:*.js=1;33:*.ts=1;34:*.jsx=1;33:*.tsx=1;34:*.css=0;35:*.scss=0;35:*.html=0;31:*.php=0;35:*.rb=0;31:*.java=0;33:*.c=0;32:*.cpp=0;36:*.sh=0;32:*.vim=0;35"
            else
                # Warp light theme colors - softer, darker text for readability
                echo "di=0;34:fi=0;30:ln=0;36:pi=0;33:so=0;35:bd=0;33;47:cd=0;33;47:or=0;31;47:ex=0;32:*.tar=0;31:*.tgz=0;31:*.zip=0;31:*.gz=0;31:*.bz2=0;31:*.json=0;30:*.yml=0;30:*.yaml=0;30:*.md=0;34:*.txt=0;30:*.log=0;90:*.rs=0;30:*.go=0;32:*.py=0;30:*.js=0;33:*.ts=0;34:*.jsx=0;33:*.tsx=0;34:*.css=0;35:*.scss=0;35:*.html=0;31:*.php=0;35:*.rb=0;31:*.java=0;30:*.c=0;32:*.cpp=0;36:*.sh=0;32:*.vim=0;35"
            fi
            ;;
        "iterm2")
            if [[ "$is_dark_mode" == "true" ]]; then
                echo "di=1;34:fi=0;37:ln=1;36:pi=1;33:so=1;35:bd=1;33;40:cd=1;33;40:or=1;31;40:ex=1;32:*.json=0;33:*.yml=0;33:*.md=1;36:*.py=0;33:*.js=1;33:*.ts=1;34"
            else
                echo "di=0;34:fi=0;30:ln=0;36:pi=0;33:so=0;35:bd=0;33;47:cd=0;33;47:or=0;31;47:ex=0;32:*.json=0;30:*.yml=0;30:*.md=0;34:*.py=0;30:*.js=0;33:*.ts=0;34"
            fi
            ;;
        "terminal"|"vscode"|"generic")
            # Conservative colors for compatibility
            if [[ "$is_dark_mode" == "true" ]]; then
                echo "di=1;34:fi=0:ln=1;36:pi=1;33:so=1;35:bd=1;33:cd=1;33:or=1;31:ex=1;32:*.json=0;33:*.md=1;36:*.py=0;33:*.js=1;33"
            else
                echo "di=0;34:fi=0:ln=0;36:pi=0;33:so=0;35:bd=0;33:cd=0;33:or=0;31:ex=0;32:*.json=0;30:*.md=0;34:*.py=0;30:*.js=0;33"
            fi
            ;;
    esac
}

# Function to set additional color environment variables
set_color_environment() {
    local terminal_type="$1"
    local is_dark_mode="$2"
    
    # Force color output
    export CLICOLOR=1
    export CLICOLOR_FORCE=1
    
    # Configure grep colors
    if [[ "$is_dark_mode" == "true" ]]; then
        export GREP_COLOR='1;32'
        export GREP_COLORS='ms=1;32:mc=1;32:sl=:cx=:fn=1;35:ln=1;33:bn=1;33:se=1;30'
    else
        export GREP_COLOR='0;32'
        export GREP_COLORS='ms=0;32:mc=0;32:sl=:cx=:fn=0;35:ln=0;33:bn=0;33:se=0;30'
    fi
    
    # Configure less colors (for man pages, etc.)
    if [[ "$is_dark_mode" == "true" ]]; then
        export LESS_TERMCAP_mb=$'\e[1;32m'     # begin bold
        export LESS_TERMCAP_md=$'\e[1;36m'     # begin blink
        export LESS_TERMCAP_me=$'\e[0m'        # reset bold/blink
        export LESS_TERMCAP_so=$'\e[01;44;33m' # begin reverse video
        export LESS_TERMCAP_se=$'\e[0m'        # reset reverse video
        export LESS_TERMCAP_us=$'\e[1;33m'     # begin underline
        export LESS_TERMCAP_ue=$'\e[0m'        # reset underline
    else
        export LESS_TERMCAP_mb=$'\e[0;32m'     # begin bold
        export LESS_TERMCAP_md=$'\e[0;34m'     # begin blink
        export LESS_TERMCAP_me=$'\e[0m'        # reset bold/blink
        export LESS_TERMCAP_so=$'\e[01;47;30m' # begin reverse video
        export LESS_TERMCAP_se=$'\e[0m'        # reset reverse video
        export LESS_TERMCAP_us=$'\e[0;33m'     # begin underline
        export LESS_TERMCAP_ue=$'\e[0m'        # reset underline
    fi
}

# Main function to configure adaptive colors
configure_adaptive_colors() {
    # Allow override via environment variable
    local terminal_override="${FORCE_TERMINAL_TYPE:-}"
    local theme_override="${FORCE_DARK_MODE:-}"
    
    # Detect terminal and theme
    local terminal_type="${terminal_override:-$(detect_terminal)}"
    local is_dark_mode
    
    if [[ -n "$theme_override" ]]; then
        is_dark_mode="$theme_override"
    elif detect_dark_mode; then
        is_dark_mode="true"
    else
        is_dark_mode="false"
    fi
    
    # Get and set color scheme
    local color_scheme=$(get_color_scheme "$terminal_type" "$is_dark_mode")
    export LS_COLORS="$color_scheme"
    
    # Set additional color environment
    set_color_environment "$terminal_type" "$is_dark_mode"
    
    # Debug info (only if DEBUG_COLORS is set)
    if [[ "${DEBUG_COLORS:-}" == "1" ]]; then
        echo "🎨 Adaptive Colors Debug:" >&2
        echo "  Terminal: $terminal_type" >&2
        echo "  Dark Mode: $is_dark_mode" >&2
        echo "  LS_COLORS: ${LS_COLORS:0:50}..." >&2
    fi
}

# Function to manually refresh colors (useful for theme changes)
refresh_colors() {
    configure_adaptive_colors
    echo "🎨 Colors refreshed for $(detect_terminal) terminal (Dark mode: $(detect_dark_mode && echo "Yes" || echo "No"))"
}

# Export the refresh function for user convenience
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script is being executed directly
    configure_adaptive_colors
else
    # Script is being sourced
    configure_adaptive_colors
    
    # Make refresh function available as an alias
    alias refresh-colors='source "$HOME/.scripts/adaptive-colors.sh" && refresh_colors'
fi
