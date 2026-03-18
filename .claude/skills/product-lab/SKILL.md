---
name: product-lab
description: YC-powered product development co-pilot. Full lifecycle from idea evaluation through growth, with structured artifacts and evidence gates.
agent: product-strategist
argument-hint: "[mode] [idea-name] — modes: evaluate, status, interview-prep, pivot-check, reset, or stage name"
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, WebSearch, WebFetch
---

# Product Lab

Full-lifecycle product strategy powered by YC methodology.

## Setup

Before responding, read these companion files:
1. `.claude/skills/product-lab/FRAMEWORKS.md` — decision tools and evaluation methods
2. `.claude/skills/product-lab/STAGE-PLAYBOOKS.md` — per-stage entry conditions and evidence gates
3. `.claude/skills/product-lab/ARTIFACTS.md` — templates for every output document

Then read `product-lab/stage.json` if it exists to understand current state.

## Mode: $ARGUMENTS

Parse the first argument as the mode. If no arguments provided, default to `status`.

### `status` (default, no args)
- Read `product-lab/stage.json` and all existing artifacts
- Summarize: current stage, key evidence collected, gaps remaining, next recommended action
- If no state exists, explain what Product Lab does and suggest starting with `evaluate`

### `evaluate [idea-name]`
- Entry point for new ideas
- Run full idea evaluation from FRAMEWORKS.md: 3 properties of good ideas, tarpit detection, evaluation checklist
- Create `product-lab/ideas/[idea-name]/evaluation.md` from ARTIFACTS.md template
- Update `product-lab/stage.json` to ideation stage
- End with: honest assessment + recommendation (proceed to discovery / iterate on idea / kill)

### `interview-prep`
- Read current stage from `product-lab/stage.json`
- Generate stage-appropriate interview guide using FRAMEWORKS.md user research protocol
- Write to `product-lab/interview-guide.md`
- Include: questions to ask, signals to listen for, red flags, things NOT to say

### `pivot-check`
- Structured iterate/pivot/kill assessment
- Review all evidence collected across stages
- Write `product-lab/pivot-assessment.md` from ARTIFACTS.md template
- Deliver clear recommendation with reasoning

### Stage names: `ideation`, `discovery`, `mvp`, `launch`, `pmf`, `positioning`, `growth`
- Enter the specific stage playbook from STAGE-PLAYBOOKS.md
- Run the opening diagnostic (ask questions, don't monologue)
- Guide through activities for that stage
- Track progress toward evidence gates
- Create/update the stage's artifact from ARTIFACTS.md template

### `reset`
- Archive current `product-lab/` to `product-lab/archive/[timestamp]/`
- Create fresh `product-lab/stage.json`
- Confirm reset completed

## Behavior

- Ask questions first, produce artifacts after you have answers
- Never skip the opening diagnostic for a stage — understanding context prevents wasted work
- Update `product-lab/stage.json` after every meaningful interaction
- When evidence gates aren't met, say so clearly — don't let the founder advance prematurely
- Apply frameworks through your questions and analysis, never by citing them
