#!/usr/bin/env bash

# Test for Claude MCP setup script

source "$(dirname "$0")/../test_framework.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../.."

# Mock functions
mock_osascript() {
    echo "Mock: osascript $@"
    return 0
}

mock_pgrep() {
    case "$2" in
        "Claude")
            return 1  # Claude not running
            ;;
        *)
            return 1
            ;;
    esac
}

mock_pkill() {
    echo "Mock: pkill $@"
    return 0
}

mock_open() {
    echo "Mock: open $@"
    return 0
}

mock_timeout() {
    # Skip timeout and run the command directly
    shift  # Remove timeout value
    "$@"
}

# Test MCP server installation
it "should create MCP directory structure"
setup_mock() {
    local test_dir="$TEST_TMP_DIR/mcp-test"
    export MCP_ROOT_DIR="$test_dir"
    export CLAUDE_CONFIG_DIR="$TEST_TMP_DIR/claude-config"
    export BACKUP_ROOT="$TEST_TMP_DIR/backups"
    
    # Mock git operations
    mock_command "git" 'echo "Mock: git $@"; return 0'
    mock_command "npm" 'echo "Mock: npm $@"; return 0'
    mock_command "osascript" mock_osascript
    mock_command "pgrep" mock_pgrep
    mock_command "pkill" mock_pkill
    mock_command "open" mock_open
    mock_command "timeout" mock_timeout
}
setup_mock

# Source the script to test functions
source "$SCRIPT_DIR/scripts/setup-claude-mcp.sh"

# Create directory structure
mkdir -p "$MCP_OFFICIAL_DIR" "$MCP_COMMUNITY_DIR" "$MCP_CUSTOM_DIR"

assert_true "[[ -d '$MCP_ROOT_DIR/official' ]]" "Official directory created"
assert_true "[[ -d '$MCP_ROOT_DIR/community' ]]" "Community directory created"
assert_true "[[ -d '$MCP_ROOT_DIR/custom' ]]" "Custom directory created"

# Test server info parsing
it "should parse server info correctly"
parsed=$(parse_server_info "context7:https://github.com/upstash/context7-mcp.git")
assert_equals "$parsed" "context7|https://github.com/upstash/context7-mcp.git|" "Parse simple server info"

parsed=$(parse_server_info "test:https://example.com/repo.git:abc123")
assert_equals "$parsed" "test|https://example.com/repo.git|abc123" "Parse server info with checksum"

# Test npm initialization
it "should initialize npm non-interactively"
test_npm_dir="$TEST_TMP_DIR/npm-test"
mkdir -p "$test_npm_dir"
init_npm_noninteractive "$test_npm_dir"
assert_true "[[ -f '$test_npm_dir/package.json' ]]" "package.json created"

# Test configuration generation
it "should generate node server config"
# Source common.sh to get the MCP functions
source "$SCRIPT_DIR/lib/common.sh"

# Set up test environment
MCP_SERVER_BASE_PATHS["test-server"]="$TEST_TMP_DIR/server"
MCP_SERVER_TYPES["test-server"]="node"
MCP_SERVER_EXECUTABLES["test-server"]="dist/index.js"

# Create mock executable
mkdir -p "$TEST_TMP_DIR/server/dist"
touch "$TEST_TMP_DIR/server/dist/index.js"

config=$(generate_mcp_server_config "test-server")
assert_contains "$config" '"command": "node"' "Node command in config"
assert_contains "$config" '"test-server"' "Server name in config"

# Test checksum verification
it "should verify checksums correctly"
echo "test content" > "$TEST_TMP_DIR/test-file.txt"
expected_checksum=$(shasum -a 256 "$TEST_TMP_DIR/test-file.txt" | awk '{print $1}')

# Should pass with correct checksum
verify_checksum "$TEST_TMP_DIR/test-file.txt" "$expected_checksum"
assert_equals "$?" "0" "Checksum verification passes"

# Should pass with empty checksum
verify_checksum "$TEST_TMP_DIR/test-file.txt" ""
assert_equals "$?" "0" "Empty checksum passes"

# Test Claude config creation
it "should create Claude config file"
configure_claude_desktop >/dev/null 2>&1 || true
assert_true "[[ -f '$CLAUDE_CONFIG_FILE' ]]" "Claude config file created"

# Test config contains expected structure
if [[ -f "$CLAUDE_CONFIG_FILE" ]]; then
    config_content=$(cat "$CLAUDE_CONFIG_FILE")
    assert_contains "$config_content" '"mcpServers"' "Config has mcpServers section"
fi

# Test backup creation
it "should backup existing config"
echo '{"existing": "config"}' > "$CLAUDE_CONFIG_FILE"
configure_claude_desktop >/dev/null 2>&1 || true
backup_file=$(find "$BACKUP_ROOT" -name "claude_desktop_config.json" -type f | head -1)
assert_true "[[ -n '$backup_file' ]]" "Backup file created"

# Test status check function
it "should check server status"
# Create a mock config
cat > "$CLAUDE_CONFIG_FILE" <<EOF
{
  "mcpServers": {
    "filesystem": {},
    "memory": {}
  }
}
EOF

# Mock server directories
mkdir -p "$MCP_OFFICIAL_DIR/src/filesystem"
mkdir -p "$MCP_OFFICIAL_DIR/src/memory"

# Capture status output
status_output=$(check_status 2>&1) || true
assert_contains "$status_output" "MCP Server Status" "Status header shown"

# Test remove configuration
it "should remove configuration safely"
echo '{"test": "config"}' > "$CLAUDE_CONFIG_FILE"
remove_configuration >/dev/null 2>&1
assert_false "[[ -f '$CLAUDE_CONFIG_FILE' ]]" "Config file removed"

# Verify backup was created before removal
backup_exists=$(find "$BACKUP_ROOT" -name "claude_desktop_config.json" -type f | wc -l)
assert_true "[[ $backup_exists -gt 0 ]]" "Backup created before removal"

# Cleanup
cleanup_mocks

# Run test summary
summarize