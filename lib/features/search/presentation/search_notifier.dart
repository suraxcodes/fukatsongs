import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fukat_songs/models/song.dart';
import 'package:fukat_songs/providers/music_repository_provider.dart';
import 'package:fukat_songs/core/services/connectivity_service.dart';
import 'package:fukat_songs/core/repositories/history_repository.dart';

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
      
      state = await AsyncValue.guard(() async {
        try {
          if (!isConnected) {
            return _searchLibrary(query);
          }

          final results = await ref.read(musicRepositoryProvider).search(query);
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
    // Basic library search logic
    return []; // Implementation simplified for now
  }
}

final searchNotifierProvider = StateNotifierProvider<SearchNotifier, AsyncValue<List<Song>>>((ref) {
  return SearchNotifier(ref);
});
