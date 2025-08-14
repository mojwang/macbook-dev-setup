#!/usr/bin/env bash
# Setup TaskMaster AI for Claude Desktop and Claude Code
# Handles installation, API key configuration, and MCP setup

set -e
source "$(dirname "$0")/../lib/common.sh"

# Constants
SCRIPT_NAME="setup-taskmaster"
TASKMASTER_PACKAGE="task-master-ai"
API_KEYS_FILE="$HOME/.config/zsh/51-api-keys.zsh"
CLAUDE_DESKTOP_CONFIG="$HOME/Library/Application Support/Claude/claude_desktop_config.json"

# Function to check if TaskMaster is installed
check_taskmaster_installed() {
    if command -v task-master-ai &>/dev/null; then
        local version=$(task-master-ai --version 2>/dev/null | head -1 || echo "unknown")
        echo "✓ TaskMaster AI is already installed (version: $version)"
        return 0
    else
        return 1
    fi
}

# Function to install TaskMaster globally
install_taskmaster() {
    echo "Installing TaskMaster AI globally..."
    if npm install -g "$TASKMASTER_PACKAGE"; then
        echo "✓ TaskMaster AI installed successfully"
    else
        echo "✗ Failed to install TaskMaster AI"
        exit 1
    fi
}

# Function to check API keys
check_api_keys() {
    local missing_keys=()
    
    # Source API keys if file exists
    [[ -f "$API_KEYS_FILE" ]] && source "$API_KEYS_FILE"
    
    # Check required keys
    [[ -z "$ANTHROPIC_API_KEY" ]] && missing_keys+=("ANTHROPIC_API_KEY")
    [[ -z "$OPENAI_API_KEY" ]] && missing_keys+=("OPENAI_API_KEY")
    
    if [[ ${#missing_keys[@]} -gt 0 ]]; then
        echo "⚠️  Missing required API keys: ${missing_keys[*]}"
        echo "   Please add them to $API_KEYS_FILE"
        return 1
    fi
    
    echo "✓ Required API keys configured (ANTHROPIC, OPENAI)"
    
    # Check optional Perplexity key
    if [[ -n "$PERPLEXITY_API_KEY" ]]; then
        echo "✓ Perplexity API key configured (research features enabled)"
    else
        echo "ℹ️  Perplexity API key not configured (research features disabled)"
        echo "   To enable research: Add PERPLEXITY_API_KEY to $API_KEYS_FILE"
        echo "   Get your key at: https://www.perplexity.ai/settings/api"
    fi
}

# Function to configure Perplexity API key
configure_perplexity() {
    echo ""
    echo "Would you like to configure Perplexity API for research features?"
    echo "This enables TaskMaster to perform deep technical research."
    read -p "Configure now? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Get your API key from: https://www.perplexity.ai/settings/api"
        read -p "Enter your Perplexity API key (or press Enter to skip): " perplexity_key
        
        if [[ -n "$perplexity_key" ]]; then
            # Ensure API keys file exists
            mkdir -p "$(dirname "$API_KEYS_FILE")"
            touch "$API_KEYS_FILE"
            
            # Check if already exists
            if grep -q "^export PERPLEXITY_API_KEY=" "$API_KEYS_FILE" 2>/dev/null; then
                echo "Updating existing Perplexity API key..."
                sed -i '' "s/^export PERPLEXITY_API_KEY=.*/export PERPLEXITY_API_KEY=\"$perplexity_key\"/" "$API_KEYS_FILE"
            else
                echo "Adding Perplexity API key..."
                echo "export PERPLEXITY_API_KEY=\"$perplexity_key\"" >> "$API_KEYS_FILE"
            fi
            
            echo "✓ Perplexity API key configured"
        else
            echo "Skipping Perplexity configuration"
        fi
    fi
}

# Function to add TaskMaster to Claude Desktop
configure_claude_desktop() {
    echo "Configuring TaskMaster for Claude Desktop..."
    
    if [[ ! -f "$CLAUDE_DESKTOP_CONFIG" ]]; then
        echo "✗ Claude Desktop config not found at: $CLAUDE_DESKTOP_CONFIG"
        return 1
    fi
    
    # Check if TaskMaster already configured
    if grep -q '"taskmaster"' "$CLAUDE_DESKTOP_CONFIG" 2>/dev/null; then
        echo "✓ TaskMaster already configured in Claude Desktop"
        return 0
    fi
    
    # Backup config
    cp "$CLAUDE_DESKTOP_CONFIG" "$CLAUDE_DESKTOP_CONFIG.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Add TaskMaster configuration using Python for JSON manipulation
    python3 -c "
import json
import sys

config_file = '$CLAUDE_DESKTOP_CONFIG'

try:
    with open(config_file, 'r') as f:
        config = json.load(f)
    
    # Add TaskMaster configuration
    if 'mcpServers' not in config:
        config['mcpServers'] = {}
    
    config['mcpServers']['taskmaster'] = {
        'command': 'npx',
        'args': ['-y', 'task-master-ai'],
        'env': {
            'ANTHROPIC_API_KEY': '\${ANTHROPIC_API_KEY}',
            'OPENAI_API_KEY': '\${OPENAI_API_KEY}',
            'PERPLEXITY_API_KEY': '\${PERPLEXITY_API_KEY}'
        }
    }
    
    with open(config_file, 'w') as f:
        json.dump(config, f, indent=2)
    
    print('✓ TaskMaster added to Claude Desktop configuration')
except Exception as e:
    print(f'✗ Failed to update Claude Desktop config: {e}')
    sys.exit(1)
"
}

# Function to add TaskMaster to Claude Code CLI
configure_claude_code() {
    echo "Configuring TaskMaster for Claude Code CLI..."
    
    if ! command -v claude &>/dev/null; then
        echo "⚠️  Claude Code CLI not found. Skipping CLI configuration."
        return 0
    fi
    
    # Check if already configured
    if claude mcp list 2>/dev/null | grep -q "taskmaster"; then
        echo "✓ TaskMaster already configured in Claude Code"
        return 0
    fi
    
    # Add TaskMaster to Claude Code
    if claude mcp add taskmaster "npx -y task-master-ai" \
        --env "ANTHROPIC_API_KEY=\${ANTHROPIC_API_KEY}" \
        --env "OPENAI_API_KEY=\${OPENAI_API_KEY}" \
        --env "PERPLEXITY_API_KEY=\${PERPLEXITY_API_KEY}" 2>&1; then
        echo "✓ TaskMaster added to Claude Code CLI"
    else
        echo "⚠️  Failed to add TaskMaster to Claude Code CLI"
    fi
}

# Function to test TaskMaster connection
test_taskmaster() {
    echo ""
    echo "Testing TaskMaster integration..."
    
    # Test CLI availability
    if command -v task-master-ai &>/dev/null; then
        echo "✓ TaskMaster CLI available"
    else
        echo "✗ TaskMaster CLI not found"
        return 1
    fi
    
    # Test in Claude Code if available
    if command -v claude &>/dev/null; then
        echo "Checking Claude Code MCP servers..."
        if claude mcp list 2>/dev/null | grep -q "taskmaster.*Connected"; then
            echo "✓ TaskMaster connected in Claude Code"
        else
            echo "⚠️  TaskMaster not connected in Claude Code (may need restart)"
        fi
    fi
    
    echo ""
    echo "ℹ️  Note: Restart Claude Desktop to activate TaskMaster there"
}

# Main setup flow
main() {
    echo "==================================="
    echo "TaskMaster AI Setup Script"
    echo "==================================="
    echo ""
    
    # Check if already installed
    if ! check_taskmaster_installed; then
        install_taskmaster
    fi
    
    # Check API keys
    check_api_keys || configure_perplexity
    
    # Configure Claude Desktop
    configure_claude_desktop
    
    # Configure Claude Code
    configure_claude_code
    
    # Test the setup
    test_taskmaster
    
    echo ""
    echo "==================================="
    echo "TaskMaster Setup Complete!"
    echo "==================================="
    echo ""
    echo "Next steps:"
    echo "1. Restart Claude Desktop to activate TaskMaster"
    echo "2. In Claude, use TaskMaster for:"
    echo "   - Task management: Use TaskMaster tools directly"
    echo "   - PRD parsing: Provide a PRD file for breakdown"
    echo "   - Complex projects: Delegate to TaskMaster agent"
    
    if [[ -z "$PERPLEXITY_API_KEY" ]]; then
        echo ""
        echo "To enable research features later:"
        echo "1. Get API key from https://www.perplexity.ai/settings/api"
        echo "2. Add to $API_KEYS_FILE:"
        echo "   export PERPLEXITY_API_KEY=\"your-key\""
        echo "3. Restart Claude applications"
    fi
}

# Run main function
main "$@"