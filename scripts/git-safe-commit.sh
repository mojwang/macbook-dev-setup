#!/usr/bin/env bash
# Git Safe Commit - Enforces feature branch workflow
# Prevents direct commits to main branch

set -e
source "$(dirname "$0")/../lib/common.sh"

# Constants
PROTECTED_BRANCHES=("main" "master" "develop" "staging" "production")

# Function to check if current branch is protected
is_protected_branch() {
    local current_branch="$1"
    for protected in "${PROTECTED_BRANCHES[@]}"; do
        if [[ "$current_branch" == "$protected" ]]; then
            return 0
        fi
    done
    return 1
}

# Function to suggest branch name from commit message
suggest_branch_name() {
    local commit_msg="$1"
    local branch_type="feat"
    local branch_desc=""
    
    # Determine branch type from commit message
    if [[ "$commit_msg" =~ ^fix ]]; then
        branch_type="fix"
    elif [[ "$commit_msg" =~ ^docs ]]; then
        branch_type="docs"
    elif [[ "$commit_msg" =~ ^chore ]]; then
        branch_type="chore"
    elif [[ "$commit_msg" =~ ^refactor ]]; then
        branch_type="refactor"
    elif [[ "$commit_msg" =~ ^test ]]; then
        branch_type="test"
    fi
    
    # Extract description from commit message
    branch_desc=$(echo "$commit_msg" | sed -E 's/^[a-z]+(\([^)]+\))?:\s*//' | \
                  tr '[:upper:]' '[:lower:]' | \
                  sed 's/[^a-z0-9-]/-/g' | \
                  sed 's/-+/-/g' | \
                  sed 's/^-//' | \
                  sed 's/-$//' | \
                  cut -c1-50)
    
    echo "${branch_type}/${branch_desc}"
}

# Function to check if changes need a worktree
needs_worktree() {
    local changed_files=$(git diff --cached --name-only | wc -l)
    local changed_dirs=$(git diff --cached --name-only | xargs -I {} dirname {} | sort -u | wc -l)
    
    # Complex if: 3+ files OR changes span 3+ directories
    if [[ $changed_files -ge 3 ]] || [[ $changed_dirs -ge 3 ]]; then
        return 0
    fi
    return 1
}

# Main function
main() {
    local current_branch=$(git branch --show-current)
    local commit_message="$1"
    
    # Check if we're on a protected branch
    if is_protected_branch "$current_branch"; then
        echo "❌ ERROR: Cannot commit directly to '$current_branch' branch!"
        echo ""
        echo "You must create a feature branch first. Options:"
        echo ""
        
        # Suggest branch name if commit message provided
        if [[ -n "$commit_message" ]]; then
            local suggested_branch=$(suggest_branch_name "$commit_message")
            echo "1. Create feature branch:"
            echo "   git checkout -b $suggested_branch"
            echo ""
        else
            echo "1. Create feature branch:"
            echo "   git checkout -b feat/your-feature-name"
            echo ""
        fi
        
        # Check if worktree might be needed
        if needs_worktree; then
            echo "2. This looks like a complex feature (3+ files/dirs affected)."
            echo "   Consider using a worktree instead:"
            echo "   git worktree add ../$(basename $(pwd)).feature feat/your-feature"
            echo ""
        fi
        
        echo "3. Then commit your changes:"
        echo "   git add ."
        echo "   git commit -m \"$commit_message\""
        echo ""
        echo "Remember: ALL changes require feature branches!"
        
        exit 1
    fi
    
    # Safe to commit on feature branch
    echo "✅ Safe to commit on branch: $current_branch"
    
    # If this is a complex feature, remind about worktrees
    if needs_worktree; then
        echo ""
        echo "💡 TIP: This looks like a complex feature. For future complex work,"
        echo "   consider using worktrees to keep changes isolated:"
        echo "   ../$(basename $(pwd)).$current_branch/"
    fi
    
    # If commit message provided, execute the commit
    if [[ -n "$commit_message" ]]; then
        echo ""
        echo "Committing with message: $commit_message"
        git commit -m "$commit_message"
    else
        echo ""
        echo "Ready to commit. Use:"
        echo "  git commit -m \"your message\""
    fi
}

# Run main function
main "$@"