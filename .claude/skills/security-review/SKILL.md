---
name: security-review
description: Security review checks for shell injection, secrets, file access vulnerabilities, and OWASP top 10. Use when reviewing code changes, PRs, diffs, commits, or editing code that handles user input, auth, or file access.
user-invocable: false
allowed-tools: Read, Grep, Glob, Bash
---

# Security Review Skill

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

## Vault Privacy Extension (Pillar 12)

**Active only when invoked on a vault note** (path matches `vault/**/*.md` or workspace's vault directory). Especially fires on PreToolUse hook when an Edit operation flips a note's frontmatter `public: false` → `public: true` — last-mile gate before private→public flow into mojwang.tech via `sync-vault.ts`.

### Allowlist (public-OK references — do NOT flag)

- "Netflix" as employer reference
- Marvin's public role: "Sr Engineering Manager", "DVX Live UI", "DVX Live"
- Public initiatives Netflix has announced (live streaming launch dates publicly disclosed; SDUI publicly published)
- Public talks Marvin has given (titles, venues, conference names)
- Open-source projects Marvin maintains
- General industry concepts ("server-driven UI", "platform engineering")

### Blocklist (flag for review — content might leak)

- **Internal team names / codenames / project codes** — capitalized acronyms or proper nouns adjacent to "team" / "project" / "initiative" that aren't in the allowlist. Pattern: `\b[A-Z]{2,}[a-z]?\s+(team|project|initiative)\b`
- **Specific reports' or peers' names** — first-name or full-name references in performance / capability / personnel context. Cross-reference against vault's known public colleagues; flag any name that isn't.
- **Salary / metric leaks**:
  - Currency adjacent to budget context: `\$\d{2,3}[KMB]\b`
  - Percent metrics adjacent to "team", "headcount", "budget", "attrition"
  - Headcount numbers (e.g., "team of 12") if specific to non-public team
- **Internal tooling specifics** — proprietary system names, internal URL hostnames, internal slack channel names
- **Quoted blocks without attribution** — long quoted text without source citation suggests potentially-third-party material

### Verdict format

```
⚠️ VAULT-PRIVACY: [category] at line N
  Content: "<excerpt>"
  Issue: <which blocklist pattern matched>
  Fix: <recommend rewording, removal, or generalizing>
```

If no blocklist matches: report `✓ Vault-privacy: clean` with the count of allowlist references found (visibility, not flag).

Blocking when fired by the PreToolUse hook on `public: true` flip. Marvin must address each finding before the Edit completes.
