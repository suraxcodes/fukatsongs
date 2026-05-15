---
wave: 2
depends_on: [01-NAVIGATION-PLAN.md]
files_modified:
  - lib/features/library/logic/download_notifier.dart
  - lib/models/song.dart
autonomous: true
requirements_addressed: [LIB-02, LIB-03]
---

# Plan: Download Management Logic

**Objective:** Implement the background download engine with progress tracking and Hive persistence.

## Tasks

### 1. Implement DownloadNotifier
<read_first>
- lib/models/song.dart
</read_first>
<action>
Create `lib/features/library/logic/download_notifier.dart` (@riverpod).
- State: Map of `songId -> double progress`.
- Method: `downloadSong(Song song)`.
  - Fetch stream URL.
  - Use `Dio.download` with `onReceiveProgress`.
  - Save file to internal `downloads/` folder.
  - On success: Update `library` Hive box and add `localPath` to the song.
</action>
<acceptance_criteria>
- File is saved correctly in app directory.
- Download progress updates in real-time.
- Song record persists in Hive.
</acceptance_criteria>

### 2. Update LibraryScreen
<action>
Update `LibraryScreen` to display songs from the `library` Hive box.
- Use `ValueListenableBuilder` or Riverpod to listen to Hive changes.
- Display a list of `SongCard`s for downloaded music.
</action>
<acceptance_criteria>
- Downloaded songs appear instantly in the Library tab.
</acceptance_criteria>

## Verification
- Check file system after download via `path_provider`.
- Verify progress bar movement in UI.

## Must Haves
- [ ] Working Dio download logic
- [ ] Hive persistence for library
- [ ] Real-time progress updates
