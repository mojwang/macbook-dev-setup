# Stage Playbooks

Per-stage decision logic for the product strategist. Each stage has clear entry conditions, a central question, activities, and evidence gates that must be met before advancing.

---

## Stage 1: Ideation

**Entry condition**: A raw idea exists — could be a sentence, a frustration, a market observation, or a "what if."

**Key question**: Is this idea worth investigating?

**Opening diagnostic** (ask before doing anything):
- "Describe the idea in one sentence — who is it for and what does it do?"
- "Why you? What's your connection to this problem?"
- "How did this idea come to you? Was it from your own experience, someone else's pain, or a market observation?"
- "Have you seen anyone else attempt this? What happened?"

**Activities**:
- Run full idea evaluation (3 properties, tarpit detection, evaluation checklist)
- Research competitive landscape — who else is in this space, who tried and failed
- Identify the riskiest assumption in the idea
- Assess founder-market fit honestly

**Evidence gates** (all required to advance):
- [ ] Idea passes tarpit detection (no more than 2 of 4 tarpit properties)
- [ ] All 7 evaluation checklist questions have at least preliminary answers
- [ ] Riskiest assumption identified and a plan exists to test it
- [ ] Founder can articulate a specific, narrow target user (not "everyone")

**Artifact produced**: `product-lab/ideas/[name]/evaluation.md`

**Red flags**:
- Founder can't name a single person who has this problem
- The idea requires changing deeply ingrained user behavior
- "No one has tried this before" (they almost certainly have — look harder)
- The primary motivation is "this would be cool to build" rather than "people need this"

---

## Stage 2: Discovery

**Entry condition**: Idea has passed evaluation. Target user segment identified. Ready to talk to real humans.

**Key question**: Do real people have this problem, and is it painful enough to pay for a solution?

**Opening diagnostic**:
- "Have you talked to any potential users yet? How many? What did you learn?"
- "Describe your target user — not demographics, but their situation and frustration."
- "What's your current assumption about why this problem exists?"
- "How are people solving this problem today?"

**Activities**:
- Design and conduct 10-15 user interviews using the research protocol
- Log every interview: who, key quotes, pain level (1-5), current solutions, willingness to pay
- Identify pain patterns — what comes up across multiple interviews
- Test riskiest assumptions with real evidence
- Distinguish reported pain from observed behavior

**Evidence gates** (all required to advance):
- [ ] 10+ user interviews completed and logged
- [ ] Consistent pain pattern identified across 5+ interviews
- [ ] Users have existing workarounds (proves they care enough to act)
- [ ] At least 3 users expressed willingness to pay or try a solution
- [ ] Riskiest assumption from ideation has T1 or T2 evidence (not just T3)

**Artifact produced**: `product-lab/discovery.md`

**Red flags**:
- Users say "that sounds cool" but won't commit to trying it
- Pain is real but mild — inconvenience, not suffering
- Every interview reveals a different problem (no convergence)
- Users already have a good-enough solution they're happy with
- You're pitching during interviews instead of listening

---

## Stage 3: MVP

**Entry condition**: Discovery validated a real, painful problem. Target users identified by name. Ready to build the smallest thing that tests the core hypothesis.

**Key question**: Can we build something in 8 weeks that tests our riskiest assumption?

**Opening diagnostic**:
- "What's the one thing this MVP must do to test your hypothesis?"
- "Name your first 5 users — actual humans, not personas."
- "What will you measure to know if it's working?"
- "What evidence would make you stop and rethink?"

**Activities**:
- Define the core hypothesis: "We believe [action] will result in [outcome] because [evidence]"
- Map assumptions by risk × cost-to-test
- Set ruthless scope boundaries (IN/OUT/LATER)
- Identify first 5 users by name and plan outreach
- Set 8-week timeline with weekly milestones
- Define kill criteria before building starts

**Evidence gates** (all required to advance):
- [ ] Core hypothesis written and falsifiable
- [ ] Scope fits in 8 weeks (if not, cut until it does)
- [ ] First 5 users identified by name with outreach plan
- [ ] 1-2 measurable success criteria defined
- [ ] Kill criteria defined (what evidence would make you stop)
- [ ] Assumption map complete — riskiest assumption is what MVP tests

**Artifact produced**: `product-lab/mvp-scope.md`

**Red flags**:
- MVP scope keeps growing ("just one more feature")
- No named first users — only abstract market segments
- Success criteria are vanity metrics (signups, pageviews) not engagement or revenue
- "We need to build the whole thing for it to make sense" (almost never true)
- No kill criteria defined

---

## Stage 4: Launch

**Entry condition**: MVP is built (or concierge version is operational). First users identified. Feedback channels ready.

**Key question**: Will real users engage with this enough to provide signal?

**Opening diagnostic**:
- "Is the MVP live and usable? What's the current state?"
- "Have you reached out to your first 5 users? What happened?"
- "How will you collect feedback — where and how often?"
- "Are you charging? If not, why not?"

**Activities**:
- Execute outreach to first users (personal, one-at-a-time, not blast email)
- Onboard each user personally — do things that don't scale
- Set up lightweight feedback channels (not a survey — conversations)
- Track daily: who's using it, how often, what they do, what they skip
- Capture verbatim quotes — both positive and negative
- Determine pricing (charge from day one, even if it's small)

**Evidence gates** (all required to advance):
- [ ] 5+ real users have tried the product
- [ ] Usage data collected for 2+ weeks
- [ ] At least 3 users gave substantive feedback (not just "looks nice")
- [ ] Revenue exists (any amount) or clear evidence for why free trial is strategic
- [ ] You know which features users actually use vs. which they ignore

**Artifact produced**: `product-lab/launch-plan.md`

**Red flags**:
- Users try it once and don't come back
- All feedback is polite but vague ("it's nice")
- Nobody will pay anything, even a token amount
- You're avoiding launching because it's "not ready yet"
- Users use it differently than you expected (this is actually a signal, not a failure)

---

## Stage 5: PMF (Product-Market Fit)

**Entry condition**: Launched and live with real users. Usage data and feedback collected. Time to assess: is this working?

**Key question**: Would users be very disappointed if this product disappeared?

**Opening diagnostic**:
- "How many active users do you have? What's the trend — growing, flat, declining?"
- "Run the PMF test yet? What percentage said 'very disappointed'?"
- "Are users coming back without being prompted? How often?"
- "Are users telling others about it? How do you know?"

**Activities**:
- Run PMF survey: "How would you feel if you could no longer use this?"
- Segment users — find the cohort where "very disappointed" is highest
- Analyze what "very disappointed" users love — double down on that
- Track retention curves: D1, D7, D30
- Assess push→pull transition: are you still pushing, or are users pulling?
- Interview "very disappointed" users to understand what makes them love it
- Interview "not disappointed" users to understand why they signed up

**Evidence gates** (all required to advance):
- [ ] PMF test completed with 40%+ "very disappointed" in at least one segment
- [ ] Retention data shows flattening curve (users stick around)
- [ ] Word-of-mouth or organic growth detected
- [ ] Clear understanding of what core users love and why
- [ ] Push→pull transition beginning (inbound > outbound effort)

**Artifact produced**: `product-lab/pmf-assessment.md`

**Red flags**:
- PMF score below 40% across all segments
- Retention curve never flattens — continuous decay
- All growth is paid/push, no organic pull
- You're adding features hoping to find PMF (feature creep ≠ product-market fit)
- Users who pay are different from users who love it

---

## Stage 6: Positioning

**Entry condition**: PMF achieved in at least one segment. You know who loves the product and why. Time to make that obvious to the market.

**Key question**: How do we frame this product so its value is immediately obvious to the right people?

**Opening diagnostic**:
- "Who are your best customers — the ones who love it most? What do they have in common?"
- "What would these customers use if your product disappeared tomorrow?"
- "What do you do that those alternatives can't?"
- "How do your best customers describe your product to others?"

**Activities**:
- Map competitive alternatives from the customer's perspective
- Identify unique attributes vs. each alternative
- Translate attributes into value (features → outcomes)
- Define target customer characteristics (not demographics — buying triggers)
- Choose market category that makes your strengths obvious
- Draft messaging that reflects how users already describe the product

**Evidence gates** (all required to advance):
- [ ] Competitive alternatives mapped from customer perspective
- [ ] Unique attributes identified and mapped to value
- [ ] Target customer characteristics defined by behavior/situation, not demographics
- [ ] Market category chosen and justified
- [ ] Messaging tested with 5+ target customers for resonance

**Artifact produced**: `product-lab/positioning.md`

**Red flags**:
- Positioning is based on what you want to be, not what users say you are
- Market category is so broad it's meaningless ("productivity tool")
- Unique attributes are features nobody asked for
- You can't name a competitive alternative (either you're not looking or the problem doesn't exist)
- Messaging sounds like every other product in the category

---

## Stage 7: Growth

**Entry condition**: PMF achieved and positioning defined. Product works, users love it, messaging resonates. Time to scale.

**Key question**: What's the repeatable, measurable engine that drives sustainable growth?

**Opening diagnostic**:
- "What's your business model? How does revenue work?"
- "Where do your best users come from today? What channel?"
- "What's your current growth rate? Is it accelerating, linear, or decelerating?"
- "How much does it cost to acquire a user? What's their lifetime value?"

**Activities**:
- Define the growth model tied to business model (see metrics framework)
- Identify primary acquisition channel and double down
- Set up weekly sprint cycle: measure → experiment → decide
- Establish north star metric and track weekly
- Model unit economics: CAC, LTV, payback period
- Design referral or viral loops if organic growth is present
- Plan: when does current channel max out? What's channel #2?

**Evidence gates** (ongoing — growth is a continuous stage):
- [ ] North star metric defined and tracked weekly
- [ ] Primary acquisition channel identified with measurable CAC
- [ ] LTV/CAC ratio > 3 (or improving toward it)
- [ ] Weekly sprint cycle operational (measure → experiment → decide)
- [ ] Growth rate is stable or accelerating (not decelerating)

**Artifact produced**: `product-lab/growth-engine.md`

**Red flags**:
- Growth is entirely paid with no organic component
- CAC is increasing while LTV is flat
- No repeatable acquisition channel — each user is a one-off effort
- Metric focus changes weekly (sign of no real understanding of growth levers)
- Team is focused on new features instead of distribution
