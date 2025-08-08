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

# Git cleanup aliases
alias gprune="git remote prune origin"
alias gclean="git-cleanup-branches"

# Clean up stale remote-tracking branches
git-cleanup-branches() {
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "Error: Not in a git repository"
        return 1
    fi
    
    # First, prune remote branches
    echo "Pruning remote branches..."
    git remote prune origin
    
    # Find branches that are gone
    local gone_branches=$(git branch -vv | grep ": gone]" | awk '{print $1}')
    
    if [[ -z "$gone_branches" ]]; then
        echo "No stale branches to clean up"
        return 0
    fi
    
    echo ""
    echo "The following branches track remote branches that no longer exist:"
    echo "$gone_branches" | while read -r branch; do
        echo "  - $branch"
    done
    echo ""
    
    # Check if we're in non-interactive mode or if force flag is set
    if [[ "$1" == "--force" ]] || [[ "$1" == "-f" ]]; then
        echo "Force mode: Deleting branches without confirmation..."
        echo "$gone_branches" | xargs git branch -d 2>/dev/null || \
        echo "$gone_branches" | xargs git branch -D
        echo "Cleanup complete!"
    else
        # Ask for confirmation
        echo -n "Delete these branches? [y/N] "
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            # Try safe delete first, then force if needed
            echo "$gone_branches" | while read -r branch; do
                if git branch -d "$branch" 2>/dev/null; then
                    echo "Deleted: $branch"
                else
                    echo -n "Branch '$branch' is not fully merged. Force delete? [y/N] "
                    read -r force_response
                    if [[ "$force_response" =~ ^[Yy]$ ]]; then
                        git branch -D "$branch"
                        echo "Force deleted: $branch"
                    else
                        echo "Skipped: $branch"
                    fi
                fi
            done
            echo "Cleanup complete!"
        else
            echo "Cleanup cancelled"
        fi
    fi
}

# Smart worktree switcher - finds sibling worktrees
gwcd() {
    # Check for fzf dependency
    if ! command -v fzf &>/dev/null; then
        echo "Error: fzf is required for interactive worktree selection"
        echo "Install with: brew install fzf"
        return 1
    fi
    
    # Cache git root to avoid multiple calls
    local git_root
    git_root=$(git rev-parse --show-toplevel 2>/dev/null) || {
        echo "Not in a git repository"
        return 1
    }
    
    local current_repo=$(basename "$git_root")
    # Find all related worktrees (same prefix)
    local base_name="${current_repo%.*}"  # Remove suffix if any
    local parent_dir=$(dirname "$git_root")
    
    local selected=$(find "$parent_dir" -maxdepth 1 -type d -name "${base_name}*" | \
        xargs -I {} bash -c 'echo "{} ($(cd "{}" && git branch --show-current 2>/dev/null || echo "no branch"))"' | \
        fzf --header="Select worktree:" | \
        awk '{print $1}')
    
    [[ -n "$selected" ]] && cd "$selected"
}

# Quick switch between main and worktrees
gw() {
    case "$1" in
        main)   
            local main_path="${PWD%.*}"
            if [[ -d "$main_path" ]]; then
                cd "$main_path"
            else
                echo "Main worktree not found at: $main_path"
                return 1
            fi
            ;;
        review) 
            local review_path="${PWD%.*}.review"
            [[ -d "$review_path" ]] && cd "$review_path" || echo "Review worktree not found"
            ;;
        hotfix) 
            local hotfix_path="${PWD%.*}.hotfix"
            [[ -d "$hotfix_path" ]] && cd "$hotfix_path" || echo "Hotfix worktree not found"
            ;;
        test)   
            local test_path="${PWD%.*}.test"
            [[ -d "$test_path" ]] && cd "$test_path" || echo "Test worktree not found"
            ;;
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