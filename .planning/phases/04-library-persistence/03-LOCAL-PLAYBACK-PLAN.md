---
wave: 3
depends_on: [02-DOWNLOAD-LOGIC-PLAN.md]
files_modified:
  - lib/features/player/presentation/player_notifier.dart
  - lib/features/search/presentation/widgets/song_card.dart
autonomous: true
requirements_addressed: [PLAY-08, UI-02]
---

# Plan: Local-First Playback & UI Polish

**Objective:** Ensure the app prefers local files over streaming and update the UI to show download status.

## Tasks

### 1. Smart Source Switching
<read_first>
- lib/features/player/presentation/player_notifier.dart
- lib/core/audio/audio_handler.dart
</read_first>
<action>
Update `PlayerNotifier.playSong`:
- Check if `song.localPath` exists on disk using `File(path).existsSync()`.
- If yes: Pass the file path to `AudioHandler.playFile`.
- If no: Fetch stream URL and play via `AudioHandler.playUrl`.
</action>
<acceptance_criteria>
- App plays music without internet if the file is downloaded.
- Smooth transition between online and offline states.
</acceptance_criteria>

### 2. UI Status Indicators
<read_first>
- lib/features/search/presentation/widgets/song_card.dart
</read_first>
<action>
Update `SongCard`:
- Add a download icon or progress circle.
- State 1: Not Downloaded (Cloud icon).
- State 2: Downloading (Circular progress).
- State 3: Downloaded (Checkmark or "Offline" badge).
</action>
<acceptance_criteria>
- User can see which songs are available offline at a glance.
</acceptance_criteria>

## Verification
- Turn off internet and verify downloaded songs still play.
- Check download progress visibility in the grid.

## Must Haves
- [ ] Offline playback capability
- [ ] Visual download status
- [ ] Reliable file existence checks
