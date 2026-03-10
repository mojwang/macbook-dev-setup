#!/usr/bin/env bash

# Test MCP API key handling
# NOTE: figma moved to plugin (uses hosted OAuth, no API key needed)

# Load test framework
source "$(dirname "$0")/../test_framework.sh"

describe "MCP API Key Handling"

# Test: API keys are not prompted when already set
it "should detect existing API keys from environment"

# Set up test environment
export EXA_API_KEY="test-exa-key"

# Simple test function for API key detection
test_check_api_key() {
    local key_name="$1"
    [[ -n "${!key_name}" ]]
}

assert_true "test_check_api_key 'EXA_API_KEY'" "Should detect EXA_API_KEY from environment"

# Clean up
unset EXA_API_KEY

assert_false "test_check_api_key 'EXA_API_KEY'" "Should not detect EXA_API_KEY after unset"

# Test: API keys file loading
it "should load API keys from file"

# Create temporary API keys file
TEMP_API_FILE=$(mktemp)
cat > "$TEMP_API_FILE" << 'EOF'
export EXA_API_KEY="file-exa-key"
EOF

# Source the file
source "$TEMP_API_FILE"

assert_true "test_check_api_key 'EXA_API_KEY'" "Should detect EXA_API_KEY from file"
assert_equals "$EXA_API_KEY" "file-exa-key" "EXA_API_KEY should have correct value"

# Clean up
rm -f "$TEMP_API_FILE"
unset EXA_API_KEY

# Print test results
print_test_summary
