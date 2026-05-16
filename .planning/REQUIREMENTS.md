# Requirements: Milestone v2.0 Premium Experience

This document defines the scoped requirements for the Premium Experience & Playlist system.

## 1. Settings & Quality (SET)
- [ ] **SET-01**: User can choose default music quality (128kbps, 160kbps, 320kbps) in Settings.
- [ ] **SET-02**: User can set separate quality preferences for Streaming vs. Downloading.
- [ ] **SET-03**: Preferences must be persisted via Hive and applied automatically to all new playback requests.

## 2. Audio Enhancement (AUD)
- [ ] **AUD-01**: User can access a native Equalizer from the Player screen.
- [ ] **AUD-02**: Equalizer must support Bass Boost, Treble adjustment, and at least 3 presets (e.g., Pop, Rock, Classical).

## 3. Smart Home Screen (HOME)
- [ ] **HOME-01**: "Quick Picks" grid on main page showing the last 6 songs played.
- [ ] **HOME-02**: "Recent Searches" list displayed when clicking the search bar.
- [ ] **HOME-03**: UI must match the YouTube Music "Premium Dark" aesthetic (Glassmorphism, vibrance).

## 4. Immersive Playback UI (UI)
- [ ] **UI-01**: Full-screen Player page that opens automatically when a song starts.
- [ ] **UI-02**: Player page must include prominent Album Art, Playback controls, and Lyrics (if available).
- [ ] **UI-03**: Smooth "Slide-up" and "Swipe-down" animations for the player page.

## 5. Advanced Playlist Engine (PL)
- [ ] **PL-01**: User can create new playlists with custom names and icons.
- [ ] **PL-02**: "Three-Dot" menu on every song card with:
    - Play Next
    - Add to Queue
    - Save to Playlist
    - Share
- [ ] **PL-03**: User can remove songs from playlists or delete entire playlists.
- [ ] **PL-04**: Persistent "Liked Music" playlist that tracks favorited songs.

---

## Out of Scope (Milestone v2.0)
- Cloud sync (Multi-device)
- Collaborative playlists
- Real-time lyrics (LRCLIB integration deferred to v3.0)
