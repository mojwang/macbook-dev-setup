

# Development Environment .zshrc Configuration
# Optimized for Apple Silicon macOS

# Homebrew setup
if [[ $(uname -m) == "arm64" ]]; then
    # Apple Silicon
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    # Intel Mac
    eval "$(/usr/local/bin/brew shellenv)"
fi

# Homebrew completion setup
if type brew &>/dev/null; then
    FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
    autoload -Uz compinit
    compinit
fi

# Node.js version management (NVM)
# Check if nvm is installed via Homebrew first
if [ -s "$(brew --prefix)/opt/nvm/nvm.sh" ]; then
    export NVM_DIR="$HOME/.nvm"
    [ ! -d "$NVM_DIR" ] && mkdir -p "$NVM_DIR"
    source "$(brew --prefix)/opt/nvm/nvm.sh"
    [ -s "$(brew --prefix)/opt/nvm/etc/bash_completion.d/nvm" ] && source "$(brew --prefix)/opt/nvm/etc/bash_completion.d/nvm"
else
    # Fallback to manual installation
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
fi

# Auto-load .nvmrc files
autoload -U add-zsh-hook
load-nvmrc() {
    local nvmrc_path="$(nvm_find_nvmrc)"
    
    if [ -n "$nvmrc_path" ]; then
        local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")
        
        if [ "$nvmrc_node_version" = "N/A" ]; then
            nvm install
        elif [ "$nvmrc_node_version" != "$(nvm version)" ]; then
            nvm use
        fi
    elif [ -n "$(PWD=$OLDPWD nvm_find_nvmrc)" ] && [ "$(nvm version)" != "$(nvm version default)" ]; then
        echo "Reverting to nvm default version"
        nvm use default
    fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc

# Python version management (pyenv)
if command -v pyenv 1>/dev/null 2>&1; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
fi

# Custom scripts directory
export PATH="$HOME/.scripts:$PATH"

# Adaptive color configuration
# Load adaptive colors that automatically detect terminal type and theme
if [[ -f "$HOME/.scripts/adaptive-colors.sh" ]]; then
    source "$HOME/.scripts/adaptive-colors.sh"
else
    # Fallback color configuration
    export LS_COLORS="di=1;34:fi=0:ln=1;36:pi=1;33:so=1;35:bd=1;33;40:cd=1;33;40:or=1;31;40:ex=1;32"
    export CLICOLOR=1
    export CLICOLOR_FORCE=1
fi

# Modern CLI tools
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

if command -v bat &> /dev/null; then
    alias cat="bat"
fi

# Fuzzy finder (fzf)
if command -v fzf &> /dev/null; then
    eval "$(fzf --zsh)"
fi

# Smart directory navigation (zoxide)
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init zsh)"
fi

# Starship prompt
if command -v starship &> /dev/null; then
    eval "$(starship init zsh)"
fi

# Git aliases
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gl="git log --oneline"
alias gd="git diff"
alias gb="git branch"
alias gco="git checkout"

# Text editor aliases
alias vim="nvim"
alias vi="nvim"
alias v="nvim"

# Utility aliases
alias ip="ipconfig getifaddr en0"
alias home="cd ~"
alias reload="source ~/.zshrc"
alias copy="rsync -ahr --progress"

# Docker aliases
alias d="docker"
alias dc="docker-compose"
alias dps="docker ps"
alias di="docker images"

# Utility functions
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract function for various archive types
extract() {
    if [ -f $1 ] ; then
        case $1 in
            *.tar.bz2)   tar xjf $1     ;;
            *.tar.gz)    tar xzf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unrar e $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xf $1      ;;
            *.tbz2)      tar xjf $1     ;;
            *.tgz)       tar xzf $1     ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1        ;;
            *)     echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Development environment info
devinfo() {
    echo "🔧 Development Environment Info"
    echo "==============================="
    echo "OS: $(uname -s) $(uname -m)"
    echo "Shell: $SHELL"
    
    if command -v brew &> /dev/null; then
        echo "Homebrew: $(brew --version | head -n1)"
    fi
    
    if command -v node &> /dev/null; then
        echo "Node.js: $(node --version)"
        echo "npm: $(npm --version)"
    fi
    
    if command -v python3 &> /dev/null; then
        echo "Python: $(python3 --version)"
    fi
    
    if command -v git &> /dev/null; then
        echo "Git: $(git --version)"
    fi
    
    if command -v nvim &> /dev/null; then
        echo "Neovim: $(nvim --version | head -n1)"
    fi
    
    if command -v code &> /dev/null; then
        echo "VS Code: $(code --version | head -n1)"
    fi
}

# History configuration
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

# Environment variables
export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="less"
export BROWSER="open"

# Claude CLI OAuth token setup reminder
# Run: claude setup-token

# Load local customizations if they exist
if [[ -f ~/.zshrc.local ]]; then
    source ~/.zshrc.local
fi
