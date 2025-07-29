# Global Claude Code Instructions

This file provides baseline guidance to Claude Code across all projects. Project-specific instructions in local CLAUDE.md files will override or extend these.

## Communication Style

- Be direct, concise, and honest - avoid sycophantic or overly deferential language
- Provide constructive feedback when something could be improved
- Challenge assumptions when they might lead to problems
- Keep responses focused and to the point

## Development Standards

- Follow shell scripting best practices with consistent error handling
- Use color-coded output for different message types (success=green, warning=yellow, error=red, dry-run=cyan)
- All scripts should use `set -e` for fail-fast behavior
- Add timeout protection (30s) for potentially hanging commands
- Configure Git with security-conscious settings (fsckObjects enabled)

## Safety Principles

- Comprehensive prerequisite validation before any system changes
- Automatic backup of existing files before replacement
- Provide dry-run/preview modes for all destructive operations
- Detailed error handling with recovery options
- Optional logging for troubleshooting
- Signal-safe cleanup handlers for all system-modifying scripts
- Atomic file operations to prevent partial writes

## File Organization

- Use modular configuration approach when possible
- Separate concerns into focused, single-purpose files
- Support local overrides through gitignored files
- Prefer configuration over hardcoding

## Code Style

- Match existing code conventions in the project
- Use existing libraries and utilities rather than reinventing
- Follow established patterns in the codebase
- Never add comments unless explicitly requested
- Never introduce code that exposes or logs secrets

## Testing Requirements

- Practice test-driven development (TDD) whenever possible:
  - Write tests first to define expected behavior
  - Implement the minimum code needed to make tests pass
  - Refactor while keeping tests green
  - If TDD isn't feasible, explain why and write tests immediately after implementation
- Always add tests for new functionality, features, scripts, components, capabilities, or code
- Write unit tests for isolated functionality
- Write integration tests for features that interact with other components
- Ensure tests pass before considering a feature complete
- Follow existing test patterns and frameworks in the project
- If no test framework exists, suggest adding one before implementing features
- Run existing tests before making changes to ensure you don't break functionality

## Git Workflow

- Always create a new feature branch from the main/master branch before making changes
- Use descriptive branch names (e.g., `feat/add-login`, `fix/memory-leak`, `docs/update-readme`)
- Never commit directly to the main/master branch
- Commit complete implementations frequently to keep diffs small and readable:
  - Commit after each logical unit of work is complete and tested
  - Aim for diffs under 200 lines when possible
  - Break large features into smaller, incremental commits
  - Each commit should represent a working state of the code
  - Prefer multiple small commits over one large commit
- When asked to commit changes, also create a pull request unless explicitly told not to
- Follow conventional commit message formats when they exist in the project
- Keep commits focused and atomic - one logical change per commit

## Security Practices

- Always quote variables in shell scripts: `"$var"` not `$var`
- Validate and sanitize all user inputs
- Use `mktemp` for temporary files with restrictive permissions
- Never store secrets in code or logs
- Clean up sensitive data from memory/disk after use
- Implement proper signal handling for cleanup on interruption
- Use secure defaults and fail closed, not open

## Important Behavioral Guidelines

- Do only what has been asked; nothing more, nothing less
- Never create files unless absolutely necessary for the task
- Always prefer editing existing files over creating new ones
- Never proactively create documentation files (*.md) or README files unless explicitly requested
- Never commit changes unless explicitly asked to
- When blocked, ask for clarification rather than making assumptions