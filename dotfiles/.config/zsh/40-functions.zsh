# Custom Shell Functions
# Utility functions for common tasks

# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract various archive types
extract() {
    if [ -f $1 ] ; then
        case $1 in
            *.tar.bz2)   tar xjf $1     ;;
            *.tar.gz)    tar xzf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unrar e $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xf $1      ;;
            *.tbz2)      tar xjf $1     ;;
            *.tgz)       tar xzf $1     ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1        ;;
            *)     echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Development environment info
devinfo() {
    echo "🔧 Development Environment Info"
    echo "==============================="
    echo "OS: $(uname -s) $(uname -m)"
    echo "Shell: $SHELL"
    
    if command -v brew &> /dev/null; then
        echo "Homebrew: $(brew --version | head -n1)"
    fi
    
    if command -v node &> /dev/null; then
        echo "Node.js: $(node --version)"
        echo "npm: $(npm --version)"
    fi
    
    if command -v python3 &> /dev/null; then
        echo "Python: $(python3 --version)"
    fi
    
    if command -v git &> /dev/null; then
        echo "Git: $(git --version)"
    fi
    
    if command -v nvim &> /dev/null; then
        echo "Neovim: $(nvim --version | head -n1)"
    fi
    
    if command -v code &> /dev/null; then
        echo "VS Code: $(code --version | head -n1)"
    fi
}

# Quick backup function
backup() {
    if [ -z "$1" ]; then
        echo "Usage: backup <file/directory>"
        return 1
    fi
    cp -r "$1" "$1.backup.$(date +%Y%m%d_%H%M%S)"
    echo "Backed up $1"
}

# Find process by name
psgrep() {
    if [ -z "$1" ]; then
        echo "Usage: psgrep <process name>"
        return 1
    fi
    ps aux | grep -v grep | grep -i "$1"
}

# Show PATH in readable format
path() {
    echo $PATH | tr ':' '\n'
}

# Quick calculator
calc() {
    echo "scale=2; $*" | bc -l
}

# Get weather
weather() {
    local location="${1:-}"
    curl -s "wttr.in/${location}?format=3"
}

# Create a temporary directory and cd into it
tmpd() {
    local tmp_dir=$(mktemp -d)
    echo "Created temporary directory: $tmp_dir"
    cd "$tmp_dir"
}

# Corporate gh wrapper - auto-adds -R ORG/REPO when in a git repo
ghrepo() {
    if [[ -e .git/ ]] && [[ -n "$GH_CORP_ORG" ]]; then
        $(which gh) -R "${GH_CORP_ORG}/$(basename $PWD)" "$@"
    else
        $(which gh) "$@"
    fi
}

# Show expanded aliases before execution
# This function runs before each command is executed
preexec() {
    # Get the actual command that will be executed
    local cmd="$1"
    local expanded_cmd="$2"
    
    # Check if the command contains an alias
    # If the typed command differs from the expanded command, show the expansion
    if [[ "$cmd" != "$expanded_cmd" ]]; then
        # Display the expanded command in a dimmed color
        print -P "%F{240}→ $expanded_cmd%f"
    fi
}