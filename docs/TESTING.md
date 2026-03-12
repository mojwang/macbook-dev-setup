# Testing Guide

## Philosophy: Specification-First Testing

Tests validate what code **should do**, not what it **currently says**.

Every test must answer: "If the implementation changed but the behavior stayed correct, would this test still pass?" If the answer is no, the test is coupled to implementation — not behavior.

### The Test Theater Anti-Pattern

"Test theater" is when tests verify how code is written rather than what it does. These tests create false confidence while catching zero real bugs.

**Before (theater):**
```bash
# Reads source code and checks it contains a string — proves nothing
font_script=$(cat "$ROOT_DIR/scripts/setup-terminal-fonts.sh")
assert_contains "$font_script" 'configure_iterm2()' "Should have iTerm2 function"
```

**After (behavioral):**
```bash
# Actually runs the function and checks the outcome
output=$(configure_iterm2 2>&1)
assert_equals "0" "$?" "configure_iterm2 should succeed"
```

**Red flags** that a test is theater:
- `cat some_script.sh` followed by `assert_contains`
- `grep -q "function_name" script.sh`
- `assert_true "true"` (always passes, tests nothing)
- Testing documentation content instead of command output

## Running Tests

```bash
./tests/run_tests.sh              # All tests (sequential)
./tests/run_tests.sh unit         # Unit tests only
./tests/run_tests.sh integration  # Integration tests only
./tests/run_tests.sh ci           # CI-specific tests

./tests/run_tests_parallel_simple.sh  # All tests (parallel, faster)
```

## Test Organization

- **Unit Tests** (`tests/unit/`): Test individual functions and library behavior
- **Integration Tests** (`tests/integration/`): Test script interactions and project init workflows
- **CI Tests** (`tests/ci/`): Tests specific to CI environment

## Writing Tests

### Behavioral Test (default)

Source a library, call its functions, check outcomes:

```bash
#!/usr/bin/env bash
source "$(dirname "$0")/../test_framework.sh"
source "$ROOT_DIR/lib/common.sh"

describe "Common Library"

it "should detect existing commands"
assert_true "command_exists bash" "bash should exist"
assert_false "command_exists nonexistent_cmd_xyz" "fake command should not exist"

it "should validate with correct exit codes"
assert_exit_code "0" "command_exists bash" "bash detection exits 0"
assert_exit_code "1" "command_exists nonexistent_cmd_xyz" "missing cmd exits 1"
```

### Integration Test with Sandbox

For tests that modify files, use `create_sandbox` for isolation:

```bash
#!/usr/bin/env bash
source "$(dirname "$0")/../test_framework.sh"

describe "Dotfile Installation"

it "should install config to target directory"
create_sandbox
cp "$ROOT_DIR/dotfiles/.config/starship.toml" "$SANDBOX_HOME/.config/starship.toml" 2>/dev/null
# ... run install logic ...
assert_file_exists "$SANDBOX_HOME/.config/starship.toml" "Config should be installed"
assert_file_contains "$SANDBOX_HOME/.config/starship.toml" "[character]" "Should have character section"
destroy_sandbox
```

### Repo Inventory Test

File existence checks that verify required project files are present. Label them clearly:

```bash
describe "Repo Inventory: Zsh Modules"

it "should have all required zsh modules"
assert_file_exists "$ROOT_DIR/dotfiles/.config/zsh/00-homebrew.zsh" "Homebrew module"
assert_file_exists "$ROOT_DIR/dotfiles/.config/zsh/10-languages.zsh" "Languages module"
```

## Framework Reference

### Assertions

| Function | Use For |
|----------|---------|
| `assert_equals(expected, actual, msg)` | Exact value comparison |
| `assert_true(condition, msg)` | Condition evaluation |
| `assert_false(condition, msg)` | Inverse condition |
| `assert_contains(haystack, needle, msg)` | Substring in a string variable |
| `assert_not_contains(haystack, needle, msg)` | Substring absent |
| `assert_file_exists(path, msg)` | File exists on disk |
| `assert_directory_exists(path, msg)` | Directory exists |
| `assert_command_exists(cmd, msg)` | Command in PATH |
| `assert_empty(value, msg)` | Empty string |
| `assert_not_empty(value, msg)` | Non-empty string |
| `assert_exit_code(expected, cmd, msg)` | Command exit code |
| `assert_file_contains(file, needle, msg)` | String in file on disk |

### Helpers

| Function | Purpose |
|----------|---------|
| `describe(name)` | Print test suite header |
| `it(name)` | Print individual test name |
| `skip_test(reason)` | Skip with message |
| `mock_command(name, output, exit_code)` | Override a command |
| `cleanup_mocks(names...)` | Remove mock overrides |
| `create_sandbox()` | Create isolated temp dir (`$SANDBOX_DIR`, `$SANDBOX_HOME`) |
| `destroy_sandbox()` | Clean up sandbox |

## Anti-Patterns

1. **Never grep source code to test behavior** — run the code instead
2. **Never `assert_true "true"`** — if it always passes, it tests nothing
3. **Never test documentation content** — docs change independently of behavior
4. **Never duplicate behavioral tests with structural ones** — if you test that `setup.sh preview` works, don't also grep `setup.sh` for the word "preview"
5. **Label inventory checks honestly** — `assert_file_exists` for project structure is valid, but call it "Repo Inventory", not "Unit Test"
