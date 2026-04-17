# Motion Design System

Motion vocabulary for design specs. Referenced by the designer agent when specifying animations and by the implementer when building them. Library-agnostic — values work with CSS transitions, Web Animations API, or Motion/Framer Motion.

## Motion Modes

**Productive motion** — Fast, functional, task-focused. Animations that should be felt but not noticed.
Use for: Button states, dropdowns, toggles, data table sorting, form validation, tab switches, tooltip appear/dismiss.
Character: Quick, confident, invisible. The user shouldn't consciously register the animation — they should just feel that the interface is responsive.

**Expressive motion** — Enthusiastic, brand-forward. Animations that create delight and convey personality.
Use for: Page entrances, primary action confirmations, onboarding reveals, celebration moments (confetti, success), empty-state-to-content transitions.
Character: Deliberate, noticeable, intentional. The user should feel that something meaningful just happened.

**Mapping to MOTION_INTENSITY dial:**
- **1-3**: Productive only. No expressive motion. Appropriate for healthcare, finance, legal, enterprise task UIs.
- **4-6**: Productive as default, expressive for 1-2 key moments per page (hero entrance, primary CTA confirmation). Most projects live here.
- **7-10**: Expressive as primary mode. Appropriate for consumer products, portfolios, marketing sites, playful brands.

---

## Duration Scale

Synthesized from IBM Carbon, Shopify Polaris, and Material Design 3. Six tokens covering the full range of UI animation needs.

| Token | Duration | Use Case | Examples |
|-------|----------|----------|----------|
| `duration-instant` | 70ms | Micro-interactions | Toggle, checkbox, radio button |
| `duration-fast` | 110ms | Small feedback | Button press, focus ring, hover color shift |
| `duration-moderate` | 150ms | Standard transitions | Dropdown open, tab switch, tooltip appear |
| `duration-comfortable` | 240ms | Expansion animations | Accordion expand, modal enter, card flip |
| `duration-slow` | 400ms | Large movements | Page section entrance, card grid reveal, sidebar open |
| `duration-deliberate` | 700ms | Background effects | Overlay dim, skeleton shimmer, ambient pulse |

**Rules:**
- Never exceed **500ms total** for a choreographed sequence of user-initiated UI elements. Users perceive delays beyond this as sluggish.
- Background and ambient animations (shimmer, pulse, loading) can exceed 500ms — they aren't blocking interaction.
- **Distance scaling**: Short distance (< 25% viewport) → `duration-fast` to `duration-moderate`. Medium (25-50%) → `duration-moderate` to `duration-comfortable`. Long (> 50%) → `duration-slow`.
- Exit animations should be **faster** than their corresponding entrance (users don't need to watch things leave).

---

## Easing Curves

Six curves organized by animation phase (standard, entrance, exit) and motion mode (productive, expressive). Based on IBM Carbon's proven model with exact cubic-bezier values.

### Standard Easing
Element visible from start to finish. For repositioning, sorting, resizing, reordering.

- **Productive**: `cubic-bezier(0.2, 0, 0.38, 0.9)` — Smooth, efficient, no personality.
- **Expressive**: `cubic-bezier(0.4, 0.14, 0.3, 1)` — Slightly more dramatic acceleration, confident settle.

### Entrance Easing
Element appearing on screen. For modals opening, dropdowns expanding, content loading in.

- **Productive**: `cubic-bezier(0, 0, 0.38, 0.9)` — Quick appear, smooth settle. Functional.
- **Expressive**: `cubic-bezier(0, 0, 0.3, 1)` — Dramatic entrance, confident landing. Noticeable.

### Exit Easing
Element leaving screen. For modals closing, tooltips dismissing, content being removed.

- **Productive**: `cubic-bezier(0.2, 0, 1, 0.9)` — Smooth departure, quick finish.
- **Expressive**: `cubic-bezier(0.4, 0.14, 1, 1)` — Purposeful departure, accelerates out.

**Selection rule**: Pick the mode (productive/expressive) from the MOTION_INTENSITY dial. Pick the phase (standard/entrance/exit) from what the element is doing. This gives you exactly one curve per animation.

---

## Spring Physics

For gesture-driven and physics-based animations. Springs produce natural, momentum-aware motion that fixed curves cannot replicate. Use Motion (Framer Motion) or React Spring.

### When to Use Springs
- Drag interactions (cards, sliders, drawers)
- Gesture responses (swipe, pull-to-refresh, fling)
- Playful consumer products where MOTION_INTENSITY is 6+
- Layout animations where elements respond to content changes

### When NOT to Use Springs
- Healthcare, finance, legal interfaces (unless brand tone explicitly supports it)
- Micro-interactions that need to be invisible (use CSS transitions instead)
- When `prefers-reduced-motion` is active (fall back to instant or fade)

### Spring Configurations

| Name | Stiffness | Damping | Mass | Character | Use Case |
|------|-----------|---------|------|-----------|----------|
| **Default** | 100 | 15 | 1 | Responsive, no bounce | General-purpose spring when curves feel too mechanical |
| **Snappy** | 300 | 20 | 1 | Fast settle, minimal overshoot | Toggle switches, quick snap-to-position |
| **Gentle** | 80 | 20 | 1 | Slow, smooth, no overshoot | Sidebar reveals, slow content shifts |
| **Bouncy** | 150 | 8 | 1 | Visible overshoot, playful | Consumer apps, celebrations, playful contexts only |

**Rule**: Never use the Bouncy config at MOTION_INTENSITY below 7. It signals playfulness that conflicts with serious contexts.

---

## Choreography

How multiple elements animate together. Choreography turns individual animations into a cohesive motion narrative.

### Stagger Pattern
Sequential elements (list items, card grids, navigation items) enter with a fixed delay between each:
- **Stagger delay**: 20-50ms between elements (20ms for tight lists, 50ms for distinct cards)
- **Total sequence budget**: Keep the complete stagger sequence under 500ms
- **Math**: With 20ms stagger and 10 items, the last item starts at 180ms. Add the element's own animation duration (~150ms) = 330ms total. Under budget.

### Load Priority Order
When a page or section loads, elements animate in this order:
1. **Static chrome** (nav, footer) — already visible or instant
2. **Static body content** (headings, body text) — fast entrance
3. **Dynamic data** (fetched content, user-specific) — moderate entrance after data arrives
4. **Interactive elements** (buttons, forms) — appear after content establishes context
5. **Decorative effects** (background animation, ambient motion) — last, lowest priority

### Direction Rules
- Elements enter from their **semantic origin**: sidebar slides from the side, dropdown descends from trigger, modal scales from center, toast rises from bottom.
- Elements move along **grid axes** — no diagonal movements unless intentionally playful (MOTION_INTENSITY 7+).
- Scroll-triggered elements enter with **short translate** (20-30px) + fade. Not dramatic fly-ins from off-screen.

### Exit Choreography
- Exits are faster than entrances (users don't need to watch things leave)
- Stagger in reverse order (last in, first out) or collapse simultaneously
- Never block user action while exit animation plays

---

## Accessibility

Non-negotiable requirements. Every animation implementation must satisfy these.

### `prefers-reduced-motion` Support
```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

**Reduce, don't eliminate**: Replace scale/rotate/translate effects with opacity fade or instant state change. The state change itself still matters — the motion is what becomes optional.

### Motion Safety Rules
- Never communicate information **solely** through animation — provide a static alternative
- No auto-playing animations that can't be paused (WCAG 2.2.2)
- No flashing content exceeding 3 flashes per second (WCAG 2.3.1)
- Parallax and scroll-hijacking must degrade gracefully when reduced motion is active
- Spring animations with overshoot can trigger vestibular discomfort — always gate behind `prefers-reduced-motion`

---

## Implementation Priority

Choose the simplest technology that achieves the motion goal:

1. **CSS transitions** — Hover states, focus rings, color shifts, simple show/hide. Highest performance, least code.
2. **CSS animations + @keyframes** — Loading spinners, skeleton shimmer, repeating ambient effects.
3. **Web Animations API** — Programmatic control needed (play/pause/reverse), multi-step sequences, scroll-linked via ScrollTimeline.
4. **Motion / Framer Motion** — Complex choreography, gesture response, layout animations, AnimatePresence exit animations, spring physics.

**Never**: `transition: all` — always specify exact properties. `transition: all` animates properties you don't intend (padding, border, color) and creates jank.

**GPU-safe properties**: Animate only `transform` and `opacity` for composited animations. Animating `width`, `height`, `top`, `left`, `margin`, `padding` triggers layout recalculation and paint — these are expensive and cause frame drops.
