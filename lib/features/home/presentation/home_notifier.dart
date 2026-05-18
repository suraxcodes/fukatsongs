import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../models/song.dart';
import '../../../models/playlist.dart';
import '../../../providers/music_repository_provider.dart';
import '../../player/presentation/player_notifier.dart';
import '../../library/logic/playlist_notifier.dart';
import '../../../core/audio/audio_handler_provider.dart';
import '../../../core/repositories/history_repository.dart';
import '../../../core/network/spotify_chart_service.dart';

part 'home_notifier.g.dart';

class HomeState {
  final List<dynamic> speedDialItems;
  final List<Song> quickPicks;
  final List<Song> trending;
  final List<Song> samples;
  final List<Song> paginatedFeed;
  final int currentPage;
  final bool hasMore;
  final bool isFetchingMore;
  final String selectedCategory;
  final List<Song> categorySongs;
  final bool isLoading;

  HomeState({
    this.speedDialItems = const [],
    this.quickPicks = const [],
    this.trending = const [],
    this.samples = const [],
    this.paginatedFeed = const [],
    this.currentPage = 1,
    this.hasMore = true,
    this.isFetchingMore = false,
    this.categorySongs = const [],
    this.selectedCategory = '',
    this.isLoading = false,
  });

  HomeState copyWith({
    List<dynamic>? speedDialItems,
    List<Song>? quickPicks,
    List<Song>? trending,
    List<Song>? samples,
    List<Song>? paginatedFeed,
    int? currentPage,
    bool? hasMore,
    bool? isFetchingMore,
    List<Song>? categorySongs,
    String? selectedCategory,
    bool? isLoading,
  }) {
    return HomeState(
      speedDialItems: speedDialItems ?? this.speedDialItems,
      quickPicks: quickPicks ?? this.quickPicks,
      trending: trending ?? this.trending,
      samples: samples ?? this.samples,
      paginatedFeed: paginatedFeed ?? this.paginatedFeed,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
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
    final playlists = ref.read(playlistNotifierProvider);

    List<Song> trendingSongs = [];
    List<Song> sampleSongs = [];
    List<Song> initialFeed = [];

    final spotifyChartService = ref.read(spotifyChartServiceProvider);
    try {
      // 37i9dQZEVXbLZ3370vK7gZ is the official "Top 50 - India" playlist ID on Spotify
      trendingSongs = await spotifyChartService.fetchPlaylistTracks("37i9dQZEVXbLZ3370vK7gZ");
    } catch (e) {
      debugPrint('Failed to fetch Spotify trending: $e');
      try {
        trendingSongs = await musicRepo.getTrending();
      } catch (err) {
        debugPrint('Failed to fetch backup JioSaavn trending: $err');
      }
    }

    try {
      sampleSongs = await musicRepo.search('latest hits', page: 1, limit: 15);
    } catch (e) {
      debugPrint('Failed to fetch samples: $e');
    }

    try {
      initialFeed = await musicRepo.search('trending list', page: 1, limit: 20);
    } catch (e) {
      debugPrint('Failed to fetch initial feed: $e');
    }

    final history = historyRepo.getPlaybackHistory()..shuffle();
    if (trendingSongs.isEmpty && sampleSongs.isNotEmpty) {
      trendingSongs = List.from(sampleSongs);
    } else {
      trendingSongs.shuffle();
    }
    
    // Build Speed Dial: Playlists first, then frequent history
    final List<dynamic> speedDial = [
      ...playlists.take(2), 
      ...history.take(4),    
    ];

    // If speed dial is too short, pad with trending
    if (speedDial.length < 6) {
      speedDial.addAll(trendingSongs.take(6 - speedDial.length).toList()..shuffle());
    }

    return HomeState(
      speedDialItems: speedDial..shuffle(),
      trending: trendingSongs,
      samples: sampleSongs,
      paginatedFeed: initialFeed,
      currentPage: 1,
      hasMore: initialFeed.isNotEmpty,
      quickPicks: history.isNotEmpty ? (history..shuffle()) : (trendingSongs..shuffle()),
      isLoading: false,
    );
  }

  Future<void> fetchMoreFeed() async {
    final current = state.value;
    if (current == null || current.isFetchingMore || !current.hasMore) return;

    state = AsyncValue.data(current.copyWith(isFetchingMore: true));
    try {
      final musicRepo = ref.read(musicRepositoryProvider);
      final nextPage = current.currentPage + 1;
      final newSongs = await musicRepo.search('trending list', page: nextPage, limit: 20);
      
      state = AsyncValue.data(current.copyWith(
        paginatedFeed: [...current.paginatedFeed, ...newSongs],
        currentPage: nextPage,
        hasMore: newSongs.isNotEmpty,
        isFetchingMore: false,
      ));
    } catch (e) {
      state = AsyncValue.data(current.copyWith(isFetchingMore: false));
    }
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
