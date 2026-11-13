import 'dart:convert';

enum PlaylistSortMode { recentlyAdded, oldestAdded, mostPlayed }

extension PlaylistSortLabel on PlaylistSortMode {
  String get label => switch (this) {
    PlaylistSortMode.recentlyAdded => 'Recently added',
    PlaylistSortMode.oldestAdded => 'Oldest added',
    PlaylistSortMode.mostPlayed => 'Most played',
  };
}

/// Metadata is independent of editable playlist positions and provider streams.
class PlaylistSortEntry {
  final int batch;
  final int originalOrder;
  int plays;
  PlaylistSortEntry(this.batch, this.originalOrder, [this.plays = 0]);
  Map<String, Object> toJson() => {
    'batch': batch,
    'order': originalOrder,
    'plays': plays,
  };
}

class PlaylistSortData {
  PlaylistSortMode mode = PlaylistSortMode.oldestAdded;
  int nextBatch = 1;
  int nextOrder = 0;
  final Map<String, int> batches = {};
  final Map<String, PlaylistSortEntry> entries = {};

  PlaylistSortData();

  factory PlaylistSortData.decode(String? value) {
    final result = PlaylistSortData();
    if (value == null) return result;
    final map = jsonDecode(value) as Map<String, dynamic>;
    if (map['v'] != 1)
      throw const FormatException('Unknown playlist sort metadata version');
    result.mode = PlaylistSortMode.values.firstWhere(
      (m) => m.name == map['mode'],
      orElse: () => PlaylistSortMode.oldestAdded,
    );
    result.nextBatch = map['nextBatch'] as int;
    result.nextOrder = map['nextOrder'] as int;
    for (final item in (map['batches'] as Map<String, dynamic>).entries) {
      result.batches[item.key] = item.value as int;
    }
    for (final item in (map['entries'] as Map<String, dynamic>).entries) {
      final row = item.value as Map<String, dynamic>;
      result.entries[item.key] = PlaylistSortEntry(
        row['batch'] as int,
        row['order'] as int,
        row['plays'] as int,
      );
    }
    return result;
  }

  /// First access preserves ALL old entries as one legacy batch. Later missing
  /// rows are also treated conservatively; no import history is invented.
  void reconcile(List<String> currentIds) {
    final current = currentIds.toSet();
    entries.removeWhere((id, _) => !current.contains(id));
    for (final id in currentIds) {
      entries.putIfAbsent(id, () => PlaylistSortEntry(0, nextOrder++));
    }
  }

  /// Each single add gets its own token; all chunks of an import share a token.
  void add(Iterable<String> ids, String batchToken) {
    final fresh = ids.where((id) => !entries.containsKey(id)).toList();
    if (fresh.isEmpty) return;
    final batch = batches.putIfAbsent(batchToken, () => nextBatch++);
    for (final id in fresh) {
      entries.putIfAbsent(id, () => PlaylistSortEntry(batch, nextOrder++));
    }
  }

  List<String> sortedIds() {
    final ids = entries.keys.toList();
    ids.sort((a, b) {
      final left = entries[a]!;
      final right = entries[b]!;
      final primary = switch (mode) {
        PlaylistSortMode.recentlyAdded => right.batch.compareTo(left.batch),
        PlaylistSortMode.oldestAdded => left.batch.compareTo(right.batch),
        PlaylistSortMode.mostPlayed => right.plays.compareTo(left.plays),
      };
      if (primary != 0) return primary;
      final stable = left.originalOrder.compareTo(right.originalOrder);
      return stable != 0 ? stable : a.compareTo(b);
    });
    return ids;
  }

  String encode() => jsonEncode({
    'v': 1,
    'mode': mode.name,
    'nextBatch': nextBatch,
    'nextOrder': nextOrder,
    'batches': batches,
    'entries': entries.map((id, row) => MapEntry(id, row.toJson())),
  });
}
