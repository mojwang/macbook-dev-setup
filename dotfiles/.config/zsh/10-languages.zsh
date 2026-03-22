# Programming Language Version Managers
# Node.js, Python, Ruby, etc.

# Node.js version management (NVM)
# Node.js is managed exclusively by nvm (not Homebrew) to avoid PATH conflicts
# in non-interactive shells (agents, CI, scripts).
export NVM_DIR="$HOME/.nvm"
[ ! -d "$NVM_DIR" ] && mkdir -p "$NVM_DIR"

# Source nvm (idempotent — guarded by _NVM_LOADED)
_nvm_source() {
    if [[ -n "$_NVM_LOADED" ]]; then return; fi
    _NVM_LOADED=1
    unset -f nvm node npm npx 2>/dev/null
    if [ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ]; then
        source "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"
        [ -s "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ] && source "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm"
    elif [ -s "$NVM_DIR/nvm.sh" ]; then
        source "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
    fi
}

if [[ -o interactive ]]; then
    # Interactive shells: lazy-load via wrappers for fast startup (~50ms saved)
    if [[ -z "$_NVM_LOADED" ]]; then
        nvm()  { _nvm_source; nvm "$@"; }
        node() { _nvm_source; node "$@"; }
        npm()  { _nvm_source; npm "$@"; }
        npx()  { _nvm_source; npx "$@"; }
    fi
else
    # Non-interactive shells (Claude Code, CI, scripts): eager-load nvm
    # so node/npm are real binaries from the start. No human waiting.
    _nvm_source
fi

# Auto-load .nvmrc files (interactive shells only)
if [[ -o interactive ]]; then
    autoload -U add-zsh-hook
    load-nvmrc() {
        if [[ -f .nvmrc && -r .nvmrc ]]; then
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
fi

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

# SDKMAN - JVM version manager (auto-switches JDK per-directory via .sdkmanrc)
export SDKMAN_DIR="$HOME/.sdkman"
if [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
    source "$SDKMAN_DIR/bin/sdkman-init.sh"
fi
