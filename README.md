# fukatSongs 🎵

A modern, plugin-first, cross-platform music streaming app built with Flutter &amp; Rust. Seamlessly integrates with YouTube Music, JioSaavn, and more through its secure WebAssembly (WASM) plugin system.

**Core Value:** Unmatched stability, infinite plugin extensibility, and zero cloud lock-in for your music experience.

---

## 🚀 Features

### 🎧 Core Playback &amp; Audio Engine
*   **Cross-Platform Support:** Native Android, Windows, and Linux builds powered by [Media Kit](https://pub.dev/packages/media_kit).
*   **Rust-Backed Plugin System:** Secure, sandboxed WebAssembly (WASM) plugins for music sources, lyrics providers, and more. The plugin lifecycle is managed by Rust for memory safety and performance.
*   **Dual Player Crossfade:** Smooth gapless transitions between tracks using a dual `Player` instance architecture with configurable crossfade duration.
*   **Built-in Equalizer:** 10-band equalizer with presets, loudness enhancer, and device EQ routing mode.
*   **Sleep Timer:** Customizable countdown with smooth fade-out.
*   **Global Event System:** Unified event bus for app-wide communication and state synchronization.
*   **System-Level Dynamic Island:** Persistent, interactive floating overlay that stays on screen even when app is minimized. Features real-time metadata, animated controls, and gesture support.

### 🔌 Plugin Ecosystem
*   **Content Resolvers:** YouTube Music, YouTube, and JioSaavn plugins for music streaming.
*   **Lyrics Providers:** LRCLIB support for synced lyrics.
*   **Chart Providers:** Billboard charts integration.
*   **Content Importers:** Import playlists from Spotify, YouTube Music, and more.
*   **Search Suggestions:** Smart search suggestions powered by iTunes, YTM, or MusicBrainz.
*   **Auto-Updating Plugins:** Background plugin repository sync with automatic version checking and safe updates.
*   **Plugin Repository Management:** Add/remove plugin repositories, browse available plugins, and manage installed plugins.

### 📚 Library &amp; Discovery
*   **Local Music Support:** Scan and play music files from your device with full library management.
*   **Smart Playlists:** Create and manage custom playlists with drag-and-drop ordering.
*   **History Tracking:** Detailed playback history with statistics.
*   **Last.fm Integration:** Scrobble tracks to your Last.fm profile.
*   **Artist &amp; Album Browsing:** Dedicated browse screens for complete artist discographies and albums.
*   **Shared URL Resolver:** Open YouTube/Spotify links directly in the app to play or import music.
*   **Import/Export:** Backup and restore your library, settings, and playlists via JSON or M3U files.

### 💾 Offline &amp; Utilities
*   **Offline Downloads:** Download any track for offline listening.
*   **Storage Management:** Built-in dashboard to monitor and manage disk usage.
*   **Country Aware Plugins:** Plugins respect regional restrictions via country code settings.
*   **Multi-Language Support:** Interface localized in English, Hindi, German, Spanish, Japanese, Korean, and more.
*   **Theme Customization:** Beautiful dark theme with modern UI and smooth animations.
*   **Discord Rich Presence:** Show what you're listening to on Discord.
*   **Desktop Keyboard Shortcuts:** Full keyboard control with shortcut indicator overlay (Windows/Linux).
*   **Smart Replace:** Automatic fallback to working sources if a track becomes unavailable.

---

## 🏗️ Architecture Overview

fukatSongs v3 uses a **modern, plugin-first architecture** that combines Flutter for the UI layer with Rust for performance-critical plugin management and execution.

### Key Architectural Principles
1.  **Separation of Concerns:** UI (Flutter) ↔ Business Logic (Dart) ↔ Plugin Runtime (Rust/WASM)
2.  **Event-Driven Communication:** All layers communicate via well-defined event systems
3.  **Dependency Injection via Service Locator:** Simple, static singleton pattern for core services
4.  **Local-First Data:** All data is stored locally with Isar Community database

---

## 📁 Project Structure

```text
freesongs/
├── android/                    # Android platform-specific code
├── ios/                        # iOS platform-specific code
├── lib/
│   ├── blocs/                  # BLoC state management
│   │   ├── add_to_playlist/    # Add to playlist state
│   │   ├── downloader/         # Download manager state
│   │   ├── explore/            # Explore/home screen state
│   │   ├── global_events/      # Global app event system
│   │   ├── history/            # Playback history
│   │   ├── internet_connectivity/ # Network status
│   │   ├── kill_switch/        # Emergency kill switch (Firebase)
│   │   ├── lastdotfm/          # Last.fm integration
│   │   ├── library/            # Library management
│   │   ├── local_music/        # Local music scanning
│   │   ├── lyrics/             # Lyrics display
│   │   ├── media_player/       # Main audio player
│   │   ├── mini_player/        # Mini player UI
│   │   ├── notification/       # App notifications
│   │   ├── player_overlay/     # Dynamic Island/overlay
│   │   ├── search_suggestions/ # Search suggestions
│   │   ├── settings_cubit/     # App settings
│   │   └── timer/              # Sleep timer
│   ├── core/                   # Core application utilities
│   │   ├── adapters/           # Data adapters
│   │   ├── constants/          # App constants, API keys, settings keys
│   │   ├── di/                 # Service locator (dependency injection)
│   │   ├── events/             # Global event bus
│   │   ├── models/             # Core data models
│   │   └── theme/              # App theming
│   ├── l10n/                   # Localization files (ARB)
│   ├── plugins/                # Plugin system UI &amp; logic
│   │   ├── blocs/              # Plugin management BLoCs
│   │   ├── errors/             # Plugin exception types
│   │   ├── models/             # Plugin data models
│   │   ├── services/           # Plugin repository service
│   │   ├── ui/                 # Plugin UI components
│   │   └── utils/              # Plugin utilities
│   ├── repository/             # Data repositories
│   │   └── bloomee/            # App-specific repositories
│   ├── routes/                 # GoRouter routing configuration
│   ├── screens/                # UI screens
│   │   ├── screen/             # Main app screens
│   │   └── widgets/            # Reusable UI widgets
│   ├── services/               # Business logic services
│   │   ├── audio_service_initializer.dart
│   │   ├── bootstrap.dart      # App startup bootstrap
│   │   ├── discord_service.dart
│   │   ├── dynamic_island_service.dart
│   │   ├── import_export_service.dart
│   │   ├── keyboard_shortcuts_service.dart
│   │   ├── onboarding_service.dart
│   │   ├── plugin_bootstrap_service.dart
│   │   ├── shared_url_resolver_service.dart
│   │   ├── bloomee_updater_tools.dart
│   │   ├── cache/              # Plugin cache system
│   │   ├── db/                 # Database DAOs
│   │   │   ├── dao/            # Data access objects
│   │   │   ├── legacy/         # Legacy migration code
│   │   │   └── mappers/        # Data mappers
│   │   ├── player/             # Audio player &amp; engine
│   │   └── plugin/             # Plugin runtime services
│   ├── src/                    # Rust FFI bridge
│   │   └── rust/               # Generated Dart bindings
│   ├── utils/                  # Utility functions
│   └── main.dart               # App entry point
├── rust/                       # Rust plugin runtime source
├── api/                        # Node.js helper API (if used)
└── assets/                     # Images, fonts, icons
```

---

## 🛠️ Technology Stack

### Frontend &amp; UI
*   **Framework:** Flutter 3.x
*   **State Management:** `flutter_bloc` &amp; BLoC pattern
*   **Routing:** `go_router` for declarative routing
*   **UI Components:** `sliding_up_panel`, `carousel_slider`, `google_nav_bar`
*   **Responsiveness:** `responsive_framework` &amp; `flutter_screenutil`
*   **Localization:** `flutter_localizations` &amp; `intl`

### Audio &amp; Multimedia
*   **Audio Engine:** `media_kit` (cross-platform audio playback)
*   **Background Playback:** `audio_service` (Android/iOS/Windows/Linux)
*   **Audio Session:** `audio_session` for focus management

### Data &amp; Storage
*   **Database:** `isar_community` (fast NoSQL local database)
*   **File System:** `path_provider`, `permission_handler`
*   **Caching:** Custom L1/L2 plugin cache system (LRU cache + Isar persistence)

### Plugin System
*   **Runtime:** Rust with Wasmtime/WASMT for secure plugin execution
*   **Communication:** `flutter_rust_bridge` (FFI bridge)
*   **Plugin Format:** `.bex` (Bloomee Extension) - compressed ZIP with manifest + WASM module

### Backend &amp; Services
*   **Firebase:** Used for kill switch functionality (emergency app disabling if needed)
*   **Last.fm:** Scrobbling integration
*   **GitHub Releases:** App and plugin auto-update system

### Networking
*   **HTTP Client:** `http` &amp; `dio`
*   **HTML Parsing:** `html` library
*   **Network Status:** `connectivity_plus`

### Build &amp; Code Gen
*   **Code Generation:** `build_runner`, `freezed`, `freezed_annotation`
*   **Launcher Icons:** `flutter_launcher_icons`

---

## 🚀 Getting Started

### Prerequisites
*   **Flutter SDK:** 3.3.0 or higher (check with `flutter --version`)
*   **Rust Toolchain:** For building the Rust plugin runtime (install via [rustup](https://rustup.rs/))
*   **Android Studio / Android SDK:** (API level 21+) for Android development
*   **Visual Studio 2022:** (with "Desktop development with C++" workload) for Windows builds
*   **Git:** For version control

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/suraxcodes/fukatsongs.git
    cd freesongs
    ```

2.  **Install Flutter dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run Code Generation:**
    Generate Freezed models and other generated files:
    ```bash
    dart run build_runner build --delete-conflicting-outputs
    ```

4.  **Setup Rust (if modifying plugins):**
    ```bash
    # Initialize Rust build
    # (See the `rust/` directory for specific instructions)
    ```

5.  **Run the App:**

    **Android:**
    ```bash
    flutter run
    ```

    **Windows:**
    ```bash
    flutter run -d windows
    ```

    **Linux:**
    ```bash
    flutter run -d linux
    ```

---

## 🔌 Plugin System Deep Dive

The plugin system is the heart of fukatSongs. Here's how it works:

### Plugin Lifecycle
1.  **Repository Sync:** `PluginBootstrapService` fetches `repositories.json` and plugin catalogs
2.  **Plugin Discovery:** `PluginService` scans the plugins directory for available `.bex` packages
3.  **Plugin Loading:** `PluginService` loads plugins via Rust `PluginManager`
4.  **Command Execution:** Plugins respond to typed commands (search, get_streams, etc.)
5.  **Storage:** Plugins can persist data via `PluginStorageService` (Isar-backed)
6.  **Events:** Plugins emit events that are captured by `PluginEventBus`

### Plugin Types
*   **ContentResolver:** Search, browse, and stream music
*   **ChartProvider:** Provide chart data
*   **LyricsProvider:** Fetch synced/unsynced lyrics
*   **SearchSuggestionProvider:** Search autocomplete suggestions
*   **ContentImporter:** Import from external services
*   **MetadataProvider:** Enhanced track/album metadata

### Plugin Storage
Plugins get their own isolated storage bucket via:
```dart
// From a plugin:
storage_put("my_key", "my_value");
final value = storage_get("my_key");
```
All plugin data is persisted locally in Isar database.

---

## 💾 Database Schema

fukatSongs uses **Isar Community** for local storage with the following collections:

| Collection | Purpose |
|------------|---------|
| `SettingDB` | App settings, preferences |
| `TrackDB` | Music track metadata |
| `PlaylistDB` | User playlists |
| `PlaylistItemDB` | Playlist entries |
| `DownloadDB` | Downloaded track records |
| `HistoryDB` | Playback history entries |
| `LyricsDB` | Cached lyrics |
| `SearchHistoryDB` | Search query history |
| `CacheDB` | Plugin API response cache |
| `PluginStorageDB` | Isolated plugin storage |
| `NotificationDB` | App notifications |

---

## 🎨 Theming &amp; UI

fukatSongs features a beautiful, modern dark theme using the `Unageo` and `Gilroy` font families. Key UI elements include:
- Immersive player screen with synced lyrics
- Dynamic Island floating overlay (global)
- Smooth slide transitions and animations
- Responsive design that adapts to all screen sizes
- Material You-inspired color scheme

---

## 🔧 Configuration &amp; Secrets

Most configuration is stored locally in Isar. However, there are some secrets:

### `app_secrets.dart`
This file contains:
- Firebase configuration (for kill switch)
- (Optional) API keys for external services

**Note:** This file is gitignored by default. For your own builds, create this file with your credentials.

---

## 🚢 Building for Release

### Android APK/AAB
```bash
# Build APK (split by ABI for smaller size)
flutter build apk --split-per-abi

# Or build App Bundle for Google Play
flutter build appbundle
```

### Windows
```bash
flutter build windows --release
```

### Linux
```bash
flutter build linux --release
```

---

## 📦 Plugin Repository Setup

fukatSongs comes pre-configured to use the **Bloom Factory** plugin repository. To set up your own:

1.  Host your `repositories.json` file somewhere accessible (GitHub Pages, etc.)
2.  Update `PluginBootstrapService.hostedRepositoriesUrl` in `lib/services/plugin_bootstrap_service.dart`
3.  Publish your plugins to a repository that follows the Bloom Factory manifest format

---

## ⚠️ Important Notes

### Security &amp; Privacy
- Plugins are sandboxed and cannot access arbitrary system resources
- All data is stored locally on your device
- No personal data is sent to any servers without explicit consent

### API Stability
- The plugin API is versioned using semantic versioning
- Plugins declare their manifest compatibility version
- Breaking changes will increment the major version

### License Considerations
- This project is licensed under GPL-3.0 (check LICENSE file)
- Plugins may have their own licenses
- Third-party dependencies have their own licenses (check `pubspec.yaml`)

---

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1.  Fork the repository
2.  Create a feature branch (`git checkout -b feature/amazing-feature`)
3.  Make your changes
4.  Run tests if available
5.  Commit your changes (`git commit -m 'feat: add some amazing feature'`)
6.  Push to the branch (`git push origin feature/amazing-feature`)
7.  Open a Pull Request

### Development Guidelines
- Follow the existing code style and architecture
- Write clear, concise commit messages
- Test your changes thoroughly on target platforms
- Update documentation if needed

---

## 📜 Changelog

See [CHANGELOG.md](CHANGELOG.md) or the app's built-in changelog viewer for a detailed history of changes.

---

## 🆘 Support &amp; Community

If you encounter issues or have questions:
- Check the [Issues](https://github.com/suraxcodes/fukatsongs/issues) page
- Look for existing solutions in closed issues
- Open a new issue if you can't find an answer

---

## 📄 License

This project is licensed under the **GNU General Public License v3.0** - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

*   **BloomeeTunes:** Original project that this fork is based on
*   **Hemant Arya:** Creator of BloomeeTunes
*   **Media Kit:** For excellent cross-platform audio support
*   **Isar Community:** For the fast local database
*   **All Contributors:** To everyone who has contributed code, translations, or bug reports

---

**Made with ❤️ for music lovers everywhere**
