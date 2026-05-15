# Research Summary — fukatSongs

## TL;DR

Build a Flutter Android music app with Riverpod + just_audio + audio_service + Hive. Prioritize playback stability and provider abstraction over features. The #1 risk is unofficial API fragility — design the provider abstraction layer from day one.

---

## Stack

| Area | Choice | Version |
|------|--------|---------|
| Framework | Flutter | latest stable |
| Language | Dart | latest stable |
| State | flutter_riverpod + riverpod_annotation | ^2.5.1 |
| Audio | just_audio + audio_service | ^0.9.36 / ^0.18.13 |
| Network | dio | ^5.4.0 |
| Local DB | hive + hive_flutter | ^2.2.3 / ^1.1.0 |
| Files | path_provider + permission_handler | ^2.1.2 / ^11.3.0 |
| Images | cached_network_image | ^3.3.1 |
| Models | freezed + json_serializable | ^2.4.7 / ^6.7.1 |
| Logging | logger | ^2.0.2 |

**Key decision:** Use manual `AudioHandler` (not `just_audio_background`) — fukatSongs needs custom stream URL refresh + provider fallback inside the playback loop.

---

## Table Stakes Features (Must Ship)

1. Search via JioSaavn API with debouncing
2. Play / pause / seek / skip with background audio
3. Queue with shuffle + repeat
4. Playlists + liked songs (Hive)
5. Song download + offline playback
6. YouTube Music as fallback provider
7. Parallel search + result ranking + deduplication

---

## Watch Out For

| Risk | Prevention |
|------|-----------|
| Stream URLs expire | Never store URLs — store IDs, fetch fresh on playback |
| Multiple AudioPlayer instances | Singleton in AudioHandler — never instantiate elsewhere |
| Missing AndroidManifest entries for audio_service | Add service/receiver/permissions in Phase 3 |
| Android 13+ storage permissions | Use `permission_handler` ^11.x, prefer app-specific storage |
| Destructive shuffle | Maintain `_originalQueue` + `_shuffledQueue` separately |
| Riverpod ref unavailable in AudioHandler | Pass Repository directly, not a Riverpod ref |
| API downtime crashes app | Wrap all API calls in try/catch, fallback to second provider |
| Memory leaks from stream subscriptions | Cancel in `ref.onDispose()` |

---

## Recommended Build Order

| Phase | Goal | Key Risk |
|-------|------|----------|
| 1 | Project setup, Song model, folder structure | Lock Song model early — changes break everything |
| 2 | Saavn integration + search screen | API fragility, result normalization |
| 3 | Audio playback + background audio + queue | AudioHandler complexity, AndroidManifest setup |
| 4 | Playlists + likes + Hive persistence | Hive box design, don't block main thread |
| 5 | Downloads + offline playback | Android storage permissions, file validation |
| 6 | YouTube provider + parallel search + ranking | Provider abstraction, deduplication algorithm |
| 7 | Caching + optimization + polish | Search cache TTL, image cache sizing |

---

## Architecture in One Paragraph

UI talks to Riverpod providers only. Riverpod providers talk to a Repository layer that orchestrates the `MusicProvider` abstraction (Saavn, YouTube). Audio playback runs through a single `AudioHandler` that wraps `just_audio`. The handler fetches fresh stream URLs at playback time, never from stored state. All persistent data (playlists, likes, queue state, download metadata) lives in Hive. Audio files live on device storage. No backend, no Firebase, no cloud.
