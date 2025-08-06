#!/usr/bin/env bash

# Script to update Exa MCP configuration with API key

set -e

# Load common library
source "$(dirname "$0")/../lib/common.sh"

# Function to update Exa MCP configuration
update_exa_config() {
    local api_key="$1"
    
    if [[ -z "$api_key" ]]; then
        print_error "Please provide your Exa API key as an argument"
        echo "Usage: $0 YOUR_EXA_API_KEY"
        exit 1
    fi
    
    print_info "Updating Exa MCP configuration..."
    
    # Create a temporary Python script to update the settings
    cat > /tmp/update_exa_mcp.py << 'EOF'
import json
import sys
import os
import subprocess

# Get API key from environment variable for security
api_key = os.environ.get('EXA_API_KEY')
if not api_key:
    print("Error: No API key provided (set EXA_API_KEY environment variable)")
    sys.exit(1)

# Get current settings
try:
    result = subprocess.run(['claude', 'settings', 'export'], 
                          capture_output=True, text=True, timeout=10)
    if result.returncode != 0:
        print(f"Error getting settings: {result.stderr}")
        sys.exit(1)
    
    settings = json.loads(result.stdout)
except Exception as e:
    print(f"Error parsing settings: {e}")
    sys.exit(1)

# Update Exa configuration to use remote endpoint
if 'mcpServers' not in settings:
    settings['mcpServers'] = {}

settings['mcpServers']['exa'] = {
    "command": "npx",
    "args": [
        "-y",
        "@modelcontextprotocol/server-exa"
    ],
    "env": {
        "EXA_API_KEY": api_key
    }
}

# Write updated settings
updated_json = json.dumps(settings, indent=2)
print("Updated configuration:")
print(updated_json)

# Import the settings back
import_process = subprocess.Popen(['claude', 'settings', 'import'],
                                stdin=subprocess.PIPE,
                                stdout=subprocess.PIPE,
                                stderr=subprocess.PIPE,
                                text=True)
stdout, stderr = import_process.communicate(input=updated_json, timeout=10)

if import_process.returncode != 0:
    print(f"Error importing settings: {stderr}")
    sys.exit(1)
else:
    print("Successfully updated Exa MCP configuration!")
EOF
    
    # Run the Python script with API key via environment variable
    EXA_API_KEY="$api_key" python3 /tmp/update_exa_mcp.py
    
    # Clean up
    rm -f /tmp/update_exa_mcp.py
    
    print_success "Exa MCP configuration updated!"
    print_info "Testing connection..."
    
    # Test the connection
    sleep 2
    claude mcp list | grep -A1 "exa:" || true
}

# Main
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    update_exa_config "$@"
fi