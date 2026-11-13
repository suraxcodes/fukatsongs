import 'dart:math';

import 'package:isar_community/isar.dart';
import 'package:fukatsongs/services/db/global_db.dart';

import 'playlist_sort_data.dart';
export 'playlist_sort_data.dart';

/// Reuses the existing versioned string-settings collection. No destructive
/// migration or generated-schema edits. Every read/modify/write is inside the
/// SAME Isar transaction as its playlist mutation.
class PlaylistSortStore {
  static final _random = Random.secure();
  static String newBatchToken() =>
      '${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(1 << 32)}';
  static String key(int id) => 'playlist_sort_v1:$id';

  /// Caller MUST hold a write transaction. Reconciles before adding new rows.
  static Future<PlaylistSortData> readInTransaction(Isar isar, int id) async {
    final setting = await isar.appSettingsStrDBs
        .filter()
        .settingNameEqualTo(key(id))
        .findFirst();
    final data = PlaylistSortData.decode(setting?.settingValue);
    final entries = await isar.playlistEntryDBs
        .filter()
        .playlistIdEqualTo(id)
        .sortByPosition()
        .findAll();
    await Future.wait(entries.map((e) => e.track.load()));
    data.reconcile(
      entries.map((e) => e.track.value?.mediaId).whereType<String>().toList(),
    );
    return data;
  }

  static Future<void> writeInTransaction(
    Isar isar,
    int id,
    PlaylistSortData data,
  ) async {
    await isar.appSettingsStrDBs.put(
      AppSettingsStrDB(settingName: key(id), settingValue: data.encode()),
    );
  }

  static Future<void> deleteInTransaction(Isar isar, int id) async {
    await isar.appSettingsStrDBs
        .filter()
        .settingNameEqualTo(key(id))
        .deleteAll();
  }
}

class PlaylistOrderSnapshot {
  final PlaylistSortMode mode;
  final List<int> trackDbIds;
  const PlaylistOrderSnapshot(this.mode, this.trackDbIds);
}
