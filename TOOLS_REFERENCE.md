# Your MacBook Setup Tools & Aliases Reference

## 🚀 Modern CLI Tool Replacements
- **ls → eza**: Enhanced file listing with colors, icons, and tree view
  - `ls` - List files with colors and directories first
  - `ll` - Long format with details
  - `la` - List all including hidden files
  - `tree` - Tree view of directory structure
- **cat → bat**: Syntax highlighting and line numbers
- **cd → zoxide**: Smart directory jumping (use `z` command)
- **find → fd**: Fast and user-friendly file search
- **grep → ripgrep**: Blazing fast text search
- **git diff → delta**: Beautiful side-by-side diffs with syntax highlighting

## ⚡ Warp Terminal Power Tools
### Performance & Analysis
- `bench <command>` - Benchmark command performance (hyperfine)
- `loc` - Show code statistics (tokei)
- `ast <pattern>` - Advanced code search with AST-based patterns
- `astf <pattern> <lang>` - Language-specific AST search
- `watch <cmd>` - Run command on file changes (entr)

### Enhanced Commands
- `api <METHOD> <URL>` - Make HTTP requests with formatted JSON output
- `preview <file/dir>` - Smart preview with syntax highlighting
- `glog_fancy` - Beautiful git log optimized for Warp blocks
- `project <name>` - Quick project switcher with auto-navigation

### Warp Workflows
- `wf` - Warp workflow shortcut
- `wfl` - List available workflows
- `wfr` - Run a workflow
- **Available workflows**:
  - Git Feature Branch - Create and push feature branches
  - Docker Development - Common Docker tasks
  - Project Setup - Clone and setup new projects

### Warp-Specific Aliases
- `l` - eza -la (enhanced ls)
- `lt` - Tree view with 2 levels
- `lm` - List by modification time
- `gst` - Compact git status
- `glog` - Pretty git log (last 20 commits)
- `gdiff` - Git diff with delta
- `dps` - Docker ps with clean format
- `dlog` - Docker logs with tail
- `zshrc` - Quick edit .zshrc
- `zshreload` - Reload shell config

## 📁 Navigation & File Operations
- `..`, `...`, `....` - Navigate up directories
- `~` - Go to home directory
- `mkcd <dir>` - Create directory and cd into it
- `tmpd` - Create temp directory and cd into it
- `home` - Go to home directory
- `path` - Show PATH in readable format
- `extract <file>` - Extract any archive type (enhanced version with progress)
- `backup <file>` - Create timestamped backup
- `copy` - Enhanced copy with progress (rsync)

## 🔧 Git Shortcuts
### Shell Aliases
- `gs` - git status
- `ga` - git add
- `gc` - git commit
- `gp` - git push
- `gl` - git log --oneline
- `gd` - git diff
- `gb` - git branch
- `gco` - git checkout
- `gpl` - git pull
- `gf` - git fetch
- `gm` - git merge
- `gr` - git rebase
- `gst` - git stash

### Git Config Aliases
- `git st` - status
- `git lg` - pretty log with graph
- `git lga` - log all branches
- `git hist` - formatted history
- `git uncommit` - undo last commit (keep changes)
- `git amend` - amend without editing message
- `git cleanup` - delete merged branches
- `git sync` - fetch and rebase from origin/main

### Conventional Commit Helpers
- `gci` - Interactive commit helper
- `gciq` - Quick interactive commit
- `gcft "msg"` - feat: msg
- `gcfx "msg"` - fix: msg
- `gcd "msg"` - docs: msg
- `gcfs scope "msg"` - feat(scope): msg
- `gcxs scope "msg"` - fix(scope): msg
- `gcaf` - git add . && feat commit
- `commit-help` - Show commit format guide
- `gchelp` - View full commit guide

## 🐳 Docker Aliases
- `d` - docker
- `dc` - docker-compose
- `dps` - docker ps (enhanced format in Warp)
- `dpsa` - docker ps -a
- `di` - docker images
- `dlog` - docker logs -f (with tail in Warp)
- `dex` - docker exec -it
- `drm` - docker rm
- `drmi` - docker rmi

## 🛠️ Utility Functions
- `devinfo` - Show development environment info
- `psgrep <name>` - Find process by name
- `calc <expr>` - Quick calculator
- `weather [location]` - Get weather info
- `reload` - Reload shell configuration
- `ip` - Show local IP address
- `flushdns` - Flush DNS cache (macOS)
- `showfiles`/`hidefiles` - Toggle hidden files in Finder

## 🔒 Safety Aliases
- `rm`, `cp`, `mv` - Interactive mode by default

## 🎨 Editor
- `vim`, `vi`, `v` - All mapped to neovim

## 🧠 Optional AI-Powered Tools (if installed)
- **atuin** - Cloud-synced searchable shell history
  - Access with custom keybinding (not Ctrl+R by default)
  - `atuin search` - Search command history
- **mcfly** - Neural network powered history (replaces Ctrl+R if enabled)
- **navi** - Interactive command cheatsheets (Ctrl+G)
- **direnv** - Auto-load project-specific environment variables

## 💡 Pro Tips
1. Use `fzf` for fuzzy finding files (Ctrl+T)
2. Use `zoxide` with `z <partial-name>` to jump to frequently used directories
3. Warp disables Starship prompt (uses its own enhanced prompt)
4. Git now uses delta for beautiful side-by-side diffs
5. Use `bench` to compare performance of different commands
6. Warp workflows can automate multi-step processes
7. Use Cmd+P for Warp command palette
8. Use Cmd+D to duplicate blocks in Warp
9. Type naturally - Warp AI helps with command suggestions

## 🚀 Quick Start Examples
```bash
# Benchmark command performance
bench 'find . -name "*.js"' 'fd -e js'

# Smart project navigation
project my-app

# API testing with formatting
api GET https://api.github.com/users/github

# View code statistics
loc

# Advanced code search
ast 'console.log($$$)'

# Create feature branch workflow
wfr "Git Feature Branch"
```

Remember: These tools are already configured and ready to use!