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
