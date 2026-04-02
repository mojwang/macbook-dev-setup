# UI/UX Pro Max - Design Knowledge Database Reference

Source: https://github.com/nextlevelbuilder/ui-ux-pro-max-skill
Extracted: 2026-04-01

## File Inventory

All raw CSV data files are saved alongside this report for direct use:

| File | Rows | Description |
|------|------|-------------|
| `ui-reasoning.csv` | 161 | Industry reasoning rules: style, color mood, typography, effects, decision rules, anti-patterns per product type |
| `colors.csv` | 161 | WCAG-compliant color palettes: Primary, Secondary, Accent, Background, Foreground, Card, Muted, Border, Destructive per product type |
| `typography.csv` | 72 | Font pairings: heading + body fonts with Google Fonts URLs, CSS imports, Tailwind configs, and usage notes |
| `styles.csv` | 71 | UI style definitions: keywords, colors, effects, best-for/avoid, framework compatibility, AI prompt keywords, CSS keywords, implementation checklists |
| `ux-guidelines.csv` | 98 | UX best practices: Do/Don't with code examples across Navigation, Animation, Layout, Touch, Interaction, Accessibility, Performance, Forms, Responsive, Typography, Feedback |
| `products.csv` | 162 | Product type -> style mapping: primary/secondary styles, landing page pattern, dashboard style, color focus, key considerations |
| `design.csv` | 1775 | Full design system definitions (large, cross-references other tables) |
| `google-fonts.csv` | 1924 | Google Fonts metadata catalog |
| `charts.csv` | 26 | Chart type recommendations for dashboards |
| `icons.csv` | 105 | Icon library recommendations |
| `landing.csv` | 35 | Landing page pattern definitions |
| `app-interface.csv` | 30 | App interface pattern definitions |

---

## 1. Industry Reasoning Rules (ui-reasoning.csv)

### Schema
`No, UI_Category, Recommended_Pattern, Style_Priority, Color_Mood, Typography_Mood, Key_Effects, Decision_Rules, Anti_Patterns, Severity`

### Key Decision Rules by Industry

**SaaS (General)**
- Pattern: Hero + Features + CTA
- Style: Glassmorphism + Flat Design
- Colors: Trust blue + Accent contrast
- Rule: `if_ux_focused -> prioritize-minimalism`, `if_data_heavy -> add-glassmorphism`
- Anti-patterns: Excessive animation, Dark mode by default

**E-commerce**
- Pattern: Feature-Rich Showcase
- Style: Vibrant & Block-based
- Colors: Brand primary + Success green
- Rule: `if_luxury -> switch-to-liquid-glass`, `if_conversion_focused -> add-urgency-colors`
- Anti-patterns: Flat design without depth, Text-heavy pages

**Healthcare App**
- Pattern: Social Proof-Focused
- Style: Neumorphism + Accessible & Ethical
- Colors: Calm blue + Health green
- Rule: `must_have -> wcag-aaa-compliance`, `if_medication -> red-alert-colors`
- Anti-patterns: Bright neon colors, Motion-heavy animations, AI purple/pink gradients

**Financial Dashboard**
- Pattern: Data-Dense Dashboard
- Style: Dark Mode (OLED) + Data-Dense
- Colors: Dark bg + Red/Green alerts + Trust blue
- Rule: `must_have -> real-time-updates`, `must_have -> high-contrast`
- Anti-patterns: Light mode default, Slow rendering

**AI/Chatbot Platform**
- Pattern: Interactive Demo + Minimal
- Style: AI-Native UI + Minimalism
- Colors: Neutral + AI Purple (#6366F1)
- Rule: `must_have -> conversational-ui`, `must_have -> context-awareness`
- Anti-patterns: Heavy chrome, Slow response feedback

**Government/Public Service**
- Pattern: Minimal & Direct
- Style: Accessible & Ethical + Minimalism
- Colors: Professional blue + High contrast
- Rule: `must_have -> wcag-aaa`, `must_have -> keyboard-navigation`
- Anti-patterns: Ornate design, Low contrast, Motion effects, AI purple/pink gradients

### Full Category Coverage (161 categories)
SaaS, Micro SaaS, E-commerce, E-commerce Luxury, B2B Service, Financial Dashboard, Analytics Dashboard, Healthcare App, Educational App, Creative Agency, Portfolio/Personal, Gaming, Government/Public Service, Fintech/Crypto, Social Media App, Productivity Tool, Design System/Component Library, AI/Chatbot Platform, NFT/Web3 Platform, Creator Economy Platform, Remote Work/Collaboration Tool, Mental Health App, Pet Tech App, Smart Home/IoT Dashboard, EV/Charging Ecosystem, Subscription Box Service, Podcast Platform, Dating App, Micro-Credentials/Badges Platform, Knowledge Base/Documentation, Hyperlocal Services, Beauty/Spa/Wellness Service, Luxury/Premium Brand, Restaurant/Food Service, Fitness/Gym App, Real Estate/Property, Travel/Tourism Agency, Hotel/Hospitality, Wedding/Event Planning, Legal Services, Insurance Platform, Banking/Traditional Finance, Online Course/E-learning, Non-profit/Charity, Music Streaming, Video Streaming/OTT, Job Board/Recruitment, Marketplace (P2P), Logistics/Delivery, Agriculture/Farm Tech, Construction/Architecture, Automotive/Car Dealership, Photography Studio, Coworking Space, Home Services, Childcare/Daycare, Senior Care/Elderly, Medical Clinic, Pharmacy/Drug Store, Dental Practice, Veterinary Clinic, Florist/Plant Shop, Bakery/Cafe, Brewery/Winery, Airline, News/Media Platform, Magazine/Blog, Freelancer Platform, Marketing Agency, Event Management, Membership/Community, Newsletter Platform, Digital Products/Downloads, Church/Religious Organization, Sports Team/Club, Museum/Gallery, Theater/Cinema, Language Learning App, Coding Bootcamp, Cybersecurity Platform, Developer Tool/IDE, Biotech/Life Sciences, Space Tech/Aerospace, Architecture/Interior, Quantum Computing Interface, Biohacking/Longevity App, Autonomous Drone Fleet Manager, Generative Art Platform, Spatial Computing OS/App, Sustainable Energy/Climate Tech, Personal Finance Tracker, Chat & Messaging App, Notes & Writing App, Habit Tracker, Food Delivery/On-Demand, Ride Hailing/Transportation, Recipe & Cooking App, Meditation & Mindfulness, Weather App, Diary & Journal App, CRM & Client Management, Inventory & Stock Management, Flashcard & Study Tool, Booking & Appointment App, Invoice & Billing Tool, Grocery & Shopping List, Timer & Pomodoro, Parenting & Baby Tracker, Scanner & Document Manager, Calendar & Scheduling App, Password Manager, Expense Splitter/Bill Split, Voice Recorder & Memo, Bookmark & Read-Later, Translator App, Calculator & Unit Converter, Alarm & World Clock, File Manager & Transfer, Email Client, Casual Puzzle Game, Trivia & Quiz Game, Card & Board Game, Idle & Clicker Game, Word & Crossword Game, Arcade & Retro Game, Photo Editor & Filters, Short Video Editor, Drawing & Sketching Canvas, Music Creation & Beat Maker, Meme & Sticker Maker, AI Photo & Avatar Generator, Link-in-Bio Page Builder, Wardrobe & Outfit Planner, Plant Care Tracker, Book & Reading Tracker, Couple & Relationship App, Family Calendar & Chores, Mood Tracker, Gift & Wishlist, Running & Cycling GPS, Yoga & Stretching Guide, Sleep Tracker, Calorie & Nutrition Counter, Period & Cycle Tracker, Medication & Pill Reminder, Water & Hydration Reminder, Fasting & Intermittent Timer, Anonymous Community/Confession, Local Events & Discovery, Study Together/Virtual Coworking, Coding Challenge & Practice, Kids Learning (ABC & Math), Music Instrument Learning, Parking Finder, Public Transit Guide, Road Trip Planner, VPN & Privacy Tool, Emergency SOS & Safety, Wallpaper & Theme App, White Noise & Ambient Sound

---

## 2. Color Palettes (colors.csv)

### Schema
`No, Product Type, Primary, On Primary, Secondary, On Secondary, Accent, On Accent, Background, Foreground, Card, Card Foreground, Muted, Muted Foreground, Border, Destructive, On Destructive, Ring, Notes`

All colors are WCAG-compliant with notes indicating adjustments made for contrast ratios.

### Quick Reference - Common Industry Palettes

| Product Type | Primary | Accent | Background | Notes |
|---|---|---|---|---|
| SaaS (General) | #2563EB | #EA580C | #F8FAFC | Trust blue + orange CTA |
| E-commerce | #059669 | #EA580C | #ECFDF5 | Success green + urgency orange |
| E-commerce Luxury | #1C1917 | #A16207 | #FAFAF9 | Premium dark + gold accent |
| Healthcare App | #0891B2 | #059669 | #ECFEFF | Calm cyan + health green |
| Financial Dashboard | #0F172A | #22C55E | #020617 | Dark bg + green indicators |
| AI/Chatbot Platform | #7C3AED | #0891B2 | #FAF5FF | AI purple + cyan interactions |
| Gaming | #7C3AED | #F43F5E | #0F0F23 | Neon purple + rose action |
| Restaurant/Food | #DC2626 | #A16207 | #FEF2F2 | Appetizing red + warm gold |
| Fitness/Gym | #F97316 | #22C55E | #1F2937 | Energy orange + success green |
| Real Estate | #0F766E | #0369A1 | #F0FDFA | Trust teal + professional blue |
| Cybersecurity | #00FF41 | #FF3333 | #000000 | Matrix green + alert red |
| Space Tech | #F8FAFC | #3B82F6 | #0B0B10 | Star white + launch blue |
| Meditation | #7C3AED | #059669 | #FAF5FF | Calm lavender + mindful green |
| Food Delivery | #EA580C | #2563EB | #FFF7ED | Appetizing orange + trust blue |

---

## 3. Typography Pairings (typography.csv)

### Schema
`No, Font Pairing Name, Category, Heading Font, Body Font, Mood/Style Keywords, Best For, Google Fonts URL, CSS Import, Tailwind Config, Notes`

### Complete Font Pairing Index (72 pairings)

| # | Name | Heading | Body | Best For |
|---|---|---|---|---|
| 1 | Classic Elegant | Playfair Display | Inter | Luxury, fashion, spa, beauty |
| 2 | Modern Professional | Poppins | Open Sans | SaaS, corporate, startups |
| 3 | Tech Startup | Space Grotesk | DM Sans | Tech companies, AI products |
| 4 | Editorial Classic | Cormorant Garamond | Libre Baskerville | Publishing, blogs, news |
| 5 | Minimal Swiss | Inter | Inter | Dashboards, admin, design systems |
| 6 | Playful Creative | Fredoka | Nunito | Children's apps, gaming |
| 7 | Bold Statement | Bebas Neue | Source Sans 3 | Marketing, portfolios, agencies |
| 8 | Wellness Calm | Lora | Raleway | Health, spa, meditation |
| 9 | Developer Mono | JetBrains Mono | IBM Plex Sans | Dev tools, documentation |
| 10 | Retro Vintage | Abril Fatface | Merriweather | Vintage brands, breweries |
| 11 | Geometric Modern | Outfit | Work Sans | Portfolios, agencies, landing pages |
| 12 | Luxury Serif | Cormorant | Montserrat | Fashion, luxury e-commerce |
| 13 | Friendly SaaS | Plus Jakarta Sans | Plus Jakarta Sans | SaaS, web apps, dashboards |
| 14 | News Editorial | Newsreader | Roboto | News, magazines, journalism |
| 15 | Handwritten Charm | Caveat | Quicksand | Personal blogs, invitations |
| 16 | Corporate Trust | Lexend | Source Sans 3 | Enterprise, government, healthcare |
| 17 | Brutalist Raw | Space Mono | Space Mono | Developer portfolios, experimental |
| 18 | Fashion Forward | Syne | Manrope | Fashion, creative agencies |
| 19 | Soft Rounded | Varela Round | Nunito Sans | Children's products, pet apps |
| 20 | Premium Sans | Satoshi* | General Sans* | Premium brands (*DM Sans as Google alt) |
| 21 | Vietnamese Friendly | Be Vietnam Pro | Noto Sans | Vietnamese/multilingual sites |
| 22 | Japanese Elegant | Noto Serif JP | Noto Sans JP | Japanese sites, cultural |
| 23 | Korean Modern | Noto Sans KR | Noto Sans KR | Korean sites, K-beauty |
| 24 | Chinese Traditional | Noto Serif TC | Noto Sans TC | Taiwan/Hong Kong markets |
| 25 | Chinese Simplified | Noto Sans SC | Noto Sans SC | Mainland China market |
| 26 | Arabic Elegant | Noto Naskh Arabic | Noto Sans Arabic | RTL, Middle East |
| 27 | Thai Modern | Noto Sans Thai | Noto Sans Thai | Thai sites, Southeast Asia |
| 28 | Hebrew Modern | Noto Sans Hebrew | Noto Sans Hebrew | RTL, Israeli market |
| 29 | Legal Professional | EB Garamond | Lato | Law firms, government |
| 30 | Medical Clean | Figtree | Noto Sans | Healthcare, pharma |
| 31 | Financial Trust | IBM Plex Sans | IBM Plex Sans | Banks, finance, insurance |
| 32 | Real Estate Luxury | Cinzel | Josefin Sans | Real estate, architecture |
| 33 | Restaurant Menu | Playfair Display SC | Karla | Restaurants, cafes |
| 34 | Art Deco | Poiret One | Didact Gothic | Vintage events, luxury hotels |
| 35 | Magazine Style | Libre Bodoni | Public Sans | Magazines, editorial |
| 36 | Crypto/Web3 | Orbitron | Exo 2 | Crypto, blockchain, web3 |
| 37 | Gaming Bold | Russo One | Chakra Petch | Gaming, esports |
| 38 | Indie/Craft | Amatic SC | Cabin | Craft brands, artisan |
| 39 | Startup Bold | Clash Display* | Satoshi* | Startups, pitch decks (*Outfit/Rubik as Google alt) |
| 40 | E-commerce Clean | Rubik | Nunito Sans | E-commerce, online stores |
| 41 | Academic/Research | Crimson Pro | Atkinson Hyperlegible | Universities, research |
| 42 | Dashboard Data | Fira Code | Fira Sans | Dashboards, analytics |
| 43 | Music/Entertainment | Righteous | Poppins | Music, entertainment |
| 44 | Minimalist Portfolio | Space Grotesk | Archivo | Design portfolios |
| 45 | Kids/Education | Baloo 2 | Comic Neue | Children's apps |
| 46 | Wedding/Romance | Great Vibes | Cormorant Infant | Wedding sites, invitations |
| 47 | Science/Tech | Exo | Roboto Mono | Science, research |
| 48 | Accessibility First | Atkinson Hyperlegible | Atkinson Hyperlegible | WCAG, government, healthcare |
| 49 | Sports/Fitness | Barlow Condensed | Barlow | Sports, fitness, gyms |
| 50 | Luxury Minimalist | Bodoni Moda | Jost | Luxury minimalist brands |
| 51 | Tech/HUD Mono | Share Tech Mono | Fira Code | Sci-fi, cybersecurity |
| 52 | Pixel Retro | Press Start 2P | VT323 | Pixel art games, retro |
| 53 | Neubrutalist Bold | Lexend Mega | Public Sans | Gen Z brands, bold marketing |
| 54 | Academic/Archival | EB Garamond | Crimson Text | Universities, archives |
| 55 | Spatial Clear | Inter | Inter | Spatial computing, AR/VR |
| 56 | Kinetic Motion | Syncopate | Space Mono | Music festivals, automotive |
| 57 | Gen Z Brutal | Anton | Epilogue | Gen Z, streetwear |
| 58 | Minimalist Monochrome Editorial | Playfair Display | Source Serif 4 | Luxury fashion, editorial |
| 59 | Modern Dark Cinema | Inter | Inter | Developer tools, fintech, AI dashboards |
| 60 | SaaS Mobile Boutique | Calistoga | Inter | B2B SaaS, fintech apps |
| 61 | Terminal CLI Monospace | JetBrains Mono | JetBrains Mono | Developer tools, Web3, hacker aesthetic |
| 62 | Kinetic Brutalism | Space Grotesk | Space Grotesk | Music/culture, sports platforms |
| 63 | Flat Design Mobile | Inter | Inter | Cross-platform apps, dashboards |
| 64 | Material You MD3 | Roboto | Roboto | Android apps, enterprise mobile |
| 65 | Neo Brutalism Mobile | Space Grotesk | Space Grotesk | Creative tools, Gen-Z marketing |
| 66 | Bold Typography Mobile | Inter | Playfair Display | Creative brand flagships, reading platforms |
| 67 | Academia Mobile | Cormorant Garamond | Crimson Pro | Knowledge apps, scholarly tools |
| 68 | Cyberpunk Mobile | Orbitron | JetBrains Mono | Gaming, fintech/crypto, cyberpunk |
| 69 | Web3 Bitcoin DeFi | Space Grotesk | Inter | DeFi, NFT, metaverse |
| 70 | Claymorphism Mobile | Nunito | DM Sans | Children education, teen social |
| 71 | Enterprise SaaS Mobile | Plus Jakarta Sans | Plus Jakarta Sans | B2B SaaS, admin dashboards |
| 72 | Sketch Hand-Drawn | Kalam | Patrick Hand | Journaling, creative platforms |

---

## 4. UI Styles (styles.csv)

### Schema
`No, Style Category, Type, Keywords, Primary Colors, Secondary Colors, Effects & Animation, Best For, Do Not Use For, Light Mode, Dark Mode, Performance, Accessibility, Mobile-Friendly, Conversion-Focused, Framework Compatibility, Era/Origin, Complexity, AI Prompt Keywords, CSS/Technical Keywords, Implementation Checklist, Design System Variables`

### Style Catalog (71 styles)

1. Minimalism & Swiss Style
2. Neumorphism
3. Glassmorphism
4. Brutalism
5. 3D & Hyperrealism
6. Vibrant & Block-based
7. Dark Mode (OLED)
8. Accessible & Ethical
9. Claymorphism
10. Flat Design
11. Retro-Futurism
12. Micro-interactions
13. Motion-Driven
14. Aurora UI
15. Soft UI Evolution
16. Bento Box Grid
17. AI-Native UI
18. Storytelling-Driven
19. Data-Dense Dashboard
20. Swiss Modernism 2.0
21. Organic Biophilic
22. Cyberpunk UI
23. Liquid Glass
24. E-Ink / Paper
25. Zero Interface
26. Holographic / HUD
27. Spatial UI (VisionOS-inspired)
28-71. Landing page, dashboard, and mobile-specific variants

### Key Style Properties (examples)

**Glassmorphism**
- Colors: Translucent white rgba(255,255,255,0.1-0.3)
- Effects: Backdrop blur (10-20px), subtle border 1px solid rgba white 0.2
- Best for: Modern SaaS, financial dashboards, lifestyle apps
- CSS: `backdrop-filter: blur(15px); background: rgba(255,255,255,0.15);`
- Variables: `--blur-amount: 15px; --glass-opacity: 0.15;`

**Dark Mode (OLED)**
- Colors: Deep Black #000000, Dark Grey #121212, Midnight Blue #0A0E27
- Accents: Neon Green #39FF14, Electric Blue #0080FF, Gold #FFD700
- Performance: Excellent
- CSS: `background: #000000 or #121212; text-shadow: 0 0 10px neon-color;`

**Brutalism**
- Colors: Red #FF0000, Blue #0000FF, Yellow #FFFF00, Black, White
- Effects: No transitions (instant), sharp corners (0px), bold 700+
- CSS: `border-radius: 0px; transition: none; font-weight: 700+;`

---

## 5. UX Guidelines (ux-guidelines.csv)

### Schema
`No, Category, Issue, Platform, Description, Do, Don't, Code Example Good, Code Example Bad, Severity`

### Categories Covered
- **Navigation** (6 rules): Smooth scroll, sticky nav, active state, back button, deep linking, breadcrumbs
- **Animation** (8 rules): Excessive motion, duration timing (150-300ms), reduced motion, loading states, hover vs tap, continuous animation, transform performance, easing functions
- **Layout** (5 rules): Z-index management, overflow, fixed positioning, stacking context, content jumping
- **Touch** (6 rules): 44x44px minimum targets, 8px spacing, gesture conflicts, tap delay, pull to refresh, haptic feedback
- **Interaction** (8 rules): Focus states, hover states, active states, disabled states, loading buttons, error/success feedback, confirmation dialogs
- **Accessibility** (10 rules): Color contrast 4.5:1, color-only avoidance, alt text, heading hierarchy, ARIA labels, keyboard navigation, screen reader, form labels, error messages, skip links
- **Performance** (8 rules): Image optimization, lazy loading, code splitting, caching, font loading, third party scripts, bundle size, render blocking
- **Forms** (10 rules): Input labels, error placement, inline validation, input types, autofill, required indicators, password visibility, submit feedback, input affordance, mobile keyboards
- **Responsive** (8 rules): Mobile first, breakpoint testing, touch friendly, 16px minimum font, viewport meta, no horizontal scroll, image scaling, table handling
- **Typography** (6 rules): Line height 1.5-1.75, line length 65-75ch, font size scale, font loading, contrast readability, heading clarity
- **Feedback** (6 rules): Loading indicators, empty states, error recovery, progress indicators, toast notifications (3-5s auto-dismiss), confirmation messages
- **Content** (4 rules): Truncation, date formatting, number formatting, placeholder content
- **AI Interaction** (3 rules): AI disclaimer, streaming text, feedback loop
- **Spatial UI** (2 rules): Gaze hover (VisionOS), depth layering
- **Sustainability** (2 rules): Auto-play video, asset weight

---

## How to Use These Files

### Direct CSV Lookup
The CSV files can be loaded directly into any tool, script, or AI context for lookups. Example queries:
- "What colors should a fintech app use?" -> Look up row 14 in `colors.csv`
- "What font pairing for a healthcare app?" -> Search `typography.csv` for "medical" or "health"
- "What style should a gaming app use?" -> Look up row 12 in `ui-reasoning.csv`

### Cross-Reference Pattern
1. Start with `products.csv` to find your product type and get style + pattern recommendations
2. Use `ui-reasoning.csv` for decision rules and anti-patterns
3. Look up the specific palette in `colors.csv`
4. Select typography from `typography.csv`
5. Get detailed style implementation from `styles.csv`
6. Apply `ux-guidelines.csv` best practices

### As AI Context
Include the relevant CSV files (or excerpts) in AI prompts for design-aware code generation. The `styles.csv` file includes AI prompt keywords and CSS technical keywords that can be fed directly into generation prompts.
