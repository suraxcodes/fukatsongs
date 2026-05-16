---
wave: 3
depends_on: ["02-PLAN.md"]
files_modified:
  - lib/features/library/presentation/library_screen.dart
  - lib/features/player/presentation/player_screen.dart
  - lib/features/shared/widgets/song_list_tile.dart
autonomous: false
---

# Plan: UI Integration

<objective>
Expose download functionality to the user through the Immersive Player and song menus, and create a Library section for viewing downloaded music.
</objective>

<tasks>
1. <task>
   <read_first>
   - lib/features/shared/widgets/song_list_tile.dart
   - lib/providers/download_provider.dart
   </read_first>
   <action>
   In `lib/features/shared/widgets/song_list_tile.dart` (or wherever the three-dot menu is defined for a song), add a "Download" option to the `PopupMenuButton` or modal bottom sheet.
   When tapped, call `ref.read(downloadNotifierProvider(song.id).notifier).downloadSong(song)`.
   </action>
   <acceptance_criteria>
   - The three-dot menu contains a "Download" action.
   - Tapping it triggers the download provider for that specific song.
   </acceptance_criteria>
   </task>

2. <task>
   <read_first>
   - lib/features/player/presentation/player_screen.dart
   - lib/providers/download_provider.dart
   </read_first>
   <action>
   In `lib/features/player/presentation/player_screen.dart`, add a download icon button near the playback controls or favorite button.
   Use `ref.watch(downloadNotifierProvider(currentSong.id))` to listen to the state.
   - If `initial` or `error`, show a download icon (e.g., `Icons.download`).
   - If `downloading(progress)`, show a `CircularProgressIndicator(value: progress)` sized to fit the icon area.
   - If `completed`, show a checkmark icon (e.g., `Icons.download_done`).
   </action>
   <acceptance_criteria>
   - Player screen contains a dynamic download button.
   - Button renders `CircularProgressIndicator` with real-time progress while downloading.
   - Button renders `Icons.download_done` when completed.
   </acceptance_criteria>
   </task>

3. <task>
   <read_first>
   - lib/features/library/presentation/library_screen.dart
   - lib/core/constants/hive_boxes.dart
   </read_first>
   <action>
   In `lib/features/library/presentation/library_screen.dart`, add a "Downloaded Music" section or tab.
   Read the `downloadsBox` from Hive to get a list of all downloaded `Song` objects.
   Display them using a standard `ListView.builder` with `SongListTile` widgets.
   </action>
   <acceptance_criteria>
   - Library screen contains a "Downloaded Music" access point or section.
   - The list correctly reads from `Hive.box(downloadsBox)` and displays the items.
   </acceptance_criteria>
   </task>
</tasks>

<verification>
- Verify that a user can tap "Download", observe the progress indicator, and subsequently find the song in the "Downloaded Music" section of their library.
</verification>
