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
- Global CSS color rules on interactive elements (`a { color: ... }`) affect all descendants including SVG fills — verify that `currentColor` usage in nested elements resolves correctly in both themes

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

## Core Web Vitals
- LCP: largest element should load within 2.5s (check for unoptimized hero images, render-blocking resources)
- CLS: no layout shifts from images without dimensions, fonts without `font-display`, or dynamically injected content
- INP: interactive elements respond within 200ms (check for heavy `onClick` handlers, synchronous operations)

## Structured Data
- Healthcare sites: `schema.org/MedicalBusiness` on layout, `schema.org/Physician` on provider pages
- JSON-LD preferred over microdata
- Validate with Google Rich Results Test patterns

## Mobile & Viewport
- `<meta name="viewport">` with `width=device-width, initial-scale=1`
- Touch targets minimum 44x44px (WCAG 2.5.5)
- No horizontal scroll on mobile (test at 320px width)
- Phone numbers wrapped in `tel:` links

## Social & Sharing
- Open Graph tags: `og:title`, `og:description`, `og:image`, `og:url`
- Twitter Card meta tags
- Canonical URLs on all pages

## Output Format
When issues found:
```
⚠ WEB: [category] in file:line
  Issue: description
  Fix: suggested remediation
```
