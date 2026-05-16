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

---

## Success Criteria (Milestone v2.0)
1. User can switch to 128kbps in settings and verify the stream URL changes.
2. "Quick Picks" grid updates in real-time as songs finish playing.
3. Full-screen player opens flawlessly from any search or playlist result.
4. User can create a "Morning Mix" playlist, add 3 songs, and play them in order.
