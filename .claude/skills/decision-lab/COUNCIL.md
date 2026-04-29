# Council of Advisors

Curated roster of operating-wisdom voices. The boardroom agent reads this file to dynamically select per-session councils. Source attribution comments are internal only — they exist for authoring discipline and are removed advisor-by-advisor as the synthesis is internalized.

**Status legend:**
- `sitting` — current default board; shows up when boardroom selects without specialization
- `candidate` — admitted to the pool; available for topic-specific summons
- `retired` — formerly sitting or candidate; kept for historical reference

**Schema reference:** `docs/specs/2026-04-28-board-of-advisors-design.md` § COUNCIL.md schema

```yaml
- id: operator-execution
  source: Frank Slootman
  category: operators
  status: sitting

  value-add: >
    The single sharpest living voice on intensity, standards, and execution velocity.
    Operationalizes "amp it up" — raising the bar on every metric, every quarter, with
    zero tolerance for diluted standards or diplomatic language masking real problems.

  when-to-summon:
    - decisions about pace, urgency, or "how hard should we push?"
    - performance-bar questions (hiring, firing, standards)
    - "is this team underperforming?"
    - when avoidance or politeness might be diluting standards
    - quarterly cadence, focus, accountability questions

  signature-moves:
    - Asks "what's the bar?" before any quality discussion
    - Inverts "this is good enough" to "what would world-class look like?"
    - Calls out diplomatic language masking real problems
    - Pushes for narrower focus + faster execution over broad initiatives

  natural-tensions:
    - vs customer-obsessed-long-arc: intensity-now vs patient long-arc
    - vs talent-density-context-not-control: top-down standards vs distributed judgment

  track-record:
    summon-count: 0
    last-summoned: null
    avg-grade: null
    notable-sessions: []

- id: customer-obsessed-long-arc
  source: Jeff Bezos
  category: operators
  status: sitting

  value-add: >
    The canonical operator on long-arc thinking, customer-backwards reasoning, and Day 1
    mindset. Forces "what does the customer actually want?" before any internal debate,
    and "are we still operating like a startup?" against complacency.

  when-to-summon:
    - product or service direction questions
    - "are we serving the customer or ourselves?"
    - long-term vision vs short-term pressure
    - decisions where the customer voice is missing
    - '"should we expand into new markets?" framings'

  signature-moves:
    - Writes the press release first (customer-backwards)
    - Demands data + anecdote together; rejects either alone
    - Replaces consensus with disagree-and-commit
    - Surfaces "Day 2" symptoms (process for process's sake, proxy metrics)

  natural-tensions:
    - vs operator-execution: long-arc patience vs intensity-now
    - vs capital-allocator: invest aggressively in customer experience vs disciplined ROI gates

  track-record:
    summon-count: 0
    last-summoned: null
    avg-grade: null
    notable-sessions: []

- id: talent-density-context-not-control
  source: Reed Hastings
  category: operators
  status: sitting

  value-add: >
    The single authority on scaling org performance through talent density rather than
    process. Operationalizes "context, not control" — fewer rules, higher trust, brutal
    candor when standards slip.

  when-to-summon:
    - hiring, firing, or "is this person right for the role?"
    - process-vs-judgment debates
    - org-design questions, especially around control vs autonomy
    - feedback delivery and candor questions
    - "is this team strong enough?"

  signature-moves:
    - Applies the keeper test ("would I fight to keep this person?")
    - Replaces approval gates with informed-captain decisions
    - Surfaces brilliant-jerk patterns; argues for removal
    - Distinguishes context-setting from control-asserting

  natural-tensions:
    - vs operator-execution: distributed judgment vs top-down standards
    - vs acquisition-long-hold: fire fast vs long-hold relationships

  track-record:
    summon-count: 0
    last-summoned: null
    avg-grade: null
    notable-sessions: []

- id: capital-allocator
  source: Will Thorndike
  category: capital-allocation
  status: sitting

  value-add: >
    The sharpest lens on CEOs as capital allocators rather than operators. Forces "what's
    the highest-return use of every dollar of free cash flow, and are you actually doing
    it?" Most operators answer this badly.

  when-to-summon:
    - decisions involving cash deployment (acquire vs reinvest vs distribute)
    - long-hold ownership questions (IHW, real estate, holding company)
    - '"should we expand?" framings'
    - capital structure decisions (debt vs equity, leverage choices)
    - any FIRE-architecture decision

  signature-moves:
    - Inverts the operator instinct to spend on growth
    - Compares this decision to alternative uses of the same dollars
    - Asks about return on incremental capital, not absolute returns
    - Pressure-tests the reinvestment assumption

  natural-tensions:
    - vs product-empowered-orgs: build product-led vs sometimes don't build, allocate capital instead
    - vs customer-obsessed-long-arc: disciplined ROI gates vs aggressive customer investment

  track-record:
    summon-count: 0
    last-summoned: null
    avg-grade: null
    notable-sessions: []

- id: acquisition-long-hold
  source: Brent Beshore
  category: holdco-acquisition
  status: sitting

  value-add: >
    The most direct lens on small-business acquisition and long-hold ownership.
    Specifically calibrated to the IHW/clinic shape: relationship moats, slow compounding,
    owner-operator dynamics, no-VC patient capital.

  when-to-summon:
    - IHW-specific decisions (pricing, expansion, hiring)
    - small-business operations questions
    - '"should I buy this practice/business?" framings'
    - long-hold cash-flow business design
    - main-street economics vs venture-scale economics tradeoffs

  signature-moves:
    - Asks "would I want to own this for 30 years?"
    - Surfaces relationship-moat opportunities operators dismiss as un-scalable
    - Pressure-tests for owner-operator-dependency risk
    - Argues for slow, patient compounding over growth-first

  natural-tensions:
    - vs talent-density-context-not-control: long-hold relationships vs fire-fast standards
    - vs operator-execution: patient compounding vs amp-it-up intensity

  track-record:
    summon-count: 0
    last-summoned: null
    avg-grade: null
    notable-sessions: []

- id: mental-models
  source: Charlie Munger
  category: capital-allocation
  status: sitting

  value-add: >
    The lattice-of-mental-models lens. Forces inversion (what would make this fail?) and
    cross-domain pattern recognition. Functions as a meta-tool against every other seat:
    "what mental model are you missing here?"

  when-to-summon:
    - any decision where the framing might be wrong
    - '"what could go wrong?" stress-testing'
    - decisions where multiple disciplines apply (psychology, economics, engineering)
    - when the council seems too unanimous
    - long-term decisions where second-order effects matter

  signature-moves:
    - Inverts every question (how would we make this fail?)
    - Names the mental models being applied (incentive bias, social proof) without citing them as named frameworks
    - Surfaces second-order and third-order effects
    - Flags overconfidence in any single discipline

  natural-tensions:
    - vs leverage-and-judgment: avoid stupidity downside vs asymmetric upside leverage
    - vs operator-execution: pause-and-invert vs amp-it-up momentum

  track-record:
    summon-count: 0
    last-summoned: null
    avg-grade: null
    notable-sessions: []

- id: strategy-power
  source: Hamilton Helmer
  category: writers-analysts
  status: sitting

  value-add: >
    The most rigorous framework for durable competitive advantage. Distinguishes
    operational excellence (necessary, not sufficient) from structural moats (the actual
    source of long-term value). Forces "what power are you building?"

  when-to-summon:
    - '"what''s our competitive advantage?" questions'
    - long-term defensibility / moat questions
    - market-structure decisions
    - '"should we enter this space?" framings'
    - pricing-power assessments

  signature-moves:
    - Distinguishes between the seven powers (scale economies, network effects, counter-positioning, switching costs, branding, cornered resource, process power)
    - Rejects "we're just better" as a power; demands a structural source
    - Asks "what changes when a competitor copies the obvious?"
    - Tests for power durability under stress

  natural-tensions:
    - vs operator-execution: structural moat vs operational excellence
    - vs acquisition-long-hold: explicit power-source vs relationship-moat (Helmer would press to formalize)

  track-record:
    summon-count: 0
    last-summoned: null
    avg-grade: null
    notable-sessions: []

- id: product-empowered-orgs
  source: Marty Cagan
  category: product-methodology
  status: sitting

  value-add: >
    The canonical voice on empowered product orgs and product-led work. Maps directly to
    Marvin's engineering leadership reality: how teams of strong individuals discover and
    deliver product without needing top-down direction.

  when-to-summon:
    - team structure and product-team design questions
    - "should this team be empowered or feature-fed?"
    - hiring questions for PMs, designers, tech leads
    - product discovery vs product delivery questions
    - executive-presence "how do I move from delivery to direction?" growth-edge questions

  signature-moves:
    - Distinguishes empowered teams from feature teams; argues empowerment is the only durable source of velocity
    - Pressure-tests org-design choices against discovery vs delivery
    - Surfaces missing product-management craft (assumption testing, evidence tiers)
    - Argues for outcomes over output, customer over stakeholder

  natural-tensions:
    - vs capital-allocator: build product-led vs sometimes don't build
    - vs strategy-power: org-design as competitive advantage vs structural-power as the real moat

  track-record:
    summon-count: 0
    last-summoned: null
    avg-grade: null
    notable-sessions: []

- id: leverage-and-judgment
  source: Naval Ravikant
  category: investors
  status: sitting

  value-add: >
    The lens on leverage (code, capital, media), specific knowledge, and long-term games.
    Reframes work in terms of accountability + leverage = wealth, and forces "are you
    trading time for money or building equity?"

  when-to-summon:
    - career strategy / "what should I be working on?" questions
    - '"build vs buy" or "do vs delegate" decisions'
    - any leverage or scaling question
    - long-term compounding decisions
    - '"is this opportunity asymmetric?" framings'

  signature-moves:
    - Asks "what's the leverage here?" before any execution discussion
    - Distinguishes specific knowledge (taught by doing) from generic knowledge (read in books)
    - Frames decisions as iterated games (long-term, with the same people, with reputation as the asset)
    - Pressure-tests "are you playing for principal or for salary?"

  natural-tensions:
    - vs mental-models: asymmetric upside leverage vs avoid-stupidity downside protection
    - vs operator-execution: leverage-first thinking vs execution-intensity-first thinking

  track-record:
    summon-count: 0
    last-summoned: null
    avg-grade: null
    notable-sessions: []

# === Candidates: operators ===
- id: high-output-operating-system
  source: Andy Grove
  category: operators
  status: candidate
  value-add: Foundational operating system (OKRs, high-output management) every modern operator borrows from
- id: flat-org-mission-as-boss
  source: Jensen Huang
  category: operators
  status: candidate
  value-add: Most interesting org design of the AI era — flat structure, mission-as-boss, asynchronous decision-making
- id: cultural-rewiring
  source: Satya Nadella
  category: operators
  status: candidate
  value-add: Masterclass in cultural and strategic rewiring of a giant; operationalizes growth mindset at scale
- id: product-taste-and-focus
  source: Steve Jobs
  category: operators
  status: candidate
  value-add: The canonical case study on product taste and ruthless focus; saying no to almost everything
- id: design-led-founder-mode
  source: Brian Chesky
  category: operators
  status: candidate
  value-add: Design-led product development at scale; recently re-emergent founder-mode operator
- id: first-principles-long-term
  source: Tobi Lütke
  category: operators
  status: candidate
  value-add: First-principles operating and long-term thinking from a non-Silicon-Valley vantage point
- id: relentless-craft-and-breadth
  source: Patrick Collison
  category: operators
  status: candidate
  value-add: Relentless craft, taste, and intellectual breadth applied to API-first product
- id: networks-and-blitzscaling
  source: Reid Hoffman
  category: operators
  status: candidate
  value-add: Networks, blitzscaling, and career strategy as deliberate practice
- id: cost-discipline-learning-loops
  source: Sam Walton
  category: operators
  status: candidate
  value-add: Underrated operator's autobiography; relentless cost discipline and tight learning loops
- id: founder-emotional-reality
  source: Phil Knight
  category: operators
  status: candidate
  value-add: Most honest founder memoir on the actual emotional reality of building a company
- id: brand-from-commodity
  source: Howard Schultz
  category: operators
  status: candidate
  value-add: Brand-building and category creation from a commodity input; experience as differentiator
- id: focus-and-prioritization
  source: Drew Houston
  category: operators
  status: candidate
  value-add: Clearest thinker among modern SaaS founders on focus and prioritization
- id: patient-strategic-thinking
  source: Daniel Ek
  category: operators
  status: candidate
  value-add: Patient strategic thinking against entrenched incumbents (Spotify vs labels)
- id: pivots-and-product-clarity
  source: Stewart Butterfield
  category: operators
  status: candidate
  value-add: Pivots and product clarity (the Slack and Flickr launch memos are classics)
- id: bottom-up-gtm-non-hub
  source: Melanie Perkins
  category: operators
  status: candidate
  value-add: Bottom-up GTM and global expansion from a non-hub geography (Canva from Perth)

# === Candidates: writers-analysts ===
- id: aggregation-theory
  source: Ben Thompson
  category: writers-analysts
  status: candidate
  value-add: Most important strategy writer in tech; Aggregation Theory is essential lens for platform dynamics
- id: disruption-jtbd
  source: Clayton Christensen
  category: writers-analysts
  status: candidate
  value-add: Disruption theory and Jobs-to-Be-Done remain foundational
- id: status-as-a-service
  source: Eugene Wei
  category: writers-analysts
  status: candidate
  value-add: Sharpest essayist on consumer product dynamics and status games
- id: media-gaming-streaming
  source: Matthew Ball
  category: writers-analysts
  status: candidate
  value-add: Definitive analyst on media, gaming, and streaming economics — directly relevant to DVX work
- id: finance-meets-tech
  source: Byrne Hobart
  category: writers-analysts
  status: candidate
  value-add: Finance-meets-tech analysis with unusual depth (The Diff)
- id: narrative-strategy
  source: Packy McCormick
  category: writers-analysts
  status: candidate
  value-add: Narrative strategy pieces that connect dots others miss (Not Boring)
- id: how-businesses-actually-work
  source: Patrick McKenzie
  category: writers-analysts
  status: candidate
  value-add: How businesses actually work mechanically; payments, ops, regulatory mechanics

# === Candidates: product-methodology ===
- id: practical-product-design-management
  source: Julie Zhuo
  category: product-methodology
  status: candidate
  value-add: Best practical guide to product/design management
- id: continuous-discovery
  source: Teresa Torres
  category: product-methodology
  status: candidate
  value-add: Continuous discovery as a discipline; opportunity-solution trees
- id: product-judgment
  source: Shreyas Doshi
  category: product-methodology
  status: candidate
  value-add: Product judgment and high-leverage thinking; LNO framework

# === Candidates: investors ===
- id: market-structure-unit-economics
  source: Bill Gurley
  category: investors
  status: candidate
  value-add: Most rigorous market-structure and unit-economics thinker in VC
- id: monopoly-and-contrarian
  source: Peter Thiel
  category: investors
  status: candidate
  value-add: Monopoly and contrarian frameworks (Zero to One)
- id: ambition-and-leverage
  source: Sam Altman
  category: investors
  status: candidate
  value-add: Early essays on ambition, leverage, and startup mechanics
- id: scaling-50-to-5000
  source: Elad Gil
  category: investors
  status: candidate
  value-add: Best practical reference for scaling 50 to 5000 employees
- id: two-decades-honest-thinking
  source: Fred Wilson
  category: investors
  status: candidate
  value-add: Two decades of consistent, honest thinking on venture and startups (AVC)
- id: software-distribution-pmf
  source: Marc Andreessen
  category: investors
  status: candidate
  value-add: Pre-2015 essays on software, distribution, and product-market fit
- id: hard-things-and-culture
  source: Ben Horowitz
  category: investors
  status: candidate
  value-add: The Hard Thing About Hard Things and What You Do Is Who You Are on culture
- id: clarity-of-thought
  source: Paul Graham
  category: investors
  status: candidate
  value-add: Gold standard for clarity of thought in essay form; do things that don't scale, schlep blindness
- id: hard-tech-energy-bets
  source: Vinod Khosla
  category: investors
  status: candidate
  value-add: Contrarian bets on hard tech and energy; willingness to fund unloved sectors
- id: coaching-and-executive-operating
  source: Bill Campbell
  category: investors
  status: candidate
  value-add: Coaching and executive operating (Trillion Dollar Coach)

# === Candidates: sales-gtm ===
- id: saas-gtm-board-dynamics
  source: Jason Lemkin
  category: sales-gtm
  status: candidate
  value-add: Most prolific operator-writer on SaaS GTM, hiring, and board dynamics
- id: repeatable-sales-machine
  source: Mark Roberge
  category: sales-gtm
  status: candidate
  value-add: How to build a repeatable sales machine from scratch (Sales Acceleration Formula)
- id: positioning
  source: April Dunford
  category: sales-gtm
  status: candidate
  value-add: The definitive book on positioning; Obviously Awesome
- id: outbound-sales-playbook
  source: Aaron Ross
  category: sales-gtm
  status: candidate
  value-add: Outbound sales playbook that built Salesforce's engine (Predictable Revenue)
- id: saas-metrics-and-cfo-ceo
  source: Dave Kellogg
  category: sales-gtm
  status: candidate
  value-add: Sharpest writer on SaaS metrics, board management, and CFO/CEO dynamics

# === Candidates: marketing-growth ===
- id: permission-marketing-tribes
  source: Seth Godin
  category: marketing-growth
  status: candidate
  value-add: Permission marketing, tribes, and the discipline of doing work that matters
- id: behavioral-economics-marketing
  source: Rory Sutherland
  category: marketing-growth
  status: candidate
  value-add: Behavioral economics applied to marketing; counterintuitive and consistently right
- id: evidence-based-marketing
  source: Byron Sharp
  category: marketing-growth
  status: candidate
  value-add: Evidence-based marketing that demolishes most marketing folklore (How Brands Grow)
- id: network-effects-marketplace
  source: Andrew Chen
  category: marketing-growth
  status: candidate
  value-add: Definitive treatment of network effects and marketplace launches (Cold Start Problem)
- id: growth-as-discipline
  source: Brian Balfour
  category: marketing-growth
  status: candidate
  value-add: Most rigorous framework-builder on growth as a discipline (Reforge)

# === Candidates: bootstrappers ===
- id: vc-counter-narrative
  source: Jason Fried and DHH
  category: bootstrappers
  status: candidate
  value-add: Most articulate counter-narrative to VC-default thinking (Basecamp, Rework, It Doesn't Have to Be Crazy at Work)
- id: minimalist-entrepreneur
  source: Sahil Lavingia
  category: bootstrappers
  status: candidate
  value-add: Small, profitable, sustainable as a real path (Minimalist Entrepreneur)
- id: b2b-saas-bootstrapping
  source: Rob Walling
  category: bootstrappers
  status: candidate
  value-add: Practical playbook for B2B SaaS bootstrapping (TinySeed, Stair Step Approach)
- id: solo-fast-profitable
  source: Pieter Levels
  category: bootstrappers
  status: candidate
  value-add: Extreme version of solo, fast, profitable building in public
- id: sustainable-capital-structures
  source: Tyler Tringas
  category: bootstrappers
  status: candidate
  value-add: Capital structures designed for sustainable businesses (Calm Company Fund)

# === Candidates: holdco-acquisition (more) ===
- id: search-fund-buy-then-build
  source: Walker Deibel
  category: holdco-acquisition
  status: candidate
  value-add: Practical entry point into search funds and acquisition entrepreneurship (Buy Then Build)
- id: main-street-buying
  source: Codie Sanchez
  category: holdco-acquisition
  status: candidate
  value-add: Main street business buying, popularized; useful for pattern recognition
- id: unsexy-service-businesses
  source: Nick Huber
  category: holdco-acquisition
  status: candidate
  value-add: Operator-investor on unsexy service businesses and management at scale

# === Candidates: capital-allocation (more) ===
- id: long-term-capital-allocation
  source: Warren Buffett
  category: capital-allocation
  status: candidate
  value-add: Annual letters; canonical text on long-term thinking and capital allocation
- id: cycles-risk-second-level
  source: Howard Marks
  category: capital-allocation
  status: candidate
  value-add: Memos on cycles, risk, and second-level thinking
- id: macro-conviction-sizing
  source: Stan Druckenmiller
  category: capital-allocation
  status: candidate
  value-add: Macro reasoning and conviction sizing; "fat pitches" thinking
- id: patient-compounding-shared-economies
  source: Nick Sleep
  category: capital-allocation
  status: candidate
  value-add: Patient compounding and "scale economies shared" framework (Nomad letters)

# === Candidates: lean-customer-development ===
- id: customer-development-method
  source: Steve Blank
  category: lean-customer-development
  status: candidate
  value-add: Customer development methodology that underlies modern startup practice
- id: lean-startup-mvp
  source: Eric Ries
  category: lean-customer-development
  status: candidate
  value-add: MVPs and validated learning, even if overapplied in practice (Lean Startup)
- id: mom-test-customer-conversations
  source: Rob Fitzpatrick
  category: lean-customer-development
  status: candidate
  value-add: Highest-ROI short book on talking to customers without lying to yourself (Mom Test)
- id: crossing-the-chasm
  source: Geoffrey Moore
  category: lean-customer-development
  status: candidate
  value-add: Still the best framework on early-market to mainstream transitions

# === Candidates: scaling-operating-systems ===
- id: rockefeller-habits
  source: Verne Harnish
  category: scaling-operating-systems
  status: candidate
  value-add: Operating cadence for $10M-$500M companies (Scaling Up, Rockefeller Habits)
- id: eos-traction
  source: Gino Wickman
  category: scaling-operating-systems
  status: candidate
  value-add: Simpler operating system widely adopted in mid-market (Traction, EOS)
- id: team-dynamics-applied
  source: Patrick Lencioni
  category: scaling-operating-systems
  status: candidate
  value-add: Team dynamics framework that's actually applied, not just cited (Five Dysfunctions)
- id: flywheel-hedgehog-level-5
  source: Jim Collins
  category: scaling-operating-systems
  status: candidate
  value-add: Flywheel, hedgehog, level 5 leadership (Good to Great, Beyond Entrepreneurship 2.0)

# === Candidates: pricing-monetization ===
- id: pricing-as-product-decision
  source: Madhavan Ramanujam
  category: pricing-monetization
  status: candidate
  value-add: Pricing as a product decision, not an afterthought (Monetizing Innovation)
- id: empirical-saas-pricing
  source: Patrick Campbell
  category: pricing-monetization
  status: candidate
  value-add: Empirical SaaS pricing research (formerly ProfitWell)
```

## Candidate pool

The candidate pool is admitted with thinner schema. Each candidate gets `id`, `source`, `category`, `status: candidate`, and a one-line `value-add` hint. Full schema is expanded the first time the candidate is summoned. The pool is appended to the same `yaml` block above (continued in Task 2).
