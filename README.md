# fukatSongs 🎵

fukatSongs is a feature-rich, entirely local, ad-free personal Android music streaming app built with Flutter. It seamlessly integrates searches across YouTube Music and JioSaavn, providing high-fidelity streaming, offline downloads, and stable queue management without the need for a backend server.

**Core Value:** Stable, uninterrupted music playback with a reliable queue system, local offline storage, and zero cloud dependency.

---

## 🚀 Features

### 🎧 Core Playback & Audio Engine
*   **Dual-Source Streaming Architecture:** Parallel querying and streaming from JioSaavn and YouTube Music APIs, maximizing song availability.
*   **Multi-Tunnel Fallback System:** A resilient proxy rotation and fallback mechanism designed to seamlessly bypass aggressive rate-limiting or geographic blocks from YouTube.
*   **"Infinite Music" (Smart Autoplay):** Radio-like infinite playback. When the queue ends, the application intelligently searches for and appends top tracks from the most recently played artist.
*   **Reorderable Queue Management:** Full drag-and-drop support within the immersive player's "Up Next" section, allowing users to effortlessly curate their active listening session.
*   **High-Fidelity Audio:** Configurable streaming and download quality modes, intelligently adapting to network conditions (e.g., automatically starting at 160kbps on mobile data to prevent stuttering).
*   **Built-in Equalizer & Loudness Enhancer:** Native Android audio effects pipeline (`AndroidLoudnessEnhancer`, `AndroidEqualizer`) for deep bass and up to +4dB volume boosting.
*   **Gapless Playback:** Custom audio buffering logic to eliminate "pops" and reduce buffering delays during track transitions.

### 📚 Library & Discovery
*   **Smart Library Organization:** Advanced dynamic sorting engine across Downloads, Playlists, and Liked Songs tabs. Users can sort by Title, Artist, Album, Recently Added, Duration, and Custom Order.
*   **Customizable UI Views:** Toggleable View Modes (List vs. Compact Grid), empowering users to prioritize high-resolution artwork or dense text lists for larger music collections.
*   **Background Playlist Importer:** A robust, asynchronous importer that seamlessly migrates massive playlists from Spotify and YouTube directly into the app. Features include real-time progress indicators, background execution, and the ability to cancel or hide the import dialog without interrupting the process.
*   **Intelligent Search History:** The search home interface displays a curated horizontal list of actual recently played songs alongside a persistent query history, mimicking the fluidity of premium streaming services.
*   **Personalized Listening Stats:** A dynamic "Your Top Songs" section that tracks local playback counts, automatically elevating your most listened-to tracks to the top of the search dashboard.
*   **Artist & Album Browsing:** Dedicated, immersive browse screens dynamically generated for exploring complete artist discographies and album tracklists.
*   **Synced Lyrics Engine:** High-precision, real-time synchronized lyrics integration powered by the LRCLIB API.

### 💾 Offline & Utilities
*   **Zero-Cloud Local Storage:** Instantaneous loading of metadata, playlists, liked songs, and application settings via a blazing-fast local NoSQL key-value store (`Hive`).
*   **Offline Downloads:** Download any track for offline listening. Audio files are saved directly to application-specific storage.
*   **Storage Management:** Built-in utility dashboard to monitor disk usage and manually clear specific caches or downloaded files.
*   **Sleep Timer:** Set a customized countdown timer to automatically fade out and stop playback when falling asleep.
*   **Intelligent Queue Shuffling:** Maintains absolute state synchronization between `originalQueue` and `shuffledQueue`, allowing users to toggle shuffle without destructively modifying their original playlist order.
*   **Background Playback & Integrations:** Full Android background execution support via `audio_service`, featuring lock-screen controls, media session management, and responsive push notifications.

---

## 🛠 Technology Stack

### Architecture & State Management
*   **Framework:** Flutter (Android only for V1)
*   **State Management:** `flutter_riverpod` (v2.5.1) with code-generation (`riverpod_annotation`).

### Audio & Networking
*   **Audio Engine:** `just_audio` (v0.9.36) and `audio_service` (v0.18.13). Handles HLS, MP3, M4A, and OPUS formats.
*   **Network Client:** `dio` (v5.4.0) with custom interceptors for retries, auth, and download streaming.
*   **API Interactions:** `youtube_explode_dart` (for YT metadata) and direct JioSaavn API interactions.

### Local Storage & Data
*   **Database:** `hive` (v2.2.3) & `hive_flutter`.
*   **File System:** `path_provider` and `permission_handler` for Android 13+ storage & audio permissions.
*   **Models:** `freezed` and `json_serializable` for immutable, boilerplate-free data classes.

### UI & UX
*   **Image Caching:** `cached_network_image`.
*   **Responsiveness:** `flutter_screenutil` for perfect scaling across all Android device sizes.

---

## 🏗 Development Setup

### Prerequisites
*   Flutter SDK (3.19.0 or higher recommended)
*   Android Studio / Android SDK (API level 34+)

### Installation
1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/fukat_songs.git
   cd freesongs
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run Code Generation:**
   Since the app relies heavily on Freezed and Riverpod annotations, you must run the build runner to generate the `.g.dart` and `.freezed.dart` files.
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Run the App:**
   Connect an Android emulator or physical device.
   ```bash
   flutter run
   ```

### Building the APK
To build a production-ready APK split by architecture (reduces app size):
```bash
flutter build apk --split-per-abi
```
The output APKs will be located in `build/app/outputs/flutter-apk/`.

---

## 🧩 Project Structure

```text
lib/
├── core/
│   ├── audio/         # AudioHandler, Audio sources, Equalizer config
│   ├── constants/     # API keys, Hive box names, UI constants
│   └── repositories/  # Abstracted data fetching (History, Music, etc.)
├── features/
│   ├── home/          # Feed, recently played, top charts
│   ├── library/       # Offline downloads, playlists, liked songs
│   ├── player/        # Immersive player, queue management, lyrics, sleep timer
│   ├── search/        # Multi-source search, Browse pages
│   └── settings/      # Audio quality, theme, gapless playback toggles
└── models/            # Freezed data models (Song, AppSettings, etc.)
```

---

## ⚠️ Constraints & Disclaimers
*   **Android Exclusive:** Version 1 is strictly optimized for Android. iOS support is not currently planned due to background audio limitations and file system constraints.
*   **API Volatility:** This application relies on unofficial APIs (YouTube Music, JioSaavn). Stream URLs are intentionally never persisted in the database; they are dynamically resolved at playback time to prevent broken streams.
*   **Single Instance Player:** The app strictly enforces a single global `AudioPlayer` instance to prevent memory leaks and overlapping audio states.

---

## 🤝 Contributing
As this is a personal learning project, contributions, forks, and pull requests are welcome but not actively managed. If you find a bug regarding API resolution, feel free to submit a patch!
