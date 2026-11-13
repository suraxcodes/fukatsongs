// No packages needed: dart run tool/playlist_sort_checks.dart
import '../lib/services/playlist_sort/playlist_sort_data.dart';
import '../lib/services/playlist_sort/play_accumulator.dart';

void check(bool value, String name) {
  if (!value) throw StateError('FAIL: $name');
  print('PASS: $name');
}

void main() {
  var data = PlaylistSortData()..reconcile(['legacyB', 'legacyA']);
  data.add(['c', 'd', 'c'], 'import1');
  data = PlaylistSortData.decode(data.encode());
  data.add(['e'], 'import1');
  data.add(['f'], 'import2');
  data.mode = PlaylistSortMode.recentlyAdded;
  check(
    data.sortedIds().join(',') == 'f,c,d,e,legacyB,legacyA',
    'recent batches/chunks/resume/duplicate/legacy order',
  );
  data.mode = PlaylistSortMode.oldestAdded;
  check(
    data.sortedIds().join(',') == 'legacyB,legacyA,c,d,e,f',
    'oldest batches keep internal order',
  );
  data.entries['e']!.plays = 2;
  data.entries['c']!.plays = 1;
  data.mode = PlaylistSortMode.mostPlayed;
  check(
    data.sortedIds().join(',') == 'e,c,legacyB,legacyA,d,f',
    'playlist counts and deterministic ties',
  );
  data.reconcile(['f', 'e', 'd', 'c', 'legacyA', 'legacyB']);
  check(
    data.sortedIds().join(',') == 'e,c,legacyB,legacyA,d,f',
    'reorder preserves original tie order/counts',
  );
  data = PlaylistSortData.decode(data.encode());
  check(
    data.mode == PlaylistSortMode.mostPlayed && data.entries['e']!.plays == 2,
    'persistence',
  );
  data.reconcile(['c', 'd']);
  data.add(['e'], 'newMembership');
  check(
    data.entries['e']!.plays == 0,
    'removed membership does not retain old count',
  );
  final large = PlaylistSortData()
    ..add(List.generate(252, (i) => '$i'), 'batch');
  large.add(['new'], 'later');
  large.mode = PlaylistSortMode.recentlyAdded;
  final snapshot = large.sortedIds();
  check(
    snapshot.take(40).first == 'new' &&
        snapshot[40] == '39' &&
        snapshot.toSet().length == 253,
    'full sort before 40-row pagination',
  );

  PlayAccumulator normal() {
    final a = PlayAccumulator();
    for (int i = 0; i <= 59000; i += 250) {
      a.sample(nowMs: i, positionMs: i, playing: true);
    }
    return a;
  }

  final a = normal();
  check(!a.counted, '59 seconds never counts');
  bool counted = false;
  for (int i = 59250; i <= 60000; i += 250) {
    counted = a.sample(nowMs: i, positionMs: i, playing: true) || counted;
  }
  check(counted && a.counted, '60 actual seconds counts');
  check(
    !a.sample(nowMs: 60250, positionMs: 60250, playing: true),
    'once per attempt',
  );
  final paused = normal();
  paused.sample(nowMs: 59250, positionMs: 59000, playing: false);
  paused.sample(nowMs: 120000, positionMs: 59000, playing: true);
  check(
    !paused.counted && paused.listenedMs == 59000,
    'pause/background wall gap adds nothing',
  );
  paused.seeked();
  paused.sample(nowMs: 120250, positionMs: 200000, playing: true);
  check(!paused.counted, 'seek jump adds nothing');
  final short = PlayAccumulator();
  for (int i = 0; i <= 29500; i += 250) {
    short.sample(nowMs: i, positionMs: i, playing: true);
  }
  check(short.completeShort(durationMs: 30000), 'natural short completion');
  check(!short.completeShort(durationMs: 30000), 'short completion only once');
  final seek = PlayAccumulator()..seeked();
  check(
    !seek.completeShort(durationMs: 30000),
    'seek-to-end cannot fake completion',
  );
  final failed = PlayAccumulator();
  check(
    !failed.completeShort(durationMs: 30000),
    'failure/no listening cannot count',
  );
  final speed = PlayAccumulator();
  for (int i = 0; i <= 30000; i += 250) {
    speed.sample(nowMs: i, positionMs: i * 2, playing: true, speed: 2);
  }
  check(
    !speed.counted && speed.listenedMs == 30000,
    '2x speed uses actual wall listening',
  );
  final retry = normal()..gap();
  retry.sample(nowMs: 100000, positionMs: 59000, playing: true);
  check(
    retry.listenedMs == 59000 && !retry.counted,
    'retry gap preserves listening without adding downtime',
  );
}
