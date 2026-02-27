#!/usr/bin/env bash

# Extract testable functions from scripts/setup-claude-mcp.sh for unit testing
# This file isolates pure functions that can be tested without sourcing the full script

# Parse server info from format "name:url[:checksum]"
parse_server_info() {
    local server_info="$1"
    IFS=':' read -r server_name server_url server_checksum <<< "$server_info"

    # Handle URLs with colons (like https://)
    if [[ "$server_url" == "https" || "$server_url" == "http" ]]; then
        server_url="${server_url}:${server_checksum}"
        server_checksum=""
        # Check if there's another part that might be the actual checksum
        if [[ "$server_info" =~ ^[^:]+:https?://[^:]+:(.+)$ ]]; then
            server_checksum="${BASH_REMATCH[1]}"
        fi
    fi

    echo "$server_name|$server_url|$server_checksum"
}

# Initialize npm with default values to prevent interactive prompts
init_npm_noninteractive() {
    local dir="$1"
    cd "$dir" || return 1

    # Create minimal package.json if it doesn't exist
    if [[ ! -f package.json ]]; then
        cat > package.json <<EOF
{
  "name": "$(basename "$dir")",
  "version": "1.0.0",
  "description": "MCP server",
  "private": true
}
EOF
    fi
}

# Verify checksum if provided
verify_checksum() {
    local file="$1"
    local expected_checksum="$2"

    if [[ -z "$expected_checksum" ]]; then
        return 0
    fi

    local actual_checksum
    actual_checksum=$(shasum -a 256 "$file" | awk '{print $1}')

    if [[ "$actual_checksum" != "$expected_checksum" ]]; then
        return 1
    fi

    return 0
}

# Remove MCP configuration (simplified for testing)
remove_configuration() {
    # Backup current config
    if [[ -f "$CLAUDE_CONFIG_FILE" ]]; then
        mkdir -p "$BACKUP_DIR"
        cp "$CLAUDE_CONFIG_FILE" "$BACKUP_DIR/claude_desktop_config.json"

        # Remove the config file
        rm -f "$CLAUDE_CONFIG_FILE"
    fi
}
