import 'dart:async';
import 'dart:developer';

import 'package:fukatsongs/services/player/player_engine.dart';
import 'package:fukatsongs/services/db/dao/playlist_dao.dart';
import 'package:fukatsongs/services/db/dao/track_dao.dart';
import 'package:fukatsongs/services/db/db_provider.dart';

import 'play_accumulator.dart';

/// Separate from RecentlyPlayedTracker. Never changes global history thresholds.
class PlaylistPlayTracker {
  PlaylistPlayTracker(this.engine, {required this.isLoopOne}) {
    _timer = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => _sample(),
    );
  }
  final PlayerEngine engine;
  final bool Function() isLoopOne;
  final _clock = Stopwatch()..start();
  late final Timer _timer;
  PlayAccumulator _counter = PlayAccumulator();
  int? _playlistId;
  String? _mediaId;
  bool _opened = false;
  int? _lastLoopPosition;
  int _durationMs = 0;
  double _lastSpeed = 1;

  void begin(int? playlistId, String mediaId, {bool preserveAttempt = false}) {
    if (!preserveAttempt || _playlistId != playlistId || _mediaId != mediaId) {
      _counter = PlayAccumulator();
      _durationMs = 0;
    }
    _playlistId = playlistId;
    _mediaId = mediaId;
    _opened = false;
    _counter.gap();
    _lastLoopPosition = null;
  }

  void openSucceeded() {
    _opened = true;
    _counter.gap();
  }

  void seeked() {
    _counter.seeked();
    _lastLoopPosition = null;
  }

  void end() {
    _opened = false;
    _counter.gap();
    _lastLoopPosition = null;
  }

  void _sample() {
    if (!_opened || _playlistId == null || _mediaId == null) {
      _counter.gap();
      return;
    }
    final position = engine.position.inMilliseconds;
    final duration = engine.duration.inMilliseconds;
    if (duration > 0) _durationMs = duration;
    _lastSpeed = engine.speed;
    final progressing = engine.playing && engine.state == EngineState.ready;
    final previous = _lastLoopPosition;
    // Repeat-one is performed internally by the engine, without completionStream.
    // Explicit seeks clear this evidence through seeked().
    if (progressing &&
        isLoopOne() &&
        previous != null &&
        _durationMs > 2000 &&
        previous >= _durationMs - 1500 &&
        position < 1500 &&
        previous - position > 1000) {
      if (_counter.completeShort(durationMs: _durationMs, speed: _lastSpeed))
        _record();
      _counter = PlayAccumulator();
    }
    _lastLoopPosition = progressing ? position : null;
    if (_counter.sample(
      nowMs: _clock.elapsedMilliseconds,
      positionMs: position,
      playing: progressing,
      speed: _lastSpeed,
    ))
      _record();
  }

  void completed() {
    if (!_opened) return;
    if (_counter.completeShort(durationMs: _durationMs, speed: _lastSpeed))
      _record();
    end();
  }

  void _record() {
    // Capture origin before awaiting: next-track/UI changes cannot redirect count.
    final playlistId = _playlistId;
    final mediaId = _mediaId;
    if (playlistId == null || mediaId == null) return;
    unawaited(_persist(playlistId, mediaId));
  }

  Future<void> _persist(int playlistId, String mediaId) async {
    try {
      await PlaylistDAO(
        DBProvider.db,
        TrackDAO(DBProvider.db),
      ).recordPlaylistPlay(playlistId, mediaId);
    } catch (error, stack) {
      log(
        'Could not record playlist play: $error',
        name: 'PlaylistPlayTracker',
        stackTrace: stack,
      );
    }
  }

  void dispose() {
    _timer.cancel();
    _clock.stop();
    end();
  }
}
