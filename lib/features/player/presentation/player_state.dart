import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:audio_service/audio_service.dart';
import '../../../models/song.dart';

part 'player_state.freezed.dart';

@freezed
class PlayerState with _$PlayerState {
  const factory PlayerState({
    Song? currentSong,
    @Default(false) bool isPlaying,
    @Default(Duration.zero) Duration position,
    @Default(Duration.zero) Duration bufferedPosition,
    @Default(Duration.zero) Duration totalDuration,
    @Default(AudioProcessingState.idle) AudioProcessingState processingState,
    @Default([]) List<Song> queue,
    @Default(0) int currentIndex,
    @Default(false) bool isShuffleModeEnabled,
    @Default(AudioServiceRepeatMode.none) AudioServiceRepeatMode repeatMode,
  }) = _PlayerState;
}
