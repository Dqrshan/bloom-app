---
version: 1
slug: "lib-app-dart"
primary_target: "lib/app.dart"
related_targets: ["lib/screens/home/home_screen.dart","lib/screens/calendar/calendar_screen.dart","lib/screens/notes/notes_screen.dart","lib/screens/sync/sync_screen.dart","lib/screens/settings/settings_screen.dart","lib/screens/ai/bloom_ai_chat_screen.dart","lib/screens/day/day_detail_screen.dart","lib/screens/onboarding/onboarding_screen.dart"]
---

# Bloom app shell & primary surfaces

## Scope

Whole-app rebuild: navigation shell, Home, Calendar, Notes, Sync, Settings, Bloom AI chat, Day detail, Onboarding. Mode: **Operate**. Android primary, iOS co-equal, mobile only.

## Audience, job, task, proof, constraints

- **Audience / job:** a couple tracking a cycle. The logger needs "where am I" and a one-tap log in a private, often one-handed moment.
- **Task:** log a period or a daily note in seconds; read cycle phase at a glance.
- **Proof:** the live cycle engine — day, phase, predicted window, rolling averages — and Bloom AI grounded in that data.
- **Constraints:** every existing string stays verbatim; PDF report layout untouched; pairing/sync flow steps and wording unchanged; Material 3 on both platforms; 48 dp targets; dark theme first-class; never read as a hospital app.

## Chosen direction and memorable moment

Inherit the established Bloom world (rose `#D65A78`, Outfit, cherry-blossom mark) and rebuild the system on top of it. The memorable moment is the **Bloom dial**: the cycle dial is the app's own blossom — petals unfurl around the cycle, filled to the current day — so the signature mark and the core mechanism become the same object.

## Direction contract

**THESIS:** A cycle position is a living blossom, not a clinical gauge. The category default — cold calendar, anxious red, a wall of stat cards, a big "Day 14" metric — is refused; one warm, honest action leads.

**OWN-WORLD:** Warm off-white ground `#FAFAFD`; white hairline-outlined surfaces; one rose accent `#D65A78` carrying interactive emphasis; sage, peach and lavender reserved for fertile, predicted and notes states. Outfit across the Material type scale. Radii 12–16, pills only for small controls. Elevation declared once: hairline outline for flat surfaces, one soft rose glow on the Bloom dial.

**STORY:** Open Bloom and see your cycle as a blossom open to today's petal, one tap from logging, with your partner's shared status if linked.

**FIRST VIEWPORT:** Full-bleed blossom dial centred, cycle day inside its centre disc; one full-width rose "Log Period" button directly beneath, "Daily Note" beside it as a tonal secondary; greeting and Bloom AI entry in the top bar row; recent cycles below the fold.

**FORM:** Extension of an inherited established world — the five-tab Material shell rebuilt, not a new or replacement world, so no concept-seed roll applies.

**FINISH:** unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance

## Unresolved decisions

- Outfit resolves at runtime through `google_fonts`; bundling the font files into the repo is out of scope for this round.
- The orphaned duplicate `lib/screens/notes/day_detail_screen.dart` is folded into the active day-detail screen (it carries the AI-relief workflow the active copy lacks) and then removed.
