# Features Research — fukatSongs

## Domain: Personal Android Music Streaming App

---

## Table Stakes (Users Expect These — Must Have)

### Playback Core
- Play / Pause / Stop
- Seek (scrub progress bar)
- Next / Previous track
- Background playback (music continues when app is minimized)
- Lock screen controls + media notification
- Volume control
- Auto-advance to next track

### Queue Management
- Add to queue
- View current queue
- Reorder queue items
- Clear queue
- Shuffle (non-destructive — preserve original order)
- Repeat: Off / Repeat One / Repeat All

### Search
- Text search with results
- Display: title, artist, album art, duration
- Debounced input (no API spam per keystroke)

### Library
- Liked songs list
- Recently played list
- Create / rename / delete playlists
- Add / remove songs from playlists
- View playlist contents

### Downloads / Offline
- Download individual songs
- View downloaded songs
- Play downloaded songs without internet
- Delete downloads
- Download progress indicator

### UI Screens
- Home screen (recents, liked, playlists)
- Search screen
- Now Playing / Player screen
- Library screen
- Downloads screen

---

## Differentiators (fukatSongs-specific — competitive advantage)

### Multi-Provider Architecture
- Parallel search across Saavn + YouTube
- Automatic fallback when primary provider fails
- Provider-agnostic song model (store IDs, not URLs)
- Smart ranking/deduplication of results

### Resilience
- Stream URL refresh at playback time (never store expiring URLs)
- Automatic provider switching on playback failure
- Graceful degradation on API failure

### Smart Search
- Result scoring system (title match +50, artist match +40, official audio +20)
- Filter garbage results (slowed, reverb, lyrics videos, fan edits)
- Duplicate removal across providers

### Queue Persistence
- Restore queue + position after app restart
- Save shuffle/repeat state across sessions

---

## Anti-Features (Deliberately NOT Building in V1)

| Feature | Reason |
|---------|--------|
| Lyrics sync | Doesn't solve core stability; complex to implement correctly |
| Equalizer | Peripheral feature; adds complexity |
| AI recommendations | Overengineered; no user data to train on |
| Social features | Not personal use case |
| Themes / dark mode toggle | Flutter defaults to system theme; not priority |
| Account system | No backend in V1 |
| Cloud sync | No backend in V1 |
| Podcast support | Different content type; separate project |
| Radio / stations | Complex; not in scope |
| Crossfade | Nice-to-have; V2 |
| Gapless playback | Nice-to-have; V2 |
| Last.fm scrobbling | V2 |

---

## Feature Complexity Assessment

| Feature | Complexity | Dependencies |
|---------|------------|--------------|
| Project setup | Low | — |
| Song model + normalization | Low | — |
| Saavn API integration | Medium | Dio, Song model |
| Basic playback | Medium | just_audio |
| Background playback | High | audio_service + just_audio |
| Queue management | Medium | Playback core |
| Shuffle/repeat | Medium | Queue |
| Search UI + debounce | Low-Medium | Riverpod |
| Hive persistence | Low | Hive |
| Playlists + likes | Low-Medium | Hive |
| File download | Medium | Dio, path_provider, permission_handler |
| Offline playback | Low (once download works) | Download system |
| YouTube integration | Medium | Provider abstraction |
| Parallel search | Medium | Provider abstraction, async |
| Result ranking | Medium | Search system |
| Queue persistence | Low | Hive, queue manager |
| Image caching | Low | cached_network_image |

---

## Feature Dependencies Graph

```
Project Setup
    ↓
Song Model
    ↓
Saavn Provider → Search UI
    ↓
Playback Core (just_audio)
    ↓
Background Playback (audio_service)
    ↓
Queue Manager
    ↓
Hive Persistence → Playlists + Likes
    ↓
Download Manager → Offline Playback
    ↓
YouTube Provider → Parallel Search → Result Ranking
    ↓
Caching + Optimization
```
