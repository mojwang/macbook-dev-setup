#!/usr/bin/env bash
# Feature Worktree - Automatically create worktree for complex features
# Enforces worktree usage for multi-file features

set -e
source "$(dirname "$0")/../lib/common.sh"

# Constants
PROJECT_NAME=$(basename "$(pwd)")
PARENT_DIR=$(dirname "$(pwd)")

# Function to validate branch name
validate_branch_name() {
    local branch="$1"
    local valid_prefixes=("feat" "fix" "docs" "chore" "refactor" "test")
    
    for prefix in "${valid_prefixes[@]}"; do
        if [[ "$branch" =~ ^${prefix}/ ]]; then
            return 0
        fi
    done
    
    echo "❌ Invalid branch name: $branch"
    echo "   Must start with: feat/, fix/, docs/, chore/, refactor/, or test/"
    return 1
}

# Function to check if worktree already exists
worktree_exists() {
    local worktree_path="$1"
    git worktree list | grep -q "$worktree_path" && return 0 || return 1
}

# Function to get worktree name from branch
get_worktree_name() {
    local branch="$1"
    # Convert feat/feature-name to feature-name
    local feature_name=$(echo "$branch" | sed 's|^[^/]*/||' | tr '/' '-')
    echo "${PROJECT_NAME}.${feature_name}"
}

# Function to create worktree
create_worktree() {
    local branch="$1"
    local worktree_name=$(get_worktree_name "$branch")
    local worktree_path="${PARENT_DIR}/${worktree_name}"
    
    # Check if worktree already exists
    if worktree_exists "$worktree_path"; then
        echo "✅ Worktree already exists: $worktree_path"
        echo "   Switching to it..."
        cd "$worktree_path"
        return 0
    fi
    
    # Check if branch exists
    local branch_exists=false
    if git show-ref --verify --quiet "refs/heads/$branch"; then
        branch_exists=true
    fi
    
    echo "Creating worktree for complex feature..."
    echo "  Branch: $branch"
    echo "  Location: $worktree_path"
    echo ""
    
    # Create the worktree
    if $branch_exists; then
        git worktree add "$worktree_path" "$branch"
    else
        git worktree add -b "$branch" "$worktree_path"
    fi
    
    echo ""
    echo "✅ Worktree created successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Navigate to worktree:"
    echo "   cd $worktree_path"
    echo ""
    echo "2. Work on your feature there"
    echo ""
    echo "3. When done, remove worktree:"
    echo "   git worktree remove $worktree_path"
    echo ""
    echo "Or use aliases:"
    echo "   gw ${feature_name}  # Quick switch to this worktree"
    
    # Optionally switch to the new worktree
    read -p "Switch to the new worktree now? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cd "$worktree_path"
        echo "Switched to: $(pwd)"
    fi
}

# Function to list existing worktrees
list_worktrees() {
    echo "Existing worktrees for $PROJECT_NAME:"
    echo ""
    git worktree list | while read -r line; do
        local path=$(echo "$line" | awk '{print $1}')
        local branch=$(echo "$line" | sed 's/.*\[//' | sed 's/\]//')
        local current=""
        
        if [[ "$path" == "$(pwd)" ]]; then
            current=" (current)"
        fi
        
        echo "  $(basename "$path") → $branch$current"
    done
}

# Main function
main() {
    local branch="$1"
    
    # If no branch provided, show help
    if [[ -z "$branch" ]]; then
        echo "Feature Worktree Helper"
        echo ""
        echo "Usage: $0 <branch-name>"
        echo ""
        echo "Examples:"
        echo "  $0 feat/payment-integration"
        echo "  $0 fix/login-bug"
        echo "  $0 refactor/database-layer"
        echo ""
        echo "This will create a worktree at:"
        echo "  ../PROJECT.feature-name/"
        echo ""
        list_worktrees
        exit 1
    fi
    
    # Validate branch name
    if ! validate_branch_name "$branch"; then
        exit 1
    fi
    
    # Check current branch
    local current_branch=$(git branch --show-current)
    if [[ "$current_branch" == "main" ]] || [[ "$current_branch" == "master" ]]; then
        echo "✅ Currently on $current_branch, safe to create worktree"
    else
        echo "⚠️  Currently on branch: $current_branch"
        echo "   Consider committing or stashing changes first"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Aborted."
            exit 1
        fi
    fi
    
    # Create the worktree
    create_worktree "$branch"
}

# Run main function
main "$@"