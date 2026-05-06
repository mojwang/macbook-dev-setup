#!/usr/bin/env bash

# Install packages from Brewfile with error handling
set -e

# Detect whether this script is being sourced (for testing) or executed.
# When sourced, the main install flow at the bottom is skipped — only
# function/constant definitions are exposed to the sourcing shell.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    _INSTALL_PACKAGES_SOURCED=false
else
    _INSTALL_PACKAGES_SOURCED=true
fi

# Source signal-safe temp-file helpers (safe_mktemp_dir + setup_cleanup).
# Provides automatic temp-resource cleanup on EXIT/INT/TERM/HUP/QUIT.
_SIGNAL_SAFETY_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/signal-safety.sh"
if [[ -f "$_SIGNAL_SAFETY_LIB" ]]; then
    # shellcheck source=../lib/signal-safety.sh
    source "$_SIGNAL_SAFETY_LIB"
fi

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

# Install a single formula, logging result to a temp dir.
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

# Install a single cask, logging result to a temp dir.
# Defined at top level (issue #3) — was originally nested inside
# install_packages() and `export -f`d there. If `set -e` aborted before the
# nested definition was reached, the function would never export and all
# parallel cask installs would silently fail with "command not found".
# Usage: _install_one_cask <cask> <results_dir>
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

# Diagnostic: when a formula install fails, check whether the package is
# actually a cask. If yes, emit a hint that the Brewfile may have it under
# the wrong category. Restored from commit 03c80dc (was dropped during the
# parallel rewrite — issue #2).
_warn_if_formula_is_cask() {
    local pkg="$1"
    if brew info --cask "$pkg" &>/dev/null; then
        print_warning "  ↳ '$pkg' appears to be a cask. Consider updating Brewfile: cask \"$pkg\""
    fi
}

# Export colors for subshells
export GREEN YELLOW RED NC

# Shared deps that show up as transitive dependencies of many parallel
# packages. Installing these serially up-front prevents N parallel workers
# from racing to install the same dep concurrently. Cheap (~20 sec) and
# usually a net speedup because workers don't queue on shared-dep locks.
# Mitigation #2 from the parallel-install hardening pass.
SHARED_DEPS=(openssl@3 readline gmp libffi pkg-config)

# Pre-install shared deps serially. Skip ones already installed.
# Usage: _preinstall_shared_deps
_preinstall_shared_deps() {
    local dep
    local installed=0 skipped=0
    for dep in "${SHARED_DEPS[@]}"; do
        if brew list --formula "$dep" &>/dev/null; then
            : $((skipped++))
            continue
        fi
        if HOMEBREW_NO_AUTO_UPDATE=1 brew install "$dep" &>/dev/null; then
            echo -e "  ${GREEN}✓${NC} shared dep: $dep"
            : $((installed++))
        else
            print_warning "  ↳ shared dep $dep failed; parallel installs may queue on this dep"
        fi
    done
    if [[ $installed -gt 0 ]] || [[ $skipped -gt 0 ]]; then
        echo "Shared deps: $installed installed, $skipped already present"
    fi
}

# Pre-flight all taps from a Brewfile serially. Two parallel `brew tap`
# operations on the same tap can race and leave state inconsistent.
# Mitigation #1 — extracted from install_packages() so it can be tested
# independently and called from any entry point.
# Usage: _preflight_taps <brewfile_path>
_preflight_taps() {
    local brewfile="$1"
    local line tap
    while IFS= read -r line; do
        if [[ "$line" =~ ^tap[[:space:]]+\"(.+)\" ]]; then
            tap="${BASH_REMATCH[1]}"
            echo "Tapping $tap..."
            if ! brew tap "$tap" 2>/dev/null; then
                print_warning "Failed to tap $tap"
            fi
        fi
    done < "$brewfile"
}

# Function to check if a font cask is already installed
is_font_installed() {
    local font_name="$1"
    brew list --cask 2>/dev/null | grep -q "^${font_name}$"
}

# Parse and install packages with better error handling
install_packages() {
    local failed_packages=()
    local skipped_fonts=()
    
    # Pre-flight all taps serially BEFORE any parallel work (mitigation #1)
    _preflight_taps "$BREWFILE"

    # Pre-install shared dependencies serially BEFORE parallel formula install
    # (mitigation #2). Prevents N parallel workers from racing on common deps.
    _preinstall_shared_deps

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
        # Use safe_mktemp_dir so signal-safe cleanup removes this on
        # EXIT/INT/TERM (issue #4). Falls back to plain mktemp -d if the
        # signal-safety lib couldn't be sourced.
        if declare -F safe_mktemp_dir >/dev/null; then
            results_dir=$(safe_mktemp_dir "install-packages-formulae.XXXXXX")
        else
            results_dir=$(mktemp -d)
        fi
        touch "$results_dir/installed.txt" "$results_dir/failed.txt"

        # Safe pattern: -n1 (one input per invocation, no -I{} text-substitution
        # which would word-split package names containing spaces or shell
        # metacharacters). `|| true` swallows xargs's non-zero exit when any
        # parallel install fails — failure tracking happens via the temp-file
        # results below, not via xargs's exit code. Without `|| true`, set -e
        # would abort the script before failure collection runs.
        printf '%s\n' "${formulae_to_install[@]}" | \
            xargs -P "$PARALLEL_FORMULAE" -n1 \
                bash -c '_install_one_formula "$2" "$1"' _ "$results_dir" \
            || true

        # Collect failures from temp-file results (authoritative — not xargs exit).
        # For each failure, run the formula-as-cask diagnostic (issue #2): some
        # Brewfile entries land under `brew "X"` when they should be `cask "X"`.
        while IFS= read -r pkg; do
            if [[ -n "$pkg" ]]; then
                failed_packages+=("brew \"$pkg\"")
                _warn_if_formula_is_cask "$pkg"
            fi
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
        # Use signal-safe temp dir creation (issue #4). _install_one_cask is
        # defined at top level (issue #3) so we don't redefine it here.
        if declare -F safe_mktemp_dir >/dev/null; then
            cask_results_dir=$(safe_mktemp_dir "install-packages-casks.XXXXXX")
        else
            cask_results_dir=$(mktemp -d)
        fi
        touch "$cask_results_dir/installed.txt" "$cask_results_dir/failed.txt"

        # Safe pattern + failure-tolerant exit (see formula install above for rationale)
        printf '%s\n' "${casks_to_install[@]}" | \
            xargs -P "$PARALLEL_CASKS" -n1 \
                bash -c '_install_one_cask "$2" "$1"' _ "$cask_results_dir" \
            || true

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

# Main install flow — skipped when sourced (e.g., from tests)
if [[ "$_INSTALL_PACKAGES_SOURCED" == "false" ]]; then
    # Homebrew presence check (only when actually running)
    if ! command -v brew &> /dev/null; then
        print_error "Homebrew is not installed. Please run install-homebrew.sh first."
        exit 1
    fi

    # Brewfile presence check (only when actually running)
    BREWFILE="${BREWFILE:-homebrew/Brewfile}"
    if [[ ! -f "$BREWFILE" ]]; then
        print_error "Brewfile not found at $BREWFILE"
        exit 1
    fi

    # Register signal-safe cleanup so temp dirs are removed on interrupt (issue #4)
    if declare -F setup_cleanup >/dev/null; then
        setup_cleanup default_cleanup
    fi

    echo "Installing packages from Brewfile..."

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
fi
