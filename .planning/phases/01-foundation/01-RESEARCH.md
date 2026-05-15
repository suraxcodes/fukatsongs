# Phase 1: Foundation - Research

**Date:** 2026-05-15
**Goal:** Establish technical patterns for FukatSongs foundation.

## 1. Dependencies & Versions (Standard 2025)

The project will use the following locked versions for stability:

| Package | Version | Role |
|---------|---------|------|
| `flutter_riverpod` | `^2.5.1` | State Management |
| `just_audio` | `^0.9.36` | Playback Engine |
| `audio_service` | `^0.18.13` | Background Audio |
| `hive_flutter` | `^1.1.0` | Local Storage |
| `dio` | `^5.4.0` | Networking |
| `freezed_annotation` | `^2.4.1` | Immutable Models |
| `path_provider` | `^2.1.2` | File Paths |

**Dev Dependencies:**
- `build_runner`: `^2.4.8`
- `freezed`: `^2.4.7`
- `riverpod_generator`: `^2.4.0`
- `hive_generator`: `^2.0.1`

## 2. Song Model Pattern (Freezed + Hive)

To ensure the `Song` model is both immutable and persistent:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'song.freezed.dart';
part 'song.g.dart';

@freezed
class Song with _$Song {
  @HiveType(typeId: 0)
  const factory Song({
    @HiveField(0) required String id,
    @HiveField(1) required String title,
    @HiveField(2) required String artist,
    @HiveField(3) required String albumName,
    @HiveField(4) required String year,
    @HiveField(5) required String imageUrl,
    @HiveField(6) required int duration, // in seconds
    @HiveField(7) required String source, // 'saavn' | 'youtube'
    @HiveField(8) required Map<String, String> providers, // provider_id -> song_id
    @HiveField(9) String? localPath,
  }) = _Song;
}
```

## 3. Audio Service Integration

**Prerequisites for Android:**
1. `AndroidManifest.xml`:
   - Add `FOREGROUND_SERVICE` and `FOREGROUND_SERVICE_MEDIA_PLAYBACK` permissions.
   - Declare `com.ryanheise.audioservice.AudioService` in the `<application>` tag.
2. `MainActivity.kt`: Ensure it extends `FlutterActivity` (default).

## 4. Folder Structure (Feature-First)

```text
lib/
├── core/
│   ├── theme/          # Deep Midnight theme definitions
│   ├── constants/      # App-wide constants
│   └── utils/          # Formatting, logging
├── models/             # Shared data models (Song, etc.)
├── providers/          # Global providers (AudioHandler)
└── features/
    └── home/           # Scaffolding for Phase 1
        ├── presentation/
        ├── domain/
        └── data/
```

## ## Validation Architecture

1. **Model Integrity**: Run `flutter pub run build_runner build` — verify `.freezed.dart` and `.g.dart` files exist.
2. **Hive Setup**: Initial test script to open and close all 8 boxes.
3. **Audio Permissions**: Grep `AndroidManifest.xml` for `FOREGROUND_SERVICE_MEDIA_PLAYBACK`.
4. **App Boot**: `flutter run` check for no exceptions during `main()` initialization.
