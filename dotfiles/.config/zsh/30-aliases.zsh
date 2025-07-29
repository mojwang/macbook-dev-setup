# Shell Aliases
# Git, Docker, and utility shortcuts

# Git aliases
alias g="git"
alias gs="git status"
alias ga="git add"
alias gp="git push"
alias gpl="git pull"
alias gf="git fetch"
# Enhanced git diff with delta if available
if command -v delta &> /dev/null; then
    alias gd="git diff | delta"
else
    alias gd="git diff"
fi
# Use git aliases from .gitconfig for these
alias gl="git lg"
alias gla="git lga"
alias gco="git checkout"
alias gb="git branch"
alias gm="git merge"
alias gr="git rebase"
alias gstash="git stash"

# Git worktree aliases
alias gwa="git worktree add"
alias gwl="git worktree list"
alias gwr="git worktree remove"
alias gwp="git worktree prune"

# Smart worktree switcher - finds sibling worktrees
gwcd() {
    # If in a repo with worktrees, show them
    local current_repo=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)")
    if [[ -n "$current_repo" ]]; then
        # Find all related worktrees (same prefix)
        local base_name="${current_repo%.*}"  # Remove suffix if any
        local selected=$(find "$(dirname "$(pwd)")" -maxdepth 1 -type d -name "${base_name}*" | \
            xargs -I {} bash -c 'echo "{} ($(cd "{}" && git branch --show-current 2>/dev/null || echo "no branch"))"' | \
            fzf --header="Select worktree:" | \
            awk '{print $1}')
        [[ -n "$selected" ]] && cd "$selected"
    else
        echo "Not in a git repository"
    fi
}

# Quick switch between main and worktrees
gw() {
    case "$1" in
        main)   cd "${PWD%.*}";;           # Go to main (remove suffix)
        review) cd "${PWD%.*}.review";;    # Go to review worktree
        hotfix) cd "${PWD%.*}.hotfix";;    # Go to hotfix worktree
        test)   cd "${PWD%.*}.test";;      # Go to test worktree
        *)      gwcd;;                     # Interactive selection
    esac
}

# Setup standard worktrees for current repo
setup_worktrees() {
    local repo_name=$(basename "$(pwd)")
    echo "Setting up standard worktrees for $repo_name..."
    
    # Create standard worktrees as siblings
    git worktree add ../${repo_name}.review main
    git worktree add ../${repo_name}.hotfix main
    
    echo "Worktrees created:"
    git worktree list
}

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

# Help system alias - dynamically find the setup directory
if [[ -f "$HOME/repos/personal/macbook-dev-setup/setup.sh" ]]; then
    alias devhelp="$HOME/repos/personal/macbook-dev-setup/setup.sh info"
elif command -v setup.sh &>/dev/null; then
    alias devhelp="setup.sh info"
else
    # Try to find setup.sh in common locations
    for dir in "$HOME/macbook-dev-setup" "$HOME/dev/macbook-dev-setup" "$HOME/projects/macbook-dev-setup"; do
        if [[ -f "$dir/setup.sh" ]]; then
            alias devhelp="$dir/setup.sh info"
            break
        fi
    done
fi

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