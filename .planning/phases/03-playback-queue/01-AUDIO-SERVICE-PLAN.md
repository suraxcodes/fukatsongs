---
wave: 1
depends_on: []
files_modified:
  - lib/core/audio/audio_handler.dart
  - lib/main.dart
  - lib/features/player/presentation/player_notifier.dart
autonomous: true
requirements_addressed: [PLAY-01, PLAY-02, PLAY-03]
---

# Plan: Audio Service Foundation

**Objective:** Establish the background audio service and a singleton audio handler to manage playback.

## Tasks

### 1. Create MusicAudioHandler
<read_first>
- lib/models/song.dart
</read_first>
<action>
Create `lib/core/audio/audio_handler.dart`.
- Extend `BaseAudioHandler`.
- Initialize `AudioPlayer` (just_audio).
- Implement `play`, `pause`, `seek`, `skipToNext`, `skipToPrevious`.
- Implement `playMediaItem` (maps Song to MediaItem and starts playback).
- Sync `player.playbackEventStream` with `playbackState`.
</action>
<acceptance_criteria>
- `AudioHandler` is initialized without errors.
- Can start/stop playback programmatically.
- System notification appears on Android.
</acceptance_criteria>

### 2. Initialize Service in main.dart
<read_first>
- lib/main.dart
</read_first>
<action>
Update `main.dart` to initialize the `AudioHandler`.
- Call `AudioService.init`.
- Store the handler in a global or accessible way (to be wrapped by Riverpod).
</action>
<acceptance_criteria>
- App boots with `audio_service` active.
</acceptance_criteria>

### 3. Implement PlayerNotifier
<action>
Create `lib/features/player/presentation/player_notifier.dart` using `@riverpod`.
- State: `PlayerState` (current song, isPlaying, progress).
- Wraps the `AudioHandler` calls.
- Listens to handler streams to update UI state.
</action>
<acceptance_criteria>
- UI can subscribe to `PlayerNotifier` for real-time playback updates.
</acceptance_criteria>

## Verification
- Verify media notification controls work on Android emulator.
- Check logs for "Audio service initialized".

## Must Haves
- [ ] Working AudioHandler
- [ ] Background playback capability
- [ ] Riverpod wrapper for UI
