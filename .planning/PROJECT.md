# fukatSongs

## What This Is

fukatSongs is a personal Android music streaming app built in Flutter for learning and personal use. It searches songs from Saavn and YouTube Music in parallel, plays them with a stable queue system, and lets users download songs for offline listening — all stored locally with no backend or cloud dependency.

## Core Value

Stable, uninterrupted music playback with a reliable queue system — everything else is secondary.

## Requirements

### Validated

<!-- Shipped and confirmed valuable. -->

(None yet — ship to validate)

### Active

<!-- Current scope. Building toward these. -->

- [ ] App boots with correct folder structure and all dependencies configured
- [ ] User can search songs via Saavn API and see normalized results
- [ ] User can play, pause, seek, skip, and control playback with background audio support
- [ ] User can manage a queue with shuffle and repeat modes
- [ ] User can create playlists, like songs, and view recent songs (stored in Hive)
- [ ] User can download songs to device storage and play them offline
- [ ] User can search both Saavn and YouTube in parallel with fallback provider logic
- [ ] App caches metadata, search results, and images for performance

### Out of Scope

<!-- Explicit boundaries. Includes reasoning to prevent re-adding. -->

- Lyrics sync — not core to stability, deferred to V2
- Equalizer — not core to stability, deferred to V2
- AI recommendations — overengineered for V1
- Firebase / cloud sync / account system — adds complexity without solving core problem
- Social features — not personal use case
- Fancy animations — not priority over stability
- Backend / FastAPI — not needed until multi-device sync is required
- iOS support — Android only for V1

## Context

- **Stack**: Flutter (Dart), Riverpod (state), just_audio + audio_service (playback), Hive (local DB), Dio (networking), cached_network_image (images), youtube_explode_dart (YT stream URLs)
- **Providers**: JioSaavn (unofficial API, primary), YouTube Music (fallback — Dart-native implementation of internal YouTube Music API endpoints, same approach as ytmusicapi but in Dart; stream URLs extracted via `youtube_explode_dart`)
- **Architecture**: Provider abstraction layer — each music source implements a common `MusicProvider` interface; results are normalized into a single `Song` model
- **Data strategy**: Never store stream URLs (they expire); store provider IDs and fetch fresh URLs at playback time
- **Local-only**: No backend, no Firebase, no cloud. All data (playlists, likes, queue state, download metadata) stored in Hive. Audio files stored on device storage.
- **Codebase state**: Fresh Flutter scaffold (`flutter create`), no implementation yet. App name in pubspec is `freesongs` — to be renamed to `fukatSongs`.

## Constraints

- **Platform**: Android only — no iOS for V1
- **Architecture**: No backend until multi-device sync is genuinely needed
- **APIs**: Unofficial APIs (Saavn, YouTube) may break — must build provider abstraction with fallback from day one
- **Stream URLs**: Must never be persisted — always fetch fresh at playback time
- **Audio**: Single global audio player instance — never create multiple `AudioPlayer()` instances
- **Shuffle**: Maintain both `originalQueue` and `shuffledQueue` — never destructively shuffle

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Riverpod for state management | Scalable, clean async handling, better than Provider | — Pending |
| Hive for local DB | Lightweight, fast, good for app data; SQLite would be overkill | — Pending |
| just_audio + audio_service | Industry standard for Flutter background audio | — Pending |
| Dio over http package | Retries, interceptors, better download handling | — Pending |
| Provider abstraction from day one | APIs break — abstraction allows swapping without rewriting playback | — Pending |
| YouTube Music via Dart-native API calls | ytmusicapi is Python-only; replicate same internal YT Music HTTP endpoints in Dart via Dio + youtube_explode_dart for stream URLs — no Python server needed | — Pending |
| Parallel search (asyncio.gather style) | Sequential search is slow and gives bad UX | — Pending |
| Local-only V1 architecture | Simpler, faster, fewer failure points, no server costs | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-05-15 after initialization*
