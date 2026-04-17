# Design Techniques Catalog

Organized by outcome. Each technique includes when to use and when NOT to use. Pick 2-3 per spec — not more. For data-heavy specs, combine one Visualize Data technique with one Communicate Numbers technique.

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

## Motion & Choreography

**Entrance Choreography**
Staggered element entrance with 20-50ms delays between sequential items, total sequence under 500ms. Content loads in priority order: chrome → static content → dynamic data → interactive elements → decorative.
Use: Page loads, route transitions, accordion/tab reveals, card grid population.
Avoid: Already-visible content repositioning (use standard easing instead), instant state changes, dashboards where data should appear immediately.

**Spring-Physics Interaction**
Physics-based animation using stiffness/damping/mass parameters for gesture-driven elements. Springs incorporate velocity from user input, creating momentum-aware responses that fixed curves cannot replicate. See `MOTION-SYSTEM.md` for spring configurations.
Use: Drag interactions, swipe gestures, pull-to-refresh, playful consumer products (MOTION_INTENSITY 6+), layout animations responding to content changes.
Avoid: Healthcare, finance, enterprise task UIs (unless brand explicitly supports it). Micro-interactions that need to be invisible. Any context where overshoot could trigger vestibular discomfort.

**Productive Micro-Motion**
Fast, nearly invisible transitions (70-150ms) for interactive state feedback. Toggle, checkbox, button press, focus ring, hover color shift. The user shouldn't consciously register the animation — they should just feel the interface is responsive.
Use: Every interactive element. Non-negotiable for design maturity Level 3+.
Avoid: Never avoid this. Absence of micro-motion makes interfaces feel broken or cheap.

**Scroll-Triggered Reveal**
Elements animate into view on scroll using Intersection Observer. Short fade + translate (20-30px vertical). Single animation per element — no repeat on re-entry. Fire once, then the element stays visible.
Use: Long-form content pages, feature showcases, landing page sections, marketing sites.
Avoid: Dashboard UIs, data-heavy pages where content should be immediately scannable, pages where users scroll fast to find specific information.

**Page Transition Continuity**
Shared element transitions between routes using View Transitions API or layout animations. The departing and arriving pages share a visual element (image, card, header) that morphs between states, maintaining spatial context during navigation.
Use: App-like experiences, detail views (list → detail), media galleries, portfolio sites.
Avoid: Document-style sites where instant navigation is expected, content-heavy pages, contexts where transition delay would frustrate task completion.

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

## Visualize Data

**Maximize Data-Ink Ratio**
Remove every non-data element (gridlines, borders, decorative fills) until nothing else can be removed without losing information. Every pixel should encode data. (Tufte)
Use: Every chart, as a finishing pass.
Avoid: Never skip this.

**Direct Labeling**
Place data labels directly on or adjacent to data series instead of using a separate legend. Eliminates eye-travel cost.
Use: Line charts with 2-5 series, bar charts, any chart where a legend forces cross-referencing.
Avoid: Charts with 10+ overlapping series where labels would collide, interactive contexts with hover tooltips.

**Gray + One Accent**
Render all data in muted gray, highlight the one series you want the audience to focus on in a single accent color. Forces attention to the insight.
Use: Presentations, executive summaries, any context with a specific point to make.
Avoid: Exploratory dashboards where users need to compare all series equally.

**Annotation Callouts**
Add text annotations directly on the chart surface pointing to notable data points, explaining *why* something happened. Turns description into explanation.
Use: Time series with notable events, narrative/presentation contexts.
Avoid: Real-time operational dashboards, exploratory tools where users define their own narrative.

**Sparklines**
Tiny word-sized line charts embedded inline with text or table cells. Show trend shape without axes, labels, or chrome. (Tufte)
Use: KPI tables needing current value + trend. Dashboards with many metrics. Inline with prose.
Avoid: When precise values matter more than trend shape.

**Small Multiples**
Repeat the same chart type across a grid, one panel per category, all sharing the same axes. Enables comparison without spaghetti overlap.
Use: Comparing trends across 6-30 categories (regions, products, cohorts).
Avoid: Fewer than 4 categories (just overlay them). Wildly different scales across categories.

**Slopegraph**
Two vertical axes (before/after) connected by lines. Shows rank changes and magnitude changes simultaneously.
Use: Comparing values between exactly two time periods. Before/after with 5-15 items.
Avoid: More than two time periods. Fewer than 3 items.

**Waterfall Chart**
Shows how an initial value is affected by sequential positive and negative values, arriving at a final total.
Use: Financial breakdowns (revenue to profit), explaining how a metric changed through contributing factors.
Avoid: Non-additive factors. More than 12-15 contributing factors.

**Reference Lines and Bands**
Horizontal/vertical lines or shaded bands indicating targets, averages, thresholds. Provides instant "good vs. bad" context.
Use: Any metric chart with targets. SLA monitoring. Goal tracking.
Avoid: Exploratory contexts where no target exists yet.

**Progressive Data Disclosure**
Show simplified view by default; reveal detailed data on hover/click/drill-down. "Overview first, zoom and filter, details on demand." (Shneiderman)
Use: Interactive dashboards. Dense datasets. Mixed-expertise audiences.
Avoid: Static reports, printed materials, presentation slides.

## Communicate Numbers

**Big Number Display**
A single metric in very large typography (48-72px+) as the dominant visual element. The number IS the visualization.
Use: KPI cards, single-stat slides, status boards, hero stats.
Avoid: When the number needs heavy context. When showing multiple equally-important metrics.

**Trend Indicator (Delta + Arrow)**
Show change direction (arrow) and magnitude (+12%) next to current value. Color-code green/red only when direction has clear meaning. Always add arrow shape as redundant cue for colorblind users.
Use: Any current-value display. KPI cards. Dashboard headers.
Avoid: When "up" isn't inherently good or bad without context.

**Contextual Benchmark**
Always pair a number with a comparison: vs. target, vs. last period, vs. industry. A number without context is just a number.
Use: Every KPI display. Every metric card. Every data slide.
Avoid: When the benchmark itself would be misleading (anomalous comparison period).

**Progress-to-Goal**
Show current value as progress toward a defined target. Bullet charts (Tufte) are most ink-efficient: single horizontal bar with target marker and qualitative ranges.
Use: Sales targets, fundraising, OKR tracking, SLA compliance.
Avoid: When there is no defined target. Avoid circular gauges — use bullet charts instead.

**Humanized Scale**
Translate abstract large numbers into relatable terms. "1.3M tons" becomes "enough to fill 520 Olympic swimming pools." Makes numbers memorable and shareable.
Use: Public communications, marketing, investor decks, journalism.
Avoid: Technical contexts where precision matters. Internal operational dashboards.

**Anchoring**
Present a reference number first to set expectations, then reveal the actual number. "Industry average: 2.3%. Our rate: 0.4%." The anchor makes the actual number land with impact.
Use: Presentations, pitch decks, competitive comparisons, before/after narratives.
Avoid: Dashboards where all values are visible simultaneously.

**Magnitude Formatting**
Format large numbers for scanability: $1.2M not $1,234,567. Use K/M/B suffixes. Right-align in tables. Use tabular (monospace) numerals for alignment.
Use: Every dashboard, every KPI card, every data table.
Avoid: Financial audits requiring exact figures.

**Conditional Color Encoding**
Apply background/text color to numbers based on thresholds. Red/amber/green for status. Heatmap intensity for tables. Add icon redundancy for accessibility.
Use: Status matrices, scorecards, data tables with 10+ rows.
Avoid: When threshold definitions are ambiguous.

## Structure Dashboards

**KPI Header Strip**
Horizontal row of 3-6 large-number cards spanning full width at top. Each: metric name, big number, trend indicator, optional sparkline.
Use: Executive dashboards. Any dashboard where the first question is "are we on track?"
Avoid: Analytical dashboards where no single metric is the headline.

**Inverted Pyramid Layout**
Top: aggregate/summary. Middle: breakdowns/segments. Bottom: detail tables/drill-downs. Executives scan top, analysts scroll down.
Use: Dashboards serving mixed audiences.
Avoid: Dashboards for a single expert persona who always wants detail first.

**Card Grid Dashboard**
Independent, equally-sized cards in responsive grid. Each card is self-contained with title, chart, and optional action. Cards can be rearranged.
Use: Overview dashboards covering multiple domains. Customizable user dashboards.
Avoid: When charts need to be read in sequence. When cross-chart comparison requires aligned axes.

**Narrative Dashboard (Scrollytelling)**
Vertically scrolling page interleaving text with charts, guiding the reader through a data story with beginning, middle, end.
Use: Data journalism, annual reports, onboarding users into complex data.
Avoid: Real-time monitoring. Expert tools where narrative slows power users.

**The 3-Second Rule**
The most critical information on any dashboard must be comprehensible within 3 seconds of looking. Test by glancing and asking for the main takeaway.
Use: Every dashboard design review, as a QA gate.
Avoid: Never skip this.

## Present Data

**Single-Stat Slide**
One enormous number centered on the slide. Nothing else except a short label. Forces the audience to absorb one fact.
Use: Opening a section with a dramatic stat. TED-style keynotes.
Avoid: Internal meetings expecting information density.

**Build-Up Reveal**
Show chart progressively: axes, then one series, then comparison, then annotation. Each build adds one idea. Creates narrative tension.
Use: Complex charts in live presentations. Charts with a punchline. Max 2-3 per deck.
Avoid: Leave-behind decks. Async reading contexts.

**Insight Title (Not Descriptive Title)**
Replace "Q3 Revenue by Region" with "Northeast revenue grew 40% while all other regions declined." The title states the takeaway.
Use: Every presentation chart. Single highest-impact presentation technique.
Avoid: Dashboards where users draw their own conclusions. Editorially neutral contexts.

**Chart Simplification for Slides**
Strip analytical charts for presentation: remove gridlines, reduce axis ticks, enlarge fonts to 18pt+, reduce to 2-3 colors, add takeaway title. A slide chart should have 50% of the elements of a dashboard chart.
Use: Every time a chart moves from a dashboard into a slide deck.
Avoid: Never present an analytical chart as-is in a slide.

**Highlight Table**
Simple data table with conditional formatting (bold, color, size) on key cells. More credible than charts for skeptical audiences.
Use: Financial audiences, audit committees, detailed quarterly results.
Avoid: When the story is about trend/shape rather than precise values.
