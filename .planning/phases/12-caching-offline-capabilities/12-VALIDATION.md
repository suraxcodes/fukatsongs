# Phase 12: Caching & Offline Capabilities - Validation Strategy

**Date:** 2026-05-16

## Validation Architecture

1. **Local Interception (Network Independence):**
   - Play a song that is downloaded while the device is in Airplane Mode. It must play successfully.
   - Verify that `MusicAudioHandler.playUrl` short-circuits and logs the local file path instead of fetching a new URL.

2. **File Storage Constraints:**
   - Verify that the files are saved in the `path_provider` application documents directory.
   - Verify they are not visible in the public Android `Music` folder or Media Store.

3. **Metadata Persistence:**
   - Verify that the "Downloaded Music" library screen loads the downloaded songs from Hive without requiring an internet connection.

4. **Temporary Caching (Buffer):**
   - Verify that rewinding a streaming song does not cause a buffer stall if the stream was wrapped in `LockCachingAudioSource`.

5. **Download Progress UI:**
   - Verify that tapping "Download" shows a progress indicator that correctly hits 100% and transitions to a "Downloaded" state.
