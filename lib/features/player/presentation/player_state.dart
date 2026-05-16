import 'package:audio_service/audio_service.dart';
import 'package:fukat_songs/models/song.dart';

class PlayerState {
  final Song? currentSong;
  final bool isPlaying;
  final Duration position;
  final Duration bufferedPosition;
  final Duration totalDuration;
  final AudioProcessingState processingState;
  final List<Song> queue;
  final int currentIndex;
  final bool isShuffleModeEnabled;
  final AudioServiceRepeatMode repeatMode;

  const PlayerState({
    this.currentSong,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.totalDuration = Duration.zero,
    this.processingState = AudioProcessingState.idle,
    this.queue = const [],
    this.currentIndex = 0,
    this.isShuffleModeEnabled = false,
    this.repeatMode = AudioServiceRepeatMode.none,
  });

  PlayerState copyWith({
    Song? currentSong,
    bool? isPlaying,
    Duration? position,
    Duration? bufferedPosition,
    Duration? totalDuration,
    AudioProcessingState? processingState,
    List<Song>? queue,
    int? currentIndex,
    bool? isShuffleModeEnabled,
    AudioServiceRepeatMode? repeatMode,
  }) {
    return PlayerState(
      currentSong: currentSong ?? this.currentSong,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      totalDuration: totalDuration ?? this.totalDuration,
      processingState: processingState ?? this.processingState,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isShuffleModeEnabled: isShuffleModeEnabled ?? this.isShuffleModeEnabled,
      repeatMode: repeatMode ?? this.repeatMode,
    );
  }
}
