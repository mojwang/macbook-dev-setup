# Homebrew Setup and Configuration
# Optimized for Apple Silicon macOS

# Cache Homebrew prefix for performance
if [[ -z "$HOMEBREW_PREFIX" ]]; then
    if [[ $(uname -m) == "arm64" ]]; then
        export HOMEBREW_PREFIX="/opt/homebrew"
    else
        export HOMEBREW_PREFIX="/usr/local"
    fi
fi

# Initialize Homebrew if available
if [[ -x "$HOMEBREW_PREFIX/bin/brew" ]]; then
    eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"
    
    # Homebrew completion setup
    FPATH="$HOMEBREW_PREFIX/share/zsh/site-functions:${FPATH}"
    autoload -Uz compinit
    compinit
fi