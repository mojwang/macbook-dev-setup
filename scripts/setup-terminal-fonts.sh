#!/usr/bin/env bash
#
# setup-terminal-fonts.sh
# Configure consistent fonts across all terminal applications

set -euo pipefail

# Font configuration - detect from Warp if available
if [[ -d "/Applications/Warp.app" ]] && command -v defaults &> /dev/null; then
    FONT_NAME=$(defaults read dev.warp.Warp-Stable FontName 2>/dev/null || echo "AnonymicePro Nerd Font Mono")
    FONT_SIZE=$(defaults read dev.warp.Warp-Stable FontSize 2>/dev/null || echo "13")
    # Remove quotes from font name if present
    FONT_NAME=$(echo "$FONT_NAME" | tr -d '"')
    # Convert float to int for font size
    FONT_SIZE=${FONT_SIZE%.*}
else
    FONT_NAME="AnonymicePro Nerd Font Mono"
    FONT_SIZE="13"
fi

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Helper functions
print_info() {
    echo -e "${BLUE}ℹ ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Configure iTerm2
configure_iterm2() {
    if [[ -d "/Applications/iTerm.app" ]]; then
        print_info "Configuring iTerm2 font..."
        
        # Create iTerm2 preference file if it doesn't exist
        local plist_dir="$HOME/Library/Preferences"
        local plist_file="com.googlecode.iterm2.plist"
        
        # Set font for default profile
        defaults write com.googlecode.iterm2 "New Bookmarks" -array-add "$(
            defaults read com.googlecode.iterm2 "New Bookmarks" | 
            sed "s/Normal Font = \".*\";/Normal Font = \"${FONT_NAME} ${FONT_SIZE}\";/g"
        )" 2>/dev/null || {
            print_warning "Could not update iTerm2 preferences automatically"
            print_info "Please set font manually in iTerm2 > Preferences > Profiles > Text"
        }
        
        print_success "iTerm2 font configuration attempted"
    else
        print_info "iTerm2 not installed, skipping..."
    fi
}

# Configure Terminal.app
configure_terminal_app() {
    if [[ -e "/System/Applications/Utilities/Terminal.app" || -e "/Applications/Utilities/Terminal.app" ]]; then
        print_info "Configuring Terminal.app font..."
        
        # Create a temporary plist with font settings
        local temp_plist="/tmp/terminal_font_config.plist"
        
        cat > "$temp_plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Font</key>
    <data>
    $(echo -n "${FONT_NAME}" | base64)
    </data>
    <key>FontAntialias</key>
    <true/>
    <key>FontWidthSpacing</key>
    <real>1.0</real>
    <key>FontHeightSpacing</key>
    <real>1.0</real>
</dict>
</plist>
EOF
        
        # Apply to Terminal
        osascript <<EOF 2>/dev/null || true
tell application "Terminal"
    set font name of settings set "Basic" to "${FONT_NAME}"
    set font size of settings set "Basic" to ${FONT_SIZE}
end tell
EOF
        
        rm -f "$temp_plist"
        print_success "Terminal.app font configured"
    else
        print_info "Terminal.app not found, skipping..."
    fi
}

# Configure VS Code
configure_vscode() {
    local vscode_settings="$HOME/Library/Application Support/Code/User/settings.json"
    
    if command -v code &> /dev/null; then
        print_info "Configuring VS Code terminal font..."
        
        # Check if settings file exists
        if [[ -f "$vscode_settings" ]]; then
            # Backup existing settings
            cp "$vscode_settings" "$vscode_settings.backup"
            
            # Update or add terminal font settings using jq if available
            if command -v jq &> /dev/null; then
                jq --arg font "$FONT_NAME" --arg size "$FONT_SIZE" \
                    '. + {"terminal.integrated.fontFamily": $font, "terminal.integrated.fontSize": ($size | tonumber)}' \
                    "$vscode_settings" > "$vscode_settings.tmp" && \
                    mv "$vscode_settings.tmp" "$vscode_settings"
                print_success "VS Code terminal font configured"
            else
                print_warning "jq not installed. Please manually set terminal font in VS Code settings:"
                print_info "  terminal.integrated.fontFamily: \"$FONT_NAME\""
                print_info "  terminal.integrated.fontSize: $FONT_SIZE"
            fi
        else
            print_warning "VS Code settings file not found"
            print_info "Creating new settings file with font configuration..."
            mkdir -p "$(dirname "$vscode_settings")"
            cat > "$vscode_settings" << EOF
{
    "terminal.integrated.fontFamily": "${FONT_NAME}",
    "terminal.integrated.fontSize": ${FONT_SIZE}
}
EOF
            print_success "VS Code settings created with terminal font"
        fi
    else
        print_info "VS Code not installed, skipping..."
    fi
}

# Configure Warp (for completeness, though it's already set)
configure_warp() {
    if [[ -d "/Applications/Warp.app" ]]; then
        print_info "Checking Warp font configuration..."
        
        current_font=$(defaults read dev.warp.Warp-Stable FontName 2>/dev/null || echo "")
        if [[ "$current_font" == "$FONT_NAME" ]]; then
            print_success "Warp already using correct font"
        else
            defaults write dev.warp.Warp-Stable FontName "$FONT_NAME"
            defaults write dev.warp.Warp-Stable FontSize -int "$FONT_SIZE"
            print_success "Warp font configured"
        fi
    else
        print_info "Warp not installed, skipping..."
    fi
}

# Main execution
main() {
    echo "🔤 Terminal Font Configuration"
    echo "=============================="
    echo
    print_info "Configuring all terminals to use: $FONT_NAME (size $FONT_SIZE)"
    echo
    
    # Check if font is installed
    # Remove quotes from font name for checking
    FONT_CHECK=$(echo "$FONT_NAME" | tr -d '"')
    if fc-list 2>/dev/null | grep -qi "anonymice" || ls ~/Library/Fonts/*Anonymice* &>/dev/null || brew list | grep -q "font-anonymice-nerd-font"; then
        print_success "Font is installed"
    else
        print_error "Font not found! Please ensure it's installed via Homebrew"
        print_info "Run: brew install font-anonymice-nerd-font"
        exit 1
    fi
    
    # Configure each terminal
    configure_iterm2
    configure_terminal_app
    configure_vscode
    configure_warp
    
    echo
    print_success "Font configuration complete!"
    print_info "You may need to restart your terminal applications for changes to take effect"
}

# Run main function
main "$@"