import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../models/song.dart';
import '../../../providers/music_repository_provider.dart';
import '../../../core/repositories/history_repository.dart';

part 'home_notifier.g.dart';

class HomeState {
  final List<Song> quickPicks;
  final List<Song> trending;
  final bool isLoading;

  HomeState({
    this.quickPicks = const [],
    this.trending = const [],
    this.isLoading = false,
  });

  HomeState copyWith({
    List<Song>? quickPicks,
    List<Song>? trending,
    bool? isLoading,
  }) {
    return HomeState(
      quickPicks: quickPicks ?? this.quickPicks,
      trending: trending ?? this.trending,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

@riverpod
class HomeNotifier extends _$HomeNotifier {
  @override
  FutureOr<HomeState> build() async {
    return _fetchHomeData();
  }

  Future<HomeState> _fetchHomeData() async {
    final historyRepo = ref.read(historyRepositoryProvider);
    final musicRepo = ref.read(musicRepositoryProvider);

    final quickPicks = historyRepo.getPlaybackHistory().take(6).toList();
    final trending = await musicRepo.getTrending();

    return HomeState(
      quickPicks: quickPicks,
      trending: trending,
      isLoading: false,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchHomeData());
  }
}
