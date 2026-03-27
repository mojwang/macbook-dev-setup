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
- In themed projects, use `var(--color-*)` tokens for SVG `fill` and `stroke` — never `currentColor`, which inherits unpredictably through the CSS cascade (especially inside `<a>` tags with global color overrides)
- When SVGs need theme-awareness, prefer inline SVGs over external files — external SVGs are sandboxed documents that cannot read the page's CSS custom properties or inherit `color`

## Error Handling
- Server components: let errors bubble to `error.tsx` boundaries
- Client components: `try/catch` in event handlers, show user-facing feedback
- API calls: handle network errors, show meaningful messages, never silently swallow
- Form validation: validate on submit, show inline errors per field, use `aria-invalid`

## Async & Data Patterns
- Server components: `async` function with direct `fetch()` or DB queries — no `useEffect` for data
- Client components: use `useTransition` for non-urgent updates, `useOptimistic` for instant feedback
- Server Actions: use `"use server"` functions for mutations, call from `action` prop or `startTransition`
- Cache: use Next.js `fetch` cache options or `unstable_cache` for expensive operations

## State Management
- Server state: keep in server components, pass via props — no client-side duplication
- Client state: `useState` for local, lift to nearest shared parent, Context for cross-tree
- URL state: use `searchParams` for filterable/shareable state (pagination, filters, sort)
- Avoid external state libraries unless complexity justifies it

## Testing Patterns
- Unit tests: Vitest + Testing Library — test behavior, not implementation
- Use `screen.getByRole`, `getByText`, `getByLabelText` — never query by class name
- Mock only external boundaries (API calls, browser APIs) — never mock internal modules
- Data files: test that exports match expected schema and constraints
- Pages: test that key content renders, links work, metadata is correct
