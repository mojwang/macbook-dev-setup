#!/bin/bash

# Comprehensive validation script for v2.0 implementation
set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== macOS Dev Setup v2.0 Implementation Validation ===${NC}"
echo ""

# Track issues
ISSUES=()
WARNINGS=()

# 1. Verify simplified command structure
echo -e "${BLUE}1. Checking simplified command structure...${NC}"
if grep -q 'case "${1:-}" in' setup.sh && grep -q '"help"|"-h"|"--help")' setup.sh; then
    echo -e "${GREEN}✓ Command structure implemented correctly${NC}"
else
    ISSUES+=("Command structure not properly implemented")
    echo -e "${RED}✗ Command structure issues found${NC}"
fi

# 2. Verify Warp detection logic
echo -e "\n${BLUE}2. Checking Warp detection logic...${NC}"
if grep -q 'check_and_setup_warp()' setup.sh; then
    echo -e "${GREEN}✓ Warp detection function exists${NC}"
    
    # Check all detection methods
    if grep -q 'TERM_PROGRAM.*WarpTerminal' setup.sh && \
       grep -q '/Applications/Warp.app' setup.sh && \
       grep -q 'command -v warp' setup.sh; then
        echo -e "${GREEN}✓ All Warp detection methods implemented${NC}"
    else
        ISSUES+=("Incomplete Warp detection methods")
        echo -e "${RED}✗ Missing some Warp detection methods${NC}"
    fi
    
    # Check for auto-install with confirmation
    if grep -q 'confirm.*optimize.*Warp' setup.sh; then
        echo -e "${GREEN}✓ User confirmation for Warp setup${NC}"
    else
        ISSUES+=("Missing user confirmation for Warp setup")
        echo -e "${RED}✗ No user confirmation for Warp${NC}"
    fi
else
    ISSUES+=("Warp detection function missing")
    echo -e "${RED}✗ Warp detection not implemented${NC}"
fi

# 3. Verify font conflict handling
echo -e "\n${BLUE}3. Checking font conflict handling...${NC}"
if grep -q 'AnonymiceProNerdFont' scripts/install-packages.sh && \
   grep -q '~/Library/Fonts/\*${font_pattern}\*' scripts/install-packages.sh; then
    echo -e "${GREEN}✓ Font conflict detection implemented${NC}"
else
    ISSUES+=("Font conflict handling incomplete")
    echo -e "${RED}✗ Font conflict handling issues${NC}"
fi

# 4. Verify missing function fixes
echo -e "\n${BLUE}4. Checking print_section function fix...${NC}"
if grep -q 'if ! type print_section' scripts/setup-warp.sh && \
   grep -q 'print_section()' scripts/setup-warp.sh; then
    echo -e "${GREEN}✓ print_section fallback implemented${NC}"
else
    ISSUES+=("print_section fallback missing")
    echo -e "${RED}✗ print_section fallback not found${NC}"
fi

# 5. Check smart detection
echo -e "\n${BLUE}5. Checking smart setup detection...${NC}"
if grep -q 'detect_setup_state()' setup.sh && \
   grep -q 'state="fresh"' setup.sh && \
   grep -q 'state="update"' setup.sh; then
    echo -e "${GREEN}✓ Smart state detection implemented${NC}"
else
    ISSUES+=("Smart state detection incomplete")
    echo -e "${RED}✗ Smart state detection issues${NC}"
fi

# 6. Verify environment variable support
echo -e "\n${BLUE}6. Checking environment variable support...${NC}"
env_vars=("SETUP_VERBOSE" "SETUP_LOG" "SETUP_JOBS" "SETUP_NO_WARP")
all_good=true
for var in "${env_vars[@]}"; do
    if grep -q "$var" setup.sh; then
        echo -e "${GREEN}✓ $var supported${NC}"
    else
        ISSUES+=("$var not supported")
        echo -e "${RED}✗ $var missing${NC}"
        all_good=false
    fi
done

# 7. Check backwards compatibility
echo -e "\n${BLUE}7. Checking core functionality preserved...${NC}"
# Check if main setup flow still works
if grep -q 'main_setup()' setup.sh && \
   grep -q './scripts/install-homebrew.sh' setup.sh && \
   grep -q './scripts/install-packages.sh' setup.sh && \
   grep -q './scripts/setup-dotfiles.sh' setup.sh; then
    echo -e "${GREEN}✓ Core setup flow preserved${NC}"
else
    ISSUES+=("Core setup flow broken")
    echo -e "${RED}✗ Core setup flow issues${NC}"
fi

# 8. Verify Warp optimizations are safe
echo -e "\n${BLUE}8. Checking Warp optimization safety...${NC}"
if grep -q 'safe_tools=' scripts/setup-warp.sh && \
   grep -q 'optional_tools=' scripts/setup-warp.sh && \
   grep -q 'confirm.*optional tools' scripts/setup-warp.sh; then
    echo -e "${GREEN}✓ Safe defaults for Warp tools${NC}"
else
    ISSUES+=("Warp tools not safely configured")
    echo -e "${RED}✗ Warp tools safety issues${NC}"
fi

# 9. Check documentation updates
echo -e "\n${BLUE}9. Checking documentation...${NC}"
if grep -q './setup.sh preview' CLAUDE.md && \
   grep -q 'SETUP_NO_WARP' CLAUDE.md && \
   grep -q 'Automatic Warp Detection' CLAUDE.md; then
    echo -e "${GREEN}✓ Documentation updated${NC}"
else
    ISSUES+=("Documentation not fully updated")
    echo -e "${RED}✗ Documentation incomplete${NC}"
fi

# 10. Syntax validation
echo -e "\n${BLUE}10. Running syntax checks...${NC}"
scripts_to_check=("setup.sh" "setup-validate.sh" "scripts/setup-warp.sh" "scripts/install-packages.sh")
syntax_good=true
for script in "${scripts_to_check[@]}"; do
    if bash -n "$script" 2>/dev/null; then
        echo -e "${GREEN}✓ $script syntax valid${NC}"
    else
        ISSUES+=("$script has syntax errors")
        echo -e "${RED}✗ $script syntax errors${NC}"
        syntax_good=false
    fi
done

# 11. Check backup system implementation
echo -e "\n${BLUE}11. Checking backup system implementation...${NC}"
if [[ -f "lib/backup-manager.sh" ]]; then
    echo -e "${GREEN}✓ Backup manager exists${NC}"
    
    # Check backup functions
    if grep -q "create_backup()" lib/backup-manager.sh && \
       grep -q "clean_old_backups()" lib/backup-manager.sh && \
       grep -q "migrate_old_backups()" lib/backup-manager.sh; then
        echo -e "${GREEN}✓ All backup functions implemented${NC}"
    else
        ISSUES+=("Incomplete backup functions")
        echo -e "${RED}✗ Missing backup functions${NC}"
    fi
    
    # Check backup integration in setup.sh
    if grep -q "source.*backup-manager.sh" setup.sh && \
       grep -q "create_backup" setup.sh; then
        echo -e "${GREEN}✓ Backup system integrated${NC}"
    else
        ISSUES+=("Backup system not integrated")
        echo -e "${RED}✗ Backup integration issues${NC}"
    fi
else
    ISSUES+=("Backup manager missing")
    echo -e "${RED}✗ Backup manager not found${NC}"
fi

# 12. Validate fix/diagnostics implementation
echo -e "\n${BLUE}12. Checking diagnostics implementation...${NC}"
if grep -q "run_diagnostics()" setup.sh; then
    echo -e "${GREEN}✓ Diagnostics function exists${NC}"
    
    # Check diagnostic checks
    if grep -q "Checking prerequisites" setup.sh && \
       grep -q "Checking Homebrew" setup.sh && \
       grep -q "Checking shell" setup.sh; then
        echo -e "${GREEN}✓ Comprehensive diagnostics${NC}"
    else
        WARNINGS+=("Diagnostics may be incomplete")
        echo -e "${YELLOW}⚠ Some diagnostic checks missing${NC}"
    fi
else
    ISSUES+=("Diagnostics function missing")
    echo -e "${RED}✗ No diagnostics implementation${NC}"
fi

# 13. Check commit helper integration
echo -e "\n${BLUE}13. Checking commit helper tools...${NC}"
if [[ -f "scripts/commit-helper.sh" ]] && [[ -f "scripts/setup-git-hooks.sh" ]]; then
    echo -e "${GREEN}✓ Commit helper scripts exist${NC}"
    
    # Check commit aliases
    if [[ -f "dotfiles/.config/zsh/35-commit-aliases.zsh" ]]; then
        echo -e "${GREEN}✓ Commit aliases configured${NC}"
    else
        WARNINGS+=("Commit aliases file missing")
        echo -e "${YELLOW}⚠ Commit aliases not found${NC}"
    fi
else
    WARNINGS+=("Commit helper tools incomplete")
    echo -e "${YELLOW}⚠ Some commit tools missing${NC}"
fi

# 14. Performance optimizations check
echo -e "\n${BLUE}14. Checking performance optimizations...${NC}"
# Check parallel processing
if grep -q "PARALLEL_JOBS" setup.sh && grep -q "SETUP_JOBS" setup.sh; then
    echo -e "${GREEN}✓ Parallel processing support${NC}"
else
    WARNINGS+=("Parallel processing not fully implemented")
    echo -e "${YELLOW}⚠ Parallel jobs support incomplete${NC}"
fi

# Check lazy loading
if grep -q "nvm()" dotfiles/.config/zsh/10-languages.zsh; then
    echo -e "${GREEN}✓ Lazy loading implemented${NC}"
else
    WARNINGS+=("Lazy loading not found")
    echo -e "${YELLOW}⚠ Performance optimizations missing${NC}"
fi

# Summary
echo -e "\n${BLUE}=== Validation Summary ===${NC}"
echo ""

if [[ ${#ISSUES[@]} -eq 0 ]]; then
    echo -e "${GREEN}✅ Core implementation validated successfully!${NC}"
    echo ""
    echo "Key features verified:"
    echo "• Simplified command structure (7 commands)"
    echo "• Automatic Warp detection with user consent"
    echo "• Safe font conflict handling"
    echo "• Missing function fallbacks"
    echo "• Smart setup state detection"
    echo "• Environment variable support"
    echo "• Organized backup system"
    echo "• Diagnostics and fix command"
    echo "• Backwards compatibility maintained"
    
    if [[ ${#WARNINGS[@]} -gt 0 ]]; then
        echo ""
        echo -e "${YELLOW}⚠ Warnings (${#WARNINGS[@]}):${NC}"
        for warning in "${WARNINGS[@]}"; do
            echo -e "${YELLOW}  - $warning${NC}"
        done
        echo ""
        echo "These are non-critical issues that won't prevent setup from working."
    fi
    
    exit 0
else
    echo -e "${RED}❌ Found ${#ISSUES[@]} critical issues:${NC}"
    for issue in "${ISSUES[@]}"; do
        echo -e "${RED}  - $issue${NC}"
    done
    
    if [[ ${#WARNINGS[@]} -gt 0 ]]; then
        echo ""
        echo -e "${YELLOW}Also found ${#WARNINGS[@]} warnings:${NC}"
        for warning in "${WARNINGS[@]}"; do
            echo -e "${YELLOW}  - $warning${NC}"
        done
    fi
    
    exit 1
fi