# Programming Language Version Managers
# Node.js, Python, Ruby, etc.

# Node.js version management (NVM) - Lazy loaded for performance
export NVM_DIR="$HOME/.nvm"
[ ! -d "$NVM_DIR" ] && mkdir -p "$NVM_DIR"

# Lazy load NVM to improve shell startup time
nvm() {
    unset -f nvm node npm npx
    if [ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ]; then
        source "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"
        [ -s "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ] && source "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm"
    elif [ -s "$NVM_DIR/nvm.sh" ]; then
        source "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
    fi
    nvm "$@"
}

node() {
    unset -f nvm node npm npx
    if [ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ]; then
        source "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"
    elif [ -s "$NVM_DIR/nvm.sh" ]; then
        source "$NVM_DIR/nvm.sh"
    fi
    node "$@"
}

npm() {
    unset -f nvm node npm npx
    if [ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ]; then
        source "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"
    elif [ -s "$NVM_DIR/nvm.sh" ]; then
        source "$NVM_DIR/nvm.sh"
    fi
    npm "$@"
}

npx() {
    unset -f nvm node npm npx
    if [ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ]; then
        source "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"
    elif [ -s "$NVM_DIR/nvm.sh" ]; then
        source "$NVM_DIR/nvm.sh"
    fi
    npx "$@"
}

# Auto-load .nvmrc files
autoload -U add-zsh-hook
load-nvmrc() {
    if [[ -f .nvmrc && -r .nvmrc ]]; then
        # Ensure NVM is loaded
        if ! command -v nvm &> /dev/null; then
            nvm > /dev/null 2>&1
        fi
        
        local nvmrc_path="$(nvm_find_nvmrc)"
        
        if [ -n "$nvmrc_path" ]; then
            local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")
            
            if [ "$nvmrc_node_version" = "N/A" ]; then
                nvm install
            elif [ "$nvmrc_node_version" != "$(nvm version)" ]; then
                nvm use
            fi
        fi
    elif [ -n "$(PWD=$OLDPWD nvm_find_nvmrc 2>/dev/null)" ] && [ "$(nvm version 2>/dev/null)" != "$(nvm version default 2>/dev/null)" ]; then
        echo "Reverting to nvm default version"
        nvm use default
    fi
}
add-zsh-hook chpwd load-nvmrc

# Python version management (pyenv)
if command -v pyenv 1>/dev/null 2>&1; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
fi

# Ruby version management (rbenv)
if command -v rbenv 1>/dev/null 2>&1; then
    eval "$(rbenv init - zsh)"
fi