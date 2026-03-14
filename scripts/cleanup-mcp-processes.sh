#!/usr/bin/env bash
# MCP Process Cleanup Script
# Safely kills orphaned and duplicate MCP server processes

set -e

# Signal handling for graceful interruption
trap 'echo -e "\n\nCleanup interrupted by user"; exit 130' INT TERM

DRY_RUN=false
FORCE=false
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --force) FORCE=true ;;
    esac
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  MCP PROCESS CLEANUP"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Count current processes
BEFORE=$(ps aux | grep -E 'mcp|npx.*model|uvx.*mcp|node.*mcp' | grep -v grep | wc -l | tr -d ' ')
echo "Current MCP processes: $BEFORE"
echo ""

if $DRY_RUN; then
    echo "DRY RUN - Would kill the following processes:"
    echo ""
    ps aux | grep -E 'mcp|npx.*model|uvx.*mcp|node.*mcp' | grep -v grep || echo "  (none found)"
    echo ""
    exit 0
fi

# Warning (skip in --force mode for agent use)
if ! $FORCE; then
    echo "This will kill all MCP server processes."
    echo "   Claude Desktop and Claude Code will need to restart them."
    echo ""
    echo "Press ENTER to continue, or Ctrl+C to cancel..."
    read -r
fi

echo ""
echo "Killing MCP processes..."

# Kill NPX-based servers
echo "  • Stopping NPX servers..."
pkill -f "npx.*exa-mcp" 2>/dev/null || true
# NOTE: figma is now a plugin (managed by Claude Code, not a standalone process)
pkill -f "npm exec.*mcp" 2>/dev/null || true

# Kill UV-based servers (Python)
echo "  • Stopping UV/Python servers..."
pkill -f "uv.*mcp-server" 2>/dev/null || true
pkill -f "mcp-server-fetch" 2>/dev/null || true
pkill -f "mcp-server-git" 2>/dev/null || true

# Kill Node MCP servers
echo "  • Stopping Node servers..."
pkill -f "node.*mcp-servers/official" 2>/dev/null || true
pkill -f "node.*mcp-servers/community" 2>/dev/null || true

# Kill disclaimer wrappers
echo "  • Stopping disclaimer wrappers..."
pkill -f "disclaimer.*mcp" 2>/dev/null || true
pkill -f "disclaimer.*npx" 2>/dev/null || true
pkill -f "disclaimer.*uv" 2>/dev/null || true

# Wait for processes to terminate
echo ""
echo "Waiting for processes to terminate..."
sleep 2

# Check remaining
AFTER=$(ps aux | grep -E 'mcp|npx.*model|uvx.*mcp|node.*mcp' | grep -v grep | wc -l | tr -d ' ')

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  CLEANUP COMPLETE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Before: $BEFORE processes"
echo "After:  $AFTER processes"
echo "Killed: $((BEFORE - AFTER)) processes"
echo ""

if [[ $AFTER -gt 0 ]]; then
    echo "⚠️  Some processes remain:"
    ps aux | grep -E 'mcp|npx.*model|uvx.*mcp|node.*mcp' | grep -v grep
    echo ""
    echo "These may be actively used by Claude."
    echo "They will be recreated when needed."
else
    echo "✅ All MCP processes cleaned up successfully!"
    echo ""
    echo "📝 Next steps:"
    echo "1. Open Claude Desktop or Claude Code"
    echo "2. MCP servers will restart automatically"
    echo "3. Verify with: ps aux | grep mcp | wc -l"
fi
echo ""
