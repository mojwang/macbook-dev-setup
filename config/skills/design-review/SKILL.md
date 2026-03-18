---
name: design-review
description: Design system compliance, visual hierarchy, and healthcare UX checks. Activates on component/style changes.
user-invocable: false
allowed-tools: Read, Grep, Glob, Bash, LSP
---

# Design Review Skill

## Token Compliance
- Flag hardcoded hex/rgb colors in classNames or inline styles (should use design tokens or CSS variables)
- Flag hardcoded spacing values where design tokens exist
- Flag `!important` overrides of design token values

## Component Consistency
- Flag raw HTML (`<button>`, `<input>`, `<dialog>`) where `src/components/ui/` primitives exist
- Flag duplicate component patterns (e.g., custom card markup when `Card` component available)
- Flag inconsistent variant usage across similar contexts

## Visual Hierarchy
- Competing CTAs on the same page (multiple primary-styled buttons above the fold)
- Heading level gaps (e.g., h1 → h3 with no h2)
- Body text below 16px (readability threshold)
- Insufficient contrast between adjacent sections

## Responsive Design
- Fixed widths without responsive breakpoints
- Missing `width`/`height` on images (layout shift)
- Horizontal scroll risk from absolute positioning or overflow

## Design Intentionality
- Flag default shadcn components used without domain customization (e.g., generic Card with no variant for the specific use case)
- Flag generic headings ("Our Services", "About Us", "Contact") that could belong to any website
- Flag stock-feeling visual treatments: identical card grids, centered-text-over-hero patterns, evenly-spaced three-column layouts with no hierarchy
- Flag components that lack a clear "why this treatment" justification

## Typography & Spacing Rhythm
- Flag text sizes not matching the project type scale (random `text-sm`, `text-lg` without scale reference)
- Flag spacing values off the established rhythm (e.g., `py-7` or `mt-5` when the rhythm is 4/8/12/16/24/32)
- Flag inconsistent line-height across similar text elements
- Flag heading sizes that don't follow a clear scale progression

## Animation & Interaction Quality
- Flag transitions longer than 300ms or shorter than 100ms without justification
- Flag missing `prefers-reduced-motion` respect on animations
- Flag inconsistent transition timing across similar elements (e.g., cards hover at 200ms but buttons at 400ms)
- Flag jarring state changes without transitions (hover, focus, open/close)

## Cross-Page Consistency
- Flag inconsistent section padding across pages (e.g., `py-16` on homepage but `py-12` on about)
- Flag heading style inconsistency across pages for same-level content
- Flag navigation/header/footer differences between pages
- Flag inconsistent card treatments across pages (shadow, border, padding, radius)

## Healthcare-Specific
- Provider credentials without structured data (`schema.org/MedicalBusiness`)
- Missing trust signals on conversion pages (certifications, testimonials, insurance logos)
- Phone numbers not wrapped in `tel:` links
- Medical disclaimers missing on health content pages
- Appointment CTAs not prominent on service pages

## Output Format
When issues found:
```
⚠ DESIGN: [category] in file:line
  Issue: description
  Fix: suggested remediation
```
