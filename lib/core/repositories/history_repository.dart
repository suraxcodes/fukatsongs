import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../models/song.dart';

part 'history_repository.g.dart';

class HistoryRepository {
  final Box<Song> _playbackBox;
  final Box<String> _searchBox;

  HistoryRepository({
    required Box<Song> playbackBox,
    required Box<String> searchBox,
  })  : _playbackBox = playbackBox,
        _searchBox = searchBox;

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
    playbackBox: Hive.box<Song>('recent_songs'),
    searchBox: Hive.box<String>('search_history'),
  );
}
