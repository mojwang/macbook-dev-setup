#!/usr/bin/env bash

# Install packages from Brewfile with error handling
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Parallel installation settings
PARALLEL_FORMULAE="${SETUP_PARALLEL_FORMULAE:-4}"
PARALLEL_CASKS="${SETUP_PARALLEL_CASKS:-2}"

# Install a single formula, logging result to a temp dir
# Usage: _install_one_formula <formula> <results_dir>
_install_one_formula() {
    local formula="$1"
    local results_dir="$2"

    if HOMEBREW_NO_AUTO_UPDATE=1 brew install "$formula" &>/dev/null; then
        echo "$formula" >> "$results_dir/installed.txt"
        echo -e "${GREEN}✅ $formula${NC}"
    else
        echo "$formula" >> "$results_dir/failed.txt"
        echo -e "${YELLOW}⚠️  Failed: $formula${NC}"
    fi
}
export -f _install_one_formula
# Export colors for subshells
export GREEN YELLOW RED NC

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    print_error "Homebrew is not installed. Please run install-homebrew.sh first."
    exit 1
fi

# Check if Brewfile exists
BREWFILE="${BREWFILE:-homebrew/Brewfile}"
if [[ ! -f "$BREWFILE" ]]; then
    print_error "Brewfile not found at $BREWFILE"
    exit 1
fi

echo "Installing packages from Brewfile..."

# Function to check if a font cask is already installed
is_font_installed() {
    local font_name="$1"
    brew list --cask 2>/dev/null | grep -q "^${font_name}$"
}

# Parse and install packages with better error handling
install_packages() {
    local failed_packages=()
    local skipped_fonts=()
    
    # Process taps first
    while IFS= read -r line; do
        if [[ "$line" =~ ^tap[[:space:]]+"(.+)" ]]; then
            local tap="${BASH_REMATCH[1]}"
            echo "Tapping $tap..."
            if ! brew tap "$tap" 2>/dev/null; then
                print_warning "Failed to tap $tap"
            fi
        fi
    done < "$BREWFILE"
    
    # Process formulae — collect what needs installing, then install in parallel
    local formulae_to_install=()
    while IFS= read -r line; do
        if [[ "$line" =~ ^brew[[:space:]]+"(.+)" ]]; then
            local formula="${BASH_REMATCH[1]}"
            if brew list --formula "$formula" &>/dev/null; then
                echo "Formula $formula already installed, skipping..."
            else
                formulae_to_install+=("$formula")
            fi
        fi
    done < "$BREWFILE"

    if [[ ${#formulae_to_install[@]} -gt 0 ]]; then
        echo "Installing ${#formulae_to_install[@]} formulae (${PARALLEL_FORMULAE} parallel)..."
        local results_dir
        results_dir=$(mktemp -d)
        touch "$results_dir/installed.txt" "$results_dir/failed.txt"

        printf '%s\n' "${formulae_to_install[@]}" | \
            xargs -P "$PARALLEL_FORMULAE" -I{} bash -c '_install_one_formula "$@"' _ {} "$results_dir"

        # Collect failures
        while IFS= read -r pkg; do
            [[ -n "$pkg" ]] && failed_packages+=("brew \"$pkg\"")
        done < "$results_dir/failed.txt"

        local installed_count
        installed_count=$(wc -l < "$results_dir/installed.txt" | tr -d ' ')
        echo "Installed $installed_count formulae"
        rm -rf "$results_dir"
    fi
    
    # Process casks — collect what needs installing, then install in parallel
    local casks_to_install=()
    while IFS= read -r line; do
        if [[ "$line" =~ ^cask[[:space:]]+"(.+)" ]]; then
            local cask="${BASH_REMATCH[1]}"
            # Special handling for fonts
            if [[ "$cask" =~ ^font- ]]; then
                if is_font_installed "$cask"; then
                    echo "Font $cask already installed, skipping..."
                    skipped_fonts+=("$cask")
                    continue
                fi

                local font_pattern=""
                case "$cask" in
                    "font-anonymice-nerd-font")
                        font_pattern="AnonymiceProNerdFont"
                        ;;
                    "font-symbols-only-nerd-font")
                        font_pattern="SymbolsNerdFont"
                        ;;
                esac

                if [[ -n "$font_pattern" ]] && ls ~/Library/Fonts/*${font_pattern}* &>/dev/null 2>&1; then
                    print_warning "Font files for $cask already exist in ~/Library/Fonts/"
                    skipped_fonts+=("$cask (existing files)")
                    continue
                fi
            elif brew list --cask "$cask" &>/dev/null; then
                echo "Cask $cask already installed, skipping..."
                continue
            fi
            casks_to_install+=("$cask")
        fi
    done < "$BREWFILE"

    if [[ ${#casks_to_install[@]} -gt 0 ]]; then
        echo "Installing ${#casks_to_install[@]} casks (${PARALLEL_CASKS} parallel)..."
        local cask_results_dir
        cask_results_dir=$(mktemp -d)
        touch "$cask_results_dir/installed.txt" "$cask_results_dir/failed.txt"

        # Helper for cask installation
        _install_one_cask() {
            local cask="$1"
            local results_dir="$2"
            if HOMEBREW_NO_AUTO_UPDATE=1 brew install --cask "$cask" &>/dev/null; then
                echo "$cask" >> "$results_dir/installed.txt"
                echo -e "${GREEN}✅ $cask${NC}"
            else
                echo "$cask" >> "$results_dir/failed.txt"
                echo -e "${YELLOW}⚠️  Failed: $cask${NC}"
            fi
        }
        export -f _install_one_cask

        printf '%s\n' "${casks_to_install[@]}" | \
            xargs -P "$PARALLEL_CASKS" -I{} bash -c '_install_one_cask "$@"' _ {} "$cask_results_dir"

        while IFS= read -r pkg; do
            [[ -n "$pkg" ]] && failed_packages+=("cask \"$pkg\"")
        done < "$cask_results_dir/failed.txt"

        local cask_installed_count
        cask_installed_count=$(wc -l < "$cask_results_dir/installed.txt" | tr -d ' ')
        echo "Installed $cask_installed_count casks"
        rm -rf "$cask_results_dir"
    fi
    
    # Report results
    if [[ ${#skipped_fonts[@]} -gt 0 ]]; then
        print_success "Skipped ${#skipped_fonts[@]} already installed fonts: ${skipped_fonts[*]}"
    fi
    
    if [[ ${#failed_packages[@]} -gt 0 ]]; then
        print_error "Failed to install ${#failed_packages[@]} packages:"
        for pkg in "${failed_packages[@]}"; do
            echo "  - $pkg"
        done
        return 1
    else
        print_success "All packages installed successfully"
        return 0
    fi
}

# Run installation with fallback to brew bundle if custom installation fails
if ! install_packages; then
    print_warning "Custom installation encountered errors. Trying brew bundle as fallback..."
    if ! HOMEBREW_NO_AUTO_UPDATE=1 brew bundle --file="$BREWFILE"; then
        print_error "Some packages failed to install. Check the output above for details."
        exit 1
    fi
fi

# Install local overrides if present (machine-specific packages)
if [[ -f "homebrew/Brewfile.local" ]]; then
    print_success "Installing local packages from Brewfile.local..."
    HOMEBREW_NO_AUTO_UPDATE=1 brew bundle --file="homebrew/Brewfile.local" || \
        print_warning "Some local packages failed to install"
fi

# Update all packages
echo "Updating Homebrew and installed packages..."
if ! brew update; then
    print_warning "Failed to update Homebrew package list"
fi

if ! brew upgrade; then
    print_warning "Failed to upgrade some packages"
fi

# Cleanup
echo "Cleaning up old package versions..."
if ! brew cleanup; then
    print_warning "Cleanup failed, but packages are installed"
fi

print_success "Package installation and cleanup completed"
