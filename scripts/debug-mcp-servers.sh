#!/usr/bin/env bash
set -e

# Debug and test MCP server configurations

# Load common library
source "$(dirname "$0")/../lib/common.sh"

# Load API keys if available
API_KEYS_FILE="$HOME/.config/zsh/51-api-keys.zsh"
if [[ -f "$API_KEYS_FILE" ]]; then
    source "$API_KEYS_FILE" 2>/dev/null || true
fi

echo "=== MCP Server Debug Tool ==="
echo ""

# Function to test a server
test_server() {
    local name=$1
    local command=$2
    shift 2
    local args=("$@")
    
    echo -n "Testing $name... "
    
    # Use standardized timeout function from common.sh
    if run_with_timeout 5 "$command" "${args[@]}" 2>&1 | grep -q "Content-Type: application/vnd.mcp"; then
        echo "✓ Working"
        return 0
    else
        echo "✗ Failed"
        return 1
    fi
}

# Test MCP server using configuration
test_mcp_server() {
    local server_name="$1"
    local server_path=$(find_mcp_server_executable "$server_name")
    local server_type="${MCP_SERVER_TYPES[$server_name]}"
    
    if ! is_mcp_server_installed "$server_name"; then
        echo "✗ Not installed"
        return 1
    fi
    
    if [[ -z "$server_path" ]]; then
        echo "✗ Executable not found"
        return 1
    fi
    
    # Set up environment for servers that need API keys
    local env_vars=""
    if [[ -n "${MCP_SERVER_API_KEYS[$server_name]}" ]]; then
        local api_key_var="${MCP_SERVER_API_KEYS[$server_name]}"
        env_vars="${api_key_var}=${!api_key_var}"
    fi
    
    case "$server_type" in
        "node")
            if [[ "$server_name" == "filesystem" ]]; then
                if [[ -n "$env_vars" ]]; then
                    env $env_vars test_server "$server_name" node "$server_path" "/tmp"
                else
                    test_server "$server_name" node "$server_path" "/tmp"
                fi
            else
                if [[ -n "$env_vars" ]]; then
                    env $env_vars test_server "$server_name" node "$server_path"
                else
                    test_server "$server_name" node "$server_path"
                fi
            fi
            ;;
        "python-uv")
            (cd "$server_path" && test_server "$server_name" uv run "mcp-server-$server_name")
            ;;
        "python-uvx")
            test_server "$server_name" uvx --with mcp==1.11.0 semgrep-mcp
            ;;
    esac
}

# Check environment variables
echo "Checking environment variables..."
for server in "${!MCP_SERVER_API_KEYS[@]}"; do
    api_key_var="${MCP_SERVER_API_KEYS[$server]}"
    echo -n "$api_key_var: "
    if [ -n "${!api_key_var}" ]; then
        key_value="${!api_key_var}"
        echo "✓ Set (${#key_value} chars)"
    else
        echo "✗ Not set"
    fi
done

echo ""
echo "Testing MCP servers individually..."
echo ""

# Test official servers
echo "Official servers:"
for server in "filesystem" "memory" "sequentialthinking" "git" "fetch"; do
    echo -n "  $server: "
    test_mcp_server "$server"
done

echo ""
echo "Community servers:"
for server in "context7" "playwright" "figma" "semgrep" "exa"; do
    echo -n "  $server: "
    # Skip API key servers if key not set
    if [[ -n "${MCP_SERVER_API_KEYS[$server]}" ]]; then
        api_key_var="${MCP_SERVER_API_KEYS[$server]}"
        if [[ -z "${!api_key_var}" ]]; then
            echo "✗ $api_key_var not set"
            continue
        fi
    fi
    test_mcp_server "$server"
done

# Test Claude Desktop configuration
echo ""
echo "Checking Claude Desktop configuration..."
CLAUDE_CONFIG="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
if [[ -f "$CLAUDE_CONFIG" ]]; then
    echo "✓ Config file exists"
    # Check for each server in config
    for server in "${!MCP_SERVER_BASE_PATHS[@]}"; do
        if grep -q "\"$server\"" "$CLAUDE_CONFIG" 2>/dev/null; then
            echo "  ✓ $server configured"
        fi
    done
else
    echo "✗ Config file not found"
fi

# Test Claude Code configuration
echo ""
echo "Checking Claude Code configuration..."
if command -v claude &>/dev/null; then
    echo "✓ Claude Code CLI installed"
    echo ""
    echo "Current MCP servers:"
    claude mcp list 2>/dev/null || echo "  No servers configured or error listing servers"
else
    echo "✗ Claude Code CLI not found"
fi

echo ""
echo "Debug complete!"

# Provide fix suggestions
echo ""
echo "To fix issues:"
echo "  - Missing servers: Run ./scripts/setup-claude-mcp.sh"
echo "  - Config issues: Run ./scripts/fix-mcp-servers.sh"
echo "  - API key issues: Set environment variables in ~/.config/zsh/51-api-keys.zsh"
echo "  - Claude Code: Run ./scripts/setup-claude-code-mcp.sh"