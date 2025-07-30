# Testing Guide

## Testing Philosophy

This project uses a pragmatic combination of TDD, BDD, and SDD approaches:

### Test-Driven Development (TDD)
- Default approach for all new code
- Write unit tests first, then implement
- Keep tests simple and focused

### Behavior-Driven Development (BDD)
- Use for user-facing features when it adds clarity
- Given/When/Then format available in test framework
- No separate feature files needed - use inline in tests

### Specification-Driven Development (SDD)
- Document critical contracts and invariants
- Use `specify`, `invariant`, `precondition`, `postcondition` functions
- Only for APIs and critical system boundaries

### Example:
```bash
#!/bin/bash
source "$(dirname "$0")/../test_framework.sh"

specify "critical API contract"
invariant "[[ condition ]]" "System invariant maintained"

it "user-facing feature"
given "initial state"
when "user action"
expect "[[ expected result ]]" "Outcome achieved"
```

## Running Tests
```bash
# Run all tests
./tests/run_tests.sh

# Run specific test suites
./tests/run_tests.sh unit        # Unit tests only
./tests/run_tests.sh integration # Integration tests only
./tests/run_tests.sh ci          # CI-specific tests

# Run tests in parallel (faster)
./tests/run_tests_parallel.sh

# Run with custom parallelism
TEST_JOBS=8 ./tests/run_tests.sh
```

## Test Organization
- **Unit Tests** (`tests/unit/`): Test individual functions and components
- **Integration Tests** (`tests/integration/`): Test script interactions
- **CI Tests** (`tests/ci/`): Tests specific to CI environment
- **Stress Tests** (`tests/stress/`): Performance and load testing
- **Performance Tests** (`tests/performance/`): Benchmark and optimization tests

## Writing Tests
Use the test framework's built-in functions:
```bash
it "should describe what it tests"
assert_equals "expected" "actual" "Test description"
assert_true "[[ condition ]]" "Condition should be true"
assert_false "[[ condition ]]" "Condition should be false"
assert_contains "haystack" "needle" "Should contain substring"
assert_file_exists "/path/to/file" "File should exist"
assert_dir_exists "/path/to/dir" "Directory should exist"
```

## Testing Signal Safety
Always test your cleanup implementation:

```bash
# Start your script and interrupt it
./your-script.sh &
PID=$!
sleep 2
kill -INT $PID
# Verify no artifacts remain
```