# fukatSongs — V1 Requirements

## v1 Requirements

### Setup & Foundation (SETUP)

- [x] **SETUP-01**: Project runs on Android with correct folder structure, all dependencies installed, and app boots to a home screen
- [x] **SETUP-02**: Song model is defined with id, title, artist, imageUrl, duration, source, providers map, primaryProvider, and optional localPath fields
- [x] **SETUP-03**: MusicProvider abstract interface is defined with `search()` and `getStreamUrl()` contracts
- [x] **SETUP-04**: Hive is initialized at app startup with all required boxes (songs, playlists, liked_songs, recent_songs, queue_state, downloads, settings)
- [x] **SETUP-05**: Riverpod ProviderScope wraps the app and core providers are registered
- [x] **SETUP-06**: Folder structure matches: `lib/core/`, `lib/features/`, `lib/models/`, `lib/providers/`, `lib/database/`

---

### Search (SEARCH)

- [ ] **SEARCH-01**: User can type a query in the search bar and see a list of song results — from JioSaavn (Phase 2) and YouTube Music via internal YT Music API (Phase 6); both providers run in parallel when available
- [ ] **SEARCH-02**: Search input is debounced (300ms) — API is not called on every keystroke
- [ ] **SEARCH-03**: Search results display song title, artist name, album art thumbnail, and duration
- [ ] **SEARCH-04**: User can see a loading indicator while search is in progress
- [ ] **SEARCH-05**: User sees an error message when search fails (API down, no network)
- [ ] **SEARCH-06**: User can clear the search and return to an empty/recent state
- [ ] **SEARCH-07**: Search results are paginated or lazy-loaded (no 500-item flat list)

---

### Playback (PLAY)

- [ ] **PLAY-01**: User can tap a song from search results and it begins playing
- [ ] **PLAY-02**: User can play and pause the current song
- [ ] **PLAY-03**: User can seek to any position in the song using a progress bar
- [ ] **PLAY-04**: Music continues playing when the app is sent to the background or screen is turned off
- [ ] **PLAY-05**: A media notification appears on Android with song title, artist, album art, and play/pause/skip controls
- [ ] **PLAY-06**: Lock screen media controls work (play, pause, next, previous)
- [ ] **PLAY-07**: Music pauses automatically when headphones are removed
- [ ] **PLAY-08**: Music pauses automatically when an incoming call is received
- [ ] **PLAY-09**: User can skip to the next song in the queue
- [ ] **PLAY-10**: User can go back to the previous song in the queue
- [ ] **PLAY-11**: Player screen shows current song artwork, title, artist, seek bar, and playback controls

---

### Queue (QUEUE)

- [ ] **QUEUE-01**: User can view the current playback queue
- [ ] **QUEUE-02**: User can toggle shuffle mode — original queue order is preserved and restorable
- [ ] **QUEUE-03**: User can cycle through repeat modes: Off → Repeat All → Repeat One
- [ ] **QUEUE-04**: Queue automatically advances to next track when current track ends
- [ ] **QUEUE-05**: Current queue, playback position, shuffle state, and repeat state are saved to Hive and restored when app restarts

---

### Library (LIB)

- [ ] **LIB-01**: User can like a song and it appears in a "Liked Songs" list
- [ ] **LIB-02**: User can unlike a song and it is removed from Liked Songs
- [ ] **LIB-03**: Recently played songs are tracked automatically (last 50 songs)
- [ ] **LIB-04**: User can create a new playlist with a name
- [ ] **LIB-05**: User can add a song to any existing playlist
- [ ] **LIB-06**: User can remove a song from a playlist
- [ ] **LIB-07**: User can delete a playlist entirely
- [ ] **LIB-08**: User can view all songs in a playlist and play from it

---

### Downloads (DL)

- [ ] **DL-01**: User can tap a download button on any song to download it to device storage
- [ ] **DL-02**: Download progress is shown (percentage or progress bar)
- [ ] **DL-03**: Downloaded songs are playable without internet connection
- [ ] **DL-04**: User can view a list of all downloaded songs
- [ ] **DL-05**: User can delete a downloaded song (removes file from storage + metadata from Hive)
- [ ] **DL-06**: App detects if a downloaded file is missing/corrupted and marks it as unavailable
- [ ] **DL-07**: Duplicate download is prevented — app checks if song is already downloaded before starting

---

### YouTube Provider (YT)

- [ ] **YT-01**: App searches both JioSaavn and YouTube Music simultaneously in parallel for any query
- [ ] **YT-02**: Results from both providers are normalized into the same Song model
- [ ] **YT-03**: Duplicate songs across providers are detected and merged (by title + artist similarity)
- [ ] **YT-04**: Garbage YouTube results are filtered out (slowed, reverb, 8D, lyrics videos, fan edits)
- [ ] **YT-05**: Results are ranked by score (exact title +50, exact artist +40, official audio +20, remix/slowed -50)
- [ ] **YT-06**: If JioSaavn playback fails, app automatically retries with YouTube provider transparently
- [ ] **YT-07**: Stream URLs for YouTube are extracted via `youtube_explode_dart` at playback time (never stored)

---

### Performance & Reliability (PERF)

- [ ] **PERF-01**: Album art images are cached to disk — same image is not re-downloaded on revisit
- [ ] **PERF-02**: Song metadata (title, artist, duration) is cached in Hive after first search — reduces API calls
- [ ] **PERF-03**: Recent search queries and their results are cached (TTL: 30 minutes)
- [ ] **PERF-04**: All API calls have timeouts (connect: 10s, receive: 15s) and fail gracefully
- [ ] **PERF-05**: App handles network switching (WiFi to mobile data) without crashing — playback retries automatically

---

## v2 Requirements (Deferred)

- Lyrics sync — complex, doesn't affect stability
- Equalizer / audio effects
- Crossfade between tracks
- Gapless playback
- Last.fm scrobbling
- Account system + cloud sync
- Multi-device sync
- AI recommendations
- Themes / appearance customization
- Podcast support
- Backend / FastAPI server

---

## Out of Scope (Explicit Exclusions)

| Excluded | Reason |
|----------|--------|
| iOS support | Android only for V1; iOS requires separate entitlements, different audio setup |
| Firebase | No cloud dependency in V1 |
| Account / login | No backend in V1 |
| Social features | Not personal use case |
| Python backend | Not needed — YouTube Music API replicated in Dart directly |
| Fancy animations / transitions | Stability over aesthetics in V1 |

---

## Traceability

| Phase | Requirements |
|-------|-------------|
| Phase 1: Foundation | SETUP-01 through SETUP-06 |
| Phase 2: Saavn Search | SEARCH-01 (partial — Saavn only), SEARCH-02 → SEARCH-07 |
| Phase 3: Playback & Queue | PLAY-01 through PLAY-11, QUEUE-01 through QUEUE-05 |
| Phase 4: Library & Persistence | LIB-01 through LIB-08 |
| Phase 5: Downloads | DL-01 through DL-07 |
| Phase 6: YouTube Provider | SEARCH-01 (completed — adds YouTube Music parallel search), YT-01 → YT-07 |
| Phase 7: Optimization | PERF-01 through PERF-05 |
