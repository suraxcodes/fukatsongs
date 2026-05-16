---
wave: 2
depends_on: ["01-PLAN.md"]
files_modified:
  - lib/core/audio/audio_handler.dart
  - lib/providers/download_provider.dart
autonomous: false
---

# Plan: AudioHandler Interception

<objective>
Update the `MusicAudioHandler` to intercept network playback requests and seamlessly play local files if they have been downloaded.
</objective>

<tasks>
1. <task>
   <read_first>
   - lib/providers/download_provider.dart
   - lib/core/audio/audio_handler.dart
   </read_first>
   <action>
   In `lib/providers/download_provider.dart` (or a helper utility), create a static method or global function `Future<File?> getLocalAudioFile(String songId) async` that:
   1. Fetches `getApplicationDocumentsDirectory()`.
   2. Returns a `File` object pointing to `${dir.path}/downloads/$songId.m4a`.
   3. Checks `await file.exists()`. If true, returns the file; otherwise, returns null.
   </action>
   <acceptance_criteria>
   - `getLocalAudioFile` returns a `File` if it exists, or `null`.
   </acceptance_criteria>
   </task>

2. <task>
   <read_first>
   - lib/core/audio/audio_handler.dart
   </read_first>
   <action>
   In `MusicAudioHandler.playUrl(String url, Song song)`, intercept the execution BEFORE trying the network providers:
   1. Call `final localFile = await getLocalAudioFile(song.id);`.
   2. If `localFile != null`, call `await playFile(localFile.path, song);` and then `return;` early.
   3. This avoids falling back to the network stream logic if the file is already available offline.
   </action>
   <acceptance_criteria>
   - `playUrl` checks for local file existence before iterating through network providers.
   - If a local file is found, it calls `playFile` and short-circuits.
   </acceptance_criteria>
   </task>

3. <task>
   <read_first>
   - lib/core/audio/audio_handler.dart
   </read_first>
   <action>
   In `MusicAudioHandler.playUrl`, for the temporary network stream caching, wrap the network stream in a `LockCachingAudioSource`.
   Change:
   `await _player.setUrl(currentUrl);`
   To:
   `await _player.setAudioSource(LockCachingAudioSource(Uri.parse(currentUrl)));`
   (Do this for both `youtube` and `jiosaavn` providers).
   </action>
   <acceptance_criteria>
   - `AudioSource.uri` and `setUrl` are replaced with `LockCachingAudioSource(Uri.parse(currentUrl))` to cache the stream temporarily.
   </acceptance_criteria>
   </task>
</tasks>

<verification>
- Verify that streaming a song creates a temporary cache (improving scrub speed).
- Verify that a downloaded song plays correctly when the device has no internet connection, triggering `playFile`.
</verification>
