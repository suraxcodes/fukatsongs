import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fukat_songs/models/song.dart';
import 'package:fukat_songs/providers/music_repository_provider.dart';
import 'package:fukat_songs/core/constants/hive_boxes.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fukat_songs/features/library/logic/playlist_notifier.dart';
import 'package:fukat_songs/core/repositories/history_repository.dart';

enum SearchSource { saavn, youtube, both }

final searchSourceProvider = StateProvider<SearchSource>((ref) => SearchSource.both);

class SearchNotifier extends StateNotifier<AsyncValue<List<Song>>> {
  final Ref ref;
  Timer? _debounceTimer;

  SearchNotifier(this.ref) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    final isConnected = await ref.read(connectivityServiceProvider.notifier).isConnected();
    if (!isConnected) {
      state = AsyncValue.data(_searchLibrary(''));
    } else {
      state = await AsyncValue.guard(() async {
        try {
          return await ref.read(musicRepositoryProvider).getTrending();
        } catch (e, stack) {
          print('--- SearchNotifier Error during getTrending: $e');
          print(stack);
          rethrow;
        }
      });
    }
  }

  void clear() {
    _init();
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      clear();
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      state = const AsyncValue.loading();
      
      final isConnected = await ref.read(connectivityServiceProvider.notifier).isConnected();
      final source = ref.read(searchSourceProvider);
      
      state = await AsyncValue.guard(() async {
        try {
          if (!isConnected) {
            return _searchLibrary(query);
          }

          final results = await ref.read(musicRepositoryProvider).search(
            query,
            source: source.name,
          );
          return results;
        } catch (e, stack) {
          print('--- SearchNotifier Error during search: $e');
          print(stack);
          rethrow;
        }
      });
    });
  }

  List<Song> _searchLibrary(String query) {
    if (query.isEmpty) return [];
    
    final downloadsBox = Hive.box<Song>(HiveBoxes.downloads);
    final likedSongs = ref.read(likedSongsNotifierProvider);
    
    // Combine both sources and remove duplicates by ID
    final Set<Song> localSongs = {
      ...downloadsBox.values,
      ...likedSongs,
    };
    
    final searchLower = query.toLowerCase();
    return localSongs.where((song) {
      return song.title.toLowerCase().contains(searchLower) ||
             song.artist.toLowerCase().contains(searchLower);
    }).toList();
  }
}

final searchNotifierProvider = StateNotifierProvider<SearchNotifier, AsyncValue<List<Song>>>((ref) {
  return SearchNotifier(ref);
});
