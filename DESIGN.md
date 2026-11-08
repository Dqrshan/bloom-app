---
name: Bloom
description: Private couples' period tracker — a cycle position rendered as a living blossom.
colors:
  period-rose: "#D65A78"
  rose-deep: "#9A2E4C"
  rose-wash: "#FBE7EC"
  fertile-sage: "#6BB88C"
  fertile-wash: "#E4F3EA"
  predicted-peach: "#CE7346"
  predicted-wash: "#FBEBE1"
  notes-lavender: "#9B8EC4"
  notes-wash: "#EDE9F7"
  ground: "#FAFAFD"
  surface: "#FFFFFF"
  surface-sunken: "#F4F4F9"
  ink: "#1B1B2E"
  ink-soft: "#4A4A66"
  ink-muted: "#7C7C96"
  hairline: "#E9E9F0"
  outline: "#C9C8D6"
  dark-ground: "#101017"
  dark-surface: "#1A1A23"
typography:
  display:
    fontFamily: "Outfit"
    fontSize: "32px"
    fontWeight: 800
    lineHeight: 1.12
    letterSpacing: "-0.8px"
    fontVariation: "wght 800"
  headline:
    fontFamily: "Outfit"
    fontSize: "18px"
    fontWeight: 700
    lineHeight: 1.3
    letterSpacing: "-0.2px"
    fontVariation: "wght 700"
  title:
    fontFamily: "Outfit"
    fontSize: "17px"
    fontWeight: 600
    lineHeight: 1.35
    letterSpacing: "-0.1px"
    fontVariation: "wght 600"
  body:
    fontFamily: "Outfit"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.5
    fontVariation: "wght 400"
  label:
    fontFamily: "Outfit"
    fontSize: "12px"
    fontWeight: 600
    lineHeight: 1.2
    fontVariation: "wght 600"
rounded:
  sm: "10px"
  md: "16px"
  lg: "24px"
  pill: "999px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "16px"
  lg: "20px"
  xl: "24px"
  xxl: "32px"
  gutter: "20px"
components:
  button-primary:
    backgroundColor: "{colors.period-rose}"
    textColor: "{colors.surface}"
    rounded: "{rounded.md}"
    height: "52px"
    padding: "24px"
  button-secondary:
    backgroundColor: "{colors.notes-wash}"
    textColor: "{colors.notes-lavender}"
    rounded: "{rounded.md}"
    height: "52px"
  button-ghost:
    backgroundColor: "transparent"
    textColor: "{colors.period-rose}"
    rounded: "{rounded.sm}"
    height: "44px"
  card:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.md}"
    padding: "16px"
  input:
    backgroundColor: "{colors.surface-sunken}"
    textColor: "{colors.ink}"
    rounded: "14px"
    padding: "16px"
  chip:
    backgroundColor: "{colors.surface-sunken}"
    textColor: "{colors.ink-soft}"
    rounded: "{rounded.pill}"
    padding: "12px 9px"
  chip-selected:
    backgroundColor: "{colors.rose-wash}"
    textColor: "{colors.period-rose}"
    rounded: "{rounded.pill}"
    padding: "12px 9px"
  nav-bar:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink-muted}"
    rounded: "0px"
    height: "72px"
  nav-selected:
    backgroundColor: "{colors.rose-wash}"
    textColor: "{colors.period-rose}"
    rounded: "{rounded.pill}"
---

# Design System: Bloom

## Overview

**Creative North Star: "The Blossom in Bloom"**

Bloom is a private period tracker for couples. The category default is a cold
clinical gauge: a blue-grey calendar, anxious red, a wall of stat cards, a
large "Day 14" read-out. Bloom refuses that. A cycle position is a living
blossom, not a number on a dial — the app's own cherry-blossom mark is the
mechanism, and the cycle opens it petal by petal toward today.

The ground is a warm off-white rather than a clinical white, and the type is
Outfit across the whole Material scale — a single geometric voice rather than a
Roboto/Material default. Colour is rationed: one rose carries every
interactive emphasis, while sage, peach and lavender are reserved
respectively for fertile, predicted and notes states. The result should feel
private and unhurried — something a person opens in a quiet one-handed moment,
not a dashboard they report to.

**Key Characteristics:**

- One warm rose accent, used for action and active state only.
- Flat, hairline-outlined surfaces; depth is rare and deliberate.
- A single signature interaction — the Bloom dial — that carries the only
  shadow in the app.
- Botanical roundness: soft radii, circles for day states, pills for small
  controls.
- Dense enough to answer "where am I" at a glance, never dense enough to
  feel like a report.

## Colors

A single rose identity over a warm neutral ground, with three reserved
state accents that never compete with it for attention.

### Primary
- **Period Rose** (`#D65A78`): the one interactive accent. Primary buttons,
  the active nav indicator, the current day, the pairing code. Its rarity is
  the point.
- **Deep Rose** (`#9A2E4C`): the dark-mode identity and the pressed state of
  rose fills.

### Secondary
- **Notes Lavender** (`#9B8EC4`): notes state, the Bloom AI entry, and the
  tonal secondary action on Home.

### Tertiary
- **Fertile Sage** (`#6BB88C`): fertile-window days and the linked-partner
  state.
- **Predicted Peach** (`#CE7346`): predicted period days. Deliberately not
  red — a prediction is not a fact.

### Neutral
- **Warm Ground** (`#FAFAFD`): the app background behind every surface.
- **Raised Surface** (`#FFFFFF`): cards, the nav bar, sheets, and dialogs.
- **Sunken Surface** (`#F4F4F9`): inputs, chips, and inset list rows.
- **Ink** (`#1B1B2E`): primary text.
- **Soft Ink** (`#4A4A66`): secondary text and body copy.
- **Muted Ink** (`#7C7C96`): captions, placeholders, unselected labels.
- **Hairline** (`#E9E9F0`): dividers and the single outline on flat surfaces.
- **Dark Ground** (`#101017`) / **Dark Surface** (`#1A1A23`): the dark
  scheme's own ground and surface, not an inversion of the light ones.

### Named Rules

**The One Voice Rule.** Rose is reserved for action and active state. If a
screen has more than one rose-filled element competing for the eye, one of
them is wrong.

**The Reserved Accent Rule.** Sage, peach and lavender mean exactly one
thing each — fertile, predicted, notes. They are never used decoratively, and
never to signal a state the calendar does not already use.

**The Dark Scheme Rule.** Dark mode is designed, not inverted. Every state
role has its own dark value (rose `#E88BA2`, sage `#8FD3AA`, peach `#F0AE86`,
lavender `#BCB0E4`) chosen for legibility against `#101017`.

## Typography

**Display Font:** Outfit (bundled variable font, `wght` axis 100–900)
**Body Font:** Outfit
**Label/Mono Font:** Outfit

**Character:** A single geometric sans carries everything. Outfit's rounded
counters and open apertures keep the app warm where a neutral grotesque would
read as software, and its wide, even weight range lets a label be quiet
without switching to a second family.

### Hierarchy
- **Display** (800, 32px, 1.12): reserved for the cycle number inside the
  Bloom dial and the largest single moments. Not a page title.
- **Headline** (700, 18px, 1.30): the page title on every top-level screen
  (`headlineSmall` is the canonical title role).
- **Title** (600, 17px, 1.35): sheet and dialog titles, card headings, the
  active month.
- **Body** (400, 14px, 1.50): running copy and form content. Keep lines under
  ~70 characters.
- **Label** (600, 12px, 1.20): group labels, chips, and small metadata.
  Group labels add `0.9px` letter-spacing.

### Named Rules

**The Theme-Route Rule.** Every style comes from `Theme.of(context).textTheme`
(or a `copyWith` of it). No screen may hand-write `fontFamily: 'Outfit'` —
that bypasses the role scale and is how a single app ends up speaking in two
typefaces.

**The Two-Weight Rule.** Outfit is a variable font, and Flutter does not drive
its `wght` axis from `fontWeight` alone. Every style sets `fontWeight` *and*
`fontVariations` together, through the one `_outfit()` helper in
`lib/theme/bloom_theme.dart`.

## Layout

Mobile only (Android primary, iOS co-equal). One `Scaffold` for the whole
app, owned by the navigation shell; tab screens are body content and never
bring their own. The shell is `Scaffold(body: SafeArea(bottom: false, ...),
bottomNavigationBar: NavigationBar(...))`, so exactly one background paints
and there is no hand-rolled bottom padding to keep in sync with the bar.

The page gutter is 20px (`BloomDesign.gutter`) on every top-level screen.
Rhythm comes from a fixed scale: 4, 8, 16, 20, 24, 32. Cards sit on the
gutter with 16px internal padding; grouped lists are full-bleed inset
surfaces.

Wide viewports (tablets, landscape, desktop) are not a separate layout. The
Calendar holds its content to a 440px column and centres it, because a
square `GridView` calendar cell grows without limit and a 105px day cell is
not a calendar. Everything else scrolls full-width.

## Elevation & Depth

This system is flat by default. Depth is declared exactly once: a flat
surface gets a 1px hairline outline, and shadow is reserved for the Bloom
dial's soft rose glow (`#33D65A78`). There is no "ghost card" — an element
never carries both a border and a wide soft shadow.

### Shadow Vocabulary
- **Dial Glow** (`rgba(214, 90, 120, 0.20)`): the Bloom dial only, and only
  while the blossom is the focus of the screen.

### Named Rules

**The Elevation-Declared-Once Rule.** Choose hairline *or* shadow for a
surface, never both. Shadow is a scarce budget spent on the one element that
earns it.

## Shapes

Softly rounded, botanical. Cards and sheets use 16px (`radiusMd`), large
surfaces 24px (`radiusLg`), the bottom sheet's top corners 28px, and small
controls 10px (`radiusSm`). Pills (`radiusPill`) are reserved for chips and
small status badges — never for a primary button.

Day states are circles. The Bloom dial is a twelve-petal blossom built from
cubic-Bezier teardrops around a glossy rose core. Surfaces clip to their own
radius (`clipBehavior: Clip.antiAlias`) so hairline borders follow the curve.

## Components

### Buttons
- **Shape:** 16px radius (12px on compact header buttons), 52px tall.
- **Primary:** Period Rose fill, white label, no elevation. Used for exactly
  one thing per screen — on Home that is "Log Period".
- **Hover / Focus:** Material's own ink ripple and the theme's 2px rose focus
  border on inputs; buttons carry no bespoke hover state.
- **Secondary:** Tonal lavender wash with a lavender label — the "Daily Note"
  action.
- **Ghost:** Text button in Period Rose, no fill, 44px minimum height.

### Chips
- **Style:** Sunken Surface fill, 1px hairline, pill shape, 13px label.
- **State:** Selected chips take a 16% rose (or state-accent) wash, a 45%
  accent border, and the accent-coloured label. Unselected labels are Soft
  Ink. Selection is carried by fill *and* border, never by colour alone.

### Cards / Containers
- **Corner Style:** 16px.
- **Background:** Raised Surface in light, Dark Surface in dark.
- **Shadow Strategy:** None — hairline outline only.
- **Border:** 1px Hairline (Outline on interactive surfaces).
- **Internal Padding:** 16px, or 12/8/12/16 on the calendar month card.

### Inputs / Fields
- **Style:** Sunken Surface fill, no border, 14px radius, 16px padding.
- **Focus:** 2px Period Rose border on the focused field.
- **Error / Disabled:** 1.5px error border and rose200 disabled fill.

### Navigation
- A Material `NavigationBar` (72px) carrying five destinations — Home,
  Calendar, Notes, Sync, Settings — with labels always visible. The selected
  destination takes a rose wash pill behind the icon (rose700 at 55% in dark)
  and an ink-coloured label; unselected destinations take Muted Ink. The tab
  host builds tabs lazily and keeps inactive ones offstage, so a hidden tab
  never answers a finder or opens a socket.

### The Bloom dial
The app's signature element and its only shadow. Twelve petals unfurl around
the cycle as it advances, the filled set clipped to a wedge so the blossom
opens continuously rather than in discrete steps, with a glossy radial-gradient
rose core holding the cycle day in white and a small marker on the leading
edge. It animates once over 900ms on ease-out, and stands still when the
platform's reduce-motion signal is set.

## Do's and Don'ts

### Do:
- **Do** lead a screen with one action. On Home that is a full-width
  "Log Period"; everything else is secondary.
- **Do** resolve every colour through `BloomPalette.of(context)` so both
  schemes stay correct.
- **Do** keep every string in the app exactly as it is written — the words
  are the product.
- **Do** use `BloomDesign.card` for surfaces and `BloomDesign.pillChip` for
  selectable chips so every screen shares one form vocabulary.
- **Do** stack two labelled actions vertically when the screen must survive a
  1.3× system font scale.
- **Do** cap a self-sizing grid to a comfortable column width instead of
  letting its cells grow without bound.

### Don't:
- **Don't** hand-write font styles or name a font family directly; route
  typography through the theme.
- **Don't** give a surface both a border and a shadow.
- **Don't** use red for a predicted period — predictions are peach.
- **Don't** put a shadow on anything but the Bloom dial.
- **Don't** lead with a grid of metrics, and don't build a dashboard where a
  single answer will do.
- **Don't** let the app read clinical: no cold blue-grey ground, no alarming
  numbers, no urgency the product doesn't have.
- **Don't** change the PDF health report's layout, or the wording of the
  pairing and sync flow.
