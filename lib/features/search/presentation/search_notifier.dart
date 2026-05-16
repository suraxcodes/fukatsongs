import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../models/song.dart';
import '../../../providers/music_repository_provider.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/repositories/history_repository.dart';

part 'search_notifier.g.dart';

@riverpod
class SearchNotifier extends _$SearchNotifier {
  Timer? _debounceTimer;
  late final Box<String> _cacheBox;

  @override
  FutureOr<List<Song>> build() async {
    _cacheBox = Hive.box<String>('search_cache');
    
    final isConnected = await ref.read(connectivityServiceProvider.notifier).isConnected();
    if (!isConnected) {
      return _searchLibrary('');
    }
    
    return ref.read(musicRepositoryProvider).getTrending();
  }

  Future<void> search(String query) async {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      state = const AsyncValue.loading();
      
      final isConnected = await ref.read(connectivityServiceProvider.notifier).isConnected();
      
      state = await AsyncValue.guard(() async {
        if (!isConnected) {
          return _searchLibrary(query);
        }

        if (query.trim().isEmpty) {
          return ref.read(musicRepositoryProvider).getTrending();
        }

        // Track History
        ref.read(historyRepositoryProvider).addToSearchHistory(query);

        final results = await ref.read(musicRepositoryProvider).search(query);
        return results;
      });
    });
  }

  List<Song> _searchLibrary(String query) {
    final libraryBox = Hive.box('library');
    final songs = libraryBox.values
        .map((j) => Song.fromJson(Map<String, dynamic>.from(j)))
        .toList();

    if (query.isEmpty) return songs;

    final q = query.toLowerCase();
    return songs.where((s) => 
      s.title.toLowerCase().contains(q) || 
      s.artist.toLowerCase().contains(q)
    ).toList();
  }
}
