import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../models/song.dart';
import '../../../providers/music_repository_provider.dart';

part 'search_notifier.g.dart';

@riverpod
class SearchNotifier extends _$SearchNotifier {
  Timer? _debounceTimer;
  late final Box<String> _historyBox;

  @override
  FutureOr<List<Song>> build() async {
    _historyBox = Hive.box<String>('search_cache');
    // Initial state: Trending songs
    return ref.read(musicRepositoryProvider).getTrending();
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() => ref.read(musicRepositoryProvider).getTrending());
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() async {
        final results = await ref.read(musicRepositoryProvider).search(query);
        if (results.isNotEmpty) {
          _addToHistory(query);
        }
        return results;
      });
    });
  }

  void _addToHistory(String query) {
    final history = _historyBox.values.toList();
    if (history.contains(query)) {
      _historyBox.deleteAt(history.indexOf(query));
    }
    _historyBox.add(query);

    // Keep only last 10
    if (_historyBox.length > 10) {
      _historyBox.deleteAt(0);
    }
  }

  List<String> getHistory() {
    return _historyBox.values.toList().reversed.toList();
  }

  void clearHistory() {
    _historyBox.clear();
    ref.invalidateSelf();
  }
}
