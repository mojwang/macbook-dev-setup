# Tools & Features

Complete list of tools installed by this setup.

## Programming Languages & Runtimes

### JavaScript/TypeScript
- **[Node.js](https://nodejs.org/)** - JavaScript runtime (via NVM for version management)
- **[NVM](https://github.com/nvm-sh/nvm)** - Node Version Manager
- **[Bun](https://bun.sh/)** - Fast all-in-one JavaScript runtime
- **[pnpm](https://pnpm.io/)** - Fast, disk space efficient package manager

### Python
- **[Python](https://www.python.org/)** - via pyenv for version management
- **[pyenv](https://github.com/pyenv/pyenv)** - Python version management
- **[uv](https://github.com/astral-sh/uv)** - Modern Python package installer

### Other Languages
- **[Go](https://golang.org/)** - Go programming language
- **[Rust](https://www.rust-lang.org/)** - Rust programming language
- **[Ruby](https://www.ruby-lang.org/)** - via rbenv
- **[PHP](https://www.php.net/)** - PHP with Composer

## Development Tools

### Version Control
- **[Git](https://git-scm.com/)** - Distributed version control
- **[GitHub CLI](https://cli.github.com/)** - GitHub from the command line
- **[diff-so-fancy](https://github.com/so-fancy/diff-so-fancy)** - Better git diffs
- **[commitizen](https://commitizen-tools.github.io/)** - Conventional commits

### Editors & IDEs
- **[Neovim](https://neovim.io/)** - Hyperextensible Vim-based text editor
- **[Visual Studio Code](https://code.visualstudio.com/)** - Modern code editor
- **[Vim](https://www.vim.org/)** - Classic text editor

### Container & Cloud Tools
- **[Docker](https://www.docker.com/)** - Container platform
- **[kubectl](https://kubernetes.io/docs/reference/kubectl/)** - Kubernetes CLI
- **[helm](https://helm.sh/)** - Kubernetes package manager
- **[minikube](https://minikube.sigs.k8s.io/)** - Local Kubernetes
- **[OrbStack](https://orbstack.dev/)** - Fast, light Docker & Linux

### Cloud CLIs
- **[AWS CLI](https://aws.amazon.com/cli/)** - Amazon Web Services CLI
- **[Azure CLI](https://docs.microsoft.com/en-us/cli/azure/)** - Microsoft Azure CLI
- **[Google Cloud SDK](https://cloud.google.com/sdk)** - Google Cloud CLI

### Infrastructure Tools
- **[Terraform](https://www.terraform.io/)** - Infrastructure as Code
- **[Ansible](https://www.ansible.com/)** - Automation platform

## Enhanced CLI Tools

### Modern Unix Replacements
- **[bat](https://github.com/sharkdp/bat)** - `cat` with syntax highlighting
- **[eza](https://github.com/eza-community/eza)** - Modern `ls` replacement
- **[fd](https://github.com/sharkdp/fd)** - Fast `find` alternative
- **[ripgrep](https://github.com/BurntSushi/ripgrep)** - Fast grep alternative
- **[zoxide](https://github.com/ajeetdsouza/zoxide)** - Smarter `cd` command
- **[fzf](https://github.com/junegunn/fzf)** - Fuzzy finder

### System Monitoring
- **[htop](https://htop.dev/)** - Interactive process viewer
- **[btop](https://github.com/aristocratos/btop)** - Resource monitor
- **[procs](https://github.com/dalance/procs)** - Modern `ps` replacement
- **[gping](https://github.com/orf/gping)** - Ping with graph

### Development Utilities
- **[jq](https://stedolan.github.io/jq/)** - JSON processor
- **[yq](https://github.com/mikefarah/yq)** - YAML processor
- **[httpie](https://httpie.io/)** - Modern HTTP client
- **[tldr](https://tldr.sh/)** - Simplified man pages
- **[entr](https://github.com/eradman/entr)** - File watcher
- **[watchman](https://facebook.github.io/watchman/)** - File watching service

### Terminal Enhancements
- **[Starship](https://starship.rs/)** - Cross-shell prompt
- **[tmux](https://github.com/tmux/tmux)** - Terminal multiplexer
- **[iTerm2](https://iterm2.com/)** - Terminal emulator
- **[Warp](https://www.warp.dev/)** - Modern terminal

## Database Tools

### Database Servers
- **[PostgreSQL](https://www.postgresql.org/)** - Advanced SQL database
- **[MySQL](https://www.mysql.com/)** - Popular SQL database
- **[Redis](https://redis.io/)** - In-memory data store
- **[SQLite](https://www.sqlite.org/)** - Embedded database

### Database Clients
- **[pgcli](https://www.pgcli.com/)** - PostgreSQL CLI with auto-completion
- **[mycli](https://www.mycli.net/)** - MySQL CLI with auto-completion
- **[TablePlus](https://tableplus.com/)** - Modern database GUI
- **[Postico](https://eggerapps.at/postico/)** - PostgreSQL GUI
- **[Sequel Ace](https://sequel-ace.com/)** - MySQL/MariaDB GUI

## AI & Productivity Tools

### AI Assistants
- **[Claude Desktop](https://claude.ai/)** - Anthropic's AI assistant
- **Claude CLI** - Command-line interface for Claude

### API Development
- **[Postman](https://www.postman.com/)** - API development platform
- **[Insomnia](https://insomnia.rest/)** - API design and testing

### Browsers
- **[Google Chrome](https://www.google.com/chrome/)** - Web browser
- **[Firefox](https://www.mozilla.org/firefox/)** - Privacy-focused browser
- **[Brave](https://brave.com/)** - Privacy browser with ad blocking
- **[Microsoft Edge](https://www.microsoft.com/edge)** - Chromium-based browser

### Communication
- **[Slack](https://slack.com/)** - Team communication
- **[Discord](https://discord.com/)** - Voice and text chat

### Design
- **[Figma](https://www.figma.com/)** - Collaborative design tool

## Fonts

### Programming Fonts
- **Meslo Nerd Font** - Patched with icons
- **FiraCode Nerd Font** - With ligatures
- **JetBrains Mono Nerd Font** - Developer font

## Security Tools

- **[gnupg](https://gnupg.org/)** - GPG encryption
- **[openssh](https://www.openssh.com/)** - SSH client/server
- **Git configured with GPG signing**

## Package Managers

- **[Homebrew](https://brew.sh/)** - macOS package manager
- **[npm](https://www.npmjs.com/)** - Node package manager
- **[pip](https://pip.pypa.io/)** - Python package manager
- **[cargo](https://doc.rust-lang.org/cargo/)** - Rust package manager

## VS Code Extensions

Automatically installed extensions include:
- Language support (Python, Go, Rust, etc.)
- GitLens for enhanced Git integration
- Prettier for code formatting
- ESLint for JavaScript linting
- Docker and Kubernetes tools
- AI assistants (GitHub Copilot ready)
- Theme and icon packs

See `vscode/extensions.txt` for the complete list.

## Custom Scripts

Located in `~/.scripts/`:
- **exa-wrapper.sh** - Smart eza wrapper with environment detection
- **adaptive-colors.sh** - Terminal color adaptation

## Configuration Files

Dotfiles installed to your home directory:
- `.zshrc` - Modular Zsh configuration
- `.gitconfig` - Git with diff-so-fancy
- `.vimrc` - Vim configuration
- `.config/nvim/init.lua` - Neovim configuration
- `.config/starship.toml` - Starship prompt config