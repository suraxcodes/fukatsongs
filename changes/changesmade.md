---

## Date
2026-07-07 23:46

## Task
Fix Playlist Playback, Duration Updates, and Notification Shuffle

## Reason
Users reported that imported songs were failing to play entirely. Additionally, playback notifications were displaying 0:00 for the duration, and there was no shuffle button available on the system notification panel.

## what problem/error we fixed 
- Removed the unreliable `youtube_explode_dart` fallback inside `media_resolver_service.dart` that was causing HTTP 403 Forbidden errors for imported tracks.
- Fixed `durationStream` integration in `BloomeeMusicPlayer` so that total duration properly pushes to the notification when audio engine resolves it.
- Added a Shuffle toggle directly to Android Media Session notifications.

## Files Changed
- lib/plugins/blocs/import/content_import_cubit.dart
- lib/services/player/media_resolver_service.dart
- lib/services/bloomee_player.dart
- android/app/src/main/res/drawable/ic_shuffle.xml
- android/app/src/main/res/drawable/ic_shuffle_on.xml

## Main Changes
- Switched YouTube imported tracks to correctly use `content-resolver.bloomfactory.ytmusic` instead of the non-existent `yt_search`.
- Removed dart fallback WASM bypass logic so all streams now route through the native rust WASM plugins.
- Implemented `engine.durationStream.listen()` in `bloomee_player.dart` to sync track duration dynamically.
- Created custom `MediaControl` instances in `bloomee_player.dart` mapped to newly created XML vector assets for shuffle state.

## Technical Notes
- Do not use `yt_search` as a plugin ID; the app strictly relies on `content-resolver.bloomfactory.ytmusic` for all YouTube track streaming via Rust plugins.
- Shuffle actions on the system notification panel fall back to custom action slots if the OS (Android 12-) doesn't natively parse it.

## Impact
- Users can seamlessly play imported YouTube playlists without tracks auto-skipping due to 403 errors.
- Notification panel duration accurately reflects actual track length.
- Users can toggle shuffle from the lock screen natively.

## Breaking Changes
None

## Status
Completed

---

## Date
2026-07-07 23:55

## Task
Notification UI & Sync Fixes

## Reason
Fixed notification timeline dropping to 000 and repositioned the shuffle button.

## what problem/error we fixed
- Notification timeline desyncs randomly because of missed playback state broadcasts from media_kit on audio_service.
- Shuffle button was missing on compact notifications because compact actions weren't defined in the PlaybackState.

## Files Changed
- lib/services/bloomee_player.dart

## Main Changes
- Added a throttled position stream listener in BloomeeMusicPlayer to periodically sync the engine position with audio_service.
- Updated _broadcastPlaybackState to render the shuffle control on the right side.
- Added androidCompactActionIndices in PlaybackState to correctly position the standard prev/play/next buttons on the unexpanded system notification.

## Technical Notes
- Throttled position broadcasts keep the OS notification slider in absolute sync without flooding the audio_service pipeline.

## Breaking Changes
None

## Status
Completed
---

## Date
2026-07-08 00:15

## Task
UI Consistency Update

## Reason
Player screen background did not match the home screen.

## what problem/error we fixed
- Replaced the hardcoded dark color on the player screen with the global theme color to match the home screen.

## Files Changed
- lib/screens/screen/player_screen.dart

## Main Changes
- Updated the Scaffold backgroundColor from a hardcoded Color.fromARGB(255, 12, 4, 9) to Default_Theme.themeColor in player_screen.dart.

## Technical Notes
- Ensures UI consistency when navigating between the explore screen and player screen.

## Breaking Changes
None

## Status
Completed
---

## Date
2026-07-08 00:20

## Task
Visually distinct Shuffle icons

## Reason
Users couldn't tell if shuffle was active because Android recolored the notification icons, and the PlayerScreen icon only changed colors without changing shape.

## what problem/error we fixed
- Android 13+ overrides vector drawable colors, making the ON and OFF shuffle icons look identical.
- The PlayerScreen shuffle button only changed color, making it hard to notice the toggle.

## Files Changed
- lib/screens/screen/player_screen.dart
- android/app/src/main/res/drawable/ic_shuffle_on.xml

## Main Changes
- Swapped PlayerScreen's shuffle icon to explicitly change between MingCute.shuffle_2_line and MingCute.shuffle_2_fill when toggled.
- Appended a center-dot path to ic_shuffle_on.xml so it is structurally different from the OFF state in Android notifications.

## Technical Notes
- Vector shapes must differ structurally when dealing with Android MediaStyle notifications since it forces monochromatic tinting.

## Breaking Changes
None

## Status
Completed
---

## Date
2026-07-08 00:25

## Task
Change Shuffle Icon Style

## Reason
The user preferred a more modern, crossed arrow icon for shuffle instead of the loopy one.

## what problem/error we fixed
- Replaced MingCute.shuffle_2_line/fill with MingCute.shuffle_line/fill for a cleaner aesthetic.

## Files Changed
- lib/screens/screen/player_screen.dart
- lib/screens/widgets/shortcut_indicator_overlay.dart

## Main Changes
- Updated the shuffle icon in the PlayerScreen to use the MingCute.shuffle_line and MingCute.shuffle_fill icons.
- Updated the shortcut overlay to match.

## Technical Notes
- None.

## Breaking Changes
None

## Status
Completed
---

## Date
2026-07-08 00:30

## Task
Add global shuffle toggle to playlists

## Reason
The user wanted the shuffle toggle button from the player screen to also be present on the playlist and downloaded/local music screens.

## what problem/error we fixed
- Previously, the shuffle button on playlists only triggered 'Shuffle Play' rather than showing the global shuffle state.

## Files Changed
- lib/screens/screen/library_views/playlist_screen.dart
- lib/screens/screen/local_music_screen.dart

## Main Changes
- Refactored the action icons on Playlist and Local Music screens to listen to the global shuffleMode stream.
- The button now changes color and icon (MingCute.shuffle_line to MingCute.shuffle_fill) perfectly mirroring the PlayerScreen toggle.
- Added iconColor property to local ActionChipButton and _buildActionIcon to support dynamic state colors.

## Technical Notes
- Shuffle mode is now visually synchronized across all screens.

## Breaking Changes
None

## Status
Completed
---

## Date
2026-07-08 00:46

## Task
Overhaul Explore Screen UI

## Reason
Update home page layout to a frosted glass carousel and a sleek Recently Played list based on user mockup.

## what problem/error we fixed
- Replaced outdated chart carousel style with a modern, inset frosted glass aesthetic.
- Redesigned recently played UI to a smooth horizontal scrolling view instead of vertical grid tiles.

## Files Changed
- lib/screens/screen/chart/chart_widget.dart
- lib/screens/screen/chart/carousal_widget.dart
- lib/screens/screen/explore_screen.dart

## Main Changes
- Redesigned ChartWidget with rounded corners, frosted background, and shadow inset cover image.
- Updated CaraouselWidget to include auto-scaling centered pages and a dynamic dot indicator.
- Created RecentlyPlayedHorizontalCard and injected it into explore_screen.dart for a horizontally scrollable list of recent tracks.

## Technical Notes
- Used CarouselSlider's enlargeCenterPage and viewportFraction to achieve the requested scale effect.
- Added custom dot pagination relying on component state.

## Breaking Changes
None

## Status
Completed
---
## Date
2026-07-16 18:20

## Task
Fix YouTube Direct imported songs stuck on loading

## Reason
Wrong plugin ID used.

## what problem/error we fixed
Imported YouTube playlists got stuck in loading state when playing because they were assigned the ytmusic plugin ID instead of ytvideo, causing stream resolution failure.

## Files Changed
- lib/plugins/blocs/import/content_import_cubit.dart

## Main Changes
- Switched sourceId for YouTube Direct imports from content-resolver.bloomfactory.ytmusic to content-resolver.bloomfactory.ytvideo.

## Technical Notes
- ytvideo is the correct plugin for generic YouTube video IDs, while ytmusic is specifically for YouTube Music IDs.

## Breaking Changes
None

## Status
Completed

---
## Date
2026-07-16 18:34

## Task
Fix scrollable_positioned_list compile error

## Reason
Dart 3 switch exhaustiveness error.

## what problem/error we fixed
Fixed The type 'dynamic' is not exhaustively matched by the switch cases error by pointing scrollable_positioned_list to the master branch of its GitHub repo which contains the fix.

## Files Changed
- pubspec.yaml

## Main Changes
- Updated scrollable_positioned_list dependency to point to its official GitHub repository instead of pub.dev version 0.3.8.

## Technical Notes
- pub.dev version 0.3.8 is broken on newer Dart SDKs. Using the unreleased master branch ( .3.8+1) circumvents this.

## Breaking Changes
None

## Status
Completed

---
