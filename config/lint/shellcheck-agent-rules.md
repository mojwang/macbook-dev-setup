# ShellCheck Agent Remediation Rules

When flagging or encountering these shellcheck warnings, include the concrete fix in your output.

## Most Common

| Code | Issue | Fix |
|------|-------|-----|
| SC2086 | Double quote to prevent globbing and word splitting | `"$var"` not `$var` |
| SC2046 | Quote command substitution to prevent word splitting | `"$(command)"` not `$(command)` |
| SC2034 | Variable appears unused | Remove it, or export it, or prefix with `_` if intentionally unused |
| SC2155 | Declare and assign separately to avoid masking return values | `local var` then `var=$(cmd)` on next line |
| SC2164 | Use `cd ... \|\| exit` in case cd fails | `cd "$dir" \|\| exit 1` |
| SC2128 | Expanding an array without index only gives first element | `"${array[@]}"` not `$array` |
| SC2206 | Quote to prevent word splitting or use mapfile | `mapfile -t arr < <(cmd)` |
| SC2162 | read without -r will mangle backslashes | `read -r var` |
| SC2236 | Use `-n` instead of `! -z` | `[[ -n "$var" ]]` not `[[ ! -z "$var" ]]` |
| SC2250 | Prefer `${var}` over `$var` for clarity in strings | Use braces when adjacent to other text |

## Structural

| Code | Issue | Fix |
|------|-------|-----|
| SC2148 | Tips depend on target shell, add shebang | `#!/usr/bin/env bash` as first line |
| SC1090 | Can't follow non-constant source | Add `# shellcheck source=path/to/file` directive |
| SC2154 | Variable referenced but not assigned | Either assign it or declare it as an expected env var with a comment |

## Best Practices (project conventions)

| Pattern | Convention |
|---------|-----------|
| Shebang | `#!/usr/bin/env bash` (never `#!/bin/bash`) |
| Error handling | `set -e` near top of every script |
| Cleanup | Use `trap cleanup EXIT` for temp files |
| Timeouts | Add `--max-time` to curl, `timeout` to long commands |
| Logging | Use `echo "PREFIX: message"` with consistent prefixes |
