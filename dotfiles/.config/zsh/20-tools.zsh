# Modern CLI Tools Configuration
# Enhanced replacements for common Unix tools

# Custom scripts directory
export PATH="$HOME/.scripts:$PATH"

# Adaptive color configuration
if [[ -f "$HOME/.scripts/adaptive-colors.sh" ]]; then
    source "$HOME/.scripts/adaptive-colors.sh"
else
    # Fallback color configuration
    export LS_COLORS="di=1;34:fi=0:ln=1;36:pi=1;33:so=1;35:bd=1;33;40:cd=1;33;40:or=1;31;40:ex=1;32"
    export CLICOLOR=1
    export CLICOLOR_FORCE=1
fi

# Modern ls replacement (eza/exa)
if command -v eza &> /dev/null; then
    # Use custom eza wrapper if available
    if [[ -x "$HOME/.scripts/exa-wrapper.sh" ]]; then
        alias ls="$HOME/.scripts/exa-wrapper.sh"
        alias ll="$HOME/.scripts/exa-wrapper.sh -l"
        alias la="$HOME/.scripts/exa-wrapper.sh -la"
        alias tree="$HOME/.scripts/exa-wrapper.sh --tree"
    else
        alias ls="eza --color=always --group-directories-first"
        alias ll="eza -l --color=always --group-directories-first"
        alias la="eza -la --color=always --group-directories-first"
        alias tree="eza --tree --color=always"
    fi
else
    alias ls="/bin/ls $LS_OPTIONS"
    alias ll="ls -aghl"
fi

# Enhanced cat (bat)
if command -v bat &> /dev/null; then
    alias cat="bat"
    export BAT_THEME="auto"
fi

# Fuzzy finder (fzf)
if command -v fzf &> /dev/null; then
    eval "$(fzf --zsh)"
    export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"
    
    # Use fd for fzf if available
    if command -v fd &> /dev/null; then
        export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    fi
fi

# Smart directory navigation (zoxide)
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init zsh)"
fi

# Starship prompt
if command -v starship &> /dev/null; then
    eval "$(starship init zsh)"
fi

# Zsh autosuggestions
if [[ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    # Optional: customize suggestion color (default is grayed out)
    # ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8"
fi