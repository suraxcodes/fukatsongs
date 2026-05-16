# Phase 12: Caching & Offline Capabilities - Research

## 1. Domain Overview
The goal is to provide reliable offline playback through a combination of manual permanent downloads and temporary streaming caches, bypassing network requests entirely when local audio files are available. 

## 2. Audio Storage & Caching Mechanisms

### A. Permanent Downloads
- **Mechanism:** Use `Dio` to download the audio stream directly to the app's private storage (obtained via `path_provider`'s `getApplicationDocumentsDirectory()`).
- **File Naming:** Use the `song.id` (and potentially a quality indicator) as the filename (e.g., `${song.id}.m4a` or `.mp3`).
- **Metadata Persistence:** We must save the `Song` metadata into a dedicated Hive box (e.g., `downloadsBox`) so the app can render the offline library when the network is completely disconnected.

### B. Temporary Streaming Caching
- **Mechanism:** Streaming natively with `just_audio` uses internal buffering, but to prevent re-downloading the same bytes when seeking or replaying within a session, we should wrap the stream URL in a `LockCachingAudioSource`.
- **Constraint:** Stream URLs expire (especially YouTube). Because `LockCachingAudioSource` caches based on the exact URL string, it won't hit the cache in future sessions if we generate a new URL. For V1, temporary caching is best restricted to the current session buffer, while relying on explicit Permanent Downloads for cross-session offline playback.

## 3. Playback Interception
In `MusicAudioHandler.playUrl()`, we must introduce a local interception layer:
1. Before fetching a fresh stream URL or initializing the network player, check if a file exists at `${downloads_dir}/${song.id}.audio_extension`.
2. If the file exists, immediately route to `playFile()` using `AudioSource.file()`.
3. If no file exists, proceed with the standard network fallback strategy (Piped proxy -> YouTube extraction).

## 4. UI/UX Integrations
- **Download Actions:** Add a "Download" button to the song's "Three-Dot" menu and the Immersive Player UI.
- **Progress Tracking:** A `DownloadNotifier` (Riverpod) needs to track active download progress via `Dio`'s `onReceiveProgress` to update UI indicators (e.g., a circular progress indicator turning into a "Downloaded" checkmark).
- **Library View:** Add a "Downloaded Music" section in the Library screen reading from the local Hive `downloadsBox`.

## 5. Validation Architecture (Nyquist)
- **Dimension 1 (Local Interception):** When playing a downloaded song, no network requests should be made to YouTube/Saavn.
- **Dimension 2 (File Storage):** Downloaded files must reside in the private app directory, not public storage.
- **Dimension 3 (Metadata):** Downloaded songs must appear in the Library even when the device is in Airplane mode.
