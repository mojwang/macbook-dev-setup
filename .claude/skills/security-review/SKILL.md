# Security Review Skill

Auto-invoked when reviewing code, creating PRs, or auditing security.

## When to Activate
- Reviewing code changes (PRs, diffs, commits)
- Writing or editing code that handles user input, auth, or file access
- Security-focused sub-agent tasks

## Checks

### Shell Injection
- Flag unquoted variables in command substitutions: `$(cmd $var)` → `$(cmd "$var")`
- Flag `eval` usage — suggest alternatives (arrays, `command`)
- Flag `xargs` without `-0` on untrusted input
- Check for command injection via string interpolation

### Secret/Credential Detection
- Hardcoded API keys, tokens, passwords in source
- `.env` files or credential files staged for commit
- Base64-encoded secrets in config files
- Private keys committed to repo

### File Access Patterns
- Path traversal vulnerabilities (`../` in user-controlled paths)
- Unsafe temp file creation (use `mktemp` instead)
- World-readable permissions on sensitive files
- Symlink following attacks

### OWASP Top 10 (for web code)
- SQL injection (string concatenation in queries)
- XSS (unescaped output in templates/HTML)
- CSRF (missing token validation)
- Insecure deserialization
- Broken authentication patterns

## Output Format
When issues found, report as:
```
⚠️ SECURITY: [category] in file:line
  Issue: description
  Fix: suggested remediation
```
