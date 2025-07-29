# Signal Safety and Cleanup Guide

This document explains how scripts in this repository handle signals and cleanup to ensure no temporary files or resources are left behind, even when interrupted.

## The Problem

When a script is interrupted (e.g., via Ctrl+C), it receives a SIGINT signal. If the script only uses `trap cleanup EXIT`, the cleanup function won't run because:
- `EXIT` trap only triggers on normal script termination
- SIGINT causes immediate termination unless explicitly handled
- This can leave temporary files, directories, and other resources behind

## The Solution

All scripts that create temporary resources should use signal-aware traps:

```bash
# ❌ BAD: Only handles normal exit
trap cleanup EXIT

# ✅ GOOD: Handles interrupts and other signals
trap cleanup EXIT INT TERM HUP
```

### Signal Explanation

- **EXIT**: Normal script termination
- **INT**: Interrupt signal (Ctrl+C)
- **TERM**: Termination request (kill command)
- **HUP**: Terminal hangup (closing terminal)

## Implementation Guide

### Basic Pattern

```bash
#!/bin/bash

# Define cleanup function
cleanup() {
    rm -f "$temp_file"
    rm -rf "$temp_dir"
}

# Set up signal-safe trap
trap cleanup EXIT INT TERM HUP

# Create temporary resources
temp_file=$(mktemp /tmp/myapp.XXXXXX)
temp_dir=$(mktemp -d /tmp/myapp_dir.XXXXXX)

# Your script logic here
```

### Using the Signal Safety Library

For more complex scripts, use the provided library:

```bash
#!/bin/bash

source "$(dirname "$0")/../lib/signal-safety.sh"

# Define custom cleanup
cleanup() {
    echo "Cleaning up..."
    # Your cleanup code here
    default_cleanup  # Cleans registered temp resources
}

# Setup signal handling
setup_cleanup "cleanup"

# Use safe temp file creation
temp_file=$(safe_mktemp "myapp.XXXXXX")
temp_dir=$(safe_mktemp_dir "myapp_work.XXXXXX")
```

### Preventing Multiple Cleanup Calls

The signal-safety library ensures cleanup only runs once:

```bash
CLEANUP_DONE=false

safe_cleanup() {
    if [[ "$CLEANUP_DONE" == "false" ]]; then
        CLEANUP_DONE=true
        cleanup
    fi
}

trap safe_cleanup EXIT INT TERM HUP
```

## Testing Signal Handling

Run the signal handling tests:

```bash
./tests/test_signal_handling.sh
```

This test suite verifies:
- Cleanup on SIGINT (Ctrl+C)
- Cleanup on SIGTERM
- Proper trap inheritance in subshells
- Prevention of multiple cleanup calls

## CI/CD Considerations

GitHub Actions and other CI systems may forcefully terminate jobs. Our scripts handle this by:

1. Using proper signal traps in all scripts
2. Running periodic cleanup tests in CI
3. Providing a cleanup utility for safety

## Cleanup Utility

For additional safety, a cleanup utility is provided:

```bash
# Dry run (default) - shows what would be cleaned
./scripts/cleanup-artifacts.sh

# Actually clean up
./scripts/cleanup-artifacts.sh --execute

# Add to crontab for automatic cleanup
0 3 * * 0 /path/to/cleanup-artifacts.sh --execute
```

## Best Practices

1. **Always use signal-aware traps** when creating temporary resources
2. **Use /tmp for temporary files** via `mktemp /tmp/prefix.XXXXXX`
3. **Test signal handling** when modifying scripts that create resources
4. **Clean up in reverse order** of resource creation
5. **Use the signal-safety library** for complex scripts

## Verification

To verify no artifacts are left behind:

```bash
# Run CI cleanup verification
./tests/test_ci_cleanup.sh

# Check for common artifacts
find /tmp -name "test_*" -o -name "tmp.*" | wc -l
find ~ -maxdepth 1 -name ".test-setup-backups-*" | wc -l
```

## Updated Scripts

The following scripts have been updated with proper signal handling:
- `lib/common.sh` - Main library with signal-safe trap
- `tests/test_backup_system.sh` - Handles test backup cleanup
- `scripts/rollback.sh` - Cleans up temporary requirements file
- `tests/test_error_recovery.sh` - Cleans up test artifacts
- All scripts using the common library inherit signal safety