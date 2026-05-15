# Stack Research — fukatSongs

## Domain: Flutter Android Music Streaming App (2025)

---

## Recommended Stack

### State Management

| Package | Version | Rationale | Confidence |
|---------|---------|-----------|------------|
| `flutter_riverpod` | ^2.5.1 | Industry-standard for Flutter in 2025. Code-gen with `@riverpod` annotation is cleanest pattern for async audio state. Better than Bloc for this use case — less boilerplate, native async support. | High |
| `riverpod_annotation` | ^2.3.5 | Required for code-gen approach | High |
| `riverpod_generator` | ^2.4.0 | Build runner for @riverpod annotations | High |

**NOT recommended:** Provider (deprecated path), Bloc (too verbose for audio state), GetX (anti-pattern).

---

### Audio Playback

| Package | Version | Rationale | Confidence |
|---------|---------|-----------|------------|
| `just_audio` | ^0.9.36 | De-facto standard. Handles HLS, MP3, M4A, OPUS. Cross-platform. Well maintained by Ryan Heise. | High |
| `audio_service` | ^0.18.13 | Required for Android background playback, media notifications, lock screen controls. Works with just_audio via AudioHandler. | High |
| `just_audio_background` | ^0.0.1-beta.12 | Thin wrapper that integrates just_audio + audio_service with less boilerplate than manual AudioHandler. **Use this ONLY for simple apps.** For fukatSongs, prefer manual AudioHandler — more control over queue, metadata. | Medium |

**Key decision:** Use manual `AudioHandler` (not `just_audio_background`) because fukatSongs needs custom queue management, provider fallback logic, and stream URL refresh — too complex for the thin wrapper.

---

### Networking

| Package | Version | Rationale | Confidence |
|---------|---------|-----------|------------|
| `dio` | ^5.4.0 | Best HTTP client for Flutter. Interceptors for retry/auth, cancel tokens, download progress streams. Vastly superior to `http` package for this use case. | High |

---

### Local Database

| Package | Version | Rationale | Confidence |
|---------|---------|-----------|------------|
| `hive` | ^2.2.3 | Fast key-value store. Good for playlists, liked songs, settings, cached metadata. Zero native dependencies. | High |
| `hive_flutter` | ^1.1.0 | Flutter integration for Hive | High |

**Alternative considered — Isar:** Isar 3.x is faster and has a query language. BUT it requires native compilation and has had breaking changes. For fukatSongs V1, Hive's simplicity wins. Isar makes sense in V2 if query complexity grows.

---

### File & Downloads

| Package | Version | Rationale | Confidence |
|---------|---------|-----------|------------|
| `path_provider` | ^2.1.2 | Get app-specific storage directories. Required for download file paths. | High |
| `permission_handler` | ^11.3.0 | Runtime permission requests (storage on Android < 13, audio on Android 13+). | High |

**Android storage note:** Android 13+ (API 33+) uses `READ_MEDIA_AUDIO` instead of `READ_EXTERNAL_STORAGE`. permission_handler 11.x handles this correctly.

---

### UI & Images

| Package | Version | Rationale | Confidence |
|---------|---------|-----------|------------|
| `cached_network_image` | ^3.3.1 | Album art caching. Disk + memory cache. Placeholder + error widget support. | High |
| `flutter_screenutil` | ^5.9.0 | Responsive sizing for different Android screen sizes. | Medium |

---

### Utilities

| Package | Version | Rationale | Confidence |
|---------|---------|-----------|------------|
| `freezed` | ^2.4.7 | Immutable data classes for Song model, PlayerState. Eliminates boilerplate. | High |
| `freezed_annotation` | ^2.4.1 | Required annotation package | High |
| `json_annotation` | ^4.8.1 | JSON serialization for API responses | High |
| `json_serializable` | ^6.7.1 | Code-gen for JSON | High |
| `build_runner` | ^2.4.8 | Runs all code generation (Riverpod, Freezed, JSON) | High |
| `logger` | ^2.0.2 | Structured logging for debugging provider failures, playback errors | Medium |
| `connectivity_plus` | ^5.0.2 | Detect WiFi vs mobile data switches during playback | Medium |
| `flutter_cache_manager` | ^3.3.1 | General file caching (used by cached_network_image internally) | Medium |

---

## What NOT to Use

| Package | Reason |
|---------|--------|
| `youtube_explode_dart` | Extracts YouTube stream URLs — may violate ToS, brittle to YouTube changes |
| `get` (GetX) | Anti-pattern, poor separation of concerns |
| `provider` | Outdated, Riverpod is the successor |
| `sqflite` | Overkill for this use case; Hive is faster and simpler |
| `sembast` | Less ecosystem support vs Hive |
| `firebase_*` | Explicitly out of scope for V1 |

---

## pubspec.yaml (V1)

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  
  # Audio
  just_audio: ^0.9.36
  audio_service: ^0.18.13
  
  # Network
  dio: ^5.4.0
  
  # Local DB
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  
  # Files
  path_provider: ^2.1.2
  permission_handler: ^11.3.0
  
  # UI
  cached_network_image: ^3.3.1
  flutter_screenutil: ^5.9.0
  
  # Utils
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1
  logger: ^2.0.2
  connectivity_plus: ^5.0.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.8
  riverpod_generator: ^2.4.0
  freezed: ^2.4.7
  json_serializable: ^6.7.1
```
