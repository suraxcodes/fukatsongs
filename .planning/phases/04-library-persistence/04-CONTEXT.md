# Phase 4: Library & Persistence - Context

## Implementation Decisions

### Download Engine
- **Provider**: `DownloadNotifier` (@riverpod) using `Dio`.
- **Concurrency**: Support up to 3 parallel downloads.
- **Storage**: Save to `getApplicationDocumentsDirectory()/downloads/`.
- **Persistence**: Store the `localPath` in the `Song` model and update the `library` Hive box.

### Playback Strategy (Local First)
- **Logic**: 
  - `PlayerNotifier` checks if `song.localPath` is not null.
  - If it exists on disk, `AudioHandler` uses `AudioSource.file(localPath)`.
  - Otherwise, it fetches the stream URL as usual.

### Library UI
- **Structure**:
  - Add a `BottomNavigationBar` to the main app scaffold.
  - **Search Tab**: The existing search interface.
  - **Library Tab**: Lists all downloaded songs with "Offline" badges.
- **Components**:
  - `LibraryScreen`: List of downloaded songs.
  - `DownloadButton`: Integrated into `SongCard` or a context menu.

## Architecture Patterns
- **Directory Management**: Use `path_provider` to resolve paths.
- **File Naming**: `${song.id}.mp3`.
- **State**: Track download progress (0-100%) in `DownloadNotifier`.
