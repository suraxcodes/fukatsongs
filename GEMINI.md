<!-- GSD:project-start source:PROJECT.md -->
## Project

**fukatSongs**

fukatSongs is a personal Android music streaming app built in Flutter for learning and personal use. It searches songs from Saavn and YouTube Music in parallel, plays them with a stable queue system, and lets users download songs for offline listening — all stored locally with no backend or cloud dependency.

**Core Value:** Stable, uninterrupted music playback with a reliable queue system — everything else is secondary.

### Constraints

- **Platform**: Android only — no iOS for V1
- **Architecture**: No backend until multi-device sync is genuinely needed
- **APIs**: Unofficial APIs (Saavn, YouTube) may break — must build provider abstraction with fallback from day one
- **Stream URLs**: Must never be persisted — always fetch fresh at playback time
- **Audio**: Single global audio player instance — never create multiple `AudioPlayer()` instances
- **Shuffle**: Maintain both `originalQueue` and `shuffledQueue` — never destructively shuffle
<!-- GSD:project-end -->

<!-- GSD:stack-start source:research/STACK.md -->
## Technology Stack

## Domain: Flutter Android Music Streaming App (2025)
## Recommended Stack
### State Management
| Package | Version | Rationale | Confidence |
|---------|---------|-----------|------------|
| `flutter_riverpod` | ^2.5.1 | Industry-standard for Flutter in 2025. Code-gen with `@riverpod` annotation is cleanest pattern for async audio state. Better than Bloc for this use case — less boilerplate, native async support. | High |
| `riverpod_annotation` | ^2.3.5 | Required for code-gen approach | High |
| `riverpod_generator` | ^2.4.0 | Build runner for @riverpod annotations | High |
### Audio Playback
| Package | Version | Rationale | Confidence |
|---------|---------|-----------|------------|
| `just_audio` | ^0.9.36 | De-facto standard. Handles HLS, MP3, M4A, OPUS. Cross-platform. Well maintained by Ryan Heise. | High |
| `audio_service` | ^0.18.13 | Required for Android background playback, media notifications, lock screen controls. Works with just_audio via AudioHandler. | High |
| `just_audio_background` | ^0.0.1-beta.12 | Thin wrapper that integrates just_audio + audio_service with less boilerplate than manual AudioHandler. **Use this ONLY for simple apps.** For fukatSongs, prefer manual AudioHandler — more control over queue, metadata. | Medium |
### Networking
| Package | Version | Rationale | Confidence |
|---------|---------|-----------|------------|
| `dio` | ^5.4.0 | Best HTTP client for Flutter. Interceptors for retry/auth, cancel tokens, download progress streams. Vastly superior to `http` package for this use case. | High |
### Local Database
| Package | Version | Rationale | Confidence |
|---------|---------|-----------|------------|
| `hive` | ^2.2.3 | Fast key-value store. Good for playlists, liked songs, settings, cached metadata. Zero native dependencies. | High |
| `hive_flutter` | ^1.1.0 | Flutter integration for Hive | High |
### File & Downloads
| Package | Version | Rationale | Confidence |
|---------|---------|-----------|------------|
| `path_provider` | ^2.1.2 | Get app-specific storage directories. Required for download file paths. | High |
| `permission_handler` | ^11.3.0 | Runtime permission requests (storage on Android < 13, audio on Android 13+). | High |
### UI & Images
| Package | Version | Rationale | Confidence |
|---------|---------|-----------|------------|
| `cached_network_image` | ^3.3.1 | Album art caching. Disk + memory cache. Placeholder + error widget support. | High |
| `flutter_screenutil` | ^5.9.0 | Responsive sizing for different Android screen sizes. | Medium |
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
## What NOT to Use
| Package | Reason |
|---------|--------|
| `youtube_explode_dart` | Extracts YouTube stream URLs — may violate ToS, brittle to YouTube changes |
| `get` (GetX) | Anti-pattern, poor separation of concerns |
| `provider` | Outdated, Riverpod is the successor |
| `sqflite` | Overkill for this use case; Hive is faster and simpler |
| `sembast` | Less ecosystem support vs Hive |
| `firebase_*` | Explicitly out of scope for V1 |
## pubspec.yaml (V1)
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->



<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
