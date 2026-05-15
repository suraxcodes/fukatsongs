# Architecture Research — fukatSongs

## Domain: Flutter Android Music Streaming App

---

## Component Architecture

```
┌─────────────────────────────────────────────────────┐
│                   Flutter UI Layer                   │
│  HomeScreen │ SearchScreen │ PlayerScreen │ Library  │
└─────────────────────────┬───────────────────────────┘
                          │ (Riverpod Providers)
┌─────────────────────────▼───────────────────────────┐
│                  Riverpod State Layer                 │
│  PlayerProvider │ QueueProvider │ SearchProvider     │
│  LibraryProvider │ DownloadProvider                  │
└──────┬──────────────────┬──────────────────┬─────────┘
       │                  │                  │
┌──────▼──────┐   ┌───────▼──────┐  ┌───────▼────────┐
│ AudioService │   │  Repository  │  │DownloadManager │
│   Handler    │   │    Layer     │  │                │
│(just_audio)  │   │              │  │ Dio + progress │
└─────────────┘   └───────┬──────┘  └───────┬────────┘
                          │                  │
              ┌───────────▼──────────┐  ┌────▼──────────┐
              │   Provider Layer     │  │Device Storage  │
              │                      │  │   (audio files)│
              │ SaavnProvider        │  └───────────────┘
              │ YouTubeProvider      │
              │ (MusicProvider iface)│
              └───────────┬──────────┘
                          │
              ┌───────────▼──────────┐
              │    Hive Local DB     │
              │ playlists │ likes    │
              │ queue state │ cache  │
              │ download metadata   │
              └─────────────────────┘
```

---

## Component Boundaries

### UI Layer
- **Reads from:** Riverpod providers (watch/listen)
- **Writes to:** Riverpod providers (notifiers/methods)
- **Never touches:** HTTP clients, Hive, AudioPlayer directly

### Riverpod State Layer
- **PlayerProvider:** Current song, playback state, position, duration
- **QueueProvider:** Queue list, shuffle state, repeat mode, original + shuffled queues
- **SearchProvider:** Query, results, loading state, error state
- **LibraryProvider:** Playlists, liked songs, recent songs (reads/writes Hive)
- **DownloadProvider:** Download queue, progress map, completed downloads

### AudioService Handler
- **Wraps:** `just_audio` `AudioPlayer`
- **Exposes:** MediaItem, PlaybackState to Android OS (media notification, lock screen)
- **Implements:** `AudioHandler` interface from `audio_service`
- **Manages:** Queue as `ConcatenatingAudioSource`, stream URL refresh

### Repository Layer
- **Orchestrates:** Multi-provider search, result normalization, deduplication, ranking
- **Does NOT own state** — pure data operations

### Provider Layer (Music Sources)
- **Interface:** `abstract class MusicProvider { Future<List<Song>> search(String q); Future<String> getStreamUrl(String id); }`
- **SaavnProvider:** JioSaavn API integration
- **YouTubeProvider:** YouTube Music API integration

---

## Data Flow

### Search Flow
```
User types → Debounce (300ms) → SearchNotifier.search()
  → Repository.search()
    → [SaavnProvider.search(), YouTubeProvider.search()] (parallel)
  → Normalize results → Remove duplicates → Rank results → Filter garbage
  → SearchNotifier updates state → UI rebuilds
```

### Playback Flow
```
User taps song → QueueNotifier.playSong(song)
  → AudioHandler.playSong(song)
    → Repository.getStreamUrl(song) [fetch fresh URL — never stored]
    → AudioPlayer.setUrl(url)
    → AudioPlayer.play()
  → PlayerNotifier listens to AudioPlayer streams → UI updates
```

### Download Flow
```
User taps download → DownloadNotifier.download(song)
  → Repository.getStreamUrl(song) [fresh URL]
  → Dio.download(url, localPath, onReceiveProgress)
  → Validate file exists + size > 0
  → Hive.put(song.id, DownloadMetadata(localPath, downloadedAt))
  → DownloadNotifier marks complete
```

### Offline Playback Flow
```
User taps downloaded song → QueueNotifier.playSong(song)
  → AudioHandler.playSong(song)
    → Check DownloadRepo.isDownloaded(song.id)
    → If yes: AudioPlayer.setFilePath(localPath)
    → If no: fetch stream URL as normal
```

---

## Recommended Build Order

Phase dependencies determine this:

1. **Project setup + Song model** — Foundation. Nothing works without this.
2. **Saavn API + Search** — First visible feature. Validates provider pattern.
3. **Audio playback (just_audio only, no audio_service)** — Get basic play working first.
4. **Background audio + AudioHandler** — Add audio_service after basic playback works.
5. **Queue + Shuffle/Repeat** — Depends on playback being stable.
6. **Hive persistence + Library** — Depends on Song model being stable.
7. **Download manager** — Depends on stream URL fetching, file system access.
8. **YouTube provider** — Slot into existing provider abstraction.
9. **Caching + optimization** — Polish phase; last.

**Why this order:** Each phase delivers runnable functionality. You can test Saavn search without queue management. You can test playback without downloads.

---

## Key Architectural Decisions to Make Early

### 1. AudioHandler design (HIGH PRIORITY)
Decide before Phase 3: Use manual `AudioHandler` subclass, not `just_audio_background`.
Reason: Provider fallback + stream URL refresh requires custom logic in `onPlayMediaItem`.

### 2. Song model stability (HIGH PRIORITY)
Lock the `Song` model in Phase 1. Changing it later breaks Hive storage + provider contracts.

```dart
@freezed
class Song with _$Song {
  const factory Song({
    required String id,
    required String title,
    required String artist,
    required String imageUrl,
    required Duration duration,
    required String source, // 'saavn' | 'youtube'
    Map<String, dynamic>? providers, // {saavn: {id}, youtube: {id}}
    String? primaryProvider,
    String? localPath, // set if downloaded
  }) = _Song;
}
```

### 3. Hive box structure (MEDIUM PRIORITY)
Design boxes before Phase 4:
- `songs` box — Song objects (cached metadata)
- `playlists` box — Playlist objects
- `liked_songs` box — Set of song IDs
- `recent_songs` box — Ordered list of song IDs
- `queue_state` box — Current queue + position
- `downloads` box — DownloadMetadata objects
- `settings` box — App settings

### 4. Single AudioPlayer instance (HIGH PRIORITY)
Create `AudioPlayer` once, in the `AudioHandler`, registered as a singleton in Riverpod. Never create a second instance.
