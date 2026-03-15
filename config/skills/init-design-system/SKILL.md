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

## Verification
- `npm run build` passes
- `npm run lint` passes
- No visual regressions (manual check or Playwright screenshot comparison)
