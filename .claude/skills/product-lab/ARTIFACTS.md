# Artifact Templates

Templates for every document the product strategist produces. All artifacts are written to the `product-lab/` directory. They are persistent across sessions — not ephemeral like `research.md` or `plan.md`.

---

## State Tracker

**Path**: `product-lab/stage.json`

```json
{
  "current_stage": "ideation|discovery|mvp|launch|pmf|positioning|growth",
  "idea_name": "short-name",
  "started": "YYYY-MM-DD",
  "stage_entered": "YYYY-MM-DD",
  "history": [
    {
      "stage": "ideation",
      "entered": "YYYY-MM-DD",
      "exited": "YYYY-MM-DD",
      "outcome": "passed|pivoted|skipped"
    }
  ],
  "evidence_summary": {
    "strongest_signal": "One sentence — the most compelling evidence collected so far",
    "biggest_risk": "One sentence — the most dangerous unvalidated assumption",
    "next_action": "One sentence — what should happen next"
  }
}
```

Update after every stage transition and at the end of meaningful interactions.

---

## Idea Evaluation

**Path**: `product-lab/ideas/[name]/evaluation.md`

```markdown
# Idea Evaluation: [Name]

**Date**: YYYY-MM-DD
**Founder**: [who]
**One-line pitch**: [idea in one sentence]

## Three Properties Assessment

| Property | Rating | Evidence |
|---|---|---|
| Founder-market fit | Strong / Moderate / Weak | [why] |
| Market size/growth | Large / Growing / Small-stable | [why] |
| Problem acuteness | Hair-on-fire / Painful / Mild | [why] |

## Tarpit Check

| Tarpit Property | Present? | Notes |
|---|---|---|
| Obvious appeal (everyone says "great idea") | Yes / No | |
| Hidden structural barrier | Yes / No | |
| Graveyard of predecessors | Yes / No | |
| Consumer social or marketplace dynamics | Yes / No | |

**Tarpit risk**: Low (0-1 properties) / Medium (2) / High (3-4)

## Evaluation Checklist

| # | Question | Answer | Evidence Tier |
|---|---|---|---|
| 1 | Who is the user? | | T1/T2/T3 |
| 2 | What problem do they have? | | T1/T2/T3 |
| 3 | Why is this problem acute? | | T1/T2/T3 |
| 4 | Why hasn't this been solved? | | T1/T2/T3 |
| 5 | What is your unfair advantage? | | T1/T2/T3 |
| 6 | How will you reach users? | | T1/T2/T3 |
| 7 | How will you make money? | | T1/T2/T3 |

## Jobs-to-be-Done

"When [situation], I want to [motivation], so I can [outcome]."

## Riskiest Assumption

**Assumption**: [what must be true for this to work]
**Risk if wrong**: [what happens]
**How to test**: [cheapest, fastest validation method]

## Verdict

**Assessment**: Proceed to discovery / Iterate on idea / Kill
**Reasoning**: [2-3 sentences]
**Open questions**: [what still needs answers]
```

---

## Discovery Log

**Path**: `product-lab/discovery.md`

```markdown
# Discovery: [Idea Name]

**Stage entered**: YYYY-MM-DD
**Interviews completed**: X / 10 minimum

## Interview Log

### Interview 1: [Name/Role] — YYYY-MM-DD
- **Context**: [their situation]
- **Pain level**: X/5
- **Key quotes**: "[verbatim]"
- **Current solution**: [how they cope today]
- **Willingness to pay/try**: [specific commitment or lack thereof]
- **Surprise insight**: [anything unexpected]

[Repeat for each interview]

## Pain Patterns

| Pattern | Frequency | Example Quote | Evidence Tier |
|---|---|---|---|
| [pattern] | X of Y interviews | "[quote]" | T1/T2 |

## Assumption Validation

| Assumption | Pre-discovery status | Post-discovery status | Evidence |
|---|---|---|---|
| [from evaluation] | Assumed (T3) | Validated/Invalidated/Unclear | [what you learned] |

## Evidence Assessment

- **Strongest signal**: [most compelling finding]
- **Biggest concern**: [most worrying finding]
- **Surprise**: [what you didn't expect]

## Discovery Readiness Checklist

- [ ] 10+ interviews completed
- [ ] Consistent pain pattern across 5+ interviews
- [ ] Users have existing workarounds
- [ ] 3+ users expressed willingness to pay/try
- [ ] Riskiest assumption has T1/T2 evidence

**Recommendation**: Ready for MVP / Need more interviews / Pivot / Kill
```

---

## MVP Scope

**Path**: `product-lab/mvp-scope.md`

```markdown
# MVP Scope: [Idea Name]

**Stage entered**: YYYY-MM-DD
**Target ship date**: YYYY-MM-DD (8 weeks max)

## Core Hypothesis

"We believe [action] will result in [outcome] because [evidence]. We'll know we're right when [measurable signal]."

## Assumption Map

| Assumption | Risk if Wrong | Cost to Test | Priority |
|---|---|---|---|
| [assumption] | High/Med/Low | High/Med/Low | Test first / Test second / Can wait |

## Scope

| Category | Item | Reasoning |
|---|---|---|
| **IN** | [feature/capability] | [why essential for hypothesis test] |
| **OUT** | [feature/capability] | [why excluded] |
| **LATER** | [feature/capability] | [trigger for inclusion] |

## First Users

| Name | Context | Outreach Plan | Status |
|---|---|---|---|
| [actual name] | [their situation] | [how you'll reach them] | Contacted / Committed / Using |

## Success Criteria

- **Primary metric**: [what you'll measure]
- **Target**: [specific number]
- **Kill criteria**: [what evidence makes you stop]

## 8-Week Timeline

| Week | Milestone | Deliverable |
|---|---|---|
| 1 | [milestone] | [deliverable] |
| 2 | [milestone] | [deliverable] |
| ... | | |
| 8 | Launch to first users | MVP live + feedback collection |
```

---

## Launch Plan

**Path**: `product-lab/launch-plan.md`

```markdown
# Launch Plan: [Idea Name]

**Launch date**: YYYY-MM-DD

## First Users

| Name | Outreach | Onboarding Plan | Status |
|---|---|---|---|
| [name] | [channel] | [personal onboarding steps] | Reached out / Onboarded / Active |

## Outreach Sequence

1. [Step 1 — personal, specific]
2. [Step 2 — follow-up]
3. [Step 3 — if no response]

## Pricing

- **Model**: [free trial / freemium / paid from day one]
- **Price point**: [amount]
- **Justification**: [why this price]

## Feedback Channels

| Channel | Purpose | Frequency |
|---|---|---|
| [e.g., weekly call] | Deep qualitative feedback | Weekly |
| [e.g., in-app] | Usage friction points | Continuous |
| [e.g., email] | Feature requests, complaints | As received |

## Daily Tracking

| Metric | How Measured | Target |
|---|---|---|
| Active users | [source] | [target] |
| Key action completion | [source] | [target] |
| Revenue | [source] | [target] |
```

---

## PMF Assessment

**Path**: `product-lab/pmf-assessment.md`

```markdown
# PMF Assessment: [Idea Name]

**Assessment date**: YYYY-MM-DD

## Sean Ellis Test

**Question**: "How would you feel if you could no longer use [product]?"

| Response | Count | Percentage |
|---|---|---|
| Very disappointed | X | X% |
| Somewhat disappointed | X | X% |
| Not disappointed | X | X% |

**Score**: X% very disappointed (target: 40%+)

## Segment Analysis

| Segment | Very Disappointed % | What They Love | N |
|---|---|---|---|
| [segment] | X% | [key value] | X |

**Best segment**: [which segment has highest score and why]

## Retention Data

| Timeframe | Retention Rate | Benchmark |
|---|---|---|
| Day 1 | X% | 40%+ good |
| Day 7 | X% | 20%+ good |
| Day 30 | X% | 10%+ good |

## Push→Pull Assessment

- **Current state**: Pushing / Transitioning / Pulling
- **Evidence**: [how you know]
- **Organic growth signals**: [word of mouth, referrals, inbound]

## Momentum Direction

- [ ] User count growing
- [ ] Engagement deepening
- [ ] Revenue increasing
- [ ] Organic growth appearing
- [ ] Sales cycle shortening

**Overall**: Accelerating / Steady / Decelerating / Stalled

## Verdict

**PMF status**: Achieved / Approaching / Not yet / Need to pivot
**Reasoning**: [2-3 sentences]
**Next action**: [specific next step]
```

---

## Positioning

**Path**: `product-lab/positioning.md`

```markdown
# Positioning: [Idea Name]

**Date**: YYYY-MM-DD

## Dunford's Five Components

### 1. Competitive Alternatives
What customers would use if this product didn't exist:
- [Alternative 1] — [what it does well, what it lacks]
- [Alternative 2] — [what it does well, what it lacks]
- "Do nothing / status quo" — [current cost of inaction]

### 2. Unique Attributes
What we have that alternatives don't:
- [Attribute 1] — [vs. which alternative]
- [Attribute 2] — [vs. which alternative]

### 3. Value (Attributes → Outcomes)
| Attribute | Enables | User Outcome |
|---|---|---|
| [attribute] | [capability] | [what user achieves] |

### 4. Target Customer Characteristics
Who cares most about our value:
- **Situation**: [what they're dealing with]
- **Trigger**: [what makes them start looking for a solution]
- **Must-have**: [the capability they can't compromise on]

### 5. Market Category
- **Category**: [market we're competing in]
- **Why this category**: [why our strengths are strengths here]
- **Category trend**: [is this market growing, shifting, emerging?]

## Messaging

### One-liner
[How users describe the product to others — use their words]

### Value proposition
[2-3 sentences: what it is, who it's for, why it's different]

### Proof points
- [Evidence point 1]
- [Evidence point 2]
- [Evidence point 3]
```

---

## Growth Engine

**Path**: `product-lab/growth-engine.md`

```markdown
# Growth Engine: [Idea Name]

**Date**: YYYY-MM-DD

## Business Model

- **Type**: [SaaS / marketplace / e-commerce / subscription / etc.]
- **Revenue mechanism**: [how money flows]
- **Unit economics**: CAC $X, LTV $X, LTV/CAC ratio X

## North Star Metric

- **Metric**: [the one number that matters most]
- **Current value**: [number]
- **Target**: [number by date]
- **Why this metric**: [how it connects to real value delivery]

## Primary Acquisition Channel

- **Channel**: [where users come from]
- **CAC**: $X
- **Volume**: X users/month
- **Trend**: Growing / Stable / Declining
- **Channel #2 (backup)**: [next channel to develop]

## Weekly Sprint Template

### This Week
- **Focus metric**: [one metric]
- **Experiment**: [what we're testing]
- **Hypothesis**: [expected outcome]

### Last Week Results
- **Experiment**: [what we tested]
- **Result**: [what happened]
- **Decision**: Double down / Iterate / Kill

## Growth Levers

| Lever | Current State | Potential Impact | Effort |
|---|---|---|---|
| [lever] | [where it is now] | High/Med/Low | High/Med/Low |

## Risks

- [Risk 1: e.g., channel dependency]
- [Risk 2: e.g., rising CAC]
- [Risk 3: e.g., retention decay]
```

---

## Interview Guide

**Path**: `product-lab/interview-guide.md`

```markdown
# Interview Guide: [Idea Name]

**Stage**: [current stage]
**Date**: YYYY-MM-DD

## Context
[What we know so far, what we're trying to learn]

## Questions

### Opening (build rapport, 2-3 min)
- [Warm-up question about their role/situation]

### Core Questions (15-20 min)
1. [Question] — **Listen for**: [signal]
2. [Question] — **Listen for**: [signal]
3. [Question] — **Listen for**: [signal]
4. [Question] — **Listen for**: [signal]
5. [Question] — **Listen for**: [signal]

### Deeper Dive (5-10 min)
- [Follow-up on pain points that emerge]
- "Tell me more about that..."
- "Why was that hard?"

### Closing (2-3 min)
- "Is there anything I should have asked but didn't?"
- "Who else should I talk to about this?"

## Red Flags (stop and reassess if you hear these)
- [Red flag 1]
- [Red flag 2]

## Do NOT
- Pitch the solution before understanding the problem
- Ask leading questions ("Wouldn't it be great if...")
- Talk more than 30% of the time
- Accept compliments as validation
```

---

## Pivot Assessment

**Path**: `product-lab/pivot-assessment.md`

```markdown
# Pivot Assessment: [Idea Name]

**Date**: YYYY-MM-DD
**Current stage**: [stage]
**Time invested**: [weeks/months]

## Evidence Review

### What's Working
| Signal | Evidence | Tier |
|---|---|---|
| [signal] | [data/quote] | T1/T2/T3 |

### What's Not Working
| Signal | Evidence | Tier |
|---|---|---|
| [signal] | [data/quote] | T1/T2/T3 |

### Unresolved Questions
- [Question 1 — what we still don't know]
- [Question 2]

## Assessment Matrix

| Factor | Iterate | Pivot | Kill |
|---|---|---|---|
| Problem validity | Problem is real | Problem is real but different | Problem doesn't exist |
| Solution fit | Directionally right | Wrong approach | No approach works |
| User engagement | Some traction | Wrong users or wrong value | No engagement |
| Market timing | Market exists | Market exists elsewhere | No market |
| Team energy | Motivated | Motivated for new angle | Depleted |

## Recommendation

**Verdict**: Iterate / Pivot / Kill

**If iterate**: [what specifically to change and why]
**If pivot**: [new direction and why — what evidence supports it]
**If kill**: [why stopping is the right call — what was learned]

## Lessons Learned
- [Lesson 1 — applicable to future ideas]
- [Lesson 2]
```
