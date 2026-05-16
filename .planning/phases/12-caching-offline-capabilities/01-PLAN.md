---
wave: 1
depends_on: []
files_modified:
  - lib/providers/download_provider.dart
  - lib/core/constants/hive_boxes.dart
  - lib/main.dart
autonomous: false
---

# Plan: Download Provider & Storage Setup

<objective>
Implement the core logic for managing permanent song downloads to local storage, and establish the Hive box for downloaded metadata.
</objective>

<tasks>
1. <task>
   <read_first>
   - lib/main.dart
   - lib/core/constants/hive_boxes.dart
   - lib/models/song.dart
   </read_first>
   <action>
   Update `lib/core/constants/hive_boxes.dart` to add a new constant `const String downloadsBox = 'downloads';`. 
   Update `lib/main.dart` to open this box `await Hive.openBox(downloadsBox);` during initialization alongside existing boxes.
   </action>
   <acceptance_criteria>
   - `lib/core/constants/hive_boxes.dart` contains `downloadsBox` string.
   - `lib/main.dart` contains `await Hive.openBox(downloadsBox);` in `main()`.
   </acceptance_criteria>
   </task>

2. <task>
   <read_first>
   - lib/models/song.dart
   </read_first>
   <action>
   Create `lib/providers/download_provider.dart`. Define a `DownloadState` Freezed class with states: `initial`, `downloading(double progress)`, `completed(String filePath)`, `error(String message)`. 
   Create a Riverpod `Notifier` or `StateNotifier` named `DownloadNotifier` (using `@riverpod` if code-gen is used) that takes a `songId` as family parameter to track individual download states.
   </action>
   <acceptance_criteria>
   - `lib/providers/download_provider.dart` exists.
   - `DownloadState` class exists with `downloading` and `completed` states.
   - The provider manages state by song ID.
   </acceptance_criteria>
   </task>

3. <task>
   <read_first>
   - lib/providers/download_provider.dart
   </read_first>
   <action>
   In `DownloadNotifier`, implement the `downloadSong(Song song)` method:
   1. Get the app's document directory via `getApplicationDocumentsDirectory()`.
   2. Ensure a `downloads` subdirectory exists.
   3. Fetch the stream URL using `ref.read(youtubeProvider).getStreamUrl(...)` (or the appropriate fallback logic).
   4. Use `Dio().download()` to stream the file to `${app_dir}/downloads/${song.id}.m4a`, updating state with `onReceiveProgress`.
   5. On success, save the `Song` to `Hive.box(downloadsBox)` using `song.id` as the key.
   </action>
   <acceptance_criteria>
   - `downloadSong` uses `getApplicationDocumentsDirectory()`.
   - `Dio().download` is called with `onReceiveProgress`.
   - `Hive.box(downloadsBox).put(song.id, song.toJson())` is called on completion.
   </acceptance_criteria>
   </task>
</tasks>

<verification>
- Verify that calling `downloadSong` creates a file in the app documents directory and saves the song data to the `downloadsBox` Hive box.
</verification>
