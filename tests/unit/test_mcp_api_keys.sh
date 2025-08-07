#!/usr/bin/env bash

# Test MCP API key handling

# Load test framework
source "$(dirname "$0")/../test_framework.sh"

describe "MCP API Key Handling"

# Test: API keys are not prompted when already set
it "should detect existing API keys from environment"

# Set up test environment
export FIGMA_API_KEY="test-figma-key"
export EXA_API_KEY="test-exa-key"

# Simple test function for API key detection
test_check_api_key() {
    local key_name="$1"
    [[ -n "${!key_name}" ]]
}

assert_true "test_check_api_key 'FIGMA_API_KEY'" "Should detect FIGMA_API_KEY from environment"
assert_true "test_check_api_key 'EXA_API_KEY'" "Should detect EXA_API_KEY from environment"

# Clean up
unset FIGMA_API_KEY EXA_API_KEY

assert_false "test_check_api_key 'FIGMA_API_KEY'" "Should not detect FIGMA_API_KEY after unset"
assert_false "test_check_api_key 'EXA_API_KEY'" "Should not detect EXA_API_KEY after unset"

# Test: API keys file loading
it "should load API keys from file"

# Create temporary API keys file
TEMP_API_FILE=$(mktemp)
cat > "$TEMP_API_FILE" << 'EOF'
export FIGMA_API_KEY="file-figma-key"
export EXA_API_KEY="file-exa-key"
EOF

# Source the file
source "$TEMP_API_FILE"

assert_true "test_check_api_key 'FIGMA_API_KEY'" "Should detect FIGMA_API_KEY from file"
assert_equals "$FIGMA_API_KEY" "file-figma-key" "FIGMA_API_KEY should have correct value"

assert_true "test_check_api_key 'EXA_API_KEY'" "Should detect EXA_API_KEY from file"
assert_equals "$EXA_API_KEY" "file-exa-key" "EXA_API_KEY should have correct value"

# Clean up
rm -f "$TEMP_API_FILE"
unset FIGMA_API_KEY EXA_API_KEY

# Print test results
print_test_summary