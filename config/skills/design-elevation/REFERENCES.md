# Design Reference Library

Reference points for design interrogation. Not templates to copy — sources of specific lessons.

## Healthcare Web

**One Medical**
Does well: Clean scheduling flow, provider pages that feel personal, generous white space.
Borrow: Patient journey clarity, trust-through-simplicity approach.
Avoid: Over-minimalism that strips warmth.

**Parsley Health**
Does well: Warm color palette, membership model clearly explained, editorial photography.
Borrow: How they make functional medicine feel accessible, not alternative.
Avoid: Heavy reliance on lifestyle imagery over substance.

**Forward**
Does well: Technology-forward positioning, clear value proposition, bold typography.
Borrow: Confidence in a singular message per page.
Avoid: Tech-bro aesthetic that alienates older patients.

**Cityblock Health**
Does well: Community-oriented design, diverse representation, accessible language.
Borrow: Inclusive design patterns, warmth without condescension.
Avoid: Mission-heavy messaging that delays practical information.

**Oak Street Health**
Does well: Location-centric design, insurance clarity upfront, simple booking.
Borrow: How they handle multi-location with location-specific content.
Avoid: Template-feeling page layouts.

## Developer Tools & SaaS

**Linear**
Does well: Clarity as a feature. Dense information without clutter through hierarchy and spacing. Keyboard-first interaction. Performance IS design.
Borrow: Tight visual consistency across every component. Speed of rendering communicates quality.
Avoid: Strongly opinionated dark aesthetic won't work for audiences expecting warmth.

**Stripe**
Does well: Technical density made beautiful. Restrained color (mostly monochrome + one accent). KPI cards surface critical numbers within seconds.
Borrow: Whitespace as structural element. Consistent spacing rhythm, type scale as polish signal.
Avoid: Information density assumes high user sophistication. Too sparse for non-technical users.

**Vercel**
Does well: Analytics dashboard that makes web performance data immediately actionable. Sidebar nav streamlines developer workflow.
Borrow: Design for the user's workflow, not data completeness. Show what's actionable, hide what's just informational.
Avoid: Developer-centric patterns that assume technical literacy.

**Raycast**
Does well: Command palette UX, density without clutter, keyboard-first interaction. Speed as design value.
Borrow: Tight component reuse, performance-conscious rendering, clean contextual menus.
Avoid: Power-user density alienates casual users. Keyboard-first assumptions don't translate to touch.

**Supabase**
Does well: Developer docs as product, dark mode as primary context, clean data table presentation.
Borrow: Technical content made scannable through consistent component patterns and clear hierarchy.
Avoid: Dark-first aesthetic doesn't suit all audiences. Developer-centric patterns assume technical literacy.

## Consumer & Media

**Apple Health**
Does well: Warmth and technology coexist. Summary cards → trend charts → daily detail. Activity Rings are a masterclass in progress-to-goal visualization.
Borrow: Present health/sensitive data with calm, neutral visual tone. Progressive detail hierarchy.
Avoid: Platform-specific iOS patterns don't translate to web.

**Spotify Wrapped**
Does well: Turns personal data into shareable, emotional, story-driven experience. One insight per screen. Bold typography, animated transitions.
Borrow: Data as gift — make users feel seen by their own data. Design for screenshot-sharing.
Avoid: Style over substance. Bold visual approach undermines credibility in business contexts.

**Headspace**
Does well: Calming UX through animation pacing, muted palettes, and progressive disclosure.
Borrow: When building wellness or mental health adjacent features, onboarding flows.
Avoid: The soft aesthetic doesn't fit data-intensive or action-oriented contexts.

**Robinhood**
Does well: Made financial data accessible to non-experts by stripping jargon. Portfolio chart IS the home screen.
Borrow: Radical simplification for non-expert audiences. One primary visualization per screen.
Avoid: Oversimplification can hide risk. "Gamifying" serious decisions drew criticism.

## Data & Analytics

**New York Times Graphics Desk**
Does well: Best-in-class narrative data visualization. Scrollytelling with interactive charts. Extreme attention to annotation.
Borrow: Annotate everything — a chart without annotation is a chart without an argument. Scrolling as reveal mechanism.
Avoid: Production quality requires dedicated teams. Don't attempt scrollytelling without the craft to execute.

**Our World in Data**
Does well: Makes global research data accessible through simple, well-labeled charts. Radical transparency on methodology. Every chart downloadable/embeddable.
Borrow: Make data portable and citable. Use familiar chart types executed with extreme clarity over novel exotic formats.
Avoid: Academic aesthetic. Not for brand-forward products.

**Information is Beautiful (McCandless)**
Does well: Complex datasets as beautiful, shareable infographics. Four pillars: information + function + visual form + story.
Borrow: If any pillar is missing, the visualization fails. No story = boring. No information = empty.
Avoid: Static infographic style doesn't scale to interactive dashboards.

## Enterprise & Monitoring

**Datadog / Grafana**
Does well: Information-dense dashboards for experts. RED method layout (rate, errors, duration). Time-series with reference bands for thresholds.
Borrow: Consistent layout patterns across pages reduces cognitive load. Service hierarchy mirrors data flow.
Avoid: Extremely dense. Requires training. No model for casual users.

**Notion**
Does well: Composable block system for custom layouts. Multiple views of same data (table, board, calendar, gallery).
Borrow: Give users composable primitives, not fixed dashboards. Same data, different lenses.
Avoid: Too much flexibility leads to inconsistency. Provide strong defaults.

**USAFacts**
Does well: Unbiased data presentation. Progressive disclosure: overview first, breakdown on interaction. Source attribution on every visualization.
Borrow: Source attribution builds trust. "Simple first, detail upon interaction."
Avoid: Deliberately neutral stance can feel dry. Not for contexts that need to persuade.

**Airbnb**
Does well: Warm photography + functional search, trust through real content, responsive grid mastery. Content-first layout where imagery serves information, not decoration.
Borrow: Real photography over illustration. Grid systems that adapt content density per viewport. Location-aware personalization.
Avoid: Photography dependency — needs a pipeline of high-quality assets. Heavy imagery without fast CDN creates performance problems.

## Design System References

**Stripe Design System**
Does well: Token structure as gold standard. Monochrome + one accent color. Whitespace as structural element. Technical density made beautiful through restraint.
Borrow: Token naming conventions, spacing rhythm discipline, how they make dense information feel calm.
Avoid: Information density assumes high user sophistication. Too sparse for non-technical or first-time audiences.

**Linear Design System**
Does well: Performance IS design. Keyboard-first, dark aesthetic, extreme component consistency. Render speed communicates quality.
Borrow: Component reuse discipline — every variant is considered, not ad-hoc. Speed of interaction as a design decision.
Avoid: Opinionated dark mode won't work for all audiences. Density requires training that casual users won't invest in.

## Anti-References (What to Avoid)

**Generic clinic templates**
Problem: Identical layouts across thousands of practices. Hero with stock photo, three service cards, testimonial slider, contact form.
Why it fails: Zero differentiation. Patients can't distinguish one practice from another.
Fix: Apply at least one Differentiate technique to break the template pattern.

**Stock photo heavy**
Problem: Smiling-people-in-lab-coats imagery that feels interchangeable.
Why it fails: Undermines the authenticity that healthcare requires. Patients notice.
Fix: Use real photography or skip imagery entirely. A well-designed text-only section beats a stock photo section.

**Information overload**
Problem: Every service, every provider, every insurance, every FAQ — all on one page.
Why it fails: Cognitive overwhelm leads to bounce, not engagement.
Fix: Progressive disclosure. Surface the most common 3-5 items, provide clear paths to the rest.

**Sliding carousel of everything**
Problem: Auto-rotating hero carousels with 5+ slides of different messages.
Why it fails: Users don't wait for slide 4. Each slide competes with every other. Accessibility nightmare.
Fix: One hero message, committed to fully. If you can't pick one, the messaging strategy needs work first.
