#!/usr/bin/env bash

# Backup Manager Library
# Provides organized backup functionality for setup scripts

# Backup configuration
BACKUP_ROOT="${SETUP_BACKUP_ROOT:-$HOME/.setup-backups}"
MAX_BACKUPS="${SETUP_MAX_BACKUPS:-10}"
BACKUP_CATEGORIES=("dotfiles" "restore-points" "configs" "scripts")

# Ensure backup root exists
ensure_backup_root() {
    if [[ ! -d "$BACKUP_ROOT" ]]; then
        mkdir -p "$BACKUP_ROOT"
        
        # Create category directories
        for category in "${BACKUP_CATEGORIES[@]}"; do
            mkdir -p "$BACKUP_ROOT/$category"
        done
        
        # Create README
        cat > "$BACKUP_ROOT/README.md" << 'EOF'
# Setup Backups

This directory contains organized backups created by the macOS setup scripts.

## Structure

```
.setup-backups/
├── dotfiles/          # Dotfile backups (.zshrc, .gitconfig, etc.)
├── restore-points/    # Full system restore points
├── configs/           # Application configurations
├── scripts/           # Custom scripts
└── latest/           # Symlinks to most recent backups
```

## Management

- Run `setup.sh backup list` to see all backups
- Run `setup.sh backup clean` to remove old backups
- Run `setup.sh backup restore` to restore from a backup

## Automatic Cleanup

Old backups are automatically removed when the limit is exceeded.
Default limit: 10 backups per category
EOF
        
        # Create latest symlinks directory
        mkdir -p "$BACKUP_ROOT/latest"
    fi
}

# Create organized backup
create_backup() {
    local category="${1:-dotfiles}"
    local source="$2"
    local description="${3:-backup}"
    
    ensure_backup_root
    
    # Validate category
    if [[ ! " ${BACKUP_CATEGORIES[@]} " =~ " ${category} " ]]; then
        print_error "Invalid backup category: $category"
        return 1
    fi
    
    # Create timestamped directory
    local timestamp="$(date +%Y%m%d_%H%M%S)"
    local backup_dir="$BACKUP_ROOT/$category/$timestamp"
    mkdir -p "$backup_dir"
    
    # Create metadata
    cat > "$backup_dir/metadata.json" << EOF
{
    "timestamp": "$timestamp",
    "date": "$(date)",
    "category": "$category",
    "description": "$description",
    "source": "$source",
    "user": "$USER",
    "hostname": "$(hostname)"
}
EOF
    
    echo "$backup_dir"
}

# Backup file or directory with organization
backup_organized() {
    local source="$1"
    local category="${2:-dotfiles}"
    local description="${3:-}"
    
    if [[ ! -e "$source" ]]; then
        return 0  # Nothing to backup
    fi
    
    # Determine description if not provided
    if [[ -z "$description" ]]; then
        description="Backup of $(basename "$source")"
    fi
    
    # Create backup directory
    local backup_dir=$(create_backup "$category" "$source" "$description")
    if [[ -z "$backup_dir" ]]; then
        return 1
    fi
    
    # Copy the item
    local item_name="$(basename "$source")"
    if [[ -d "$source" ]]; then
        cp -r "$source" "$backup_dir/$item_name"
    else
        cp "$source" "$backup_dir/$item_name"
    fi
    
    # Update latest symlink
    update_latest_symlink "$category" "$backup_dir"
    
    # Clean old backups
    clean_old_backups "$category" >&2
    
    print_info "Backed up: $source → $backup_dir/$item_name" >&2
    # Return the backup directory path
    echo "$backup_dir"
}

# Update latest symlink
update_latest_symlink() {
    local category="$1"
    local backup_dir="$2"
    
    local latest_link="$BACKUP_ROOT/latest/$category"
    mkdir -p "$(dirname "$latest_link")"
    rm -f "$latest_link"
    ln -s "$backup_dir" "$latest_link"
}

# Clean old backups
clean_old_backups() {
    local category="$1"
    local category_dir="$BACKUP_ROOT/$category"
    
    if [[ ! -d "$category_dir" ]]; then
        return 0
    fi
    
    # Count backups
    local backup_count=$(ls -1 "$category_dir" | wc -l)
    
    if (( backup_count > MAX_BACKUPS )); then
        local to_remove=$((backup_count - MAX_BACKUPS))
        print_info "Removing $to_remove old backup(s) from $category" >&2
        
        # Remove oldest backups
        ls -1t "$category_dir" | tail -n "$to_remove" | while read -r old_backup; do
            rm -rf "$category_dir/$old_backup"
            print_info "Removed old backup: $old_backup" >&2
        done
    fi
}

# List all backups
list_backups() {
    ensure_backup_root
    
    echo "Setup Backups in $BACKUP_ROOT:"
    echo ""
    
    for category in "${BACKUP_CATEGORIES[@]}"; do
        local category_dir="$BACKUP_ROOT/$category"
        if [[ -d "$category_dir" ]] && [[ -n "$(ls -A "$category_dir" 2>/dev/null)" ]]; then
            echo "📁 $category:"
            ls -1t "$category_dir" | head -10 | while read -r backup; do
                local metadata="$category_dir/$backup/metadata.json"
                if [[ -f "$metadata" ]]; then
                    local date=$(jq -r '.date' "$metadata" 2>/dev/null || echo "Unknown")
                    local desc=$(jq -r '.description' "$metadata" 2>/dev/null || echo "No description")
                    echo "  • $backup - $desc"
                    echo "    Created: $date"
                else
                    echo "  • $backup"
                fi
            done
            echo ""
        fi
    done
    
    # Show latest symlinks
    if [[ -d "$BACKUP_ROOT/latest" ]] && [[ -n "$(ls -A "$BACKUP_ROOT/latest" 2>/dev/null)" ]]; then
        echo "🔗 Latest backups:"
        ls -la "$BACKUP_ROOT/latest" | grep -v "^total" | grep -v "^\." | while read -r line; do
            echo "  $line"
        done
    fi
}

# Migrate old backups to new structure
migrate_old_backups() {
    ensure_backup_root
    
    local migrated=0
    
    # Migrate dotfiles backups
    # Use $HOME instead of ~ to avoid bash tilde expansion caching issues
    for old_backup in "$HOME"/.dotfiles_backup_*; do
        if [[ -d "$old_backup" ]]; then
            local timestamp=$(basename "$old_backup" | sed 's/.*_//')
            local new_dir="$BACKUP_ROOT/dotfiles/$timestamp"
            
            if [[ ! -d "$new_dir" ]]; then
                mkdir -p "$new_dir"
                mv "$old_backup"/* "$new_dir/" 2>/dev/null
                
                # Create metadata
                cat > "$new_dir/metadata.json" << EOF
{
    "timestamp": "$timestamp",
    "date": "Migrated from $old_backup",
    "category": "dotfiles",
    "description": "Migrated dotfiles backup",
    "migrated": true
}
EOF
                
                rmdir "$old_backup" 2>/dev/null
                ((migrated++))
                print_success "Migrated: $old_backup → $new_dir"
            fi
        fi
    done
    
    # Migrate setup backups
    for old_backup in "$HOME"/.setup_backup_*; do
        if [[ -d "$old_backup" ]]; then
            local timestamp=$(basename "$old_backup" | sed 's/.*_//')
            local new_dir="$BACKUP_ROOT/restore-points/$timestamp"
            
            if [[ ! -d "$new_dir" ]]; then
                mkdir -p "$new_dir"
                mv "$old_backup"/* "$new_dir/" 2>/dev/null
                
                # Create metadata
                cat > "$new_dir/metadata.json" << EOF
{
    "timestamp": "$timestamp",
    "date": "Migrated from $old_backup",
    "category": "restore-points",
    "description": "Migrated restore point",
    "migrated": true
}
EOF
                
                rmdir "$old_backup" 2>/dev/null
                ((migrated++))
                print_success "Migrated: $old_backup → $new_dir"
            fi
        fi
    done
    
    # Migrate generic .backup and .bak files
    for old_backup in "$HOME"/*.backup "$HOME"/*.bak; do
        if [[ -f "$old_backup" ]]; then
            local basename=$(basename "$old_backup")
            local name_without_ext="${basename%.*}"
            local timestamp=$(date +%Y%m%d_%H%M%S)
            
            # Determine category based on filename
            local category="configs"
            if [[ "$name_without_ext" == *"zshrc"* ]] || [[ "$name_without_ext" == *"bashrc"* ]] || [[ "$name_without_ext" == *"profile"* ]]; then
                category="dotfiles"
            elif [[ "$name_without_ext" == *"script"* ]] || [[ "$name_without_ext" == *.sh ]]; then
                category="scripts"
            fi
            
            local new_dir="$BACKUP_ROOT/$category/${timestamp}_migrated"
            mkdir -p "$new_dir"
            
            # Move the file
            mv "$old_backup" "$new_dir/$basename"
            
            # Create metadata
            cat > "$new_dir/metadata.json" << EOF
{
    "timestamp": "$timestamp",
    "date": "$(date)",
    "category": "$category",
    "description": "Migrated from $old_backup",
    "original_file": "$basename",
    "migrated": true
}
EOF
            
            ((migrated++))
            print_success "Migrated: $old_backup → $new_dir"
        fi
    done
    
    if [[ $migrated -gt 0 ]]; then
        print_success "Migrated $migrated old backup(s) to organized structure"
    else
        print_info "No old backups to migrate"
    fi
}

# Export functions
export -f ensure_backup_root
export -f create_backup
export -f backup_organized
export -f update_latest_symlink
export -f clean_old_backups
export -f list_backups
export -f migrate_old_backups