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

## Core Principles

### 1. Always Use Error Handling
```bash
#!/usr/bin/env bash
set -e  # Exit on error
set -u  # Error on undefined variables
set -o pipefail  # Propagate pipe failures
```

### 2. Implement Cleanup Handlers
```bash
# Define cleanup function
cleanup() {
    local exit_code=$?
    echo "Cleaning up temporary files..."
    rm -f "$TEMP_FILE" 2>/dev/null || true
    exit $exit_code
}

# Register cleanup on signals
trap cleanup EXIT INT TERM HUP
```

### 3. Use the Signal Safety Library
```bash
source "$(dirname "$0")/../lib/signal-safety.sh"

# Automatic signal handling setup
setup_signal_handlers

# Add custom cleanup
add_cleanup_handler "rm -f /tmp/myfile"
```

## Common Signals

| Signal | Number | Description | Default Action |
|--------|--------|-------------|---------------|
| SIGHUP | 1 | Hangup detected | Terminate |
| SIGINT | 2 | Interrupt (Ctrl+C) | Terminate |
| SIGQUIT | 3 | Quit (Ctrl+\) | Core dump |
| SIGTERM | 15 | Termination request | Terminate |
| SIGKILL | 9 | Force kill (untrappable) | Terminate |
| SIGTSTP | 20 | Terminal stop (Ctrl+Z) | Stop |
| EXIT | - | Normal script termination | - |

## Implementation Patterns

### Basic Pattern
```bash
#!/usr/bin/env bash

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

### Preventing Multiple Cleanup Calls
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

### Background Processes
```bash
# Track background PIDs
PIDS=()

# Start background job
command &
PIDS+=($!)

# Cleanup function kills all background jobs
cleanup() {
    for pid in "${PIDS[@]}"; do
        kill "$pid" 2>/dev/null || true
    done
    wait
}

trap cleanup EXIT INT TERM HUP
```

### Lock Files
```bash
LOCK_FILE="/tmp/script.lock"

acquire_lock() {
    if ! mkdir "$LOCK_FILE" 2>/dev/null; then
        echo "Another instance is running"
        exit 1
    fi
    trap 'rmdir "$LOCK_FILE" 2>/dev/null' EXIT INT TERM HUP
}

acquire_lock
```

### Signal Forwarding
```bash
# Forward signals to child processes
forward_signal() {
    kill -$1 $CHILD_PID 2>/dev/null || true
}

trap 'forward_signal INT' INT
trap 'forward_signal TERM' TERM

# Start child process
./child-script.sh &
CHILD_PID=$!
wait $CHILD_PID
```

## Using the Signal Safety Library

For more complex scripts, use the provided library:

```bash
#!/usr/bin/env bash

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

## Testing Signal Handling

### Manual Testing
```bash
# Start your script
./your-script.sh &
PID=$!

# Test different signals
sleep 2
kill -INT $PID   # Ctrl+C
kill -TERM $PID  # Termination
kill -HUP $PID   # Hangup

# Verify cleanup happened
ls /tmp/  # Check temp files removed
ps aux | grep $PID  # Check process terminated
```

### Automated Testing
```bash
#!/usr/bin/env bash
source "$(dirname "$0")/../test_framework.sh"

it "should clean up on interrupt"
# Start script in background
timeout 5 ./script-with-cleanup.sh &
PID=$!
sleep 1

# Send interrupt
kill -INT $PID 2>/dev/null || true
wait $PID 2>/dev/null || true

# Verify cleanup
assert_false "[[ -f /tmp/test-file ]]" "Temp file should be removed"
```

### Run the Test Suite
```bash
# Run signal handling tests
./tests/test_signal_handling.sh

# Run CI cleanup verification
./tests/test_ci_cleanup.sh
```

## Best Practices

### 1. Quick Cleanup
- Keep cleanup functions fast and simple
- Don't perform complex operations during signal handling
- Use `|| true` to prevent cleanup failures from blocking

### 2. Idempotent Cleanup
- Make cleanup safe to run multiple times
- Check if resources exist before removing
- Use `-f` flag with `rm` to ignore missing files

### 3. Timeout Protection
```bash
# Add timeout to prevent hanging
timeout 30 ./long-running-command.sh || {
    echo "Command timed out"
    exit 1
}
```

### 4. Clean Up in Reverse Order
- Remove resources in reverse order of creation
- Kill processes before removing their files
- Close connections before removing sockets

### 5. Use /tmp for Temporary Files
```bash
# Good: Uses /tmp
temp_file=$(mktemp /tmp/myapp.XXXXXX)

# Bad: Uses current directory
temp_file=$(mktemp myapp.XXXXXX)
```

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

## Debugging Signal Issues

### Enable Debug Output
```bash
# Show signal handling
set -x
trap 'echo "Received signal"' INT TERM

# Or use debug function
debug_trap() {
    echo "Signal $1 received at line $LINENO"
}
trap 'debug_trap INT' INT
```

### Check Trap Settings
```bash
# List current traps
trap -p

# Remove specific trap
trap - INT

# Reset all traps
trap - EXIT INT TERM HUP
```

## Integration with This Project

The macbook-dev-setup project uses signal safety throughout:

1. **Setup Scripts**: All installation scripts implement cleanup handlers
2. **Parallel Execution**: Background jobs are properly tracked and terminated
3. **Backup System**: Ensures backups aren't corrupted by interrupts
4. **Test Framework**: Tests validate signal handling behavior

### Example from setup.sh
```bash
# From setup.sh
cleanup() {
    local exit_code=$?
    [[ -n "${CLEANUP_DONE:-}" ]] && return
    CLEANUP_DONE=1
    
    # Kill background jobs
    jobs -p | xargs -r kill 2>/dev/null || true
    
    # Remove temp files
    rm -f "$TEMP_LOG" 2>/dev/null || true
    
    # Show exit message
    if [[ $exit_code -eq 0 ]]; then
        print_success "Setup completed successfully"
    else
        print_error "Setup interrupted or failed"
    fi
    
    exit $exit_code
}

trap cleanup EXIT INT TERM HUP
```

## Verification

To verify no artifacts are left behind:

```bash
# Check for common artifacts
find /tmp -name "test_*" -o -name "tmp.*" | wc -l
find ~ -maxdepth 1 -name ".test-setup-backups-*" | wc -l
```

## Updated Scripts

The following scripts have been updated with proper signal handling:
- `lib/common.sh` - Main library with signal-safe trap
- `lib/signal-safety.sh` - Dedicated signal handling library
- `tests/test_backup_system.sh` - Handles test backup cleanup
- `scripts/rollback.sh` - Cleans up temporary requirements file
- `tests/test_error_recovery.sh` - Cleans up test artifacts
- All scripts using the common library inherit signal safety

## References

- [Bash Manual - Signals](https://www.gnu.org/software/bash/manual/html_node/Signals.html)
- [POSIX Signal Handling](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#trap)
- [lib/signal-safety.sh](../lib/signal-safety.sh) - Project's signal handling library
- [lib/common.sh](../lib/common.sh) - Common library with signal handling