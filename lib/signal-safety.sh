#!/usr/bin/env bash

# Signal-safe cleanup template for scripts
# Source this file and use setup_cleanup function to register cleanup

# Global flag to prevent multiple cleanup calls
CLEANUP_DONE=false

# Globally-scoped chosen cleanup function name. Must be global (not local
# inside setup_cleanup) because the trap fires AFTER setup_cleanup returns —
# at trap-fire time, any local from setup_cleanup is out of scope and
# safe_cleanup would resolve to the empty string, silently skipping cleanup.
_SIGNAL_SAFETY_CLEANUP_FUNC=""

# Function to setup signal-safe cleanup
# Usage: setup_cleanup "cleanup_function_name"
setup_cleanup() {
    _SIGNAL_SAFETY_CLEANUP_FUNC="${1:-cleanup}"

    # Wrapper to ensure cleanup only runs once
    safe_cleanup() {
        if [[ "$CLEANUP_DONE" == "false" ]]; then
            CLEANUP_DONE=true
            # Call the actual cleanup function (resolved at trap-fire time
            # from the global, NOT from setup_cleanup's stack frame).
            if declare -F "$_SIGNAL_SAFETY_CLEANUP_FUNC" >/dev/null; then
                "$_SIGNAL_SAFETY_CLEANUP_FUNC"
            fi
        fi
    }

    # Register for all common signals that should trigger cleanup
    # EXIT - Normal script termination
    # INT  - Interrupt signal (Ctrl+C)
    # TERM - Termination request
    # HUP  - Terminal hangup
    # QUIT - Quit signal (Ctrl+\)
    trap safe_cleanup EXIT INT TERM HUP QUIT
}

# Helper function to create temporary files/directories safely
# These will be automatically cleaned up
TEMP_RESOURCES=()

# Create a temporary file with automatic cleanup
safe_mktemp() {
    local template="${1:-tmp.XXXXXX}"
    local temp_file
    
    if [[ "$template" != /* ]]; then
        # Ensure temp files go to /tmp
        temp_file=$(mktemp "/tmp/$template")
    else
        temp_file=$(mktemp "$template")
    fi
    
    TEMP_RESOURCES+=("$temp_file")
    echo "$temp_file"
}

# Create a temporary directory with automatic cleanup
safe_mktemp_dir() {
    local template="${1:-tmp.XXXXXX}"
    local temp_dir
    
    if [[ "$template" != /* ]]; then
        # Ensure temp dirs go to /tmp
        temp_dir=$(mktemp -d "/tmp/$template")
    else
        temp_dir=$(mktemp -d "$template")
    fi
    
    TEMP_RESOURCES+=("$temp_dir")
    echo "$temp_dir"
}

# Default cleanup function that removes all registered temp resources
default_cleanup() {
    local resource
    for resource in "${TEMP_RESOURCES[@]}"; do
        if [[ -d "$resource" ]]; then
            rm -rf "$resource" 2>/dev/null
        elif [[ -f "$resource" ]]; then
            rm -f "$resource" 2>/dev/null
        fi
    done
}

# Example usage in a script:
# ```bash
# source "lib/signal-safety.sh"
# 
# # Define custom cleanup
# cleanup() {
#     echo "Cleaning up..."
#     # Your cleanup code here
#     default_cleanup  # Also clean temp resources
# }
# 
# # Setup signal handling
# setup_cleanup "cleanup"
# 
# # Use safe temp file creation
# temp_file=$(safe_mktemp "myapp.XXXXXX")
# temp_dir=$(safe_mktemp_dir "myapp_work.XXXXXX")
# ```

# For scripts that only need basic temp file cleanup
setup_basic_cleanup() {
    setup_cleanup "default_cleanup"
}