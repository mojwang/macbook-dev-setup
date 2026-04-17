---
name: design-elevation
description: Run when the designer agent produces a design-spec.md. Interrogates intent through 5 lenses, classifies signals, selects techniques, and verifies restraint. Includes SIGNALS.md, TECHNIQUES.md, REFERENCES.md companions.
user-invocable: false
allowed-tools: Read, Grep, Glob, Bash
---

# Design Elevation Skill

Auto-invoked when the designer agent produces a `design-spec.md`. Ensures every spec is interrogated for intent, informed by technique vocabulary, and stripped of anything that doesn't earn its place.

## Companion Files
- `SIGNALS.md` — Signal classification for interrogation findings (includes Baseline Techniques tier)
- `TECHNIQUES.md` — Technique catalog organized by outcome
- `REFERENCES.md` — Design reference library
- `MOTION-SYSTEM.md` — Duration tokens, easing curves, spring configs, choreography rules
- `SPEC-TEMPLATE.md` — Scaffold for design-spec.md with required/optional sections

## Protocol

### 1. Assess
Read the current project state to determine design maturity:
- **Level 1**: No design system. Raw Tailwind, no tokens, no shared components.
- **Level 2**: Foundations exist. Token file, some shared components, but inconsistent usage. Inline className sprawl.
- **Level 3**: Consistent system. Tokens used everywhere, component variants cover domain patterns, spacing rhythm established.
- **Level 4**: Elevated system. Distinctive visual identity, intentional technique choices, no default patterns surviving without justification.
- **Level 5**: Refined system. Every detail deliberate, micro-interactions considered, the system teaches contributors through constraints.

Document the current level and what's needed to advance one level.

### 2. Interrogate
Before producing any spec, gather project context: read the existing codebase for current design patterns, color usage, component library state, and any existing DESIGN.md or design tokens. The interrogation must be grounded in what exists, not hypothetical.

Then answer these 5 lenses. Each must have a concrete answer — "general audience" or "standard layout" are not acceptable.

- **Purpose**: What specific action should the user take after viewing this page/component? What does success look like in 30 seconds?
- **Audience**: Who is the actual person viewing this? What are they feeling? What did they just do before arriving here? What objections do they have?
- **Context**: Where does this appear in the user's journey? What comes before and after? What device and mindset are they in?
- **Uniqueness**: What makes this different from every other [healthcare site / SaaS landing page / etc.]? What would be lost if this were swapped with a competitor's version?
- **Restraint**: What is this page/component deliberately NOT doing? What was considered and rejected?

After answering all 5 lenses, set three **design parameters** that constrain the spec:
- **DESIGN_VARIANCE** (1-10): How far from conventional patterns should this deviate? 1 = safe/expected, 10 = experimental/distinctive. Derive from Uniqueness + Restraint answers.
- **MOTION_INTENSITY** (1-10): How much animation and transition? 1 = minimal/static, 10 = choreographed motion. Derive from Audience + Context answers. Anxious or high-stakes audiences → lower. Playful consumer products → higher.
- **VISUAL_DENSITY** (1-10): How much information per viewport? 1 = single-focus, 10 = dashboard-dense. Derive from Purpose + Context answers.

These parameters constrain Step 3 per this table:

| Parameter | 1-3 | 4-6 | 7-10 |
|-----------|-----|-----|------|
| DESIGN_VARIANCE | Signal Quality techniques only. Safe, conventional patterns. | Signal Quality + selective Differentiate (1 technique max). | Full Differentiate catalog available. Asymmetric layout, branded color blocking, typographic personality. |
| MOTION_INTENSITY | Productive Micro-Motion only. No scroll animations, no springs. | + Entrance Choreography, Scroll-Triggered Reveal for key sections. | + Spring-Physics Interaction, Page Transition Continuity. Full motion catalog. |
| VISUAL_DENSITY | Single-focus layouts. One CTA, generous whitespace, minimal content per viewport. | Standard content pages. Card grids, progressive disclosure, mixed content. | Dashboard techniques. KPI Header Strip, Inverted Pyramid, Card Grid Dashboard. Data-dense layouts. |

These are defaults — override with documented justification when the interrogation answers demand it.

Then classify **2-4 signals** from `SIGNALS.md` that match the findings. Each signal must trace to a specific interrogation answer — don't classify signals that aren't supported by the answers.

### 3. Select Techniques
Use the classified signals to build a technique shortlist:
1. Collect the recommended techniques from each classified signal in `SIGNALS.md`
2. Techniques recommended by **multiple signals** are strongest candidates
3. Pick 2-3 from the shortlist. For each:
   - Name the technique
   - Cite which signal(s) recommended it
   - Cite which interrogation answer the signal traces to
   - Describe how it will be applied specifically (not generically)

More than 3 techniques signals lack of focus. Apply fewer techniques strongly rather than many weakly.

When selected techniques involve animation or interaction (Micro-animations on Interaction, Distinctive Interaction Patterns, Loading State Design, Entrance Choreography, Spring-Physics Interaction), consult `MOTION-SYSTEM.md` to specify exact duration tokens, easing curves, and motion mode (productive vs expressive). The spec must include concrete motion values — "add animation" is not a specification.

### 4. Consult References
From `REFERENCES.md`, identify 1-2 reference points:
- What the reference does well that's relevant here
- What to borrow vs. what to avoid
- How to adapt the reference to this project's identity

### 5. Specify
Use `SPEC-TEMPLATE.md` as the scaffold. Write the `design-spec.md` with technique choices woven into the specification:
- Each section should reference which technique informed it
- Token usage, component choices, and layout decisions should trace back to interrogation answers
- Include a "Design Decisions" section documenting the reasoning chain
- Include a "Design Verification" subsection with measurable assertions the implementer can check:
  - Contrast ratios for key color pairs (primary text on background, CTA text on CTA background)
  - Animation duration budget (total animation time for the page load sequence)
  - Primary CTA identification (what it is, where it appears, expected visual weight)
  - Grid density (columns, gap, content-to-whitespace ratio)

**DESIGN.md output option**: When bootstrapping a project's visual identity or documenting an existing design system, optionally generate a standalone `DESIGN.md` using the 9-section format:
1. Visual Theme & Atmosphere (mood, density, design philosophy)
2. Color Palette & Roles (semantic token name + hex + functional role for each color)
3. Typography Rules (full hierarchy table: element, size, weight, line-height, letter-spacing)
4. Component Stylings (buttons, cards, inputs, nav — with all states)
5. Layout Principles (spacing scale, grid system, whitespace philosophy)
6. Depth & Elevation (shadow tokens, surface hierarchy)
7. Do's & Don'ts (design guardrails specific to the project)
8. Responsive Behavior (breakpoints, touch targets, collapse strategy)
9. Agent Prompt Guide (quick color/type reference + instructions for non-designer agents to stay on-brand)

The existing `design-spec.md` format remains primary for feature work. DESIGN.md is for project-level identity documentation.

### 6. Verify Restraint
Review every element in the spec. For each, ask: "Does removing this hurt the purpose identified in Step 2?"
- If no — remove it
- If uncertain — remove it and note what would need to be true for it to earn its place
- If yes — keep it and document why

## Rules
- Never skip the interrogation. A spec without interrogation answers is a guess.
- Techniques are tools, not decorations. Every technique must solve a problem identified in interrogation.
- Default shadcn output is a starting point, never a destination.
- One strong technique applied consistently beats three applied superficially.
- Document what was removed and why — restraint is a design decision.
