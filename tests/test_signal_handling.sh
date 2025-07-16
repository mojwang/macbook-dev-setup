#!/bin/bash

# Test signal handling and cleanup mechanisms

source "$(dirname "$0")/test_framework.sh"

describe "Signal Handling and Cleanup Tests"

# Test that cleanup happens on SIGINT (Ctrl+C)
it "should clean up on SIGINT interruption"

# Create a test script that handles signals properly
test_script=$(mktemp /tmp/signal_test.XXXXXX)
cat > "$test_script" <<'EOF'
#!/bin/bash
temp_file=$(mktemp /tmp/signal_test_file.XXXXXX)
echo "$$" > "$temp_file.pid"

cleanup() {
    echo "Cleaning up..." >> "$temp_file.log"
    rm -f "$temp_file" "$temp_file.pid" "$temp_file.log"
}

# Proper signal handling - catch all common signals
trap cleanup EXIT INT TERM HUP

echo "Started" >> "$temp_file.log"
# Simulate work
sleep 10
echo "Completed" >> "$temp_file.log"
EOF
chmod +x "$test_script"

# Run the script in background
"$test_script" &
test_pid=$!

# Wait for it to start
sleep 0.5

# Find the temp file it created
pid_file=$(find /tmp -name "signal_test_file.*.pid" -mtime -1 2>/dev/null | head -1)
if [[ -n "$pid_file" ]]; then
    temp_base="${pid_file%.pid}"
    
    # Send SIGINT (like Ctrl+C)
    kill -INT $test_pid 2>/dev/null
    
    # Wait a moment for cleanup
    sleep 0.5
    
    # Check that files were cleaned up
    assert_false "[[ -f '$temp_base' ]]" "Temp file should be cleaned up after SIGINT"
    assert_false "[[ -f '${temp_base}.pid' ]]" "PID file should be cleaned up after SIGINT"
    assert_true "[[ -f '${temp_base}.log' ]]" "Log file should exist to verify cleanup ran"
    
    # Check log contains cleanup message
    if [[ -f "${temp_base}.log" ]]; then
        assert_contains "$(cat ${temp_base}.log)" "Cleaning up" "Cleanup function should have run"
        rm -f "${temp_base}.log"
    fi
else
    fail_test "Could not find test PID file"
fi

rm -f "$test_script"

# Test that cleanup happens on SIGTERM
it "should clean up on SIGTERM"

test_script2=$(mktemp /tmp/signal_test2.XXXXXX)
cat > "$test_script2" <<'EOF'
#!/bin/bash
temp_dir=$(mktemp -d /tmp/signal_test_dir.XXXXXX)
echo "$$" > "$temp_dir/test.pid"

cleanup() {
    rm -rf "$temp_dir"
}

trap cleanup EXIT INT TERM HUP

sleep 10
EOF
chmod +x "$test_script2"

# Run in background
"$test_script2" &
test_pid2=$!
sleep 0.5

# Find the temp directory
test_dir=$(find /tmp -name "signal_test_dir.*" -type d -mtime -1 2>/dev/null | head -1)
if [[ -n "$test_dir" ]]; then
    # Send SIGTERM
    kill -TERM $test_pid2 2>/dev/null
    sleep 0.5
    
    # Check directory was cleaned up
    assert_false "[[ -d '$test_dir' ]]" "Temp directory should be cleaned up after SIGTERM"
else
    fail_test "Could not find test directory"
fi

rm -f "$test_script2"

# Test trap inheritance in subshells
it "should handle cleanup in subshells"

parent_script=$(mktemp /tmp/parent_test.XXXXXX)
cat > "$parent_script" <<'EOF'
#!/bin/bash
parent_temp=$(mktemp /tmp/parent_temp.XXXXXX)

cleanup() {
    rm -f "$parent_temp"
}

trap cleanup EXIT INT TERM

# Subshell should not interfere with parent cleanup
(
    child_temp=$(mktemp /tmp/child_temp.XXXXXX)
    trap "rm -f '$child_temp'" EXIT
    echo "child" > "$child_temp"
    exit 0
)

echo "parent" > "$parent_temp"
EOF
chmod +x "$parent_script"

# Run the script
"$parent_script"

# Both files should be cleaned up
parent_files=$(find /tmp -name "parent_temp.*" -mtime -1 2>/dev/null | wc -l)
child_files=$(find /tmp -name "child_temp.*" -mtime -1 2>/dev/null | wc -l)

assert_equals "0" "$parent_files" "Parent temp files should be cleaned up"
assert_equals "0" "$child_files" "Child temp files should be cleaned up"

rm -f "$parent_script"

# Test cleanup with multiple signals
it "should handle multiple signals correctly"

multi_script=$(mktemp /tmp/multi_signal.XXXXXX)
cat > "$multi_script" <<'EOF'
#!/bin/bash
cleanup_count=0
temp_file=$(mktemp /tmp/multi_signal_test.XXXXXX)

cleanup() {
    cleanup_count=$((cleanup_count + 1))
    echo "Cleanup called: $cleanup_count" >> "$temp_file.log"
    if [[ $cleanup_count -eq 1 ]]; then
        rm -f "$temp_file" "$temp_file.log"
    fi
}

# Ensure cleanup only runs once
trap cleanup EXIT INT TERM HUP

echo "Started" > "$temp_file"
sleep 10
EOF
chmod +x "$multi_script"

"$multi_script" &
multi_pid=$!
sleep 0.5

# Send multiple signals
kill -INT $multi_pid 2>/dev/null
kill -TERM $multi_pid 2>/dev/null
sleep 0.5

# Check that temp files are cleaned
multi_files=$(find /tmp -name "multi_signal_test.*" -mtime -1 2>/dev/null | wc -l)
assert_equals "0" "$multi_files" "All temp files should be cleaned after multiple signals"

rm -f "$multi_script"

# Test EXIT trap alone vs with signals
it "should differentiate EXIT-only vs signal-aware traps"

# Script with EXIT-only trap
exit_only=$(mktemp /tmp/exit_only.XXXXXX)
cat > "$exit_only" <<'EOF'
#!/bin/bash
temp_file=$(mktemp /tmp/exit_only_test.XXXXXX)
trap "rm -f '$temp_file'" EXIT
echo "$$" > "$temp_file"
sleep 10
EOF
chmod +x "$exit_only"

# Script with signal-aware trap
signal_aware=$(mktemp /tmp/signal_aware.XXXXXX)
cat > "$signal_aware" <<'EOF'
#!/bin/bash
temp_file=$(mktemp /tmp/signal_aware_test.XXXXXX)
trap "rm -f '$temp_file'" EXIT INT TERM HUP
echo "$$" > "$temp_file"
sleep 10
EOF
chmod +x "$signal_aware"

# Run both
"$exit_only" &
exit_pid=$!
"$signal_aware" &
signal_pid=$!
sleep 0.5

# Kill both with SIGINT
kill -INT $exit_pid 2>/dev/null
kill -INT $signal_pid 2>/dev/null
sleep 0.5

# Check cleanup - signal-aware should be cleaned, exit-only might not be
signal_aware_files=$(find /tmp -name "signal_aware_test.*" -mtime -1 2>/dev/null | wc -l)
assert_equals "0" "$signal_aware_files" "Signal-aware trap should clean up on SIGINT"

# Clean up any remaining files
rm -f /tmp/exit_only_test.* /tmp/signal_aware_test.*
rm -f "$exit_only" "$signal_aware"

# Kill any remaining processes
kill -TERM $exit_pid $signal_pid 2>/dev/null

print_summary