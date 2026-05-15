# Phase 1: Foundation - Context

**Gathered:** 2026-05-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Establishing the core Flutter project structure, renaming the package to `fukatSongs`, configuring the visual design system (Deep Midnight), defining the V1 `Song` model, and initializing Hive/Riverpod.

</domain>

<decisions>
## Implementation Decisions

### App Identity
- **D-01:** Rename package to `com.fukatsongs.app`.
- **D-02:** Update display name to `fukatSongs`.

### Visual Design (Deep Midnight)
- **D-03:** Dark mode by default.
- **D-04:** Accent color: Electric Indigo (`#6200EE`).
- **D-05:** Design language: High-contrast text, glassmorphism for the player bar, sleek modern typography (Outfit/Inter).

### Data & Storage
- **D-06:** Song model must include `albumName` and `year` in addition to standard title/artist/image/duration.
- **D-07:** Hive Boxes (8 total): `songs`, `playlists`, `liked_songs`, `recent_songs`, `queue_state`, `downloads`, `settings`, `search_cache`.
- **D-08:** Use a "Global Cache" box for search results to speed up repeated queries.

### Architecture
- **D-09:** Folder structure: Feature-first with Layer-first internals.
  - `lib/features/{feature_name}/presentation/`
  - `lib/features/{feature_name}/domain/`
  - `lib/features/{feature_name}/data/`
  - `lib/core/` (shared logic, theme, constants)
  - `lib/models/` (Song model, etc.)
  - `lib/providers/` (Global providers)

### the agent's Discretion
- Choice of specific typography (Google Fonts) that feels "Premium".
- Exact implementation of the "Glassmorphism" effect.
- Structure of the `core/` folder utilities.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Core
- `.planning/PROJECT.md` — Vision and constraints
- `.planning/REQUIREMENTS.md` — Acceptance criteria (SETUP-01 to SETUP-06)
- `.planning/research/STACK.md` — Locked versions of all packages

</canonical_refs>
