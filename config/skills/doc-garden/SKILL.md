---
name: doc-garden
description: Run when changes affect docs/, CLAUDE.md, or markdown files in skill directories. Validates internal links, catches stale references, and flags duplicated content.
user-invocable: false
allowed-tools: Read, Grep, Glob, Bash
---

# Doc Garden

Validate documentation freshness and consistency. Run mechanical checks first, then interpret results.

## Scan Sequence

### 1. Run scripts
- `scripts/check-internal-links.sh` — verify file path references in markdown resolve
- `scripts/find-stale-todos.sh` — find TODOs older than 30 days
- `scripts/check-duplicates.sh` — find identical paragraphs across markdown files

### 2. Additional checks (model-driven)
- References to deleted routes, pages, or components
- Version numbers that don't match package.json
- CLAUDE.md sections that reference files/directories that don't exist
- Skill descriptions that don't match their SKILL.md body content
- Orphaned docs (markdown files not referenced from any index or CLAUDE.md)

### 3. Produce report
```
## Doc Garden Report — [date]

### Broken links
- [file:line] references [path] (not found)

### Stale content
- [file:line] description

### Duplicates
- [file1:line] and [file2:line] share identical content
```

### 4. Auto-fix
For broken links and outdated version numbers, offer concrete fixes. For duplicates and stale content, report only — human decides which copy to keep.

## Rules
- Don't flag README.md links to external URLs (those need network to verify)
- Don't flag intentional content repetition (e.g., the same rule appearing in CLAUDE.md and a skill)
- Keep the report concise — group related findings
