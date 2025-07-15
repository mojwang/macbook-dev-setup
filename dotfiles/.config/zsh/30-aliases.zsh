# Shell Aliases
# Git, Docker, and utility shortcuts

# Git aliases
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gl="git log --oneline"
# Enhanced git diff with delta if available
if command -v delta &> /dev/null; then
    alias gd="git diff | delta"
    alias gdiff="git diff | delta"
else
    alias gd="git diff"
fi
alias gb="git branch"
alias gco="git checkout"
alias gpl="git pull"
alias gf="git fetch"
alias gm="git merge"
alias gr="git rebase"
alias gstash="git stash"

# Text editor aliases
if command -v nvim &> /dev/null; then
    alias vim="nvim"
    alias vi="nvim"
    alias v="nvim"
fi

# Utility aliases
alias ip="ipconfig getifaddr en0"
alias home="cd ~"
alias reload="source ~/.zshrc"
alias copy="rsync -ahr --progress"
alias cls="clear"
alias .....="cd ../../../.."

# Docker aliases
if command -v docker &> /dev/null; then
    alias d="docker"
    alias dc="docker-compose"
    alias dps="docker ps"
    alias dpsa="docker ps -a"
    alias di="docker images"
    alias drm="docker rm"
    alias drmi="docker rmi"
    alias dlog="docker logs -f"
fi

# Safety aliases
alias rm="rm -i"
alias cp="cp -i"
alias mv="mv -i"

# macOS specific aliases
if [[ "$(uname)" == "Darwin" ]]; then
    alias showfiles="defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder"
    alias hidefiles="defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder"
    alias flushdns="sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder"
fi