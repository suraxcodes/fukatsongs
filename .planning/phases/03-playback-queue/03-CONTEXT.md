# Phase 3: Playback & Queue - Context

## Implementation Decisions

### Audio Engine
- **Core**: Single global `AudioPlayer` instance (just_audio).
- **Service**: Manual `AudioHandler` implementation using `audio_service`.
- **Logic**:
  - `just_audio` handles the raw playback and buffering.
  - `audio_service` handles background tasks, media notifications, and lock-screen controls.
  - Stream URLs are fetched via `MusicRepository` at playback time (not persisted).

### Queue System
- **Persistence**: Store `current_queue` (list of Song IDs) and `current_index` in `queue_state` Hive box.
- **Duality**: Maintain `originalQueue` and `shuffledQueue` (as per GEMINI.md rules).
- **Operations**: Support Add to Queue, Play Next, Clear Queue, and Reorder.

### User Interface
- **Mini-player**: Persistent bottom bar with Play/Pause, Title, and Thumbnail.
- **Full Player**: Slide-up panel with:
  - High-res Artwork.
  - Progress Slider (Seek bar).
  - Playback controls (Shuffle, Prev, Play/Pause, Next, Repeat).
  - Queue view (list of upcoming songs).

## Architecture Patterns
- **Provider**: `PlayerNotifier` (@riverpod) wrapping the `AudioHandler`.
- **Streams**: Expose `Position`, `BufferedPosition`, and `Duration` as streams to the UI.
- **Theme**: Glassmorphism and Electric Indigo accents on the player controls.
