import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../models/song.dart';
import '../../../models/playlist.dart';
import '../../../providers/music_repository_provider.dart';
import '../../player/presentation/player_notifier.dart';
import '../../library/logic/playlist_notifier.dart';
import '../../../core/audio/audio_handler_provider.dart';
import '../../../core/repositories/history_repository.dart';

part 'home_notifier.g.dart';

class HomeState {
  final List<dynamic> speedDialItems;
  final List<Song> quickPicks;
  final List<Song> trending;
  final String selectedCategory;
  final List<Song> categorySongs;
  final bool isLoading;

  HomeState({
    this.speedDialItems = const [],
    this.quickPicks = const [],
    this.trending = const [],
    this.categorySongs = const [],
    this.selectedCategory = '',
    this.isLoading = false,
  });

  HomeState copyWith({
    List<dynamic>? speedDialItems,
    List<Song>? quickPicks,
    List<Song>? trending,
    List<Song>? categorySongs,
    String? selectedCategory,
    bool? isLoading,
  }) {
    return HomeState(
      speedDialItems: speedDialItems ?? this.speedDialItems,
      quickPicks: quickPicks ?? this.quickPicks,
      trending: trending ?? this.trending,
      categorySongs: categorySongs ?? this.categorySongs,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

@riverpod
class HomeNotifier extends _$HomeNotifier {
  @override
  Future<HomeState> build() async {
    return _fetchHomeData();
  }

  Future<HomeState> _fetchHomeData() async {
    final musicRepo = ref.read(musicRepositoryProvider);
    final historyRepo = ref.read(historyRepositoryProvider);
    // Use ref.read instead of watch inside non-reactive method
    final playlists = ref.read(playlistNotifierProvider);

    List<Song> trendingSongs = [];
    try {
      trendingSongs = await musicRepo.getTrending();
    } catch (e) {
      debugPrint('Failed to fetch trending: $e');
    }

    final history = historyRepo.getPlaybackHistory();
    
    // Build Speed Dial: Playlists first, then frequent history
    final List<dynamic> speedDial = [
      ...playlists.take(2), 
      ...history.take(4),    
    ];

    // If speed dial is too short, pad with trending
    if (speedDial.length < 6) {
      speedDial.addAll(trendingSongs.take(6 - speedDial.length));
    }

    return HomeState(
      speedDialItems: speedDial,
      trending: trendingSongs,
      quickPicks: history.isNotEmpty ? history : trendingSongs,
      isLoading: false,
    );
  }

  Future<void> setCategory(String category) async {
    final musicRepo = ref.read(musicRepositoryProvider);
    final current = state.value!;
    state = AsyncValue.data(current.copyWith(selectedCategory: category, isLoading: true));
    
    try {
      final results = await musicRepo.search(category);
      state = AsyncValue.data(state.value!.copyWith(
        categorySongs: results,
        isLoading: false,
      ));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(isLoading: false));
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchHomeData());
  }
}
