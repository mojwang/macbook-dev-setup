---
name: typescript-conventions
description: TypeScript and React conventions for Next.js App Router projects. Enforces strict types, component patterns, and Tailwind usage. Activates on .ts/.tsx file edits.
user-invocable: false
allowed-tools: Read, Grep, Glob, Bash, LSP
---

# TypeScript & React Conventions

## TypeScript
- Strict mode enabled — no `any` types, no `@ts-ignore`
- Prefer `interface` over `type` for object shapes
- Export types alongside their implementations
- Use `as const` for literal objects (e.g., site config, navigation)
- Prefer named exports for components, default exports only for page/layout files

## React / Next.js App Router
- Server components by default — only add `"use client"` when hooks or interactivity needed
- Props interfaces named `{ComponentName}Props`
- No inline styles — use Tailwind classes
- Semantic HTML: `<section>`, `<nav>`, `<article>`, `<main>`, not `<div>` soup
- Images via `next/image` with explicit width/height or fill
- Links via `next/link` for internal routes
- Metadata exports in page files for SEO

## Content & Data
- All user-facing text lives in `/src/data/` — never hardcode in components
- Data files export typed constants and interfaces
- Components receive data via props, not direct imports (except page-level)

## Accessibility (WCAG 2.1 AA)
- All interactive elements need accessible names (aria-label or visible text)
- Form inputs require associated `<label>` elements
- Color contrast ratio minimum 4.5:1 for normal text
- Skip navigation link for keyboard users
- Alt text for all images (empty string for decorative)

## Tailwind CSS
- Mobile-first: base styles for mobile, `sm:` / `md:` / `lg:` for larger
- Use design tokens from globals.css `@theme` (e.g., brand colors)
- Prefer `gap` over margins between flex/grid children
- Max width containers: `mx-auto max-w-7xl px-4`
