import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../models/song.dart';
import '../../../core/audio/audio_handler_provider.dart';
import '../../../providers/music_repository_provider.dart';
import 'player_state.dart';

part 'player_notifier.g.dart';

@Riverpod(keepAlive: true)
class PlayerNotifier extends _$PlayerNotifier {
  @override
  PlayerState build() {
    final handler = ref.watch(audioHandlerProvider);

    // Listen to media item changes
    handler.mediaItem.listen((item) {
      if (item != null) {
        // Map MediaItem back to Song (simulated for now, need a way to find the Song)
        // In a real app, you'd store the current song in the notifier or find it in the queue
      }
    });

    // Listen to playback state
    handler.playbackState.listen((state) {
      this.state = this.state.copyWith(
        isPlaying: state.playing,
        position: state.updatePosition,
        bufferedPosition: state.bufferedPosition,
        processingState: state.processingState,
      );
    });

    return const PlayerState();
  }

  Future<void> playSong(Song song) async {
    state = state.copyWith(currentSong: song, isPlaying: true);
    
    final repository = ref.read(musicRepositoryProvider);
    final url = await repository.getStreamUrl(song);
    
    if (url != null) {
      await ref.read(audioHandlerProvider).playSong(song, url);
    }
  }

  void pause() => ref.read(audioHandlerProvider).pause();
  void resume() => ref.read(audioHandlerProvider).play();
  void seek(Duration position) => ref.read(audioHandlerProvider).seek(position);
  void skipToNext() => ref.read(audioHandlerProvider).skipToNext();
  void skipToPrevious() => ref.read(audioHandlerProvider).skipToPrevious();
}
