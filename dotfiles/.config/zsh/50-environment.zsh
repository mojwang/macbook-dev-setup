# Environment Variables and Shell Settings

# History configuration
HISTSIZE=10000
SAVEHIST=10000
HISTFILE="$HOME/.zsh_history"
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_VERIFY

# Editor preferences
export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="less"
export BROWSER="open"

# Less configuration
export LESS="-R -F -X"
export LESSHISTFILE=-

# Locale settings
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# Development settings
export PYTHONDONTWRITEBYTECODE=1
export NODE_ENV="${NODE_ENV:-development}"

# Security settings
export GPG_TTY=$(tty)

# Performance optimizations
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_INSTALL_CLEANUP=1

# Claude CLI OAuth token setup reminder
# Run: claude setup-token