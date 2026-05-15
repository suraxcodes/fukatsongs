# Phase 4: Library & Persistence - Research

## Download Manager (2025 Patterns)

### 1. Dio Implementation
- **Concurrent Limit**: Wrap download calls in a semaphore or simple list check to limit active tasks.
- **Progress Tracking**: Store a map of `songId -> progress` in the `DownloadNotifier` state.
- **Persistence**: Once a file is downloaded, update the `localPath` in the Hive `songs` box (or a dedicated `library` box).

### 2. File Management
- **Directory**: `Directory('${appDocDir.path}/downloads')`.
- **Naming**: Use `song.id` to avoid collisions.
- **Verification**: Always verify `file.existsSync()` before attempting local playback.

### 3. Navigation (Bottom Tabs)
- Implement a `MainScreen` that hosts the `BottomNavigationBar`.
- Use an `IndexedStack` to preserve search state when switching to Library.

### 4. Smart Playback logic
- If `song.localPath != null`, attempt to load as `AudioSource.file`.
- If it fails (file deleted/moved), fallback to streaming and clear `localPath`.
