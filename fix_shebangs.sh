#!/usr/bin/env bash
# Fix Shebangs Script
# Automatically fixes shell scripts to use the correct shebang
# This ensures compatibility with modern bash features (Bash 4+)

source "$(dirname "$0")/lib/common.sh"

print_info "Fixing shell script shebangs..."
echo ""

fixed_count=0
checked_count=0

# Store files in an array to avoid subshell issues
mapfile -d '' shell_files < <(find . -name "*.sh" -type f -not -path "./.git/*" -print0)

# Process each file
for file in "${shell_files[@]}"; do
    ((checked_count++))
    
    # Get the first line of the file
    first_line=$(head -1 "$file")
    
    # Check if it has the incorrect shebang
    if [[ "$first_line" == "#!/bin/bash" ]]; then
        print_warning "Fixing: $file"
        
        # Fix the shebang
        if sed -i '' '1s|^#!/bin/bash|#!/usr/bin/env bash|' "$file"; then
            ((fixed_count++))
            print_success "  ✓ Fixed"
        else
            print_error "  ✗ Failed to fix"
        fi
    elif [[ "$first_line" == "#!/usr/bin/env bash" ]]; then
        # Already correct
        :
    elif [[ "$first_line" == "#!/bin/sh" ]]; then
        # POSIX shell script - leave as is
        :
    else
        if [[ -n "$first_line" && "$first_line" =~ ^#! ]]; then
            print_warning "Unknown shebang in $file: $first_line"
        fi
    fi
done

echo ""
print_info "Summary:"
echo "  Files checked: $checked_count"
echo "  Files fixed: $fixed_count"

if [[ $fixed_count -gt 0 ]]; then
    echo ""
    print_success "Fixed $fixed_count files with incorrect shebangs"
    print_info "All scripts now use '#!/usr/bin/env bash' for compatibility"
else
    print_success "All scripts already have correct shebangs"
fi

# Verify bash version
echo ""
print_info "Bash version check:"
echo "  System bash (/bin/bash): $(/bin/bash --version | head -1)"
if [[ -x /opt/homebrew/bin/bash ]]; then
    echo "  Homebrew bash: $(/opt/homebrew/bin/bash --version | head -1)"
elif [[ -x /usr/local/bin/bash ]]; then
    echo "  Homebrew bash: $(/usr/local/bin/bash --version | head -1)"
fi
echo "  Current bash: $(bash --version | head -1)"

# Check for associative array support
echo ""
if bash -c 'declare -A test 2>/dev/null'; then
    print_success "Current bash supports associative arrays"
else
    print_error "Current bash does NOT support associative arrays"
    print_info "Install newer bash with: brew install bash"
fi