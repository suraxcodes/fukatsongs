# Roadmap: fukatSongs v2.0

Milestone: **Premium Experience & Playlists**
Status: **Active**

---

## Phase 8: Personalization & Audio (SET/AUD)
**Goal:** Implement settings persistence and native audio equalization.
- [ ] Create Settings screen with Quality toggles (SET-01, SET-02)
- [ ] Integrate Settings into `MusicRepository` for dynamic bitrate selection (SET-03)
- [ ] Implement `just_audio` Equalizer logic in `MusicAudioHandler` (AUD-01)
- [ ] Build Equalizer UI overlay (AUD-02)

## Phase 9: Smart Main Page (HOME)
**Goal:** Implement history tracking and the YouTube Music style Home UI.
- [ ] Build "Recent Searches" persistence in Search Repository (HOME-02)
- [ ] Implement "Recently Played" (Quick Picks) tracking (HOME-01)
- [ ] Update Home Screen UI with premium grids and glassmorphism (HOME-03)

## Phase 10: Immersive Player (UI)
**Goal:** Build the full-screen sliding player experience.
- [ ] Create the Immersive Player Page (UI-01, UI-02)
- [ ] Implement slide-up animation and auto-navigation on play (UI-03)
- [ ] Add "Source Badges" and quality indicators to the player (UI-02)

## Phase 11: Playlist & Library Engine (PL)
**Goal:** Full CRUD for playlists and the advanced "Pro" menu.
- [ ] Implement Playlist Hive storage and CRUD logic (PL-01, PL-03)
- [ ] Create the "Three-Dot" Bottom Sheet with pro options (PL-02)
- [ ] Build the "Liked Music" special collection (PL-04)
- [ ] Final UI Polish: Scroll-up animations for all bottom sheets.

### Phase 12: Caching & Offline Capabilities

**Goal:** [To be planned]
**Requirements**: TBD
**Depends on:** Phase 11
**Plans:** 0 plans

Plans:
- [ ] TBD (run /gsd-plan-phase 12 to break down)

### Phase 12.1: Urgent bug fixes UI updates and performance optimizations (INSERTED)

**Goal:** [Urgent work - to be planned]
**Requirements**: TBD
**Depends on:** Phase 12
**Plans:** 0 plans

Plans:
- [ ] TBD (run /gsd-plan-phase 12.1 to break down)

### Phase 13: Multi-layered fallback structure with Piped API

**Goal:** [To be planned]
**Requirements**: TBD
**Depends on:** Phase 12
**Plans:** 1/1 plans complete

Plans:
- [x] TBD (run /gsd-plan-phase 13 to break down) (completed 2026-05-17)

### Phase 14: Desktop Windows macOS Support

**Goal:** [To be planned]
**Requirements**: TBD
**Depends on:** Phase 13
**Plans:** 0 plans

Plans:
- [ ] TBD (run /gsd-plan-phase 14 to break down)

### Phase 15: Desktop support and low-end mobile performance optimization

**Goal:** [To be planned]
**Requirements**: TBD
**Depends on:** Phase 14
**Plans:** 0 plans

Plans:
- [ ] TBD (run /gsd-plan-phase 15 to break down)

### Phase 16: Custom Serverless Decryption & Isolate Engine

**Goal:** Implement a secure, self-contained Vercel Node.js streaming proxy with client-side deciphering rules executed in a background Dart Isolate and optimistic pre-fetching to eliminate playback buffering.
**Requirements**:
- Create `lib/core/network/audio_pre_fetch_cache.dart` to manage cached streaming URLs.
- Create `lib/data/repositories/music_queue_service.dart` to pre-fetch URLs in a background queue.
- Implement background Isolate signature decryption in `lib/core/utils/audio_decipher_isolate.dart` to offload work from UI thread.
- Establish Vercel serverless function `api/stream.js` using `@distube/ytdl-core` with PoToken and IPv6 rotation.
**Depends on:** Phase 12, Phase 12.1
**Plans:** 0 plans

Plans:
- [ ] TBD (run /gsd-plan-phase 16 to break down)

---

## Success Criteria (Milestone v2.0)
1. User can switch to 128kbps in settings and verify the stream URL changes.
2. "Quick Picks" grid updates in real-time as songs finish playing.
3. Full-screen player opens flawlessly from any search or playlist result.
4. User can create a "Morning Mix" playlist, add 3 songs, and play them in order.
