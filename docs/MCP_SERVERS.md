# MCP (Model Context Protocol) Servers Configuration

This document describes the MCP servers that have been added to the Claude Code setup.

## Overview

The `setup-claude-mcp.sh` script now installs and configures both official and community MCP servers to enhance Claude Code's capabilities.

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

Run the setup script to install all servers:

```bash
./scripts/setup-claude-mcp.sh
```

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
  - Figma: Requires Figma API access token
  - Semgrep: May require Semgrep CLI installation
  - Pieces: Requires PiecesOS running locally

## Troubleshooting

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