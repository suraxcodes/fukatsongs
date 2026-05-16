# 🎵 fukatSongs

> **A personal Android music streaming app built in Flutter** — for learning and personal use.  
> Search, stream, and download songs from JioSaavn and YouTube Music. No backend. No cloud. Just music.

---

## 📱 What It Does

fukatSongs lets you:
- 🔍 **Search** songs from **JioSaavn** and **YouTube Music** simultaneously
- ▶️ **Stream** music with a stable background playback engine
- ⬇️ **Download** songs for offline listening
- 📋 **Create and manage playlists** locally on your device
- 📥 **Import playlists** from other apps (YouTube, Spotify links)
- ❤️ **Like songs** and see recent history
- 🔒 **Protected by a one-time install password** — personal use only

---

## 🛡️ Security (Gatekeeper)

This app is password-protected. On fresh install, the user must enter the password once.  
After that, the app opens directly without asking again.  
If the app is deleted and reinstalled, the password is required again.

**To change the password:**  
Open `lib/core/constants/app_secrets.dart` and change the value:
```dart
static const String appPassword = "your_password_here";
```

---

## 🏗️ Architecture

```
lib/
├── main.dart                   # App entry point, Hive + AudioService init
├── core/
│   ├── audio/
│   │   ├── audio_handler.dart  # Global AudioPlayer + effects engine
│   │   └── youtube_audio_source.dart
│   ├── constants/
│   │   ├── hive_boxes.dart     # All Hive box name constants
│   │   └── app_secrets.dart    # Password config (change here)
│   └── widgets/
│       └── song_skeleton.dart  # Loading shimmer UI
├── features/
│   ├── auth/
│   │   └── gatekeeper_screen.dart   # Password lock screen (first-run only)
│   ├── home/                        # Home tab — trending + recent
│   ├── search/                      # Search tab — Saavn + YouTube
│   ├── player/                      # Mini + Immersive player, queue
│   ├── library/                     # Playlists, liked songs, downloads
│   ├── settings/                    # Audio quality, theme, EQ
│   └── main/
│       ├── main_screen.dart         # Bottom nav shell
│       └── splash_screen.dart       # Animated splash + auth routing
├── models/
│   └── song.dart                    # Song data model (Freezed + Hive)
└── providers/
    ├── music_repository.dart        # Central stream URL gateway
    ├── saavn_provider.dart          # JioSaavn API handler
    └── youtube_provider.dart        # YouTube + Piped proxy handler
```

---

## 🎯 Design Principles

| Principle | Implementation |
|---|---|
| **Single Audio Player** | One global `AudioPlayer` instance — never duplicated |
| **Stream URLs are never persisted** | Always fetched fresh at playback time |
| **Provider Abstraction** | Saavn and YouTube behind a unified `MusicRepository` |
| **Offline First** | Downloads checked before any network request |
| **No Backend** | All data stored locally via Hive |

---

## 🔊 Audio Engine

The audio pipeline is powered by `just_audio` + `audio_service`:

- **Android Hardware EQ** (`AndroidEqualizer`) — frequency band control
- **Loudness Enhancer** (`AndroidLoudnessEnhancer`) — optional +4dB boost
- **Skip Silence** — auto-skips quiet gaps in tracks
- **Smart Pre-Buffer** — waits for 2 seconds of buffer before starting playback to prevent stuttering

### Audio Quality Levels
| Setting | Bitrate | Best For |
|---|---|---|
| Low | 96 kbps | Saving data |
| Medium | 160 kbps | Balanced |
| High | 320 kbps | Best quality |
| Hi-Fi Mode | 320 kbps (forced) | WiFi, premium listening |

---

## 🌐 Multi-Source Streaming Strategy

### YouTube
1. **Stage 1 — Stealth Tunnels**: Tries multiple Piped proxy mirrors (YouTube's rate limiting shield)
2. **Stage 2 — Direct Extraction**: Falls back to `youtube_explode_dart` for highest-bitrate Opus stream
3. **Stage 3 — Magic Switch**: If YouTube fails entirely, searches JioSaavn for the same song and plays its 320kbps stream

### JioSaavn
- Uses unofficial Saavn API with mirror rotation
- Always picks 320kbps stream if available
- Falls back to lower quality if not found

---

## 📦 Tech Stack

| Package | Purpose |
|---|---|
| `flutter_riverpod` | State management |
| `just_audio` | Audio playback engine |
| `audio_service` | Background playback + lock screen controls |
| `audio_session` | Interruption handling (calls, headphones) |
| `hive_flutter` | Local database (songs, playlists, settings) |
| `dio` | HTTP client with retry + interceptors |
| `freezed` | Immutable data models |
| `cached_network_image` | Album art with disk caching |
| `youtube_explode_dart` | YouTube stream extraction fallback |
| `connectivity_plus` | WiFi vs mobile data detection |
| `path_provider` | File system paths for downloads |
| `permission_handler` | Storage permissions |
| `flutter_launcher_icons` | Native app icons |

---

## 🚀 Getting Started (Development)

### Prerequisites
- Flutter SDK 3.x
- Android SDK / Emulator
- Java 17+

### Run in Debug Mode
```bash
flutter run
```

### Build Release APK
```bash
flutter build apk --split-per-abi
```

**Output files:**
| File | Size | Use For |
|---|---|---|
| `app-armeabi-v7a-release.apk` | ~19 MB | Old phones |
| `app-arm64-v8a-release.apk` | ~21 MB | ✅ Most modern phones |
| `app-x86_64-release.apk` | ~23 MB | Emulators |

### Regenerate Code (after model changes)
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 📂 Local Storage (Hive Boxes)

| Box | Type | Stores |
|---|---|---|
| `settings` | `dynamic` | Audio quality, theme, EQ prefs |
| `songs` | `Song` | Cached song metadata |
| `downloads` | `Song` | Offline downloaded songs |
| `liked_songs` | `dynamic` | Liked song IDs |
| `recent_songs` | `Song` | Recently played |
| `playlists` | `dynamic` | User-created playlists |
| `search_cache` | `String` | Search result cache |
| `search_history` | `String` | Recent search queries |
| `queue_state` | `dynamic` | Persisted playback queue |
| `auth` | `dynamic` | One-time unlock flag |

---

## ⚠️ Important Constraints

- **Android Only** — No iOS support in V1
- **Unofficial APIs** — Saavn and YouTube APIs may change; fallback logic is built-in
- **Personal Use** — This app is not intended for public distribution
- **No Login Required** — Anonymous streaming, no accounts

---

## 📁 APK Location After Build

```
build/app/outputs/flutter-apk/
```

---

*Built with ❤️ using Flutter — fukatSongs v1.0*
