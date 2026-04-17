# Design Spec Template

Scaffold for `design-spec.md`. All sections marked **(required)** must be completed. Sections marked **(when applicable)** are included when relevant to the feature.

---

```markdown
# Design Spec: [Feature/Page Name]

## Interrogation (required)

### Purpose
[What specific action should the user take? What does success look like in 30 seconds?]

### Audience
[Who is viewing this? What are they feeling? What did they just do before arriving here? What objections do they have?]

### Context
[Where in the user journey? What comes before and after? What device and mindset?]

### Uniqueness
[What makes this different from every other [vertical] site? What would be lost if swapped with a competitor's?]

### Restraint
[What is this deliberately NOT doing? What was considered and rejected?]

### Signals Classified
- **[signal-name]** — [which interrogation answer supports it]
- **[signal-name]** — [which interrogation answer supports it]

### Design Parameters
- **DESIGN_VARIANCE**: [1-10] — [one-line justification from Uniqueness + Restraint]
- **MOTION_INTENSITY**: [1-10] — [one-line justification from Audience + Context]
- **VISUAL_DENSITY**: [1-10] — [one-line justification from Purpose + Context]

## Techniques Selected (required)
For each (2-3 max):
- **[Technique Name]** — recommended by [signal(s)]. Applied as: [specific application, not generic].

## Design Tokens (required)

### Colors
| Token | Value | Role |
|-------|-------|------|
| `--color-*` | #hex | [functional role] |

### Typography
| Element | Size | Weight | Line-Height | Letter-Spacing |
|---------|------|--------|-------------|----------------|
| h1 | | | | |
| body | | | | |

### Spacing
Base unit and scale multiples used in this feature.

### Shadows/Depth (when applicable)
| Level | Token | Usage |
|-------|-------|-------|

## Component Specs (required)
For each component:
- **[Component Name]**
  - Variants: [list all visual variants]
  - States: hover, focus, active, disabled, loading, error
  - Composition: [sub-components used]
  - Constraints: [max-width, min-height, content limits]

## Layout (required)
- **Grid**: columns, gap, breakpoints
- **Spacing rhythm**: section padding, content gaps
- **Responsive changes**: mobile → tablet → desktop
- **Content flow**: reading order, alignment strategy

## Interactions (when applicable)
- **Transitions**: element → duration token → easing curve (from MOTION-SYSTEM.md)
- **Loading states**: skeleton/shimmer approach
- **Error states**: validation feedback pattern
- **Hover/Focus**: per-component treatments

## Motion Choreography (when applicable)
- **Entrance**: stagger pattern, priority order, total duration budget
- **Motion mode**: productive / expressive (from MOTION_INTENSITY parameter)
- **Exit**: direction, duration, blocking behavior

## Accessibility (required)
- **ARIA roles**: per component
- **Keyboard navigation**: tab order, shortcuts
- **Focus indicators**: style, contrast
- **Screen reader**: live regions, announcements for dynamic content

## Design Decisions (required)
For each non-obvious choice:
- **Decision**: [what was chosen]
- **Signal**: [which signal drove it]
- **Technique**: [which technique was applied]
- **Why**: [reasoning future specs should know]
- **Rejected**: [alternatives considered and why dropped]

## Design Verification Checklist (required)
- [ ] Contrast ratios: [primary text on bg] ≥ 4.5:1, [CTA text on CTA bg] ≥ 4.5:1
- [ ] Animation duration budget: [total ms] for page load sequence
- [ ] Primary CTA identified: [what], [where], [expected visual weight]
- [ ] Grid density: [columns] × [gap] → [content-to-whitespace ratio]
- [ ] AI anti-pattern scan: no P0/P1 patterns from AI-ANTIPATTERNS.md
- [ ] `prefers-reduced-motion` fallbacks specified for all animations
```
