#!/usr/bin/env bash

# Setup Help - Learn about installed tools, aliases, and features
# This script provides comprehensive information about the development environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Help categories - using simple arrays for compatibility
CATEGORIES=("tools" "aliases" "functions" "features" "all")
DESCRIPTIONS=(
    "Installed command-line tools and applications"
    "Shell aliases and shortcuts"
    "Custom shell functions"
    "Special features and enhancements"
    "Show everything"
)

# Function to display header
display_header() {
    echo -e "\n${BOLD}${BLUE}MacBook Dev Setup - Help System${NC}"
    echo -e "${CYAN}Learn about your development environment${NC}\n"
}

# Function to display tool information
show_tools() {
    echo -e "${BOLD}${GREEN}📦 Installed Tools${NC}\n"
    
    echo -e "${YELLOW}Modern CLI Replacements:${NC}"
    echo -e "  ${CYAN}bat${NC}      - Enhanced 'cat' with syntax highlighting"
    echo -e "  ${CYAN}eza${NC}      - Modern 'ls' replacement with icons and git info"
    echo -e "  ${CYAN}fd${NC}       - Fast and user-friendly 'find' alternative"
    echo -e "  ${CYAN}fzf${NC}      - Fuzzy finder for files, history, and more"
    echo -e "  ${CYAN}ripgrep${NC}  - Lightning-fast 'grep' alternative (rg)"
    echo -e "  ${CYAN}zoxide${NC}   - Smarter 'cd' that learns your habits (z)"
    echo -e "  ${CYAN}delta${NC}    - Beautiful git diff viewer"
    echo -e "  ${CYAN}jq${NC}       - JSON processor and pretty-printer"
    echo -e "  ${CYAN}tldr${NC}     - Simplified man pages with examples"
    echo ""
    
    echo -e "${YELLOW}Development Tools:${NC}"
    echo -e "  ${CYAN}git${NC}      - Version control with enhanced diff-so-fancy"
    echo -e "  ${CYAN}gh${NC}       - GitHub CLI for PRs, issues, and more"
    echo -e "  ${CYAN}neovim${NC}   - Modern vim with LSP support"
    echo -e "  ${CYAN}tmux${NC}     - Terminal multiplexer"
    echo -e "  ${CYAN}httpie${NC}   - User-friendly HTTP client"
    echo -e "  ${CYAN}watchman${NC} - File watching service"
    echo ""
    
    echo -e "${YELLOW}Languages & Package Managers:${NC}"
    echo -e "  ${CYAN}nvm${NC}      - Node Version Manager"
    echo -e "  ${CYAN}pyenv${NC}    - Python Version Manager"
    echo -e "  ${CYAN}rbenv${NC}    - Ruby Version Manager"
    echo -e "  ${CYAN}pnpm${NC}     - Fast, disk-efficient npm alternative"
    echo -e "  ${CYAN}uv${NC}       - Modern Python package manager"
    echo -e "  ${CYAN}cargo${NC}    - Rust package manager"
    echo ""
    
    echo -e "${YELLOW}System Monitoring:${NC}"
    echo -e "  ${CYAN}htop${NC}     - Interactive process viewer"
    echo -e "  ${CYAN}btop${NC}     - Beautiful resource monitor"
    echo -e "  ${CYAN}ncdu${NC}     - Disk usage analyzer with ncurses"
    echo -e "  ${CYAN}duf${NC}      - Modern df alternative"
    echo -e "  ${CYAN}gping${NC}    - Ping with graph"
    echo ""
    
    echo -e "${YELLOW}Container & Cloud Tools:${NC}"
    echo -e "  ${CYAN}docker${NC}   - Container runtime"
    echo -e "  ${CYAN}kubectl${NC}  - Kubernetes CLI"
    echo -e "  ${CYAN}terraform${NC} - Infrastructure as Code"
    echo -e "  ${CYAN}aws${NC}      - AWS CLI"
    echo ""
}

# Function to display aliases
show_aliases() {
    echo -e "${BOLD}${GREEN}⚡ Shell Aliases${NC}\n"
    
    echo -e "${YELLOW}Git Shortcuts:${NC}"
    echo -e "  ${CYAN}gs${NC}       - git status"
    echo -e "  ${CYAN}ga${NC}       - git add"
    echo -e "  ${CYAN}gc${NC}       - git commit"
    echo -e "  ${CYAN}gp${NC}       - git push"
    echo -e "  ${CYAN}gl${NC}       - git log --oneline --graph"
    echo -e "  ${CYAN}gd${NC}       - git diff (with delta)"
    echo -e "  ${CYAN}gb${NC}       - git branch"
    echo -e "  ${CYAN}gco${NC}      - git checkout"
    echo -e "  ${CYAN}gpl${NC}      - git pull"
    echo ""
    
    echo -e "${YELLOW}Conventional Commits:${NC}"
    echo -e "  ${CYAN}gci${NC}      - Interactive commit helper"
    echo -e "  ${CYAN}gcft${NC}     - Quick feat commit"
    echo -e "  ${CYAN}gcfx${NC}     - Quick fix commit"
    echo -e "  ${CYAN}gcd${NC}      - Quick docs commit"
    echo -e "  ${CYAN}gcfs${NC}     - Scoped feat commit (usage: gcfs scope \"message\")"
    echo -e "  ${CYAN}commit-help${NC} - Show commit format guide"
    echo ""
    
    echo -e "${YELLOW}Enhanced Commands:${NC}"
    echo -e "  ${CYAN}ls${NC}       - eza with colors and icons"
    echo -e "  ${CYAN}ll${NC}       - eza long format with git info"
    echo -e "  ${CYAN}la${NC}       - eza all files including hidden"
    echo -e "  ${CYAN}tree${NC}     - eza tree view"
    echo -e "  ${CYAN}cat${NC}      - bat with syntax highlighting"
    echo ""
    
    echo -e "${YELLOW}Docker Shortcuts:${NC}"
    echo -e "  ${CYAN}d${NC}        - docker"
    echo -e "  ${CYAN}dc${NC}       - docker-compose"
    echo -e "  ${CYAN}dps${NC}      - docker ps"
    echo -e "  ${CYAN}dpsa${NC}     - docker ps -a"
    echo -e "  ${CYAN}di${NC}       - docker images"
    echo ""
    
    echo -e "${YELLOW}System Shortcuts:${NC}"
    echo -e "  ${CYAN}reload${NC}   - Reload shell configuration"
    echo -e "  ${CYAN}ip${NC}       - Show IP addresses"
    echo -e "  ${CYAN}showfiles${NC} - Show hidden files in Finder"
    echo -e "  ${CYAN}hidefiles${NC} - Hide hidden files in Finder"
    echo ""
}

# Function to display custom functions
show_functions() {
    echo -e "${BOLD}${GREEN}🔧 Custom Functions${NC}\n"
    
    echo -e "${YELLOW}Productivity:${NC}"
    echo -e "  ${CYAN}mkcd <dir>${NC}     - Create directory and cd into it"
    echo -e "  ${CYAN}extract <file>${NC} - Extract any archive type"
    echo -e "  ${CYAN}backup <file>${NC}  - Create timestamped backup"
    echo -e "  ${CYAN}tmpd${NC}           - Create temp directory and cd into it"
    echo ""
    
    echo -e "${YELLOW}Development:${NC}"
    echo -e "  ${CYAN}devinfo${NC}        - Show development environment info"
    echo -e "  ${CYAN}psgrep <name>${NC}  - Find process by name"
    echo -e "  ${CYAN}path${NC}           - Display PATH in readable format"
    echo -e "  ${CYAN}calc <expr>${NC}    - Quick calculator"
    echo ""
    
    echo -e "${YELLOW}Utilities:${NC}"
    echo -e "  ${CYAN}weather [loc]${NC}  - Get weather forecast"
    echo -e "  ${CYAN}preexec${NC}        - Shows expanded aliases before execution"
    echo ""
}

# Function to display special features
show_features() {
    echo -e "${BOLD}${GREEN}✨ Special Features${NC}\n"
    
    echo -e "${YELLOW}Shell Enhancements:${NC}"
    echo -e "  • Zsh autosuggestions - Fish-like command suggestions"
    echo -e "  • Syntax highlighting - Real-time command validation"
    echo -e "  • Smart tab completion - Context-aware suggestions"
    echo -e "  • History substring search - Find commands by partial match"
    echo ""
    
    echo -e "${YELLOW}Git Enhancements:${NC}"
    echo -e "  • diff-so-fancy - Beautiful git diffs"
    echo -e "  • Conventional commits - Standardized commit messages"
    echo -e "  • Git hooks - Automated commit validation"
    echo -e "  • Interactive rebase - Visual commit editing"
    echo ""
    
    echo -e "${YELLOW}Terminal Features:${NC}"
    echo -e "  • Warp optimization - Enhanced terminal experience"
    echo -e "  • Adaptive colors - Environment-aware theming"
    echo -e "  • Unicode support - Emoji and special characters"
    echo -e "  • Custom prompt - Git status and context info"
    echo ""
    
    echo -e "${YELLOW}Safety & Backup:${NC}"
    echo -e "  • Automatic backups - Before any file changes"
    echo -e "  • Organized backup system - ~/.setup-backups/"
    echo -e "  • Dry-run mode - Preview changes before applying"
    echo -e "  • Recovery options - Restore from backups"
    echo ""
}

# Function to search for specific tool/command
search_command() {
    local query="$1"
    echo -e "${BOLD}${GREEN}🔍 Searching for: ${CYAN}$query${NC}\n"
    
    # Search in aliases
    if alias | grep -qi "$query"; then
        echo -e "${YELLOW}Found in aliases:${NC}"
        alias | grep -i "$query" | sed 's/^/  /'
        echo ""
    fi
    
    # Search in functions
    if declare -f | grep -qi "$query"; then
        echo -e "${YELLOW}Found in functions:${NC}"
        declare -f | grep -i "^$query" | sed 's/^/  /'
        echo ""
    fi
    
    # Search in PATH
    if command -v "$query" &> /dev/null; then
        echo -e "${YELLOW}Found in PATH:${NC}"
        echo -e "  ${CYAN}$query${NC} -> $(command -v "$query")"
        
        # Show brief description if available
        if command -v tldr &> /dev/null; then
            echo -e "\n${YELLOW}Quick info (via tldr):${NC}"
            tldr "$query" 2>/dev/null | head -10 || echo "  No tldr page available"
        fi
        echo ""
    fi
    
    # Search in Brewfile - use ROOT_DIR from common.sh
    local brewfile_path="${ROOT_DIR:-$(dirname "$0")/..}/homebrew/Brewfile"
    if [[ -f "$brewfile_path" ]] && grep -qi "$query" "$brewfile_path" 2>/dev/null; then
        echo -e "${YELLOW}Found in Brewfile:${NC}"
        grep -i "$query" "$brewfile_path" | sed 's/^/  /'
        echo ""
    fi
}

# Function to show examples
show_examples() {
    echo -e "${BOLD}${GREEN}💡 Usage Examples${NC}\n"
    
    echo -e "${YELLOW}Finding files:${NC}"
    echo -e "  ${CYAN}fd pattern${NC}              # Find files by name"
    echo -e "  ${CYAN}fd -e js${NC}                # Find JavaScript files"
    echo -e "  ${CYAN}fd pattern -x command${NC}   # Execute command on results"
    echo ""
    
    echo -e "${YELLOW}Searching in files:${NC}"
    echo -e "  ${CYAN}rg pattern${NC}              # Search for pattern"
    echo -e "  ${CYAN}rg -i pattern${NC}           # Case-insensitive search"
    echo -e "  ${CYAN}rg pattern -A 2 -B 2${NC}    # Show context lines"
    echo ""
    
    echo -e "${YELLOW}Interactive selection:${NC}"
    echo -e "  ${CYAN}ctrl+r${NC}                  # Fuzzy search command history"
    echo -e "  ${CYAN}cd **<tab>${NC}              # Fuzzy directory navigation"
    echo -e "  ${CYAN}vim \$(fzf)${NC}              # Open file with fuzzy finder"
    echo ""
    
    echo -e "${YELLOW}Git workflows:${NC}"
    echo -e "  ${CYAN}gci${NC}                     # Interactive commit"
    echo -e "  ${CYAN}gcft \"Add new feature\"${NC}  # Quick feat commit"
    echo -e "  ${CYAN}gs | fzf${NC}                # Fuzzy select from git status"
    echo ""
}

# Main function
main() {
    case "$1" in
        tools)
            display_header
            show_tools
            ;;
        aliases)
            display_header
            show_aliases
            ;;
        functions)
            display_header
            show_functions
            ;;
        features)
            display_header
            show_features
            ;;
        examples)
            display_header
            show_examples
            ;;
        search)
            if [[ -z "$2" ]]; then
                echo -e "${RED}Error: Please provide a search query${NC}"
                echo "Usage: $0 search <command>"
                exit 1
            fi
            display_header
            search_command "$2"
            ;;
        all)
            display_header
            show_tools
            echo -e "\n${BOLD}Press Enter to continue...${NC}"
            read -r
            show_aliases
            echo -e "\n${BOLD}Press Enter to continue...${NC}"
            read -r
            show_functions
            echo -e "\n${BOLD}Press Enter to continue...${NC}"
            read -r
            show_features
            echo -e "\n${BOLD}Press Enter to continue...${NC}"
            read -r
            show_examples
            ;;
        *)
            display_header
            echo -e "${BOLD}Usage:${NC} $0 <category> [query]\n"
            echo -e "${BOLD}Categories:${NC}"
            for i in "${!CATEGORIES[@]}"; do
                printf "  ${CYAN}%-12s${NC} - %s\n" "${CATEGORIES[$i]}" "${DESCRIPTIONS[$i]}"
            done
            echo -e "  ${CYAN}search <cmd>${NC} - Search for a specific command\n"
            echo -e "  ${CYAN}examples${NC}     - Show usage examples\n"
            echo -e "${BOLD}Examples:${NC}"
            echo -e "  $0 tools              # Show all installed tools"
            echo -e "  $0 aliases            # Show all shell aliases"
            echo -e "  $0 search fd          # Search for 'fd' command"
            echo -e "  $0 all                # Show everything (paginated)"
            echo ""
            ;;
    esac
}

# Run main function
main "$@"