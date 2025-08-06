# MCP (Model Context Protocol) Servers Configuration

This document describes the MCP servers that can be configured for Claude Desktop and Claude Code.

## Overview

The macbook-dev-setup project includes several scripts to manage MCP servers:

- `setup-claude-mcp.sh` - Installs and configures MCP servers for Claude Desktop
- `setup-claude-code-mcp.sh` - Configures MCP servers for Claude Code CLI
- `fix-mcp-servers.sh` - Repairs MCP configuration with dynamic server selection
- `debug-mcp-servers.sh` - Tests and debugs MCP server installations

## Official Servers

These servers are maintained by the official MCP team:

1. **filesystem** - Secure file operations with access controls
2. **memory** - In-memory key-value storage for temporary data
3. **git** - Tools to read, search, and manipulate Git repositories
4. **fetch** - Web content fetching and conversion
5. **sequentialthinking** - Dynamic problem-solving through thought sequences

## Community Servers

These servers are maintained by the community:

1. **context7** (https://github.com/upstash/context7-mcp)
   - Provides up-to-date documentation for any library/framework
   - Helps with accurate, version-specific code examples

2. **playwright** (https://github.com/microsoft/playwright-mcp)
   - Browser automation and web scraping capabilities
   - Useful for testing and data extraction

3. **figma** (https://github.com/GLips/Figma-Context-MCP)
   - Access Figma design data for AI coding tools
   - Helps with accurate design-to-code implementation

4. **semgrep** (https://github.com/semgrep/mcp)
   - Security scanning and code analysis
   - Helps identify vulnerabilities and code patterns

5. **exa** (https://github.com/exa-labs/exa-mcp-server)
   - AI-optimized search engine integration
   - Better web search results for AI agents

## Pieces MCP

Pieces MCP requires special configuration:
- Requires PiecesOS running locally
- Configure manually with SSE endpoint: `http://localhost:39300/model_context_protocol/2024-11-05/sse`
- Provides long-term memory and context-aware coding assistance

## Installation

### Claude Desktop

```bash
# Install all MCP servers
./scripts/setup-claude-mcp.sh

# Fix/update configuration
./scripts/fix-mcp-servers.sh

# Exclude servers that need API keys
./scripts/fix-mcp-servers.sh --no-api-keys

# Only install specific servers
./scripts/fix-mcp-servers.sh --servers filesystem,memory,git
```

### Claude Code

```bash
# Add all servers to user scope (global)
./scripts/setup-claude-code-mcp.sh

# Add to project scope (.mcp.json)
./scripts/setup-claude-code-mcp.sh --scope project

# Skip servers requiring API keys
./scripts/setup-claude-code-mcp.sh --no-api-keys

# Add specific servers only
./scripts/setup-claude-code-mcp.sh --servers context7,playwright
```

## Debugging

```bash
# Test all MCP servers
./scripts/debug-mcp-servers.sh
```

This will:
- Check environment variables for API keys
- Test each server individually
- Verify Claude Desktop configuration
- Check Claude Code configuration

Run the setup script to install all servers:

```bash
./scripts/setup-claude-mcp.sh
```

During installation, you'll be prompted for API keys for servers that require them:
- **Exa**: Get your API key from https://dashboard.exa.ai/api-keys
- **Figma**: Get your API key from https://www.figma.com/developers/api#access-tokens

API keys are securely stored in `~/.config/zsh/51-api-keys.zsh` and automatically loaded by your shell.

## Usage

Once installed, the servers are automatically available in Claude Code. You can:

1. Check configured servers: `claude mcp list`
2. Update servers: `./scripts/setup-claude-mcp.sh --update`
3. Remove servers: `./scripts/setup-claude-mcp.sh --remove`

## Prerequisites

- Node.js and npm (for TypeScript servers)
- Python 3 and uv (for Python servers)
- Claude Code CLI
- For specific servers:
  - Exa: Requires API key (will be prompted during setup)
  - Figma: Requires API key (will be prompted during setup)
  - Semgrep: May require Semgrep CLI installation
  - Pieces: Requires PiecesOS running locally

## Troubleshooting

### Connection Issues

To debug MCP connection failures:
1. Run `claude mcp list` to see connection status
2. Use `./scripts/debug-mcp-servers.sh` to test individual servers
3. Check API keys are set: `echo $EXA_API_KEY` and `echo $FIGMA_API_KEY`
4. Restart Claude after configuration changes: `osascript -e 'quit app "Claude"' && open -a "Claude"`

### Common Issues

**Figma/Exa servers fail to connect:**
- Ensure API keys are set in your shell environment
- Check `~/.config/zsh/51-api-keys.zsh` contains the keys
- Reload your shell or run `source ~/.zshrc`

**Playwright server fails:**
- The server may use `index.js` instead of `dist/index.js`
- Check actual file location and update config accordingly

**Semgrep server fails:**
- Requires Python and uv package manager
- Run `cd ~/repos/mcp-servers/community/semgrep && uv sync`

**Configuration gets corrupted:**
- Backup exists at `~/.setup-backups/configs/claude-mcp/`
- Or use `./scripts/fix-mcp-servers.sh` to reset

If a server fails to build or install:
1. Check that all prerequisites are installed
2. Ensure you have internet connectivity for cloning repositories
3. Some servers may have pre-built distributions and don't require building
4. Check the logs for specific error messages

## Directory Structure

```
~/repos/mcp-servers/
├── official/          # Official MCP servers
├── community/         # Community MCP servers
└── custom/           # Custom/local MCP servers
```