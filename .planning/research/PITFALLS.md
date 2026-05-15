# Pitfalls Research — fukatSongs

## Domain: Flutter Android Music Streaming App

---

## Pitfall 1: Storing Stream URLs Permanently

**Warning signs:**
- Songs play fine today, fail tomorrow with 403/404
- Download works but file plays corrupted audio

**What goes wrong:**
JioSaavn and YouTube stream URLs are signed/temporary. They expire in minutes to hours. If you store them in Hive or pass them between sessions, playback will fail silently.

**Prevention:**
- Store provider ID only (e.g., `saavn_id: "abc123"`)
- Always call `getStreamUrl(id)` immediately before playback
- Never cache stream URLs — only cache metadata (title, artist, imageUrl, duration)

**Phase:** Address in Phase 1 (Song model design) and Phase 3 (playback)

---

## Pitfall 2: Creating Multiple AudioPlayer Instances

**Warning signs:**
- Multiple songs play simultaneously
- Audio doesn't stop when navigating between screens
- Memory usage climbs over time

**What goes wrong:**
Flutter creates new widget trees during navigation. If you create `AudioPlayer()` inside a widget or provider that gets recreated, you accumulate players.

**Prevention:**
- Create `AudioPlayer` exactly once, in `AudioHandler`
- Register `AudioHandler` as a singleton: `await AudioService.init(builder: () => MyAudioHandler())`
- Never call `AudioPlayer()` anywhere outside `AudioHandler`

**Phase:** Critical in Phase 3

---

## Pitfall 3: Forgetting audio_service AndroidManifest Setup

**Warning signs:**
- Background playback works in debug but crashes in release
- Media notification appears but controls don't work
- App gets killed after screen off

**What goes wrong:**
`audio_service` requires specific AndroidManifest.xml changes. Missing these causes silent failures.

**Prevention — Required AndroidManifest entries:**
```xml
<service android:name="com.ryanheise.audioservice.AudioServiceBackground"
  android:taskAffinity=""
  android:exported="false">
  <intent-filter>
    <action android:name="android.media.browse.MediaBrowserService" />
  </intent-filter>
</service>

<receiver android:name="com.ryanheise.audioservice.MediaButtonReceiver"
  android:exported="true">
  <intent-filter>
    <action android:name="android.intent.action.MEDIA_BUTTON" />
  </intent-filter>
</receiver>
```

Also add `FOREGROUND_SERVICE` and `WAKE_LOCK` permissions.

**Phase:** Address in Phase 3

---

## Pitfall 4: Blocking Main Thread with Hive Operations

**Warning signs:**
- UI stutters when opening playlists or library
- App freezes briefly when saving queue state

**What goes wrong:**
Hive operations are synchronous. Running them on the main thread blocks UI.

**Prevention:**
- Use `Hive.openBox()` at app startup (once)
- Wrap heavy Hive reads/writes in `compute()` or `Isolate.run()` for large datasets
- For search cache, use async-friendly patterns via Riverpod's `AsyncNotifier`

**Phase:** Address in Phase 4 (Hive setup)

---

## Pitfall 5: Destructive Shuffle

**Warning signs:**
- Toggling shuffle off doesn't restore original order
- Queue is permanently scrambled after first shuffle

**What goes wrong:**
Calling `queue.shuffle()` in-place destroys the original ordering. You can't unshuffle.

**Prevention:**
- Maintain two lists: `_originalQueue` and `_shuffledQueue`
- When shuffle is enabled: generate shuffled copy, keep original intact
- When shuffle is disabled: restore from `_originalQueue`
- Current index must be tracked in both lists

**Phase:** Address in Phase 3 (queue system)

---

## Pitfall 6: Missing Android 13+ Storage Permissions

**Warning signs:**
- Downloads fail on Android 13 devices
- `permission_handler` returns `denied` even after user grants

**What goes wrong:**
Android 13+ replaced `READ_EXTERNAL_STORAGE` / `WRITE_EXTERNAL_STORAGE` with granular media permissions (`READ_MEDIA_AUDIO`). Old permission code silently fails.

**Prevention:**
- Use `permission_handler` ^11.x which handles this automatically
- For downloads, prefer `getApplicationDocumentsDirectory()` or `getExternalStorageDirectory()` — these don't require permission on any Android version
- If writing to public `Music/` folder, request `Permission.manageExternalStorage` (Android 11+) or `Permission.storage` (Android ≤ 10)

**Phase:** Address in Phase 5 (downloads)

---

## Pitfall 7: Riverpod Provider Scope Issues with AudioService

**Warning signs:**
- `ProviderScope` not found error when AudioHandler tries to read Riverpod state
- Stream URL fetch fails inside AudioHandler

**What goes wrong:**
`audio_service` runs `AudioHandler` in a background isolate context. Standard `ref.read()` doesn't work there without careful setup.

**Prevention:**
- Pass a `ProviderContainer` to `AudioHandler` at initialization
- Or use `AudioService.init()` inside `ProviderScope` and use a `Ref` passed from outside
- Pattern: `AudioHandler` holds a direct reference to `Repository`, not a Riverpod ref

**Phase:** Critical in Phase 3

---

## Pitfall 8: Not Handling API Failures Gracefully

**Warning signs:**
- App crashes when JioSaavn is down
- Search spinner never stops on timeout

**What goes wrong:**
Unofficial APIs fail. Without error handling, one API failure crashes the whole search or playback.

**Prevention:**
- Wrap all API calls in try/catch
- Use `Result<T, E>` pattern or `AsyncValue` from Riverpod for error states
- Set Dio timeout: `connectTimeout: Duration(seconds: 10), receiveTimeout: Duration(seconds: 15)`
- Search: if one provider fails, return results from the other instead of failing entirely

**Phase:** Address starting Phase 2, reinforce in Phase 6

---

## Pitfall 9: Memory Leaks from Stream Subscriptions

**Warning signs:**
- Memory climbs with each screen navigation
- `StreamSubscription` exceptions in logs

**What goes wrong:**
`just_audio` exposes `Stream<PlayerState>`, `Stream<Duration>`, etc. If you subscribe without cancelling on dispose, subscriptions accumulate.

**Prevention:**
- In Riverpod `Notifier`: cancel subscriptions in `dispose()`
- Pattern: `ref.onDispose(() => subscription.cancel())`
- Never subscribe to streams inside `build()` without `ref.listen()`

**Phase:** Address in Phase 3

---

## Pitfall 10: Unofficial API Fragility

**Warning signs:**
- JioSaavn API suddenly returns empty results
- YouTube API returns 403 unexpectedly

**What goes wrong:**
These are unofficial APIs. They can change endpoints, add auth requirements, rate limit, or shut down without notice.

**Prevention:**
- Provider abstraction from day one (swap implementation without rewriting UI)
- Log all API failures with full request context
- Never hard-code API base URLs — use constants that can be updated in one place
- Build fallback to secondary provider (YouTube) before depending on Saavn exclusively
- Consider: jio-saavn-api self-hosted wrapper to avoid direct API dependency

**Phase:** Architecture decisions in Phase 1, implementation in Phase 2 and 6
