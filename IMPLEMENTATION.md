# Per-playlist sorting — implementation handoff

Base commit: `9b61edbd8aa9f87ef9ef94cee765e06b5be63bfb`

## Status

Implementation supplied as complete replacement/new files, plus a patch against the exact base commit. **Not yet Flutter-build-verified or device-verified.** Do not describe this as a passing Android release until the checks below pass.

- PASS: 18 executable standalone Dart assertions (see `TEST_RESULTS.txt`).
- PASS: Dart analysis of the two pure logic modules and their standalone test.
- PASS: Dart formatter parsed all supplied Dart files.
- PASS: `git apply --check` against the specified base.
- NOT RUN: full Flutter analyzer, Android build, Isar integration tests, real-device playback/import tests. Flutter/Android SDKs and a connected device were not available here.

## Root cause / before → after

| Before | After |
|---|---|
| Playlist positions are the only ordering mechanism | Versioned sorting metadata is stored under the immutable database playlist ID |
| Import chunks have no shared identity | One persisted batch token follows chunk writes and resumed saves |
| Paging happens before any complete-list sort | One complete sorted ID snapshot is created, then hydrated in 40-track pages |
| No playlist origin in playback queue | Explicit saved-playlist playback attaches an origin ID; queue persistence retains it |
| Global playback history cannot identify originating playlists | Independent playlist listening counter; global Recently Played logic unchanged |
| Reorder deletes/recreates playlist memberships | Retained entry objects and timestamps are reused; sorting metadata/counts survive |

## Behaviour implemented

- **Recently added:** newest batch first, original order inside each batch.
- **Oldest added:** oldest batch first, original order inside each batch.
- **Most played:** descending playlist-specific counts; original insertion-order ties.
- Existing entries migrate lazily as a single legacy batch in their current order. Initial mode is Oldest added, so opening an existing playlist does not reverse it. Counts begin at zero.
- Preference and counts use `playlist_sort_v1:<database ID>`, not playlist titles. No schema regeneration, new package, clear-data operation or reimport is required.
- Import bookkeeping uses `sortBatchToken` in existing progress files. Import fetching, URL parsing, provider matching and import UI are not redesigned.
- A sort change reloads only the playlist screen snapshot, not the running queue. Tapped song identity is captured before asynchronous hydration.
- Explicit playlist-screen Play and library playlist-menu Play use sorted snapshots and saved origin IDs. Direct external play/search/related additions do not acquire attribution simply because a playlist screen is open. Global history remains separate.
- Timer-based accounting uses forward playback progress capped by actual elapsed listening time. Pause/loading/buffering gaps and seeks do not add listening time. One count per logical playback attempt after 60 seconds; retries preserve the attempt. Natural short completion requires listening evidence and no explicit seek.
- Repeat-one accounting observes natural position wrap because the existing engine suppresses its completion callback in that mode. This path requires particular attention in the device tests; it is not validated by the standalone tests.
- A failed counter database write is logged, not silently reported as successful or repeatedly retried. Device persistence/failure tests remain required.

## Apply — coding agent instructions

1. Confirm the working tree is based on the exact SHA above. Preserve unrelated local changes.
2. Use **one** method: apply `playlist_sort.patch`, **or** copy the supplied `lib/` and `tool/` files to their identical paths. Do not apply both.
3. All supplied source files are complete files, not snippets. Do not replace an entire repository directory; replace only listed files.
4. Run the commands below. Fix any integration/analyzer findings within the sorting scope before calling the implementation complete.
5. Commit only the explicitly listed files. **Never use `git add -A`.** Return the resulting commit SHA and actual build/test output.

```sh
git rev-parse HEAD
git apply --check /path/to/playlist_sort.patch
git apply /path/to/playlist_sort.patch

flutter pub get
dart run tool/playlist_sort_checks.dart
flutter analyze
flutter test
flutter build apk --debug
```

The standalone checks have no `package:test` dependency. Run them with `dart run`; they live under `tool/` so Flutter test discovery is unaffected.

## Exact changed files

Existing files:

1. `lib/services/db/dao/playlist_dao.dart` — atomic metadata writes, preserved membership identity on reorder, sorted snapshot and count APIs.
2. `lib/services/playlist_save_service.dart` — metadata-only batch-token propagation across save chunks/resume.
3. `lib/plugins/blocs/import/content_import_cubit.dart` — metadata-only shared token across YouTube continuation batches.
4. `lib/services/player/queue_manager.dart` — origin attachment, removal/replacement handling, persistence/restore.
5. `lib/services/bloomee_player.dart` — counter lifecycle, explicit origin parameter, successful-open/completion/seek hooks.
6. `lib/screens/screen/library_views/cubit/current_playlist_cubit.dart` — sorted snapshot hydration and race-safe selection/loading.
7. `lib/screens/screen/library_views/cubit/current_playlist_state.dart` — selected sort mode.
8. `lib/screens/screen/library_views/playlist_screen.dart` — Sort menu and sorted/tapped-ID playback snapshot.
9. `lib/blocs/library/cubit/library_items_cubit.dart` — explicit saved-playlist playback snapshot helper.
10. `lib/screens/screen/library_views/more_opts_sheet.dart` — playlist-menu Play uses the saved snapshot and ID.

New files:

11. `lib/services/playlist_sort/playlist_sort_data.dart`
12. `lib/services/playlist_sort/playlist_sort_store.dart`
13. `lib/services/playlist_sort/play_accumulator.dart`
14. `lib/services/playlist_sort/playlist_play_tracker.dart`
15. `tool/playlist_sort_checks.dart`

## Do not touch

- `lib/screens/screen/library_views/import_media_view.dart` — the previous FukatMusic-file repair remains unchanged.
- Home artwork, Explore layout, `pubspec.yaml`, Android manifests, Gradle or asset declarations.
- Source fallback/matching decisions, provider IDs, engine audio-output logic, source URL parsing.
- Voice grammar/services, Dynamic Island, navigation branches, battery information UI.
- Global `recently_played_tracker.dart` and its threshold.
- Generated Isar schemas or dependency versions.

## Required integration / device acceptance tests

Record actual PASS/FAIL for each; none are claimed passed here.

1. Existing 252-song playlist: initial order stays identical. Switch each sort, close/reopen, restart, rename. Preference persists by DB ID.
2. Import two different batches. Newest mode reverses batches only, never songs within them. Repeat with >200-song chunks, YouTube continuation pages, interrupted resume, duplicate tracks and an interrupted first write.
3. Scroll through all pages after switching sort. No missing or duplicated songs. Tap a song beyond the first page during hydration; playback begins with that song. With shuffle OFF, next/previous follows the displayed snapshot.
4. Change sort during playback. The active queue stays unchanged. A later Play action uses the new order. Test the library menu's Play action as well.
5. Same song in playlists A and B: 59 seconds in A does not count; 60 actual seconds counts once only for A. Playback from search, unrelated collections and related-song additions must not increase A or B.
6. Pause for a minute; buffering/error/retry; forward/back seek; 2x speed; fallback provider; replay; loop-one; naturally finish a song under 60 seconds. Verify no seek-to-end/failure counts and no duplicate retry counts. Include very short tracks and crossfade enabled/disabled.
7. Restart/restore queue and verify correct original playlist attribution. Old queue records without metadata must not gain guessed origins. Remove/move/reorder queue items and add external songs. Delete the source playlist while playback continues.
8. Reorder playlist entries in the editor, then check original-order ties, batch membership, added timestamps and counts. Remove/re-add a song: new membership starts at zero.
9. Use the real supplied FukatMusic export again: import succeeds and preserves order. This is a runtime regression test, not a claim of prior device success.

### Background component inventory / teardown verdict

**Device verdict: NOT RUN — neither PASS nor FAIL can be asserted.** Verify all of these together:

- Main player engine and both underlying media players.
- Audio-service playback/notification state.
- Queue state and persistence listeners.
- Existing Recently Played tracker.
- New playlist-play timer (must be cancelled during existing disposal).
- Voice foreground service, recorder/recognizer and callbacks.
- Dynamic Island/overlay service and notification.
- Existing volume polling, interruption listeners, pre-resolve/fallback work and pending retries.

Minimize: existing playback behaviour is preserved. Swipe away: verify the full teardown above. Reopen: verify fresh state and no unintended autoplay. No voice or Dynamic Island service logic is changed by this patch.
