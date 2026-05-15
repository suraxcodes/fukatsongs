# Phase 3: Playback & Queue - Research

## Audio Service Integration (2025 Patterns)

### 1. Initialization
- Must call `AudioService.init` with a custom `AudioHandler`.
- Wrap the `AudioHandler` creation in a singleton or Riverpod provider.

### 2. AudioHandler Implementation
- **Position Tracking**: Use a stream to expose `just_audio` position to the system.
- **Queue Management**:
  - `addQueueItems`: Updates the `ConcatenatingAudioSource`.
  - `playMediaItem`: Starts playback of a specific item.
- **Metadata**: Every time a song starts, update `MediaItem` to refresh the notification.

### 3. Queue Stability
- Use `audio_session` to handle audio focus (interruptions from calls, etc.).
- Persist queue index via Hive `onPlaybackEvent`.

### 4. UI Patterns
- **Mini-player**: Persistent `Overlay` or a bottom bar in the `Scaffold`.
- **ProgressBar**: Use `audio_video_progress_bar` package or a custom `Slider` with stream listening.
