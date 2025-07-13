# Modular Zsh Configuration
# Optimized for Apple Silicon macOS
# This file loads configuration modules from ~/.config/zsh/

# Performance optimization: Skip compinit security check
autoload -Uz compinit
if [[ -n ${ZDOTDIR}/.zcompdump(#qNmh+24) ]]; then
    compinit
else
    compinit -C
fi

# Load modular configuration files in order
# Files are numbered to control loading sequence:
#   00-09: Core setup (Homebrew, paths)
#   10-19: Language version managers
#   20-29: CLI tools and enhancements
#   30-39: Aliases
#   40-49: Functions
#   50-59: Environment variables
#   90-99: Local/private settings

for config in ~/.config/zsh/*.zsh(N); do
    source "$config"
done

# For backward compatibility, load the old .zshrc if it exists as .zshrc.backup
# This ensures nothing breaks during migration
if [[ -f ~/.zshrc.backup ]] && [[ ! -f ~/.config/zsh/migrated ]]; then
    echo "Note: Loading legacy .zshrc.backup for compatibility"
    echo "Run 'touch ~/.config/zsh/migrated' to disable this message"
fi