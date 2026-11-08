# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

Android is the primary target. iOS is a co-equal target on the same Material 3 design language — the user confirmed "Android + iOS only", so web, desktop and tablet-specific layouts are out of scope for this round.

## Users

Two people in a relationship share one period-tracking app. The primary user is the person doing the logging: they open the app to record a period start, log how the day felt, and understand where they are in their cycle. The secondary user is their partner, who sees a shared, read-oriented view of cycle status without gaining access to the logging tool's private notes.

The job is low-frequency, high-intent, and often done at a private moment — in a bathroom, in bed, in a queue. Logging has to take seconds, work one-handed, and never feel like a form to fill in.

## Product Purpose

Bloom is a private reproductive-health tracker that keeps every cycle, note and symptom on the owner's device, and shares a deliberately minimal slice of that with one partner through an end-to-end encrypted peer link.

Success means: logging a period takes one tap, the app always answers "where am I in my cycle right now", and the user can trust that the relay server never holds their health data.

## Positioning

Two mechanisms no neighboring product in this category can truthfully copy:

- **Zero-knowledge partner sync.** A stateless Cloudflare Worker relay routes encrypted payloads between two paired devices and never retains plaintext. Data is AES-256-CBC encrypted on-device with a SHA-256-derived shared key and a random IV per payload. The partner link requires mutual approval on both ends.
- **Cycle-grounded AI.** Bloom AI is not a generic chat assistant. Every prompt carries the user's live cycle day, phase, rolling cycle/period averages, recent symptoms and mood history, and it is hard-restricted to reproductive-health topics — it refuses everything else.

## Operating Context

Used alone, on a personal phone, in private. Data is entered in small bursts — "period started", "bad cramps today" — and read back later, often at a glance. A partner may be linked and sees shared cycle status only.

The PDF health report is the escape hatch for real-world use: a printable, shareable summary for a clinician or a GP appointment.

## Capabilities and Constraints

- **Local-first storage.** All cycles, notes and chat conversations persist to a sandboxed local JSON document database via path provider. SharedPreferences holds device identity, pairing code, relay URL and the AI key/model.
- **Cycle engine.** Rolling averages for cycle length and period length; predicted next period; estimated fertile window; duplicate-cycle prevention on identical start dates; future calendar dates are visually disabled so no future data can be entered.
- **Daily notes.** Flow level (None/Light/Medium/Heavy), mood, cramp severity 0–10, symptom tags, and free text, one note per calendar day.
- **Bloom AI chat.** Conversation CRUD (create, rename, delete thread, delete individual message), Markdown rendering, real-time cycle context injection, strict topical guardrails, wellness (not medical) disclaimer. Backed by an OpenAI-compatible chat completions endpoint; the key arrives via `--dart-define BLOOM_AI_KEY` or the stored preference. The service must degrade gracefully when no key is configured.
- **Partner sync.** Six-character alphanumeric pairing code, WebSocket relay with auto-reconnect, explicit approval on both devices, two-way deterministic merge with deduplication.
- **Export.** PDF health report via native OS share sheet; JSON backup export and restore via the file picker.
- **Five primary destinations** on the bottom navigation bar: Home, Calendar, Notes, Sync, Settings. Bloom AI is reached as a dedicated companion surface from Home and Settings.
- **Constraints.** Flutter 3.38 / Dart 3.10. Provider for state. `flutter_markdown` 0.7.x for AI responses. Platform channels are not available in the widget-test environment, so PDF and file-picker paths must stay behind user gestures and degrade quietly.

## Brand Commitments

- **Name:** Bloom, with the cherry-blossom (sakura) motif and the 🌸 emoji as established in onboarding copy.
- **Palette:** rose pink is the brand color — `#D65A78` primary, `#B83E5C` deep, `#F7E4EA` pale. Supporting roles already established in code: lavender (notes/AI), sage (fertile/success/linked), peach-orange (predicted/sync attention), sky.
- **Typeface:** Outfit, set through the Material type scale.
- **Icon:** the white cherry blossom with a glossy rose center on a luminous rose-gradient disc (`assets/icon.png`). The mark is soft, glowing and botanical — not flat, not geometric.
- **Tone:** warm, private, unhurried, clinically careful. The established product copy — "Private by design", "Data stays on your device", "Your private cycle, mood, and wellness companion" — is confirmed and stays.
- **The user confirmed the existing identity is a keeper.** The rebuild elevates the system built on top of it; it does not rename, recolor or re-mark the product.

## Evidence on Hand

- Real product copy across onboarding, the AI guardrail prompt, the security dialog and the sync explainer.
- The brand icon raster at `assets/icon.png` (577 KB, 640×640).
- The encryption, database, AI, PDF and sync implementation, each with unit tests under `test/`.
- A Cloudflare Worker + Durable Object relay under `server/cloudflare/`, and a standalone Node WebSocket fallback under `server/src/`.
- **Absent, and therefore not to be invented:** testimonials, customer counts, clinical validation, partner brands, retention figures, pricing, or any benchmark of prediction accuracy. The app states predicted dates as *estimates*, and copy must keep doing so.

## Product Principles

1. **Private by construction.** The relay carries ciphertext or nothing. Privacy is a property of the architecture, not a claim in the copy.
2. **One tap to log.** Logging a period is a single action; everything else is optional refinement.
3. **Answer "where am I" instantly.** Cycle day, phase and the next predicted window are always visible without navigation.
4. **Two people, one shared truth, no surveillance.** The partner sees shared status, never the private journal.
5. **Honest about uncertainty.** Predictions are labeled as estimates. Bloom AI offers wellness guidance and disclaims diagnosis.

## Accessibility & Inclusion

- Material 3 minimum 48×48 dp touch targets with 8 dp separation.
- Support the system font-size setting; no fixed-height text containers that clip at large scale.
- Honor the platform's reduce-motion setting for all transitions.
- Dark theme is a first-class scheme, not an inversion.
- Safe-area insets respected on both Android and iOS, including the display cutout and the IME.
