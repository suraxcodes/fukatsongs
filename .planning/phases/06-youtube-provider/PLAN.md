# Phase 06: YouTube Provider & Self-Healing - Plan

## Objectives
1. Implement a robust `YouTubeProvider` using the internal YouTube Music API.
2. Build a `SearchOrchestrator` that merges and deduplicates results from multiple sources.
3. Implement a "Self-Healing" playback loop that repairs broken links automatically.

## Wave 1: YouTube Music Engine
- [ ] Research/Implement `youtubei/v1/search` POST request structure.
- [ ] Refactor `YouTubeProvider` to use this internal API instead of generic search.
- [ ] Implement result normalization to the `Song` model.
- [ ] Ensure `getStreamUrl` still works via `youtube_explode_dart`.

## Wave 2: Unified Search & Deduplication
- [ ] Update `MusicRepository` to perform parallel searches.
- [ ] Implement `SongMerger` utility for fuzzy title/artist matching.
- [ ] Update `SearchNotifier` to display the unified list.

## Wave 3: Self-Healing & Repair
- [ ] Add `onError` listener to `just_audio` in `MusicAudioHandler`.
- [ ] Implement `repairSong(Song song)` logic:
    - Background search for fallback provider IDs.
    - Update current media item and resume playback.
    - Persist the new ID to Hive (`library` and `playlists`).
- [ ] Add notification/toast for successful repair.

## Verification
- [ ] Search for a song and verify Saavn and YouTube versions merge.
- [ ] Simulate a playback error (e.g., provide a dead URL) and verify auto-repair.
- [ ] Check Hive boxes to confirm permanent fix.
