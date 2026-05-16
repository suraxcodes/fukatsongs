# Phase 06: YouTube Provider & Self-Healing - Context

**Gathered:** 2026-05-15
**Status:** Ready for planning

<domain>
## Phase Boundary
Implementation of the YouTube Music provider (via internal API) and the search orchestration logic that merges results and enables automatic "Self-Healing" for failed links.
</domain>

<decisions>
## Implementation Decisions

### Unified Search & Deduplication
- **D-01:** Results from Saavn and YouTube are merged into a single list.
- **D-02:** Strict deduplication based on (Title + Artist) fuzzy match.
- **D-03:** Multi-Provider Storage: A single `Song` entity stores IDs for all found providers.

### Self-Healing Playback
- **D-04:** Playback Failure Hook: If a primary stream fails, trigger a background search for the song on fallback providers.
- **D-05:** Permanent Repair: When a fallback is found, update the Hive `library` and `playlists` boxes with the new provider ID so the song stays fixed.
- **D-06:** Notification: Show a user notification when a song is "repaired" via fallback.

### YouTube Strategy
- **D-07:** Replicate `ytmusicapi` (POST `youtubei/v1/search`) for official metadata.
- **D-08:** Filtering: Auto-filter `Live`, `Lyrics`, and `Cover` unless the query specifically includes those terms.

</decisions>

<canonical_refs>
## Canonical References
- `lib/providers/music_provider.dart` — Base interface
- `lib/core/audio/audio_handler.dart` — Error handling location
- `lib/models/song.dart` — Providers map structure
</canonical_refs>
