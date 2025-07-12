#!/bin/bash

# Configuration parser for setup.yaml
# Provides functions to read and parse YAML configuration

# Load common library if not already loaded
if [[ "${COMMON_LIB_LOADED:-}" != "true" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
fi

# Configuration file path
CONFIG_FILE="${CONFIG_FILE:-$ROOT_DIR/config/setup.yaml}"

# Parse a simple YAML value
# Usage: get_config_value "path.to.key"
get_config_value() {
    local key_path="$1"
    local default_value="${2:-}"
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "$default_value"
        return 1
    fi
    
    # Convert dot notation to YAML path
    local yaml_path=$(echo "$key_path" | sed 's/\./:/g')
    
    # Simple YAML parser using awk
    local value=$(awk -v path="$yaml_path" '
        BEGIN { 
            split(path, keys, ":")
            depth = 0
            found = 0
        }
        
        # Skip comments and empty lines
        /^[[:space:]]*#/ || /^[[:space:]]*$/ { next }
        
        # Calculate indentation depth
        {
            indent = 0
            for (i = 1; i <= length($0); i++) {
                if (substr($0, i, 1) == " ") indent++
                else break
            }
            current_depth = indent / 2
        }
        
        # Reset if we go back to a higher level
        current_depth < depth { depth = current_depth; found = 0 }
        
        # Check if we match the current key
        {
            if (depth < length(keys) && $1 == keys[depth + 1] ":") {
                depth++
                if (depth == length(keys)) {
                    # Found our key, get the value
                    gsub(/^[^:]+:[[:space:]]*/, "")
                    gsub(/[[:space:]]*#.*$/, "")  # Remove inline comments
                    print
                    found = 1
                    exit
                }
            }
        }
    ' "$CONFIG_FILE")
    
    # Return value or default
    if [[ -n "$value" ]]; then
        echo "$value"
        return 0
    else
        echo "$default_value"
        return 1
    fi
}

# Check if a component is enabled
# Usage: is_component_enabled "databases.postgresql"
is_component_enabled() {
    local component="$1"
    local value=$(get_config_value "components.$component" "true")
    
    # Convert to boolean (compatible with older bash)
    local lower_value=$(echo "$value" | tr '[:upper:]' '[:lower:]')
    case "$lower_value" in
        true|yes|y|1|on)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Get a list from config
# Usage: get_config_list "custom.formulae"
get_config_list() {
    local key_path="$1"
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        return 1
    fi
    
    # Convert dot notation to YAML path
    local yaml_path=$(echo "$key_path" | sed 's/\./:/g')
    
    # Extract list items
    awk -v path="$yaml_path" '
        BEGIN { 
            split(path, keys, ":")
            depth = 0
            found = 0
            in_list = 0
        }
        
        # Skip comments and empty lines
        /^[[:space:]]*#/ || /^[[:space:]]*$/ { next }
        
        # Calculate indentation depth
        {
            indent = 0
            for (i = 1; i <= length($0); i++) {
                if (substr($0, i, 1) == " ") indent++
                else break
            }
            current_depth = indent / 2
        }
        
        # Exit list if indentation decreases
        in_list && current_depth <= list_depth { exit }
        
        # Check if we found our list
        {
            if (!in_list && depth < length(keys) && $1 == keys[depth + 1] ":") {
                depth++
                if (depth == length(keys)) {
                    in_list = 1
                    list_depth = current_depth
                    next
                }
            }
        }
        
        # Print list items
        in_list && /^[[:space:]]*-/ {
            gsub(/^[[:space:]]*-[[:space:]]*/, "")
            gsub(/[[:space:]]*#.*$/, "")  # Remove comments
            if (length($0) > 0) print
        }
    ' "$CONFIG_FILE"
}

# Load configuration settings into environment
load_config_settings() {
    # Load basic settings
    VERBOSE="${VERBOSE:-$(get_config_value 'settings.verbose' 'false')}"
    LOG_FILE="${LOG_FILE:-$(get_config_value 'settings.log_file' '')}"
    PARALLEL_JOBS="${PARALLEL_JOBS:-$(get_config_value 'settings.parallel_jobs' '8')}"
    
    # Convert verbose to boolean (compatible with older bash)
    local lower_verbose=$(echo "$VERBOSE" | tr '[:upper:]' '[:lower:]')
    case "$lower_verbose" in
        true|yes|y|1|on)
            VERBOSE=true
            ;;
        *)
            VERBOSE=false
            ;;
    esac
    
    export VERBOSE LOG_FILE PARALLEL_JOBS
}

# Check if configuration file exists
check_config_file() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        print_warning "Configuration file not found: $CONFIG_FILE"
        print_info "Using default settings. Create $CONFIG_FILE to customize."
        return 1
    fi
    
    print_info "Loading configuration from: $CONFIG_FILE"
    return 0
}

# Print configuration summary
print_config_summary() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        return 1
    fi
    
    echo -e "${BLUE}Configuration Summary${NC}"
    echo "===================="
    
    # Languages
    echo -e "\n${YELLOW}Programming Languages:${NC}"
    for lang in nodejs python go rust java ruby; do
        if is_component_enabled "languages.$lang"; then
            echo "  ✓ $lang"
        else
            echo "  ✗ $lang (disabled)"
        fi
    done
    
    # Databases
    echo -e "\n${YELLOW}Databases:${NC}"
    for db in postgresql mysql redis sqlite; do
        if is_component_enabled "databases.$db"; then
            echo "  ✓ $db"
        else
            echo "  ✗ $db (disabled)"
        fi
    done
    
    # Cloud tools
    echo -e "\n${YELLOW}Cloud Tools:${NC}"
    for tool in aws_cli azure_cli google_cloud_sdk; do
        if is_component_enabled "cloud.$tool"; then
            echo "  ✓ $tool"
        else
            echo "  ✗ $tool (disabled)"
        fi
    done
    
    echo ""
}

# Generate Brewfile based on configuration
generate_custom_brewfile() {
    local output_file="${1:-$ROOT_DIR/homebrew/Brewfile.custom}"
    
    {
        echo "# Custom Brewfile generated from config/setup.yaml"
        echo "# Generated on: $(date)"
        echo ""
        
        # Add custom formulae
        local formulae=$(get_config_list "custom.formulae")
        if [[ -n "$formulae" ]]; then
            echo "# Custom formulae"
            while IFS= read -r formula; do
                echo "brew \"$formula\""
            done <<< "$formulae"
            echo ""
        fi
        
        # Add custom casks
        local casks=$(get_config_list "custom.casks")
        if [[ -n "$casks" ]]; then
            echo "# Custom casks"
            while IFS= read -r cask; do
                echo "cask \"$cask\""
            done <<< "$casks"
            echo ""
        fi
    } > "$output_file"
    
    print_success "Generated custom Brewfile: $output_file"
}

# Export functions
export -f get_config_value
export -f is_component_enabled
export -f get_config_list
export -f load_config_settings
export -f check_config_file
export -f print_config_summary
export -f generate_custom_brewfile