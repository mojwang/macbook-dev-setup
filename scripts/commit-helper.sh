#!/bin/bash

# Conventional Commit Helper
# Makes it easy to create properly formatted commits

# Load common library
source "$(dirname "$0")/../lib/common.sh"

# Commit types with descriptions
COMMIT_TYPES_LIST=("feat" "fix" "docs" "style" "refactor" "perf" "test" "build" "ci" "chore" "revert")

# Function to get commit type description
get_commit_type_desc() {
    case "$1" in
        feat) echo "New feature" ;;
        fix) echo "Bug fix" ;;
        docs) echo "Documentation changes" ;;
        style) echo "Code style changes (formatting, etc.)" ;;
        refactor) echo "Code refactoring" ;;
        perf) echo "Performance improvements" ;;
        test) echo "Test changes" ;;
        build) echo "Build system changes" ;;
        ci) echo "CI/CD changes" ;;
        chore) echo "Other maintenance" ;;
        revert) echo "Revert previous commit" ;;
        *) echo "Unknown type" ;;
    esac
}

# Valid scopes
SCOPES=(
    "setup"
    "dotfiles"
    "homebrew"
    "scripts"
    "docs"
    "tests"
    "vscode"
    "zsh"
    "none"
)

# Show usage
usage() {
    echo "Usage: $(basename "$0") [options]"
    echo
    echo "Interactive conventional commit helper"
    echo
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -q, --quick    Quick mode with minimal prompts"
    echo
    echo "Examples:"
    echo "  $(basename "$0")           # Interactive mode"
    echo "  $(basename "$0") --quick   # Quick mode"
    echo
    echo "Shortcuts (add to ~/.config/zsh/30-aliases.zsh):"
    echo "  alias gcf='git add . && ./scripts/commit-helper.sh'"
    echo "  alias gcfq='git add . && ./scripts/commit-helper.sh --quick'"
}

# Parse arguments
QUICK_MODE=false
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -q|--quick)
            QUICK_MODE=true
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Select commit type
print_header "Conventional Commit Helper"
echo
print_info "Select commit type:"
echo

# Display types with numbers
i=1
type_array=()
for type in "${COMMIT_TYPES_LIST[@]}"; do
    type_array+=("$type")
    desc=$(get_commit_type_desc "$type")
    printf "  %2d) %-10s - %s\n" "$i" "$type" "$desc"
    ((i++))
done

echo
read -p "Enter number (1-${#COMMIT_TYPES_LIST[@]}): " type_num

# Validate selection
if [[ ! "$type_num" =~ ^[0-9]+$ ]] || [ "$type_num" -lt 1 ] || [ "$type_num" -gt "${#COMMIT_TYPES_LIST[@]}" ]; then
    print_error "Invalid selection"
    exit 1
fi

# Get the selected type
SELECTED_TYPE="${type_array[$((type_num-1))]}"

# Select scope (optional)
SELECTED_SCOPE=""
if [ "$QUICK_MODE" = false ]; then
    echo
    print_info "Select scope (optional):"
    echo
    
    i=1
    for scope in "${SCOPES[@]}"; do
        printf "  %2d) %s\n" "$i" "$scope"
        ((i++))
    done
    
    echo
    read -p "Enter number (1-${#SCOPES[@]}) or press Enter to skip: " scope_num
    
    if [[ -n "$scope_num" ]]; then
        if [[ "$scope_num" =~ ^[0-9]+$ ]] && [ "$scope_num" -ge 1 ] && [ "$scope_num" -le "${#SCOPES[@]}" ]; then
            SELECTED_SCOPE="${SCOPES[$((scope_num-1))]}"
            if [ "$SELECTED_SCOPE" = "none" ]; then
                SELECTED_SCOPE=""
            fi
        fi
    fi
fi

# Get commit subject
echo
print_info "Enter commit subject (imperative mood, max 50 chars):"
read -p "> " SUBJECT

# Validate subject
if [ -z "$SUBJECT" ]; then
    print_error "Subject cannot be empty"
    exit 1
fi

if [ ${#SUBJECT} -gt 50 ]; then
    print_warning "Subject is ${#SUBJECT} characters (recommended: ≤50)"
fi

# Get commit body (optional)
BODY=""
if [ "$QUICK_MODE" = false ]; then
    echo
    print_info "Enter commit body (optional, press Ctrl+D when done):"
    echo "> "
    BODY=$(cat)
fi

# Check for breaking changes
BREAKING=""
if [ "$QUICK_MODE" = false ]; then
    echo
    read -p "Is this a breaking change? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Describe the breaking change:"
        read -p "> " BREAKING
    fi
fi

# Build commit message
if [ -n "$SELECTED_SCOPE" ]; then
    COMMIT_MSG="$SELECTED_TYPE($SELECTED_SCOPE): $SUBJECT"
else
    COMMIT_MSG="$SELECTED_TYPE: $SUBJECT"
fi

if [ -n "$BODY" ]; then
    COMMIT_MSG="$COMMIT_MSG

$BODY"
fi

if [ -n "$BREAKING" ]; then
    COMMIT_MSG="$COMMIT_MSG

BREAKING CHANGE: $BREAKING"
fi

# Show preview
echo
print_header "Commit Preview"
echo
echo "$COMMIT_MSG"
echo

# Confirm
read -p "Create this commit? (Y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    if git commit -m "$COMMIT_MSG"; then
        print_success "Commit created successfully!"
        echo
        print_info "Push to remote with: git push"
    else
        print_error "Failed to create commit"
        exit 1
    fi
else
    print_warning "Commit cancelled"
fi