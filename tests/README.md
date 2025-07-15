# macOS Dev Setup - Test Suite Documentation

This directory contains the comprehensive test suite for the macOS development environment setup scripts.

## Test Framework

### Core Framework (`test_framework.sh`)
The test framework provides assertion functions and test organization utilities:

- **Assertions**: `assert_equals`, `assert_true`, `assert_false`, `assert_contains`, `assert_empty`
- **File/Directory**: `assert_file_exists`, `assert_directory_exists`, `assert_command_exists`
- **Test Organization**: `describe`, `it`, `test_case`
- **Test Control**: `skip_test`, `pass_test`, `fail_test`
- **Mocking**: `mock_command`, `cleanup_mocks`

## Test Files

### 1. `test_common.sh`
Tests the common library functions:
- Command detection
- Email validation
- macOS and Apple Silicon detection
- Utility functions

### 2. `test_setup.sh`
Tests the main setup script functionality:
- Command-based structure (v2.0)
- Integration of old flag functionality into new system
- Command documentation in help and CLAUDE.md
- State detection

### 3. `test_warp_detection.sh`
Tests Warp Terminal detection and setup:
- Detection via TERM_PROGRAM
- Detection via installed app
- Detection via command
- SETUP_NO_WARP environment variable
- Font conflict handling

### 4. `test_sync_integration.sh`
Tests package synchronization and v2.0 features:
- Help system completeness
- Sync functionality preservation
- Brewfile.minimal existence
- Modular zsh configuration
- Lazy loading implementations
- Environment variable support
- Documentation completeness

### 5. `test_backup_system.sh`
Tests the organized backup system:
- Directory structure creation
- Backup creation with timestamps
- Latest symlink management
- Old backup cleanup (10 file limit)
- Old backup migration
- Metadata handling
- Permission preservation

### 6. `test_command_structure.sh`
Tests the new command structure:
- Help command variations (-h, --help)
- Preview command and delegation
- Environment variable handling
- Backup subcommands
- Fix/diagnostics command
- Invalid command handling
- Advanced menu existence
- Backwards compatibility

### 7. `test_v2_features.sh`
Tests v2.0 specific features:
- Preview mode functionality
- Fix command execution
- Minimal installation support
- Advanced options menu
- Smart state detection
- Warp command availability
- Performance optimizations
- Git commit helpers

### 8. `test_new_commands.sh`
Tests new command implementations:
- Command recognition
- Proper execution flow
- Error handling

### 9. `test_migration_guide.sh`
Tests migration from v1.x to v2.0:
- Help guides users to new commands
- Old flags show usage help
- Documentation explains changes
- Feature mapping (--dry-run → preview, etc.)
- Examples use new syntax
- Automatic sync/update detection

## Validation Scripts

### `setup-validate.sh`
Fast validation and preview script that:
- Detects setup state (fresh vs update)
- Validates prerequisites
- Checks configuration files
- Shows what would be installed
- Validates backup system
- Checks Warp detection
- Runs diagnostics preview
- Validates environment variables
- Checks command structure

### `validate_implementation.sh`
Comprehensive implementation validation that checks:
- Command structure implementation
- Warp detection logic
- Font conflict handling
- Function fallbacks
- State detection
- Environment variable support
- Core functionality preservation
- Warp optimization safety
- Documentation updates
- Syntax validation
- Backup system integration
- Diagnostics implementation
- Commit helper tools
- Performance optimizations

## Running Tests

### Run All Tests
```bash
./tests/run_tests.sh
```

### Run Specific Test
```bash
./tests/test_backup_system.sh
```

### Run Validation
```bash
./setup.sh preview              # Quick validation
./tests/validate_implementation.sh  # Full implementation check
```

### Run Pre-Push Checks
```bash
./scripts/pre-push-check.sh
```

## Test Coverage

The test suite covers:
- ✅ Core setup functionality
- ✅ All new v2.0 commands
- ✅ Backup system operations
- ✅ Warp Terminal detection
- ✅ Package synchronization
- ✅ Environment variables
- ✅ Error handling
- ✅ Performance features
- ✅ Documentation completeness
- ✅ Backwards compatibility

## Writing New Tests

1. Create a new test file: `test_feature.sh`
2. Source the test framework:
   ```bash
   source "$(dirname "$0")/test_framework.sh"
   ```
3. Use `describe` to group tests:
   ```bash
   describe "Feature Tests"
   ```
4. Use `it` for individual tests:
   ```bash
   it "should do something"
   assert_equals "$result" "expected" "Test description"
   ```
5. The test will automatically be picked up by `run_tests.sh`

## CI Integration

The test suite is designed to work in CI environments:
- Exit codes: 0 for success, 1 for failure
- Colored output for visibility
- Summary reports
- No interactive prompts
- Fast execution (validation uses optimized script)

## Performance

- `setup-validate.sh`: Optimized for speed (6x faster than full setup)
- Parallel test execution where possible
- Lazy loading tests verify performance features
- Minimal external dependencies