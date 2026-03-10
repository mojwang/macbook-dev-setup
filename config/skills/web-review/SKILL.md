---
name: web-review
description: Web-specific review for accessibility, SEO, performance, and content accuracy. Activates on component/page changes.
user-invocable: false
allowed-tools: Read, Grep, Glob, Bash, LSP
---

# Web Review Skill

## Accessibility Checks
- Every `<img>` has meaningful `alt` text (or `alt=""` for decorative)
- Form inputs have `<label>` with matching `htmlFor`/`id`
- Interactive elements (buttons, links) have visible or aria labels
- Heading hierarchy is sequential (no skipping h1 → h3)
- Focus states visible on all interactive elements
- Color is not the sole indicator of meaning

## SEO Checks
- Every page exports `metadata` with unique `title` and `description`
- `title` under 60 chars, `description` under 160 chars
- Only one `<h1>` per page
- Semantic landmarks: `<header>`, `<main>`, `<footer>`, `<nav>`
- Internal links use `next/link`, not `<a>` tags

## Performance Checks
- Images use `next/image` (not raw `<img>`)
- Large components lazy-loaded where appropriate
- No unnecessary `"use client"` directives
- Data imports are tree-shakeable (named exports)

## Output Format
When issues found:
```
⚠ WEB: [category] in file:line
  Issue: description
  Fix: suggested remediation
```
