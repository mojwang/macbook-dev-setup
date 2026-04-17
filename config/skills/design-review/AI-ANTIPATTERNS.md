# AI Aesthetic Anti-Pattern Catalog

Detection catalog for recognizable AI-generated design tells. Each entry: what it looks like, why it's a tell, severity, and fix. Referenced by `design-review` and `reviewer` agents.

## Severity Tiers

- **P0 — Credibility harm**: Actively damages trust. Must fix before shipping.
- **P1 — AI fingerprint**: A designer would immediately identify this as AI-generated. Fix unless intentional and documented.
- **P2 — Lazy default**: Could be intentional but usually isn't. Flag as informational.
- **P3 — Overused pattern**: Not wrong, but worth awareness. Don't report unless pattern density is high.

---

## Color & Palette

**Purple/Cyan Gradient Palette** — P1
Looks like: Primary palette built around purple-to-cyan or purple-to-pink gradients with no brand justification.
Why it's a tell: AI models default to purple/blue spectrum. It's the "I didn't choose a color" color.
Fix: Derive palette from brand identity, audience, or domain. Healthcare → warm neutrals. Finance → navy/slate. If purple IS the brand, document why.

**Gradient Text on Headings** — P1
Looks like: CSS `background-clip: text` with gradient fill on hero headings or section titles.
Why it's a tell: Overused in AI-generated landing pages as a substitute for actual typographic personality.
Fix: Use solid color with a distinctive typeface. Typography carries identity better than color tricks.

**Neon Accents Without Context** — P2
Looks like: Bright neon green, cyan, or magenta accents on an otherwise neutral interface.
Why it's a tell: AI defaults to high-saturation accents for "modern" feel without considering domain appropriateness.
Fix: Match accent saturation to brand tone. Healthcare and finance rarely warrant neon. Developer tools sometimes do.
Context adjustment: P2 general → P3 in developer tools/gaming where neon is common convention.

**Pure Black Backgrounds** — P2
Looks like: `#000000` or `bg-black` as the primary dark mode background.
Why it's a tell: Pure black creates harsh contrast and eye strain. Professional dark modes use near-black (e.g., `#0A0A0A`, `#111`).
Fix: Use a dark gray with slight warmth or coolness matching the brand palette.

**Gray Text on Colored Backgrounds** — P1
Looks like: Medium gray (`text-gray-500`) body text placed on colored or off-white backgrounds.
Why it's a tell: AI applies the same gray regardless of background, creating readability problems.
Fix: Adjust text color for sufficient contrast ratio (4.5:1 minimum). Use the palette's designated foreground tokens.

**Low Contrast Between Adjacent Sections** — P2
Looks like: Alternating sections with barely distinguishable background colors (white → off-white → white).
Why it's a tell: AI uses subtle alternation as a layout device without checking if the difference is perceptible.
Fix: Either make the contrast meaningful (clear visual separation) or use spacing/dividers instead.

---

## Typography

**Default Inter/Roboto/Poppins** — P1
Looks like: `font-family: 'Inter'` (or Roboto, Poppins, Open Sans) with no supporting typographic decisions.
Why it's a tell: These are the fonts AI reaches for first. Using them without a deliberate type system signals "didn't choose a font."
Fix: Select a typeface that carries brand personality. If Inter IS the right choice, pair it with a distinctive display face and document the reasoning.

**Uniform Font Weights** — P1
Looks like: Every heading, subheading, and label uses the same font weight (typically `font-semibold` or `font-bold`).
Why it's a tell: Real type systems use weight variation to create hierarchy. Uniform weight = flat hierarchy.
Fix: Establish a weight scale: headings (bold/black), subheadings (semibold), body (regular), captions (light/regular). Use weight as a hierarchy tool.

**Flat Type Hierarchy** — P2
Looks like: Small step between heading sizes (e.g., h1: 32px, h2: 28px, h3: 24px — nearly indistinguishable).
Why it's a tell: AI picks conservative size steps that look "safe" but create no visual drama.
Fix: Use a modular scale (1.25 or 1.333 ratio). Ensure at least 1.5x size difference between h1 and body text.

**Oversized Hero Without Scale** — P2
Looks like: 72px+ hero heading that dwarfs everything below, with no proportional scaling of supporting text.
Why it's a tell: AI maxes out hero size without considering how it relates to the page rhythm.
Fix: Scale the entire type system proportionally. If the hero is 72px, body text, subheadings, and captions should all adjust.

---

## Layout

**Three Equal-Height Card Grid** — P1
Looks like: Exactly three cards in a row, same height, same padding, same visual weight. Usually services, features, or pricing.
Why it's a tell: The most common AI layout pattern. Every AI landing page has one.
Fix: Break symmetry intentionally — vary card sizes, use a featured/promoted card, stagger layout, or use a different information architecture entirely.

**Center-Aligned Everything** — P1
Looks like: Every section has centered text, centered headings, centered CTAs. No left-aligned content blocks.
Why it's a tell: AI defaults to centering because it's "safe." Real design uses alignment as a hierarchy tool.
Fix: Left-align body text and most content. Reserve centering for hero headings and single-line CTAs. Mix alignment intentionally.

**Monotonous Section Spacing** — P2
Looks like: Every section uses identical vertical padding (e.g., `py-16` or `py-24` on every section, no variation).
Why it's a tell: AI applies uniform spacing because it doesn't understand content rhythm.
Fix: Vary spacing based on content relationship. Tightly related sections get less space. Major topic shifts get more. Create a spacing rhythm, not a spacing constant.

**Nested Cards** — P2
Looks like: Cards inside cards inside sections with borders. Three or more depth levels of contained elements.
Why it's a tell: AI nests containers to create visual separation without understanding that each level adds cognitive overhead.
Fix: Flatten the hierarchy. Use spacing, color, or typography to separate elements instead of adding container depth.

**Generic Centered Hero** — P1
Looks like: Centered heading + subheading paragraph + two side-by-side buttons (primary + secondary). Stock image or gradient background.
Why it's a tell: This is the default hero pattern for every AI-generated landing page.
Fix: Make the hero earn its space. Use asymmetric layout, editorial photography, a single committed CTA, or skip the hero entirely if content doesn't warrant it.

---

## Visual Treatment

**Glassmorphism Without Function** — P2
Looks like: Frosted glass effects (`backdrop-blur`) on cards or modals with no functional purpose.
Why it's a tell: AI applies glassmorphism as decoration. In professional design, blur signals content layering (e.g., overlays, tooltips).
Fix: Reserve glassmorphism for elements that genuinely overlay other content. Use solid backgrounds for primary surfaces.
Context adjustment: P2 general → P3 in consumer/lifestyle apps where layered UI is an intentional design language.

**Everything Pill-Shaped** — P3
Looks like: `rounded-full` on buttons, inputs, cards, badges — every element has maximum border radius.
Why it's a tell: AI over-applies rounding to signal "modern" or "friendly." Professional design varies radius by element type.
Fix: Use a deliberate radius scale. Buttons can be rounded, but cards and inputs usually work better with subtle radius (8-12px).

**Decorative Gradient Blobs** — P2
Looks like: Large blurred gradient circles in the background (purple/pink/blue). Usually positioned in corners with `blur-3xl`.
Why it's a tell: One of the most recognizable AI-generated design elements. Adds visual noise without serving any information purpose.
Fix: Remove them. If a background needs visual interest, use subtle texture, photography, or a single accent color block.

**Shadow Stacking** — P3
Looks like: Multiple `box-shadow` layers creating exaggerated depth on every card and container.
Why it's a tell: AI layers shadows for a "premium" feel, but the result is depth soup where nothing feels grounded.
Fix: Use one consistent shadow token per elevation level. Most elements need one shadow or none.

**Emojis as Icons in Production** — P0
Looks like: Emoji characters used as feature icons, section markers, or UI indicators in a production interface.
Why it's a tell: Renders differently across platforms, can't be color-matched to the palette, signals amateur work.
Fix: Use a coherent icon set (Lucide, Heroicons, Phosphor). Icons should match the design system's weight and style.

---

## Interaction

**Everything Animates on Scroll** — P2
Looks like: Every section, card, and heading has a fade-in or slide-up animation triggered on scroll.
Why it's a tell: AI adds scroll animations to everything as a substitute for actual motion design.
Fix: Animate sparingly with purpose. The hero and primary CTA can animate. Supporting content should just be there. Respect `prefers-reduced-motion`.
Context adjustment: P2 general → P3 on marketing/portfolio sites where MOTION_INTENSITY is 7+ and the `scroll-narrative` signal applies. Remains P2 on dashboards and data-heavy pages.

**Identical Hover Effects** — P3
Looks like: Every interactive element has the same hover treatment — typically `scale(1.02)` + shadow increase.
Why it's a tell: AI applies one hover pattern globally rather than designing hover states per element type.
Fix: Design hover states per component: buttons get color/shade shifts, cards get subtle elevation, links get underline/color. Each element type gets its own treatment.

**Bounce/Spring on Non-Playful Interfaces** — P2
Looks like: Bouncy spring animations (overshoot, oscillation) on healthcare, finance, or enterprise interfaces.
Why it's a tell: AI applies trendy motion without considering domain tone. Spring physics suit playful consumer products, not all contexts.
Fix: Match animation easing to domain tone. Healthcare → gentle ease-out. Finance → crisp ease-in-out. Only use spring physics when the brand tone supports it.
Context adjustment: P2 general → P0 in healthcare/finance/legal. P3 in consumer products/portfolios where the `embodied-interaction` signal applies.

---

## Content

**"Unlock/Supercharge/Elevate" Vocabulary** — P1
Looks like: Headlines using AI-favorite verbs: "Unlock your potential," "Supercharge your workflow," "Elevate your experience."
Why it's a tell: These words appear in virtually every AI-generated landing page. They signal "AI wrote this copy."
Fix: Write specific, concrete headlines that describe what the product actually does. "Book a same-day appointment" beats "Unlock better healthcare."

**Testimonial Carousel with Stock Photos** — P2
Looks like: Auto-rotating carousel of testimonials with stock portrait photos and generic praise ("Great service!").
Why it's a tell: AI default for social proof. The combination of carousel + stock photos + vague quotes undermines trust.
Fix: Use real testimonials with specific outcomes. Static layout (no carousel). Real photos or skip photos entirely. Attribute with name and context.

**All-Caps Passages** — P3
Looks like: Multiple all-caps labels, section headers, or button text exceeding 3 words.
Why it's a tell: AI over-applies uppercase for emphasis, reducing readability and creating visual monotony.
Fix: Reserve all-caps for very short labels (2-3 words max). Use font weight, size, or color for emphasis instead.
