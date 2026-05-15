// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'player_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$PlayerState {
  Song? get currentSong => throw _privateConstructorUsedError;
  bool get isPlaying => throw _privateConstructorUsedError;
  Duration get position => throw _privateConstructorUsedError;
  Duration get bufferedPosition => throw _privateConstructorUsedError;
  Duration get totalDuration => throw _privateConstructorUsedError;
  AudioProcessingState get processingState =>
      throw _privateConstructorUsedError;
  List<Song> get queue => throw _privateConstructorUsedError;
  int get currentIndex => throw _privateConstructorUsedError;
  bool get isShuffleModeEnabled => throw _privateConstructorUsedError;
  AudioServiceRepeatMode get repeatMode => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $PlayerStateCopyWith<PlayerState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlayerStateCopyWith<$Res> {
  factory $PlayerStateCopyWith(
          PlayerState value, $Res Function(PlayerState) then) =
      _$PlayerStateCopyWithImpl<$Res, PlayerState>;
  @useResult
  $Res call(
      {Song? currentSong,
      bool isPlaying,
      Duration position,
      Duration bufferedPosition,
      Duration totalDuration,
      AudioProcessingState processingState,
      List<Song> queue,
      int currentIndex,
      bool isShuffleModeEnabled,
      AudioServiceRepeatMode repeatMode});

  $SongCopyWith<$Res>? get currentSong;
}

/// @nodoc
class _$PlayerStateCopyWithImpl<$Res, $Val extends PlayerState>
    implements $PlayerStateCopyWith<$Res> {
  _$PlayerStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentSong = freezed,
    Object? isPlaying = null,
    Object? position = null,
    Object? bufferedPosition = null,
    Object? totalDuration = null,
    Object? processingState = null,
    Object? queue = null,
    Object? currentIndex = null,
    Object? isShuffleModeEnabled = null,
    Object? repeatMode = null,
  }) {
    return _then(_value.copyWith(
      currentSong: freezed == currentSong
          ? _value.currentSong
          : currentSong // ignore: cast_nullable_to_non_nullable
              as Song?,
      isPlaying: null == isPlaying
          ? _value.isPlaying
          : isPlaying // ignore: cast_nullable_to_non_nullable
              as bool,
      position: null == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as Duration,
      bufferedPosition: null == bufferedPosition
          ? _value.bufferedPosition
          : bufferedPosition // ignore: cast_nullable_to_non_nullable
              as Duration,
      totalDuration: null == totalDuration
          ? _value.totalDuration
          : totalDuration // ignore: cast_nullable_to_non_nullable
              as Duration,
      processingState: null == processingState
          ? _value.processingState
          : processingState // ignore: cast_nullable_to_non_nullable
              as AudioProcessingState,
      queue: null == queue
          ? _value.queue
          : queue // ignore: cast_nullable_to_non_nullable
              as List<Song>,
      currentIndex: null == currentIndex
          ? _value.currentIndex
          : currentIndex // ignore: cast_nullable_to_non_nullable
              as int,
      isShuffleModeEnabled: null == isShuffleModeEnabled
          ? _value.isShuffleModeEnabled
          : isShuffleModeEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      repeatMode: null == repeatMode
          ? _value.repeatMode
          : repeatMode // ignore: cast_nullable_to_non_nullable
              as AudioServiceRepeatMode,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $SongCopyWith<$Res>? get currentSong {
    if (_value.currentSong == null) {
      return null;
    }

    return $SongCopyWith<$Res>(_value.currentSong!, (value) {
      return _then(_value.copyWith(currentSong: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PlayerStateImplCopyWith<$Res>
    implements $PlayerStateCopyWith<$Res> {
  factory _$$PlayerStateImplCopyWith(
          _$PlayerStateImpl value, $Res Function(_$PlayerStateImpl) then) =
      __$$PlayerStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {Song? currentSong,
      bool isPlaying,
      Duration position,
      Duration bufferedPosition,
      Duration totalDuration,
      AudioProcessingState processingState,
      List<Song> queue,
      int currentIndex,
      bool isShuffleModeEnabled,
      AudioServiceRepeatMode repeatMode});

  @override
  $SongCopyWith<$Res>? get currentSong;
}

/// @nodoc
class __$$PlayerStateImplCopyWithImpl<$Res>
    extends _$PlayerStateCopyWithImpl<$Res, _$PlayerStateImpl>
    implements _$$PlayerStateImplCopyWith<$Res> {
  __$$PlayerStateImplCopyWithImpl(
      _$PlayerStateImpl _value, $Res Function(_$PlayerStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentSong = freezed,
    Object? isPlaying = null,
    Object? position = null,
    Object? bufferedPosition = null,
    Object? totalDuration = null,
    Object? processingState = null,
    Object? queue = null,
    Object? currentIndex = null,
    Object? isShuffleModeEnabled = null,
    Object? repeatMode = null,
  }) {
    return _then(_$PlayerStateImpl(
      currentSong: freezed == currentSong
          ? _value.currentSong
          : currentSong // ignore: cast_nullable_to_non_nullable
              as Song?,
      isPlaying: null == isPlaying
          ? _value.isPlaying
          : isPlaying // ignore: cast_nullable_to_non_nullable
              as bool,
      position: null == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as Duration,
      bufferedPosition: null == bufferedPosition
          ? _value.bufferedPosition
          : bufferedPosition // ignore: cast_nullable_to_non_nullable
              as Duration,
      totalDuration: null == totalDuration
          ? _value.totalDuration
          : totalDuration // ignore: cast_nullable_to_non_nullable
              as Duration,
      processingState: null == processingState
          ? _value.processingState
          : processingState // ignore: cast_nullable_to_non_nullable
              as AudioProcessingState,
      queue: null == queue
          ? _value._queue
          : queue // ignore: cast_nullable_to_non_nullable
              as List<Song>,
      currentIndex: null == currentIndex
          ? _value.currentIndex
          : currentIndex // ignore: cast_nullable_to_non_nullable
              as int,
      isShuffleModeEnabled: null == isShuffleModeEnabled
          ? _value.isShuffleModeEnabled
          : isShuffleModeEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      repeatMode: null == repeatMode
          ? _value.repeatMode
          : repeatMode // ignore: cast_nullable_to_non_nullable
              as AudioServiceRepeatMode,
    ));
  }
}

/// @nodoc

class _$PlayerStateImpl implements _PlayerState {
  const _$PlayerStateImpl(
      {this.currentSong,
      this.isPlaying = false,
      this.position = Duration.zero,
      this.bufferedPosition = Duration.zero,
      this.totalDuration = Duration.zero,
      this.processingState = AudioProcessingState.idle,
      final List<Song> queue = const [],
      this.currentIndex = 0,
      this.isShuffleModeEnabled = false,
      this.repeatMode = AudioServiceRepeatMode.none})
      : _queue = queue;

  @override
  final Song? currentSong;
  @override
  @JsonKey()
  final bool isPlaying;
  @override
  @JsonKey()
  final Duration position;
  @override
  @JsonKey()
  final Duration bufferedPosition;
  @override
  @JsonKey()
  final Duration totalDuration;
  @override
  @JsonKey()
  final AudioProcessingState processingState;
  final List<Song> _queue;
  @override
  @JsonKey()
  List<Song> get queue {
    if (_queue is EqualUnmodifiableListView) return _queue;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_queue);
  }

  @override
  @JsonKey()
  final int currentIndex;
  @override
  @JsonKey()
  final bool isShuffleModeEnabled;
  @override
  @JsonKey()
  final AudioServiceRepeatMode repeatMode;

  @override
  String toString() {
    return 'PlayerState(currentSong: $currentSong, isPlaying: $isPlaying, position: $position, bufferedPosition: $bufferedPosition, totalDuration: $totalDuration, processingState: $processingState, queue: $queue, currentIndex: $currentIndex, isShuffleModeEnabled: $isShuffleModeEnabled, repeatMode: $repeatMode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlayerStateImpl &&
            (identical(other.currentSong, currentSong) ||
                other.currentSong == currentSong) &&
            (identical(other.isPlaying, isPlaying) ||
                other.isPlaying == isPlaying) &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.bufferedPosition, bufferedPosition) ||
                other.bufferedPosition == bufferedPosition) &&
            (identical(other.totalDuration, totalDuration) ||
                other.totalDuration == totalDuration) &&
            (identical(other.processingState, processingState) ||
                other.processingState == processingState) &&
            const DeepCollectionEquality().equals(other._queue, _queue) &&
            (identical(other.currentIndex, currentIndex) ||
                other.currentIndex == currentIndex) &&
            (identical(other.isShuffleModeEnabled, isShuffleModeEnabled) ||
                other.isShuffleModeEnabled == isShuffleModeEnabled) &&
            (identical(other.repeatMode, repeatMode) ||
                other.repeatMode == repeatMode));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      currentSong,
      isPlaying,
      position,
      bufferedPosition,
      totalDuration,
      processingState,
      const DeepCollectionEquality().hash(_queue),
      currentIndex,
      isShuffleModeEnabled,
      repeatMode);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PlayerStateImplCopyWith<_$PlayerStateImpl> get copyWith =>
      __$$PlayerStateImplCopyWithImpl<_$PlayerStateImpl>(this, _$identity);
}

abstract class _PlayerState implements PlayerState {
  const factory _PlayerState(
      {final Song? currentSong,
      final bool isPlaying,
      final Duration position,
      final Duration bufferedPosition,
      final Duration totalDuration,
      final AudioProcessingState processingState,
      final List<Song> queue,
      final int currentIndex,
      final bool isShuffleModeEnabled,
      final AudioServiceRepeatMode repeatMode}) = _$PlayerStateImpl;

  @override
  Song? get currentSong;
  @override
  bool get isPlaying;
  @override
  Duration get position;
  @override
  Duration get bufferedPosition;
  @override
  Duration get totalDuration;
  @override
  AudioProcessingState get processingState;
  @override
  List<Song> get queue;
  @override
  int get currentIndex;
  @override
  bool get isShuffleModeEnabled;
  @override
  AudioServiceRepeatMode get repeatMode;
  @override
  @JsonKey(ignore: true)
  _$$PlayerStateImplCopyWith<_$PlayerStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
