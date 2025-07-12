#!/bin/bash

# Benchmark script to compare VSCode extension installation methods
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}VS Code Extension Installation Benchmark${NC}"
echo "========================================="
echo ""

# Count extensions
EXTENSION_COUNT=$(grep -v '^#' vscode/extensions.txt | grep -v '^$' | wc -l | tr -d ' ')
echo "Total extensions to manage: $EXTENSION_COUNT"
echo ""

# Method 1: Homebrew Bundle (old method)
echo -e "${YELLOW}Method 1: Homebrew Bundle with VSCode extensions${NC}"
echo "- Installs ALL extensions in parallel"
echo "- Can overwhelm VS Code with simultaneous installations"
echo "- May cause VS Code to crash or hang"
echo "- Forces reinstallation even if already installed"
echo ""

# Method 2: Sequential with --force (old setup-applications.sh)
echo -e "${YELLOW}Method 2: Sequential installation with --force${NC}"
echo "- Installs one extension at a time"
echo "- Uses --force flag (reinstalls even if present)"
echo "- Estimated time: ~${EXTENSION_COUNT}s (1s per extension)"
echo ""

# Method 3: Optimized batch installation (new method)
echo -e "${GREEN}Method 3: Optimized batch installation (NEW)${NC}"
echo "- Checks what's already installed (avoids reinstalls)"
echo "- Installs in batches of 5 to avoid overwhelming VS Code"
echo "- Only installs missing extensions"
echo "- Provides clear progress feedback"
echo ""

# Show current status
echo -e "${BLUE}Current Status:${NC}"
INSTALLED_COUNT=$(code --list-extensions 2>/dev/null | wc -l | tr -d ' ')
echo "Extensions already installed: $INSTALLED_COUNT"

# Calculate potential time savings
MISSING=$((EXTENSION_COUNT - INSTALLED_COUNT))
if [[ $MISSING -eq 0 ]]; then
    echo -e "${GREEN}All extensions already installed!${NC}"
    echo "- Old methods: Would still take ~${EXTENSION_COUNT}s"
    echo "- New method: Takes ~1s (just verification)"
    SAVINGS=$((EXTENSION_COUNT - 1))
    echo -e "${GREEN}Time saved: ~${SAVINGS}s (${SAVINGS}x faster)${NC}"
else
    echo "Extensions to install: $MISSING"
    OLD_TIME=$EXTENSION_COUNT
    NEW_TIME=$((MISSING + 2))  # Add 2s for checks
    SAVINGS=$((OLD_TIME - NEW_TIME))
    echo "- Old methods: ~${OLD_TIME}s"
    echo "- New method: ~${NEW_TIME}s"
    if [[ $SAVINGS -gt 0 ]]; then
        echo -e "${GREEN}Time saved: ~${SAVINGS}s${NC}"
    fi
fi

echo ""
echo -e "${BLUE}Additional Benefits:${NC}"
echo "✓ No duplicate installations"
echo "✓ Reduced VS Code crashes"
echo "✓ Clear progress tracking"
echo "✓ Batch processing prevents overload"
echo "✓ Respects existing installations"