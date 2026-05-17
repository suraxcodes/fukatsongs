import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../models/song.dart';
import '../constants/hive_boxes.dart';

part 'history_repository.g.dart';

class HistoryRepository {
  final Box<Song> _playbackBox;
  final Box<String> _searchBox;
  final Box<int> _statsBox;

  HistoryRepository({
    required Box<Song> playbackBox,
    required Box<String> searchBox,
    required Box<int> statsBox,
  })  : _playbackBox = playbackBox,
        _searchBox = searchBox,
        _statsBox = statsBox;

  // Playback History
  List<Song> getPlaybackHistory() {
    return _playbackBox.values.toList().reversed.toList();
  }

  Future<void> addToPlaybackHistory(Song song) async {
    // Remove if already exists to move to top
    final existingIndex = _playbackBox.values.toList().indexWhere((s) => s.id == song.id);
    if (existingIndex != -1) {
      await _playbackBox.deleteAt(existingIndex);
    }

    await _playbackBox.add(song);
    
    // Keep only last 20
    if (_playbackBox.length > 20) {
      await _playbackBox.deleteAt(0);
    }

    // Increment Play Count for Stats
    final currentCount = _statsBox.get(song.id, defaultValue: 0) ?? 0;
    await _statsBox.put(song.id, currentCount + 1);
  }

  // Stats
  List<MapEntry<String, int>> getTopSongIds({int limit = 10}) {
    final entries = _statsBox.toMap().entries.map((e) => MapEntry(e.key.toString(), e.value)).toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).toList();
  }

  int getPlayCount(String songId) {
    return _statsBox.get(songId, defaultValue: 0) ?? 0;
  }

  // Search History
  List<String> getSearchHistory() {
    return _searchBox.values.toList().reversed.toList();
  }

  Future<void> addToSearchHistory(String query) async {
    if (query.trim().isEmpty) return;

    final existingIndex = _searchBox.values.toList().indexOf(query);
    if (existingIndex != -1) {
      await _searchBox.deleteAt(existingIndex);
    }

    await _searchBox.add(query);

    // Keep only last 10
    if (_searchBox.length > 10) {
      await _searchBox.deleteAt(0);
    }
  }

  Future<void> removeFromSearchHistory(String query) async {
    final index = _searchBox.values.toList().indexOf(query);
    if (index != -1) {
      await _searchBox.deleteAt(index);
    }
  }

  Future<void> clearSearchHistory() async {
    await _searchBox.clear();
  }
}

@riverpod
HistoryRepository historyRepository(HistoryRepositoryRef ref) {
  return HistoryRepository(
    playbackBox: Hive.box<Song>(HiveBoxes.recentSongs),
    searchBox: Hive.box<String>(HiveBoxes.searchHistory),
    statsBox: Hive.box<int>(HiveBoxes.playStats),
  );
}
