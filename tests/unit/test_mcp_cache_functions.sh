#!/usr/bin/env bash

# Extract and define the cache functions for testing
# This file contains the functions isolated from setup-claude-mcp.sh

# Check if an API key validation is cached and still valid
is_validation_cached() {
    local key_name="$1"
    
    # Check if cache file exists
    if [[ ! -f "$VALIDATION_CACHE_FILE" ]]; then
        return 1
    fi
    
    # Check if key is in cache
    local cache_entry=$(grep "^${key_name}:" "$VALIDATION_CACHE_FILE" 2>/dev/null)
    if [[ -z "$cache_entry" ]]; then
        return 1
    fi
    
    # Check if cache entry is still valid (within duration)
    local cached_time=$(echo "$cache_entry" | cut -d: -f2)
    local current_time=$(date +%s)
    local age=$((current_time - cached_time))
    
    if [[ $age -lt $VALIDATION_CACHE_DURATION ]]; then
        return 0
    else
        # Remove expired entry
        grep -v "^${key_name}:" "$VALIDATION_CACHE_FILE" > "${VALIDATION_CACHE_FILE}.tmp" 2>/dev/null || true
        mv "${VALIDATION_CACHE_FILE}.tmp" "$VALIDATION_CACHE_FILE" 2>/dev/null || true
        return 1
    fi
}

# Add a validated key to the cache
cache_validation() {
    local key_name="$1"
    local timestamp=$(date +%s)
    
    # Set secure permissions before creating cache file
    umask 077
    
    # Create cache file if it doesn't exist
    touch "$VALIDATION_CACHE_FILE" 2>/dev/null || true
    
    # Remove any existing entry for this key
    grep -v "^${key_name}:" "$VALIDATION_CACHE_FILE" > "${VALIDATION_CACHE_FILE}.tmp" 2>/dev/null || true
    mv "${VALIDATION_CACHE_FILE}.tmp" "$VALIDATION_CACHE_FILE" 2>/dev/null || true
    
    # Add new entry
    echo "${key_name}:${timestamp}" >> "$VALIDATION_CACHE_FILE"
}

# Clean up old cache files to prevent accumulation
cleanup_old_cache_files() {
    local current_time=$(date +%s)
    local one_day_ago=$((current_time - 86400))  # 86400 seconds = 1 day
    local files_removed=0
    
    # Iterate through cache files
    for cache_file in /tmp/mcp-validated-keys-*; do
        if [[ -f "$cache_file" ]]; then
            # Get file modification time (macOS compatible)
            local file_time=$(stat -f %m "$cache_file" 2>/dev/null || stat -c %Y "$cache_file" 2>/dev/null || echo "0")
            
            # Remove if older than one day
            if [[ $file_time -lt $one_day_ago ]]; then
                rm -f "$cache_file" 2>/dev/null || true
                ((files_removed++))
            fi
        fi
    done
    
    return 0
}