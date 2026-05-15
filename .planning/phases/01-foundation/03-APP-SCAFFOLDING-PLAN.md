# Plan: App Scaffolding

**ID:** 03-APP-SCAFFOLDING
**Wave:** 3
**Depends on:** 01-PROJECT-SETUP, 02-CORE-MODELS
**Requirements addressed:** SETUP-05, SETUP-06
**Files modified:** lib/main.dart, lib/core/theme/app_theme.dart, lib/database/hive_init.dart
**Autonomous:** true

<objective>
Initialize Hive boxes, wire up Riverpod, establish folder structure, and apply the Deep Midnight theme.
</objective>

<tasks>
<task>
<read_first>lib/database/hive_init.dart</read_first>
<action>
Create `lib/database/hive_init.dart`:
- Initialize `Hive` with `Hive.initFlutter()`.
- Register `SongAdapter`.
- Open 8 boxes: `songs`, `playlists`, `liked_songs`, `recent_songs`, `queue_state`, `downloads`, `settings`, `search_cache`.
</action>
<acceptance_criteria>
- `hive_init.dart` contains code to open all 8 boxes.
- `SongAdapter` is registered.
</acceptance_criteria>
</task>

<task>
<read_first>lib/core/theme/app_theme.dart</read_first>
<action>
Create `lib/core/theme/app_theme.dart`:
- Implement `AppTheme` with `ThemeData.dark()`.
- Primary/Accent: Electric Indigo (`#6200EE`).
- High-contrast text, sleek typography (Google Fonts).
</action>
<acceptance_criteria>
- `app_theme.dart` defines a dark theme with Indigo accents.
</acceptance_criteria>
</task>

<task>
<read_first>lib/main.dart</read_first>
<action>
Update `lib/main.dart`:
- Call `HiveInit.initialize()` in `main()`.
- Wrap `MyApp` with `ProviderScope`.
- Use `AppTheme` in `MaterialApp`.
- Create a basic Home Screen scaffold.
- Create directories: `lib/features/home/presentation`, `lib/features/home/domain`, `lib/features/home/data`, `lib/core/utils`, `lib/core/constants`.
</action>
<acceptance_criteria>
- `main.dart` is wrapped in `ProviderScope`.
- Directories are created.
- App boots to a dark/indigo themed home screen.
</acceptance_criteria>
</task>
</tasks>

<verification>
Run `flutter run` and verify the app opens with the Deep Midnight theme.
</verification>

<must_haves>
- [ ] Hive initialized with 8 boxes
- [ ] ProviderScope wrapping the app
- [ ] Deep Midnight theme applied
- [ ] Folder structure established
</must_haves>
