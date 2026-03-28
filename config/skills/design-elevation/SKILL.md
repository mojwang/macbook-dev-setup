---
name: design-elevation
description: Structured interrogation and technique selection to elevate design specs beyond defaults.
user-invocable: false
allowed-tools: Read, Grep, Glob, Bash
---

# Design Elevation Skill

Auto-invoked when the designer agent produces a `design-spec.md`. Ensures every spec is interrogated for intent, informed by technique vocabulary, and stripped of anything that doesn't earn its place.

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
Before producing any spec, answer these 5 lenses. Each must have a concrete answer — "general audience" or "standard layout" are not acceptable.

- **Purpose**: What specific action should the user take after viewing this page/component? What does success look like in 30 seconds?
- **Audience**: Who is the actual person viewing this? What are they feeling? What did they just do before arriving here? What objections do they have?
- **Context**: Where does this appear in the user's journey? What comes before and after? What device and mindset are they in?
- **Uniqueness**: What makes this different from every other [healthcare site / SaaS landing page / etc.]? What would be lost if this were swapped with a competitor's version?
- **Restraint**: What is this page/component deliberately NOT doing? What was considered and rejected?

After answering all 5 lenses, classify **2-4 signals** from `SIGNALS.md` that match the findings. Each signal must trace to a specific interrogation answer — don't classify signals that aren't supported by the answers.

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

### 4. Consult References
From `REFERENCES.md`, identify 1-2 reference points:
- What the reference does well that's relevant here
- What to borrow vs. what to avoid
- How to adapt the reference to this project's identity

### 5. Specify
Write the `design-spec.md` with technique choices woven into the specification:
- Each section should reference which technique informed it
- Token usage, component choices, and layout decisions should trace back to interrogation answers
- Include a "Design Decisions" section documenting the reasoning chain

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
