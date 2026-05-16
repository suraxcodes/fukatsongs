# Phase 12: Caching & Offline Capabilities - Context

**Gathered:** 2026-05-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Implementation of local audio caching for streamed playback, alongside an explicit offline download system. Focuses on seamless failover from network streams to local files, and saving data usage on repeated listens.
</domain>

<decisions>
## Implementation Decisions

### Offline Playback Logic
- **D-01:** **Seamless Auto-Switching:** The app will transparently play downloaded or cached files if they exist locally, bypassing network requests entirely without requiring a separate "Offline Mode" toggle.

### Download Trigger & UX
- **D-02:** **Individual Songs:** Users will download individual songs manually (e.g., via the 3-dot menu or player screen). Bulk downloading of entire playlists is deferred/not prioritized.

### Storage Location
- **D-03:** **Private App Storage:** Downloaded and cached audio files will be stored in the app's private application documents/support directory, ensuring they are managed by the app and hidden from public file managers or external media scanners.

### Caching vs Downloading
- **D-04:** **Two-Tier System:** 
  1. Temporary caching occurs automatically when streaming a song (so repeat listens don't re-download).
  2. Permanent downloads are triggered manually by the user, saving the song persistently for offline listening.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Core
- `.planning/PROJECT.md` — Core constraints (Local-only, no stream URLs stored)
- `.planning/REQUIREMENTS.md` — SET-02: Quality preferences for Streaming vs. Downloading
- `lib/core/audio/audio_handler.dart` — Needs to integrate local file playing

### Libraries
- [just_audio background](https://pub.dev/packages/just_audio_background) (if applicable for caching proxy) or equivalent Dart caching proxy concepts.
</canonical_refs>

<deferred>
## Deferred Ideas

- Bulk downloading of playlists
- Exporting songs to public `Music` folders
</deferred>
