---
name: competitive-audit
description: Structured competitive website audit framework for any vertical.
disable-model-invocation: true
argument-hint: "[industry/vertical] [--sites site1.com,site2.com]"
allowed-tools: Bash, Read, Write
---

# Competitive Audit Skill

Structured framework for auditing competitor websites and synthesizing actionable design recommendations.

## Phase 1: Site Selection

### If sites provided via `--sites`:
- Validate each site is live (HTTP 200)
- Categorize as direct competitor or aspirational

### If no sites provided:
- Research the industry/vertical to identify:
  - 4-5 direct competitors (same market, geography, service type)
  - 3-5 aspirational sites (best-in-class in adjacent markets)
- Validate all sites are live
- Present list with rationale for user approval before proceeding

## Phase 2: Per-Site Audit

For each approved site, capture and analyze:

### Visual Design
- Playwright screenshots: desktop (1440px) + mobile (390px) for homepage and 2-3 key pages
- Color palette extraction (primary, secondary, accent, neutrals)
- Typography system (headings, body, font families, sizes)
- White space and density patterns

### Navigation & Information Architecture
- Primary navigation structure and labeling
- Mobile navigation pattern (hamburger, bottom nav, etc.)
- Footer organization and link hierarchy
- Breadcrumbs, search, and wayfinding

### Trust & Credibility Signals
- Certifications, awards, affiliations displayed
- Testimonials and social proof placement
- Provider credentials and bios
- Insurance/payment information visibility

### Conversion Strategy
- Primary CTA design and placement
- Secondary conversion paths
- Contact methods (phone, form, chat, booking)
- Above-the-fold value proposition

### Content Strategy
- Content types and formats used
- Blog/resource center presence
- Service page depth and structure
- Patient/customer education content

## Phase 3: Synthesis

### Pattern Frequency Matrix
Create a matrix showing which patterns appear across how many competitors:
- Navigation patterns
- CTA types and placements
- Trust signal types
- Content formats

### Gap Analysis
Compare audit findings against the current site:
- Features/patterns competitors have that we lack
- Unique differentiators we have
- Industry table-stakes we're missing

### Prioritized Recommendations
For each recommendation:
- **Priority**: P0 (table stakes) / P1 (competitive advantage) / P2 (nice-to-have)
- **Effort**: S/M/L
- **Impact**: Description of expected outcome
- **Reference**: Which competitor sites demonstrate this well

## Deliverable

Output to `docs/design/competitive-audit.md` with:
1. Executive summary
2. Per-site analysis (with screenshot references)
3. Pattern frequency matrix
4. Gap analysis vs current site
5. Prioritized recommendations with effort/impact
