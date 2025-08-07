# Claude Sub-Agents Guide

This document defines the sub-agent architecture for the macbook-dev-setup project, enabling specialized task delegation for improved code quality, security, and maintainability.

## Overview

Claude Code's Task tool enables launching specialized agents for complex, multi-step operations. Each agent runs autonomously and returns results, allowing for parallel execution and domain-specific expertise.

## Core Agents

### 1. Quality & Testing Agent
**Purpose**: Ensure code quality and test coverage  
**Triggers**:
- After implementing new features
- Before merging PRs
- When modifying test files

**Responsibilities**:
- Run test suites (`./tests/run_tests.sh`)
- Validate idempotency of scripts
- Check test coverage
- Verify performance benchmarks
- Ensure TDD/BDD/SDD compliance

**Example Activation**:
```
"Run quality checks and ensure all tests pass for the recent changes"
```

### 2. Security Analysis Agent
**Purpose**: Identify and remediate security vulnerabilities  
**Triggers**:
- Before commits involving sensitive operations
- When handling API keys or credentials
- During shell script creation/modification

**Responsibilities**:
- Scan for hardcoded secrets
- Validate secure API key handling
- Check file permissions
- Analyze shell script security patterns
- Verify sudo usage minimization

**Example Activation**:
```
"Perform security analysis on the MCP server configuration scripts"
```

### 3. Development Agent
**Purpose**: Implement features and refactor code  
**Triggers**:
- Feature requests
- Code refactoring needs
- Bug fixes

**Responsibilities**:
- Add new installation scripts
- Refactor existing components
- Implement feature enhancements
- Fix identified bugs
- Maintain code consistency

**Example Activation**:
```
"Implement a new installer for Docker Desktop with proper error handling"
```

## Specialized Agents

### 4. Shell Script Specialist Agent
**Purpose**: Optimize and validate shell scripts  
**Triggers**:
- Creating new shell scripts
- Modifying existing scripts
- Performance optimization requests

**Responsibilities**:
- Validate POSIX compliance
- Ensure signal safety (`set -e`, trap handlers)
- Optimize parallel execution
- Check for shellcheck compliance
- Implement proper error handling

**Example Activation**:
```
"Review and optimize the parallel execution in setup.sh"
```

### 5. Dependency Management Agent
**Purpose**: Manage and update project dependencies  
**Triggers**:
- Weekly dependency checks
- Security vulnerability alerts
- Version compatibility issues

**Responsibilities**:
- Track Homebrew package updates
- Monitor npm/pnpm dependencies
- Check Python/uv packages
- Identify security vulnerabilities
- Verify version compatibility

**Example Activation**:
```
"Check for outdated dependencies and security vulnerabilities in Brewfile"
```

### 6. Configuration Validator Agent
**Purpose**: Ensure configuration consistency  
**Triggers**:
- Dotfile modifications
- MCP server configuration changes
- VS Code settings updates

**Responsibilities**:
- Validate Zsh module syntax
- Check dotfile symlinks
- Verify MCP server configs
- Test VS Code extensions
- Ensure configuration idempotency

**Example Activation**:
```
"Validate all Zsh configuration modules and check for conflicts"
```

### 7. Documentation Sync Agent
**Purpose**: Maintain accurate documentation  
**Triggers**:
- After code changes
- Before releases
- Command additions/modifications

**Responsibilities**:
- Update COMMANDS.md
- Maintain CHANGELOG.md
- Sync inline documentation
- Generate API references
- Update README sections

**Example Activation**:
```
"Update documentation to reflect the new MCP server configurations"
```

### 8. CI/CD & Release Agent
**Purpose**: Manage continuous integration and releases  
**Triggers**:
- Pre-release preparation
- CI pipeline failures
- Version bumps

**Responsibilities**:
- Manage semantic versioning
- Coordinate GitHub Actions
- Handle release notes
- Update VERSION file
- Ensure CI compliance

**Example Activation**:
```
"Prepare for a new release with proper versioning and changelog"
```

### 9. Performance Optimization Agent
**Purpose**: Optimize system performance  
**Triggers**:
- Slow script execution
- Shell startup delays
- Resource usage concerns

**Responsibilities**:
- Profile script execution
- Optimize parallel job distribution
- Reduce shell startup time (<100ms)
- Benchmark critical paths
- Implement caching strategies

**Example Activation**:
```
"Optimize shell startup time and identify bottlenecks"
```

### 10. Backup & Recovery Agent
**Purpose**: Manage backup strategies  
**Triggers**:
- Before major changes
- Backup integrity checks
- Restore operations

**Responsibilities**:
- Create system backups
- Verify backup integrity
- Test restore procedures
- Manage backup rotation
- Document recovery steps

**Example Activation**:
```
"Create a backup of current configuration and test restore procedure"
```

### 11. MCP Integration Agent
**Purpose**: Manage Model Context Protocol servers  
**Triggers**:
- MCP server installation
- Configuration updates
- Connection issues

**Responsibilities**:
- Configure MCP servers
- Debug connection issues
- Manage API keys securely
- Test server integrations
- Update server versions

**Example Activation**:
```
"Debug why the Figma MCP server is failing to connect"
```

### 12. macOS Environment Agent
**Purpose**: Handle macOS-specific configurations  
**Triggers**:
- macOS version updates
- Apple Silicon compatibility checks
- System preference changes

**Responsibilities**:
- Verify Apple Silicon support
- Test Warp Terminal features
- Configure macOS defaults
- Handle Gatekeeper issues
- Manage system extensions

**Example Activation**:
```
"Verify all scripts work correctly on macOS Sequoia"
```

## Agent Coordination Patterns

### Sequential Execution
When tasks have dependencies:
```
1. Development Agent → implements feature
2. Shell Script Agent → optimizes implementation  
3. Security Agent → validates security
4. Quality Agent → runs tests
5. Documentation Agent → updates docs
```

### Parallel Execution
For independent tasks:
```
Parallel:
- Quality Agent: Run test suite
- Security Agent: Scan for vulnerabilities
- Performance Agent: Benchmark execution
```

### Triggered Cascades
Automatic agent activation:
```
On PR creation:
→ Quality Agent (tests)
→ Security Agent (if shell scripts modified)
→ Documentation Agent (if commands changed)
```

## Usage Guidelines

### When to Use Agents

1. **Always use agents for**:
   - Security-sensitive operations
   - Performance-critical changes
   - Complex multi-step tasks
   - Cross-cutting concerns

2. **Consider agents for**:
   - Routine maintenance
   - Dependency updates
   - Configuration changes
   - Documentation updates

### Agent Communication

Agents should:
- Return structured results
- Include actionable recommendations
- Flag critical issues immediately
- Provide clear success/failure status

### Best Practices

1. **Be Specific**: Provide clear, detailed instructions to agents
2. **Use Parallel**: Launch multiple agents concurrently when possible
3. **Chain Wisely**: Use sequential agents only when dependencies exist
4. **Monitor Results**: Always review agent outputs before proceeding
5. **Document Patterns**: Record successful agent workflows for reuse

## Integration with Project Workflow

### Git Hooks
```bash
# .git/hooks/pre-commit
# Trigger: Security Agent for shell scripts
# Trigger: Quality Agent for test files

# .git/hooks/pre-push  
# Trigger: Full Quality Agent suite
# Trigger: Documentation sync check
```

### CI/CD Pipeline
```yaml
# .github/workflows/ci.yml
steps:
  - name: Security Analysis
    # Runs Security Agent
  
  - name: Quality Checks
    # Runs Quality Agent
    
  - name: Performance Tests
    # Runs Performance Agent
```

### Manual Triggers
```bash
# Helper scripts for manual agent activation
./scripts/claude-agents/run-security-check.sh
./scripts/claude-agents/run-quality-suite.sh
./scripts/claude-agents/optimize-performance.sh
```

## Configuration

Agents respect project configuration in:
- `CLAUDE.md` - Project-specific instructions
- `.claude-agents.json` - Agent configuration
- `.github/workflows/` - CI/CD integration
- `tests/agents/` - Agent test suites

## Monitoring & Metrics

Track agent effectiveness:
- Task completion time
- Issues caught/prevented
- Code quality improvements
- Performance gains
- Security vulnerabilities found

## Future Enhancements

Planned agent capabilities:
- Cross-platform testing agent (Linux support)
- Containerization agent (Docker configs)
- Accessibility testing agent
- Localization support agent
- Plugin development agent

## Troubleshooting

Common issues and solutions:

### Agent Not Activating
- Check trigger conditions
- Verify agent configuration
- Review CLAUDE.md instructions

### Agent Timeout
- Break task into smaller chunks
- Increase timeout limits
- Use parallel execution

### Conflicting Agents
- Define clear boundaries
- Use coordination patterns
- Implement mutex locks

## Examples

### Example 1: Full System Update
```
User: "Update all dependencies and ensure everything still works"

Agents activated:
1. Dependency Management Agent - identifies updates
2. Development Agent - applies updates  
3. Security Agent - scans new versions
4. Quality Agent - runs full test suite
5. Documentation Agent - updates version info
```

### Example 2: New Feature Implementation
```
User: "Add support for installing Rust development tools"

Agents activated:
1. Development Agent - creates installer script
2. Shell Script Agent - optimizes script
3. Configuration Agent - updates Brewfile
4. Quality Agent - adds tests
5. Documentation Agent - updates COMMANDS.md
```

### Example 3: Performance Issue
```
User: "Shell startup is too slow, fix it"

Agents activated:
1. Performance Agent - profiles startup
2. Shell Script Agent - optimizes configs
3. Quality Agent - ensures functionality
4. Documentation Agent - records changes
```

## Conclusion

The sub-agent architecture enables specialized, efficient handling of complex tasks while maintaining code quality, security, and performance standards. By leveraging these agents appropriately, the macbook-dev-setup project can scale effectively while reducing manual overhead and potential errors.