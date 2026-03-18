# Design Techniques Catalog

Organized by outcome. Each technique includes when to use and when NOT to use. Pick 2-3 per spec — not more.

## Establish Trust

**Generous White Space**
Let content breathe. Padding and margins signal confidence — cramped layouts signal desperation.
Use: Landing pages, healthcare, finance, premium positioning.
Avoid: Dashboards, dense data displays, mobile-first utilities.

**Credential Hierarchy**
Structure credentials by relevance, not alphabetically. Lead with what the audience cares about (board certification before medical school).
Use: Provider pages, about pages, service pages with expert positioning.
Avoid: Contact forms, booking flows, navigation.

**Muted Palette + Single Accent**
Restrain the palette to neutrals with one intentional accent color for CTAs and key information.
Use: Healthcare, legal, finance — anywhere trust outweighs excitement.
Avoid: E-commerce, entertainment, children's products.

**Testimonial Patterns**
Real quotes with attribution (name, context, outcome). Photo optional but powerful.
Use: Conversion pages, service pages, pricing pages.
Avoid: Utility pages, documentation, internal tools.

**Social Proof Proximity**
Place trust signals (reviews, certifications, insurance logos) near the point of conversion, not in a separate section.
Use: Booking flows, pricing pages, service detail pages.
Avoid: Blog posts, informational pages, FAQs.

## Guide to Action

**Progressive CTA Escalation**
Start with low-commitment CTAs ("Learn more") and escalate to high-commitment ("Book now") as the user scrolls deeper.
Use: Long-form landing pages, service pages, multi-section homepages.
Avoid: Single-purpose pages with one obvious action, checkout flows.

**Sticky Booking Element**
Fixed-position CTA that follows the user. Must not obstruct content.
Use: Service pages, provider pages, long-form content with a single conversion goal.
Avoid: Short pages, multi-CTA contexts, mobile when it covers too much screen.

**Contrast Isolation**
Surround the primary CTA with visual quiet — white space, muted backgrounds — so it stands alone.
Use: Hero sections, pricing cards (featured tier), conversion moments.
Avoid: Dense UIs, toolbar-style interfaces, list views.

**Urgency Without Anxiety**
Communicate availability ("Next available: Tuesday") without pressure tactics ("Only 2 spots left!").
Use: Healthcare booking, appointment scheduling, limited-capacity services.
Avoid: Emergency messaging, sale events (where urgency is real).

**Directional Cues**
Visual elements (arrows, gaze direction in photos, layout flow) that guide the eye toward the CTA.
Use: Hero sections, feature highlights, onboarding flows.
Avoid: Dense content areas, data tables, reference pages.

## Create Warmth

**Provider Photography**
Real photos of real providers in their environment. Not stock, not AI-generated.
Use: Healthcare, professional services, any trust-dependent industry.
Avoid: When real photos aren't available (bad photo > no photo is FALSE — skip until quality photos exist).

**Rounded Shape Language**
Border radius, rounded cards, pill-shaped buttons. Signals approachability.
Use: Healthcare, wellness, consumer products, family-oriented services.
Avoid: Enterprise B2B, developer tools, editorial/news.

**Warm Neutral Base**
Replace cool grays with warm undertones (stone, sand, cream) for the base palette.
Use: Healthcare, hospitality, wellness, lifestyle brands.
Avoid: Tech products, financial dashboards, developer tools.

**Conversational Headings**
Write headings as if talking to the reader. "Your health, simplified" not "Health Services Overview."
Use: Consumer-facing landing pages, service descriptions, onboarding.
Avoid: Documentation, legal pages, technical references.

**Micro-animations on Interaction**
Subtle transitions on hover, focus, and state changes. 150-300ms duration.
Use: Buttons, cards, form elements, navigation items.
Avoid: Overuse (if everything animates, nothing stands out). Skip on prefers-reduced-motion.

## Organize Information

**Card Grid with Hierarchy**
Grid of cards where one card is visually promoted (larger, different background, "recommended" badge).
Use: Service listings, pricing tiers, feature comparisons, team pages.
Avoid: When all items are truly equal — forced hierarchy misleads.

**Progressive Disclosure Accordion**
Collapsed sections that expand on click. Show the most important content open by default.
Use: FAQs, service details, insurance lists, long-form content.
Avoid: When content is short enough to show in full, navigation-critical information.

**Tabbed Content**
Horizontal tabs for parallel content categories. Keep to 3-5 tabs maximum.
Use: Service categories, provider specialties, location details.
Avoid: Sequential content (use steps instead), more than 5 categories.

**Timeline Layout**
Vertical timeline for sequential processes (patient journey, treatment plan, history).
Use: "How it works" sections, company history, treatment process.
Avoid: Non-sequential information, more than 7 steps.

**Pricing Table with Feature Matrix**
Structured comparison with clear tier differentiation and a single recommended option.
Use: Membership plans, service packages, subscription tiers.
Avoid: Single-price offerings, when comparison creates confusion.

**Anchor Navigation**
Sticky sidebar or top navigation that scrolls to sections within a long page.
Use: Long-form pages (services, about), documentation-style content.
Avoid: Short pages, pages with a single clear flow.

## Signal Quality

**Type Scale Consistency**
Define a modular type scale (e.g., 1.25 ratio) and use it everywhere. No random font sizes.
Use: Every project. Non-negotiable for design maturity Level 3+.
Avoid: Never avoid this.

**Spacing Rhythm**
Use a base unit (4px or 8px) and derive all spacing from multiples. No arbitrary values.
Use: Every project. Non-negotiable for design maturity Level 3+.
Avoid: Never avoid this.

**Icon Coherence**
One icon set, one weight, one size per context. Mixed icon styles signal amateur work.
Use: Navigation, feature lists, service cards, UI elements.
Avoid: Don't add icons where text alone is clear.

**Consistent Component Variants**
Variants defined through CVA or equivalent — not ad-hoc className overrides.
Use: Any component that appears in more than one visual treatment.
Avoid: One-off components that will never be reused.

**Loading State Design**
Skeleton screens, shimmer effects, or meaningful progress indicators instead of spinners.
Use: Any async content, page transitions, form submissions.
Avoid: Instantaneous operations, static content.

## Differentiate

**Asymmetric Layout**
Break the grid intentionally. One column wider, offset images, overlapping elements.
Use: Hero sections, feature highlights, portfolio/case study pages.
Avoid: Data-heavy pages, forms, checkout flows.

**Editorial Photography**
Full-bleed images, dramatic crops, environmental context. Treat photos as design elements, not decoration.
Use: Hero sections, about pages, provider introductions.
Avoid: When high-quality photography isn't available. Bad editorial photography is worse than no photography.

**Branded Color Blocking**
Large areas of brand color as layout devices, not just accents.
Use: Section dividers, hero backgrounds, feature callouts.
Avoid: Full-page color — use as punctuation, not wallpaper.

**Distinctive Interaction Patterns**
Custom hover effects, scroll-triggered reveals, page transitions that feel intentional.
Use: Portfolio sites, premium brands, experience-driven sites.
Avoid: Utility-first applications, accessibility-critical flows without fallbacks.

**Typographic Personality**
A display font or distinctive type treatment that carries brand identity.
Use: Headings, hero sections, key messaging.
Avoid: Body text, UI elements, form labels.
