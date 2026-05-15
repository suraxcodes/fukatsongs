# fukatSongs — V1 Roadmap

## Overview

**7 phases** | **37 requirements mapped** | All v1 requirements covered ✓

| # | Phase | Goal | Requirements | Plans |
|---|-------|------|--------------|-------|
| 1 | Foundation | App boots with correct structure, Song model, and Hive initialized | SETUP-01 → SETUP-06 | 3 |
| 2 | Saavn Search | User can search songs via JioSaavn and see normalized results | SEARCH-01 → SEARCH-07 | 3 |
| 3 | Playback & Queue | Stable background playback with full queue management | PLAY-01 → PLAY-11, QUEUE-01 → QUEUE-05 | 5 |
| 4 | Library & Persistence | Liked songs, recents, playlists — all persisted in Hive | LIB-01 → LIB-08 | 3 |
| 5 | Downloads | Song download to device storage + offline playback | DL-01 → DL-07 | 3 |
| 6 | YouTube Provider | Parallel search + fallback + ranking + deduplication | YT-01 → YT-07 | 4 |
| 7 | Optimization | Caching, performance polish, network resilience | PERF-01 → PERF-05 | 3 |

---

## Phase 1: Foundation

**Goal:** App boots on Android with correct folder structure, all dependencies installed, Song model defined, Hive initialized, and Riverpod wired up.

**Requirements:** SETUP-01, SETUP-02, SETUP-03, SETUP-04, SETUP-05, SETUP-06

**Success Criteria:**
1. `flutter run` succeeds and app opens to a home screen on Android
2. Song model compiles with Freezed code generation (`build_runner` runs clean)
3. `MusicProvider` abstract class is defined with `search()` and `getStreamUrl()` signatures
4. Hive opens all 7 required boxes at startup without error
5. ProviderScope wraps the app and a test provider reads/writes without error

**Plans:**
- Plan 1: Project setup — rename app, install all dependencies, run `build_runner`
- Plan 2: Core models — Song (Freezed), MusicProvider interface, Hive adapters
- Plan 3: App scaffolding — ProviderScope setup, Hive initialization, folder structure, basic home screen

**UI hint:** no

---

## Phase 2: Saavn Search

**Goal:** User can type a search query, see results from JioSaavn normalized into Song objects, with loading/error states.

**Requirements:** SEARCH-01, SEARCH-02, SEARCH-03, SEARCH-04, SEARCH-05, SEARCH-06, SEARCH-07

**Success Criteria:**
1. Typing "Arijit Singh" returns a list of songs from JioSaavn within 3 seconds
2. Rapid typing only triggers one API call after 300ms pause (debounce works)
3. Each result shows title, artist, thumbnail image, and duration
4. Network error shows a user-facing error message (not a crash)
5. Clearing the search field returns to empty/recent state
6. Results list handles 50+ items without jank (lazy loading or pagination)

**Plans:**
- Plan 1: SaavnProvider — Dio client, search endpoint, response parsing, stream URL fetch
- Plan 2: SearchNotifier — Riverpod AsyncNotifier with debounce, error handling
- Plan 3: Search UI — SearchScreen, search bar, results list, loading/error/empty states

**UI hint:** yes

---

## Phase 3: Playback & Queue

**Goal:** User can tap a song and it plays — background audio, media notification, lock screen controls, queue with shuffle/repeat all working.

**Requirements:** PLAY-01 → PLAY-11, QUEUE-01 → QUEUE-05

**Success Criteria:**
1. Tapping a search result starts playing the song
2. Music continues when app is backgrounded or screen locks
3. Android media notification shows artwork, title, play/pause/skip controls
4. Lock screen controls change playback state
5. Headphone removal pauses music automatically
6. Shuffle maintains both original and shuffled queue; toggling off restores original order
7. Queue state (current song, position, shuffle, repeat) is restored after app kill/restart

**Plans:**
- Plan 1: AudioHandler — `AudioHandler` subclass wrapping `just_audio`, stream URL refresh, AndroidManifest setup
- Plan 2: Queue manager — `QueueNotifier` with `_originalQueue` / `_shuffledQueue`, repeat modes, auto-advance
- Plan 3: Player state — `PlayerNotifier` consuming `AudioPlayer` streams (position, duration, state)
- Plan 4: Player UI — PlayerScreen with artwork, seek bar, controls, queue view
- Plan 5: Audio interruptions — headphone removal, call handling, network switch retry

**UI hint:** yes

---

## Phase 4: Library & Persistence

**Goal:** User can like songs, view recently played, create playlists, add/remove songs — all persisted in Hive across sessions.

**Requirements:** LIB-01 → LIB-08

**Success Criteria:**
1. Liking a song adds it to Liked Songs; unliking removes it immediately
2. Last 50 played songs appear in recents, updating in real time
3. User can create a named playlist, add songs to it, and play from it
4. Playlists persist across app restarts
5. Deleting a playlist removes it from all screens
6. Home screen shows recent songs, liked songs count, and playlist list

**Plans:**
- Plan 1: Hive repositories — LikedSongsRepo, RecentSongsRepo, PlaylistRepo with proper Hive box operations
- Plan 2: Library providers — Riverpod notifiers for liked/recents/playlists reacting to Hive changes
- Plan 3: Library UI — LibraryScreen, playlist detail screen, home screen sections (recents, liked, playlists)

**UI hint:** yes

---

## Phase 5: Downloads

**Goal:** User can download songs to device storage, play them offline, view and delete downloads.

**Requirements:** DL-01 → DL-07

**Success Criteria:**
1. Tapping download starts downloading; progress percentage is shown
2. Downloaded song plays when device is in airplane mode
3. Downloaded songs list shows all available offline songs
4. Deleting a download removes the audio file and Hive metadata
5. Attempting to download an already-downloaded song shows "already downloaded" — no duplicate download starts
6. App detects missing/corrupted download file and marks song as unavailable

**Plans:**
- Plan 1: DownloadManager — Dio download with progress stream, file path generation, validation
- Plan 2: DownloadRepo + DownloadNotifier — Hive metadata, DownloadProvider state, duplicate detection
- Plan 3: Download UI — download button on song cards, progress indicator, downloads screen

**UI hint:** yes

---

## Phase 6: YouTube Provider

**Goal:** Search runs against both JioSaavn and YouTube Music in parallel; results are merged, ranked, deduped; YouTube is fallback for playback.

**Requirements:** YT-01 → YT-07

**Success Criteria:**
1. Searching "Kesariya" returns combined results from both providers within 4 seconds
2. Duplicate songs (same title + artist from both providers) appear only once
3. "Kesariya Slowed Reverb" and "Kesariya Lyrics Video" are filtered out
4. Top result has highest relevance score (title match + artist match + official audio)
5. If JioSaavn stream URL fails, app retries with YouTube stream URL silently
6. YouTube stream URLs come from `youtube_explode_dart` and are fetched fresh at playback time

**Plans:**
- Plan 1: YouTubeProvider — internal YouTube Music API search (POST `youtubei/v1/search`), response normalization
- Plan 2: Parallel search orchestration — `Future.wait()` across both providers, merge + dedup + filter + rank
- Plan 3: Provider fallback — playback failure detection in AudioHandler, retry with alternate provider
- Plan 4: youtube_explode_dart integration — stream URL extraction for YouTube songs

**UI hint:** no

---

## Phase 7: Optimization

**Goal:** App feels fast — images cached, metadata cached, search results cached, timeouts set, network switches handled gracefully.

**Requirements:** PERF-01 → PERF-05

**Success Criteria:**
1. Revisiting a search query shows cached results instantly (within TTL)
2. Album art loads from disk cache on revisit — no re-download
3. Previously fetched song metadata does not trigger a new API call
4. API timeout of 10s connect / 15s receive — no infinite spinners
5. Switching from WiFi to mobile data mid-playback recovers automatically

**Plans:**
- Plan 1: Metadata + search cache — Hive-backed cache with 30-min TTL for search results and song metadata
- Plan 2: Dio configuration — global timeouts, retry interceptor, connectivity monitoring
- Plan 3: Performance audit — profile with Flutter DevTools, fix jank, optimize list rendering

**UI hint:** no

---

## Dependency Graph

```
Phase 1 (Foundation)
    ↓
Phase 2 (Saavn Search)
    ↓
Phase 3 (Playback & Queue) ← most complex, deserves most time
    ↓
Phase 4 (Library)    Phase 5 (Downloads)
    ↓                      ↓
           Phase 6 (YouTube Provider)
                    ↓
           Phase 7 (Optimization)
```

Phase 4 and 5 can run in parallel after Phase 3.
