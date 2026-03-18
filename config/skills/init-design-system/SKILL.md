---
name: init-design-system
description: Bootstrap shadcn/ui with domain-appropriate customizations.
disable-model-invocation: true
argument-hint: "[target-directory] [--domain healthcare|saas|ecommerce]"
allowed-tools: Bash, Read, Write
---

# Init Design System Skill

Bootstrap a design system using shadcn/ui with domain-specific customizations.

## Steps

### 1. Detect Project Setup
- Verify Next.js project with `package.json` and `tailwind.config.*`
- Check for existing `components.json` (shadcn already initialized)
- Identify existing design tokens in `globals.css` or theme files

### 2. Initialize shadcn/ui
```bash
npx shadcn@latest init  # style=new-york, CSS vars=yes, path=src/components/ui
```
- Creates `components.json`, `src/lib/utils.ts` (cn helper)
- Adds deps: `clsx`, `tailwind-merge`, `class-variance-authority`

### 3. Map Existing Tokens
- Read existing CSS custom properties from `globals.css`
- Map to shadcn CSS variable scheme (`--primary`, `--accent`, `--ring`, etc.)
- Preserve existing token names for backward compatibility
- Add shadcn variables alongside existing definitions

### 3.5. Typography Scale
Define heading and body type scale as CSS custom properties. Use a modular scale (1.25 ratio for healthcare, 1.2 for SaaS):
```css
/* Healthcare defaults: 18px base, 1.6 line-height */
--text-xs: 0.75rem;     /* 12px — captions, legal */
--text-sm: 0.875rem;    /* 14px — small labels */
--text-base: 1.125rem;  /* 18px — body text */
--text-lg: 1.25rem;     /* 20px — lead text */
--text-xl: 1.5rem;      /* 24px — h4 */
--text-2xl: 1.875rem;   /* 30px — h3 */
--text-3xl: 2.25rem;    /* 36px — h2 */
--text-4xl: 3rem;       /* 48px — h1 */
--leading-tight: 1.25;
--leading-normal: 1.6;
--leading-relaxed: 1.75;
```

### 3.6. Spacing Scale
Define a spacing rhythm based on a 4px base unit as CSS custom properties:
```css
--space-1: 0.25rem;  /* 4px */
--space-2: 0.5rem;   /* 8px */
--space-3: 0.75rem;  /* 12px */
--space-4: 1rem;     /* 16px */
--space-6: 1.5rem;   /* 24px */
--space-8: 2rem;     /* 32px */
--space-12: 3rem;    /* 48px */
--space-16: 4rem;    /* 64px */
--space-24: 6rem;    /* 96px */
```

### 4. Install Baseline Components
```bash
npx shadcn@latest add button card input label badge separator sheet navigation-menu
```

### 5. Apply Domain Variants

**Healthcare** (`--domain healthcare`):
- Button: `trust` variant (calming primary color, larger padding — for "Book Appointment")
- Card: `service` variant (matches service listing patterns)
- Badge: `credential` variant (for provider credentials, certifications)

**SaaS** (`--domain saas`):
- Button: `cta` variant (high-contrast, prominent)
- Card: `pricing` variant (featured tier highlight)
- Badge: `plan` variant (tier labels)

**Ecommerce** (`--domain ecommerce`):
- Button: `buy` variant (action-oriented, urgency colors)
- Card: `product` variant (image-forward layout)
- Badge: `sale` variant (discount/promo labels)

### 6. Create Documentation
Generate `docs/design/design-system.md` with:
- Token mapping reference
- Component inventory with variants
- Usage guidelines and migration notes

Generate `docs/design/tokens.md` with:
- Full color token inventory (semantic name → value → usage)
- Typography scale reference with usage guidance (h1-h6, body, small, caption)
- Spacing scale reference with common patterns (section padding, card gaps, form spacing)
- Mapping from raw Tailwind classes to semantic tokens for migration

## Verification
- `npm run build` passes
- `npm run lint` passes
- No visual regressions (manual check or Playwright screenshot comparison)
