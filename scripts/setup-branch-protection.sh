#!/bin/bash

# Setup GitHub Branch Protection Rules
# This script configures branch protection for the main branch
# Requires GitHub CLI (gh) to be authenticated

set -e

# Source common functions
source "$(dirname "$0")/../lib/common.sh"

# Check if gh is installed and authenticated
check_gh_auth() {
    if ! command -v gh &> /dev/null; then
        print_error "GitHub CLI (gh) is not installed"
        echo "Install with: brew install gh"
        exit 1
    fi
    
    if ! gh auth status &> /dev/null; then
        print_error "GitHub CLI is not authenticated"
        echo "Run: gh auth login"
        exit 1
    fi
    
    print_success "GitHub CLI is authenticated"
}

# Get repository information
get_repo_info() {
    local repo_info=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)
    if [[ -z "$repo_info" ]]; then
        print_error "Could not determine repository. Are you in a git repository?"
        exit 1
    fi
    echo "$repo_info"
}

# Setup branch protection
setup_protection() {
    local repo="$1"
    local branch="main"
    
    print_step "Configuring branch protection for $repo:$branch"
    
    # Create the branch protection rule using GitHub API
    gh api \
        --method PUT \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "/repos/$repo/branches/$branch/protection" \
        -f "required_status_checks[strict]=true" \
        -f "required_status_checks[contexts][]=test" \
        -f "required_status_checks[contexts][]=validate-documentation" \
        -f "required_status_checks[contexts][]=security-scan" \
        -f "required_status_checks[contexts][]=All Checks Pass" \
        -f "enforce_admins=true" \
        -f "required_pull_request_reviews[required_approving_review_count]=1" \
        -f "required_pull_request_reviews[dismiss_stale_reviews]=true" \
        -f "required_pull_request_reviews[require_code_owner_reviews]=false" \
        -f "required_pull_request_reviews[bypass_pull_request_allowances][users][]=$GITHUB_USER" \
        -f "restrictions=null" \
        -f "allow_force_pushes=false" \
        -f "allow_deletions=false" \
        -f "required_conversation_resolution=true" \
        -f "lock_branch=false" \
        -f "allow_fork_syncing=false" 2>/dev/null || {
        
        # If the above fails, try a simpler configuration
        print_warning "Full configuration failed, trying basic configuration..."
        
        gh api \
            --method PUT \
            -H "Accept: application/vnd.github+json" \
            "/repos/$repo/branches/$branch/protection" \
            -F "required_status_checks[strict]=true" \
            -F "required_status_checks[contexts][]=test" \
            -F "required_status_checks[contexts][]=validate-documentation" \
            -F "required_status_checks[contexts][]=security-scan" \
            -F "required_status_checks[contexts][]=All Checks Pass" \
            -F "enforce_admins=true" \
            -F "required_pull_request_reviews[required_approving_review_count]=1" \
            -F "required_pull_request_reviews[dismiss_stale_reviews]=true" \
            -F "restrictions=null" \
            -F "allow_force_pushes=false" \
            -F "allow_deletions=false"
    }
    
    print_success "Branch protection configured successfully!"
}

# Display current protection status
show_protection_status() {
    local repo="$1"
    local branch="main"
    
    print_step "Current branch protection status:"
    
    gh api \
        -H "Accept: application/vnd.github+json" \
        "/repos/$repo/branches/$branch/protection" 2>/dev/null | \
        jq -r '
            "✓ Required status checks: " + (.required_status_checks.strict | tostring) + "\n" +
            "✓ Required checks: " + (.required_status_checks.contexts | join(", ")) + "\n" +
            "✓ Enforce admins: " + (.enforce_admins.enabled | tostring) + "\n" +
            "✓ Required reviews: " + (.required_pull_request_reviews.required_approving_review_count | tostring) + "\n" +
            "✓ Dismiss stale reviews: " + (.required_pull_request_reviews.dismiss_stale_reviews | tostring) + "\n" +
            "✓ Force pushes allowed: " + (.allow_force_pushes.enabled | tostring) + "\n" +
            "✓ Deletions allowed: " + (.allow_deletions.enabled | tostring)
        ' || print_warning "Could not fetch current protection status"
}

# Main execution
main() {
    echo -e "${BLUE}"
    echo "GitHub Branch Protection Setup"
    echo "=============================="
    echo -e "${NC}"
    
    # Check prerequisites
    check_gh_auth
    
    # Get repository info
    GITHUB_USER=$(gh api user -q .login)
    REPO=$(get_repo_info)
    
    print_info "Repository: $REPO"
    print_info "User: $GITHUB_USER"
    echo
    
    # Show current status
    show_protection_status "$REPO"
    echo
    
    # Confirm before applying
    read -p "Apply branch protection rules? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Branch protection setup cancelled"
        exit 0
    fi
    
    # Setup protection
    setup_protection "$REPO"
    
    echo
    print_success "Branch protection has been configured!"
    echo
    echo "Protection rules applied:"
    echo "  • PR required for non-admins"
    echo "  • 1 approval required"
    echo "  • Status checks must pass (including for admins)"
    echo "  • No force pushes allowed"
    echo "  • No branch deletion allowed"
    echo "  • Stale reviews dismissed on new commits"
    echo
    echo "Required status checks:"
    echo "  • test"
    echo "  • validate-documentation"
    echo "  • security-scan"
    echo "  • All Checks Pass"
    echo
    print_info "Admins can push directly but tests must still pass!"
}

main "$@"