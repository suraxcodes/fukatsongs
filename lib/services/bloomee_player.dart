import 'dart:developer';
import 'dart:async';
import 'dart:convert';
import 'dart:io' show exit;

import 'package:flutter/services.dart';
import 'package:fukatsongs/core/adapters/track_adapter.dart';
import 'package:fukatsongs/core/models/exported.dart' hide MediaItem;
import 'package:fukatsongs/core/models/media_playlist_model.dart';
import 'package:fukatsongs/core/constants/sentinel_values.dart';
import 'package:fukatsongs/core/constants/setting_keys.dart';
import 'package:fukatsongs/core/di/service_locator.dart';
import 'package:fukatsongs/plugins/utils/media_id.dart';
import 'package:fukatsongs/plugins/errors/plugin_exceptions.dart';
import 'package:fukatsongs/screens/widgets/snackbar.dart';
import 'package:fukatsongs/services/db/db_provider.dart';
import 'package:fukatsongs/services/db/dao/settings_dao.dart';
import 'package:fukatsongs/services/player/media_resolver_service.dart';
import 'package:fukatsongs/services/player/player_engine.dart';
import 'package:fukatsongs/services/player/player_error_handler.dart';
import 'package:fukatsongs/services/player/queue_manager.dart';
import 'package:fukatsongs/services/player/related_songs_manager.dart';
import 'package:fukatsongs/services/player/recently_played_tracker.dart';
import 'package:fukatsongs/services/plugin/plugin_service.dart';
import 'package:fukatsongs/services/meta_resolver/smart_track_replacement_service.dart';
import 'package:fukatsongs/services/discord_service.dart';
import 'package:fukatsongs/services/dynamic_island_service.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:async/async.dart';
import 'package:easy_debounce/easy_throttle.dart';
import 'package:rxdart/rxdart.dart';
import 'package:fukatsongs/services/audio_service_initializer.dart';

/// FukatMusic main audio player.
///
/// Extends [BaseAudioHandler] so the OS MediaSession contract is satisfied:
/// the notification, headset buttons, lock screen, and Android Auto all work
/// correctly without any extra native code.
///
/// ## Volume Architecture
///
/// All user-visible volume is controlled via `AudioManager.STREAM_MUSIC`
/// through the `com.fukatsongs.app/voice_service` method channel. The
/// media_kit engine volume is pinned to 1.0 forever (see
/// audio_service_initializer.dart) so effective_loudness == system_volume.
/// This guarantees:
///   - Voice commands, hardware buttons, and the in-app slider all agree.
///   - Ducking (navigation, notifications) changes what the user sees.
///   - No mismatch between the Android volume UI and actual sound level.
class BloomeeMusicPlayer extends BaseAudioHandler
    with SeekHandler, QueueHandler {
  late PlayerEngine engine;

  late PlayerErrorHandler _errorHandler;
  late QueueManager _queueManager;
  late RelatedSongsManager _relatedSongsManager;
  late RecentlyPlayedTracker _recentlyPlayedTracker;
  late MediaResolverService _resolver;
  late SmartTrackReplacementService _smartTrackReplacementService;

  static final MediaControl _shuffleControlOn = MediaControl.custom(
    androidIcon: 'drawable/ic_shuffle_on',
    label: 'Disable Shuffle',
    name: 'Disable Shuffle',
  );

  static final MediaControl _shuffleControlOff = MediaControl.custom(
    androidIcon: 'drawable/ic_shuffle',
    label: 'Enable Shuffle',
    name: 'Enable Shuffle',
  );

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'Disable Shuffle') {
      await shuffle(false);
    } else if (name == 'Enable Shuffle') {
      await shuffle(true);
    }
    return super.customAction(name, extras);
  }

  BehaviorSubject<bool> fromPlaylist = BehaviorSubject<bool>.seeded(false);
  BehaviorSubject<bool> isOffline = BehaviorSubject<bool>.seeded(false);
  BehaviorSubject<LoopMode> loopMode =
      BehaviorSubject<LoopMode>.seeded(LoopMode.off);
  BehaviorSubject<bool> isResolving = BehaviorSubject<bool>.seeded(false);

  bool _isDisposed = false;

  /// True once the OS asked us to tear down (task removed / notification
  /// deleted). Prevents revive() + event callbacks from restarting playback.
  bool _teardownStarted = false;

  /// Read by PlayerInitializer to decide rebuild-vs-reuse.
  bool get isDisposed => _isDisposed;

  CancelableCompleter<void>? _playCompleter;
  CancelableOperation<ResolvedMediaSource>? _preResolveOp;
  CancelableOperation<(Track, ResolvedMediaSource)>? _currentResolveOp;
  bool _isAdvancing = false;

  String? _preloadedTrackId;
  bool _preloadedTrackOffline = false;

  StreamSubscription? _engineStateSub;
  StreamSubscription? _completionSub;
  StreamSubscription? _errorSub;
  StreamSubscription? _queueSyncSub;
  StreamSubscription? _positionSuccessSub;
  StreamSubscription<AudioInterruptionEvent>? _audioInterruptionSub;
  StreamSubscription<void>? _audioNoisySub;
  StreamSubscription<Duration>? _durationSub;
  Timer? _relatedSongTimer;

  // ── Audio session state ──────────────────────────────────────────────────
  AudioSession? _audioSession;
  bool _shouldResumeAfterInterruption = false;

  // ── System media volume state ────────────────────────────────────────────
  //
  // All user-visible volume is STREAM_MUSIC. media_kit engine stays at 1.0.
  static const MethodChannel _voiceChannel =
      MethodChannel('com.fukatsongs.app/voice_service');
  double _cachedSystemVolume = 1.0;
  Timer? _systemVolumePollTimer;

  /// Pre-duck system volume, restored when the duck ends.
  double? _duckRestoreVolume;

  Future<double> _readSystemVolume() async {
    try {
      return await _voiceChannel.invokeMethod<double>('getMediaVolume') ?? 1.0;
    } catch (_) {
      return 1.0;
    }
  }

  Future<void> _setSystemVolumeSilent(double v) async {
    try {
      await _voiceChannel.invokeMethod(
          'duckMediaVolume', {'fraction': v.clamp(0.0, 1.0)});
    } catch (_) {}
  }

  void _startSystemVolumePoll() {
    _systemVolumePollTimer?.cancel();
    _systemVolumePollTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) async {
        final v = await _readSystemVolume();
        _cachedSystemVolume = v;
      },
    );
  }

  Duration _savedPositionForRevive = Duration.zero;

  BehaviorSubject<bool> get shuffleMode => _queueManager.shuffleMode;
  BehaviorSubject<PlayerError?> get lastError => _errorHandler.lastError;
  BehaviorSubject<List<Track>> get relatedSongs =>
      _relatedSongsManager.relatedSongs;

  @override
  BehaviorSubject<String> get queueTitle => _queueManager.queueTitle;

  Track _currentTrack = trackNull;
  Track get currentTrackInfo => _currentTrack;
  List<Track> get queueTracks => List<Track>.unmodifiable(_queueManager.tracks);
  int get currentQueueIndex => _queueManager.currentIndex;
  PluginService get pluginService => ServiceLocator.pluginService;

  // ─── Constructor ─────────────────────────────────────────────────────────

  BloomeeMusicPlayer() {
    _initEngine();
    _initModules();
    _initSubscriptions();
    _setupInterruptionListeners();
    _startSystemVolumePoll();
    _restoreEngineSettings();
    _restoreLastSession();
  }

  Future<void> _restoreLastSession() async {
    if (_isDisposed) return;
    try {
      final restored = await _queueManager.restoreQueueState();
      if (_isDisposed) return;
      if (restored) {
        final track = _queueManager.currentTrack;
        if (track != null) {
          _updateCurrentTrack(track);
        }
      }
    } catch (e) {
      log('Session restore failed: $e', name: 'BloomeeMusicPlayer');
    }
  }

  void _initEngine() {
    _isDisposed = false;
    engine = PlayerEngine();
  }

  void _setupInterruptionListeners() {
    AudioSession.instance.then((session) {
      if (_isDisposed) return;
      _audioSession = session;

      _audioInterruptionSub?.cancel();
      _audioNoisySub?.cancel();

      _audioInterruptionSub =
          session.interruptionEventStream.listen(_handleInterruptionSync);

      _audioNoisySub = session.becomingNoisyEventStream
          .listen((_) => _onHeadphonesUnplugged());
    });
  }

  // ─── Interruption Handler ────────────────────────────────────────────────
  //
  // Synchronous — per audio_session official example. Ducking changes the
  // SYSTEM media volume (not the engine), preserving the "engine = 1.0"
  // invariant that makes voice / hardware / in-app volume all agree.

  void _handleInterruptionSync(AudioInterruptionEvent event) {
    if (_isDisposed || _teardownStarted) return;

    if (event.begin) {
      if (ServiceLocator.voiceCommandService.isListening.value) {
        return;
      }
      switch (event.type) {
        case AudioInterruptionType.duck:
          _duckRestoreVolume ??= _cachedSystemVolume;
          unawaited(_setSystemVolumeSilent(_cachedSystemVolume * 0.35));
          break;

        case AudioInterruptionType.pause:
        case AudioInterruptionType.unknown:
          _shouldResumeAfterInterruption = engine.playing;
          engine.pause();
          break;
      }
      return;
    }

    // — Interruption ended —
    switch (event.type) {
      case AudioInterruptionType.duck:
        final restoreTo = _duckRestoreVolume;
        _duckRestoreVolume = null;
        if (restoreTo != null) {
          final expectedDucked = restoreTo * 0.35;
          final userIntervened =
              (_cachedSystemVolume - expectedDucked).abs() > 0.05;
          if (!userIntervened) {
            unawaited(_setSystemVolumeSilent(restoreTo));
          }
        }
        break;

      case AudioInterruptionType.pause:
        if (_shouldResumeAfterInterruption) {
          _shouldResumeAfterInterruption = false;
          _resumePlaybackAfterInterruption();
        }
        break;

      case AudioInterruptionType.unknown:
        _shouldResumeAfterInterruption = false;
        break;
    }
  }

  void _resumePlaybackAfterInterruption() {
    _activateAudioSession().then((granted) {
      if (granted && !_isDisposed && !_teardownStarted) engine.play();
    }).catchError((Object e) {
      log('Resume after interruption failed: $e', name: 'BloomeeMusicPlayer');
    });
  }

  void _onHeadphonesUnplugged() {
    if (!_isDisposed && !_teardownStarted) engine.pause();
  }

  // ─── Audio Session Activation ────────────────────────────────────────────

  Future<bool> _activateAudioSession() async {
    try {
      final session = _audioSession ?? await AudioSession.instance;
      _audioSession = session;
      return await session.setActive(true);
    } catch (e) {
      log('setActive(true) failed: $e', name: 'BloomeeMusicPlayer');
      return false;
    }
  }

  Future<void> _deactivateAudioSession() async {
    try {
      await _audioSession?.setActive(false);
    } catch (_) {}
  }

  // ─── Engine Settings Restore ─────────────────────────────────────────────

  Future<void> _restoreEngineSettings() async {
    try {
      final dao = SettingsDAO(DBProvider.db);

      final cfStr = await dao.getSettingStr(SettingKeys.crossfadeDuration);
      engine.crossfadeDuration =
          Duration(seconds: int.tryParse(cfStr ?? '0') ?? 0);

      final eqSource = await dao.getSettingStr(SettingKeys.eqSource);
      if (eqSource == EqSourceValues.device) {
        await engine.setEqualizerEnabled(false);
        return;
      }

      final gainsJson = await dao.getSettingStr(SettingKeys.eqBandGains);
      if (gainsJson != null) {
        try {
          final gains = (jsonDecode(gainsJson) as List)
              .map((e) => (e as num).toDouble())
              .toList();
          if (gains.length == 10) {
            await engine.setEqualizerBandGains(gains, immediate: true);
          }
        } catch (_) {}
      }

      final eqOn = await dao.getSettingBool(SettingKeys.eqEnabled) ?? false;
      await engine.setEqualizerEnabled(eqOn);
    } catch (e) {
      log('restoreEngineSettings failed: $e', name: 'BloomeeMusicPlayer');
    }
  }

  // ─── Module Init ─────────────────────────────────────────────────────────

  void _initModules() {
    _errorHandler = PlayerErrorHandler();
    _queueManager = QueueManager();
    _relatedSongsManager = RelatedSongsManager(ServiceLocator.pluginService);
    _resolver = MediaResolverService.create(ServiceLocator.pluginService);
    _smartTrackReplacementService =
        SmartTrackReplacementService.create(ServiceLocator.pluginService);

    _errorHandler.onSkipToNext = _internalSkipToNext;
    _errorHandler.onRetryCurrentTrack = _retryCurrentTrack;
    _errorHandler.onStopPlayback = () async {
      _playCompleter?.operation.cancel();
      _playCompleter = null;
      _currentResolveOp?.cancel();
      _preResolveOp?.cancel();
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.error,
        playing: false,
      ));
      await engine.stop();
      DiscordService.clearPresence();
    };

    _relatedSongsManager.onAddQueueItems =
        (items, {bool atLast = false}) => addQueueTracks(items, atLast: atLast);

    _recentlyPlayedTracker = RecentlyPlayedTracker(
      engine,
      () => _queueManager.currentTrack,
    );
  }

  // ─── Subscriptions ───────────────────────────────────────────────────────

  void _initSubscriptions() {
    _engineStateSub = Rx.combineLatest4(
      engine.stateStream,
      engine.playingStream,
      engine.bufferedStream,
      engine.speedStream,
      (s, pl, buf, spd) => (s, pl, buf, spd),
    ).distinct().listen((r) {
      final (s, pl, buf, spd) = r;
      _broadcastPlaybackState(s, pl, engine.position, buf, spd);
    });

    _positionSuccessSub = engine.positionStream.listen((pos) {
      if (pos > Duration.zero &&
          engine.state == EngineState.ready &&
          engine.playing) {
        final track = _queueManager.currentTrack;
        if (track != null) _errorHandler.markTrackSuccess(track.id);
      }

      EasyThrottle.throttle('sync_position_notification',
          const Duration(seconds: 1), () {
        if (!engine.playing) return;
        _broadcastPlaybackState(
          engine.state,
          engine.playing,
          engine.position,
          engine.buffered,
          engine.speed,
        );
      });
    });

    _completionSub = engine.completionStream.listen((_) => _onTrackCompleted());

    _durationSub = engine.durationStream.listen((dur) {
      if (dur > Duration.zero) {
        final currentItem = mediaItem.value;
        if (currentItem != null && currentItem.duration != dur) {
          mediaItem.add(currentItem.copyWith(duration: dur));
        }
      }
    });

    _queueManager.shuffleMode.listen((_) => syncPublicState());

    _errorSub = engine.errorStream.listen((error) {
      log('Engine error: $error', name: 'BloomeeMusicPlayer');
      final track = _queueManager.currentTrack;
      if (track != null) {
        _errorHandler.handleError(PlayerErrorType.playbackError, error, track);
      }
    });

    _queueSyncSub = _queueManager.tracksStream.listen((tracks) {
      queue.add(tracks.map(trackToMediaItem).toList());
      if (_queueManager.isRestoring) return;
      EasyThrottle.throttle(
        'persist_queue',
        const Duration(seconds: 2),
        () => unawaited(_queueManager.persistQueueState()),
      );
    });

    _relatedSongTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!_isDisposed && engine.playing) _checkRelatedSongs();
    });
  }

  // ─── Playback State Broadcast ────────────────────────────────────────────

  void _broadcastPlaybackState(EngineState state, bool playing,
      Duration position, Duration buffered, double speed) {
    final processingState = switch (state) {
      EngineState.idle => AudioProcessingState.idle,
      EngineState.loading => AudioProcessingState.loading,
      EngineState.buffering => AudioProcessingState.buffering,
      EngineState.ready => AudioProcessingState.ready,
      EngineState.completed => AudioProcessingState.completed,
      EngineState.error => AudioProcessingState.error,
    };

    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        playing ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
        shuffleMode.value ? _shuffleControlOn : _shuffleControlOff,
      ],
      processingState: processingState,
      systemActions: const {
        MediaAction.skipToPrevious,
        MediaAction.playPause,
        MediaAction.skipToNext,
        MediaAction.seek,
        MediaAction.setShuffleMode,
      },
      androidCompactActionIndices: const [1, 2, 3],
      updatePosition: position,
      updateTime: DateTime.now(),
      playing: playing,
      bufferedPosition: buffered,
      speed: speed,
      shuffleMode: shuffleMode.value
          ? AudioServiceShuffleMode.all
          : AudioServiceShuffleMode.none,
    ));

    EasyThrottle.throttle('discord_rpc', const Duration(seconds: 1), () {
      DiscordService.updatePresence(
          track: currentTrackInfo, isPlaying: playing);
    });
  }

  Track get currentMedia => _queueManager.currentTrack ?? trackNull;

  void _updateCurrentTrack(Track track) {
    _currentTrack = track;
    mediaItem.add(trackToMediaItem(track));
  }

  // ─── Public Playback Controls ────────────────────────────────────────────

  @override
  Future<void> play() async {
    if (_isDisposed) return;

    _broadcastPlaybackState(
      engine.state,
      engine.playing,
      engine.position,
      engine.buffered,
      engine.speed,
    );

    _errorHandler.resetCircuitBreaker();
    _shouldResumeAfterInterruption = false;
    final granted = await _activateAudioSession();
    if (!granted) {
      SnackbarService.showMessage('Audio focus denied. Cannot start playback.');
      return;
    }
    if (engine.state == EngineState.idle) {
      final track = _queueManager.currentTrack;
      if (track != null) {
        await _enqueuePlayTrack(track, doPlay: true);
        return;
      }
    }
    await engine.play();
  }

  @override
  Future<void> pause() async {
    if (_isDisposed) return;
    _shouldResumeAfterInterruption = false;
    await engine.pause();
  }

  @override
  Future<void> seek(Duration position) async {
    if (_isDisposed) return;
    await engine.seek(position);
  }

  Future<void> seekNSecForward(Duration n) async {
    if (_isDisposed) return;
    final dur = engine.duration;
    await engine.seek(engine.position + n > dur ? dur : engine.position + n);
  }

  Future<void> seekNSecBackward(Duration n) async {
    if (_isDisposed) return;
    final back = engine.position - n;
    await engine.seek(back < Duration.zero ? Duration.zero : back);
  }

  @override
  Future<void> stop() async {
    _errorHandler.resetCircuitBreaker();
    _shouldResumeAfterInterruption = false;
    _playCompleter?.operation.cancel();
    _playCompleter = null;
    _preResolveOp?.cancel();
    _currentResolveOp?.cancel();
    // Single idle emission: this is what makes audio_service drop the
    // foreground service and remove the media notification.
    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.idle,
      playing: false,
    ));
    await engine.stop();
    await _deactivateAudioSession();
    DiscordService.clearPresence();
    try {
      await DynamicIslandService.closeDynamicIsland();
    } catch (_) {}
    // NOTE: intentionally NO super.stop() here (was a duplicate idle).
  }

  @override
  Future<void> rewind() async {
    if (_isDisposed) return;
    if (engine.state == EngineState.ready ||
        engine.state == EngineState.buffering) {
      await engine.seek(Duration.zero);
    } else if (engine.state == EngineState.completed) {
      final track = _queueManager.currentTrack;
      if (track != null) await _enqueuePlayTrack(track, doPlay: true);
    }
  }

  // ─── Loop / Shuffle ──────────────────────────────────────────────────────

  void setLoopMode(LoopMode mode) {
    loopMode.add(mode);
    engine.setLoopMode(mode);
  }

  void setCrossfadeDuration(Duration duration) {
    engine.crossfadeDuration = duration;
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final enabled = shuffleMode == AudioServiceShuffleMode.all;
    await shuffle(enabled);
  }

  Future<void> shuffle(bool enabled) async {
    _queueManager.shuffle(enabled);
  }

  // ─── Core Play Dispatch ──────────────────────────────────────────────────

  void _clearPreloadedMarker() {
    _preloadedTrackId = null;
    _preloadedTrackOffline = false;
  }

  Future<void> _enqueuePlayTrack(
    Track track, {
    bool doPlay = true,
    Duration? initialPosition,
  }) {
    if (_isDisposed) return Future.value();

    final prev = _playCompleter;
    final completer = CancelableCompleter<void>(
      onCancel: () => log('Track load cancelled: ${track.title}',
          name: 'BloomeeMusicPlayer'),
    );
    _playCompleter = completer;
    prev?.operation.cancel();

    _doPlay(track, completer, doPlay: doPlay, initialPosition: initialPosition);
    return completer.operation.valueOrCancellation().then((_) {});
  }

  Future<void> _doPlay(
    Track track,
    CancelableCompleter<void> token, {
    bool doPlay = true,
    Duration? initialPosition,
  }) async {
    bool alive() => !token.isCanceled && !_isDisposed;
    void complete() {
      if (!token.isCompleted && !token.isCanceled) token.complete();
    }

    if (!alive()) return;

    var resolvedTrack = track;
    final canUsePreloaded = engine.isPreloaded &&
        _preloadedTrackId != null &&
        _preloadedTrackId == track.id;

    try {
      _updateCurrentTrack(track);

      if (doPlay) {
        final granted = await _activateAudioSession();
        if (!alive()) return;
        if (!granted) {
          SnackbarService.showMessage(
              'Audio focus denied. Cannot start playback.');
          return complete();
        }
      }

      _currentResolveOp?.cancel();
      engine.setLoadingState();
      isResolving.add(true);

      EngineResult result;

      if (canUsePreloaded) {
        isOffline.add(_preloadedTrackOffline);
        result = engine.crossfadeDuration > Duration.zero
            ? await engine.crossfadeToPreloaded(engine.crossfadeDuration)
            : await engine.activatePreloaded(autoPlay: doPlay);
        _clearPreloadedMarker();
      } else {
        await engine.stop(keepLoadingState: true);
        if (!alive()) return;

        _currentResolveOp = CancelableOperation.fromFuture(
          _resolveWithFallback(track).timeout(const Duration(seconds: 15)),
        );
        final resolved = await _currentResolveOp!.valueOrCancellation();
        if (resolved == null || !alive()) return;

        resolvedTrack = resolved.$1;
        if (resolvedTrack.id != track.id) _updateCurrentTrack(resolvedTrack);
        isOffline.add(resolved.$2.isOffline);

        result = await engine.openDirect(
          resolved.$2.uri,
          httpHeaders: resolved.$2.headers,
          autoPlay: doPlay,
        );
      }

      if (!alive()) return;

      if (result is EngineFailure) {
        isResolving.add(false);
        _errorHandler.handleError(
          _errorHandler.categorizeError(result.error),
          result.error.toString(),
          resolvedTrack,
          result.error,
        );
        return complete();
      }

      if (initialPosition != null && initialPosition > Duration.zero) {
        await engine.seek(initialPosition);
      }

      isResolving.add(false);
      _errorHandler.clearError();
      _preResolveNextTrack();
      _checkRelatedSongs();
      complete();
    } on TimeoutException catch (e) {
      isResolving.add(false);
      if (!alive()) return;
      _errorHandler.handleError(
          PlayerErrorType.networkDropped, 'Network timeout', track, e);
      complete();
    } catch (e, stack) {
      isResolving.add(false);
      if (!alive()) return;
      log('Play failed: ${track.title}: $e',
          name: 'BloomeeMusicPlayer', stackTrace: stack);
      _errorHandler.handleError(
          _errorHandler.categorizeError(e), e.toString(), resolvedTrack, e);
      complete();
    }
  }

  Future<(Track, ResolvedMediaSource)> _resolveWithFallback(Track track) async {
    try {
      return (track, await _resolver.resolve(track));
    } catch (e) {
      final replacement = await _tryAutoReplace(track, e);
      if (replacement == null) rethrow;
      return (replacement, await _resolver.resolve(replacement));
    }
  }

  Future<Track?> _tryAutoReplace(Track track, Object error) async {
    if (!_isAutoResolvableError(error) || isLocalMediaId(track.id)) return null;
    final enabled = await SettingsDAO(DBProvider.db)
        .getSettingBool(SettingKeys.autoResolveUnavailableTracks);
    if (enabled == false) return null;
    final candidate =
        await _smartTrackReplacementService.findBestReplacement(track);
    if (candidate == null) return null;
    SnackbarService.showMessage(
      'Playing fallback source for ${track.title} from ${candidate.pluginName}.',
      duration: const Duration(seconds: 3),
    );
    return candidate.track;
  }

  bool _isAutoResolvableError(Object error) {
    if (error is PluginNotLoadedException || error is PluginNotFoundException) {
      return true;
    }
    final msg = error.toString().toLowerCase();
    return msg.contains('no streams returned') ||
        msg.contains('plugin is not loaded') ||
        msg.contains('plugin not found');
  }

  // ─── Preload ─────────────────────────────────────────────────────────────

  void _preResolveNextTrack() {
    final next = _queueManager.peekNext(loopMode: loopMode.value);
    if (next == null) {
      _clearPreloadedMarker();
      engine.clearPreload(); // ignore: discarded_futures
      return;
    }

    final expectedId = next.id;
    _preResolveOp?.cancel();
    _preResolveOp = CancelableOperation.fromFuture(_resolver.resolve(next));
    _preResolveOp!.value.then((resolved) async {
      if (_isDisposed) return;
      if (_queueManager.peekNext(loopMode: loopMode.value)?.id != expectedId) {
        _clearPreloadedMarker();
        engine.clearPreload(); // ignore: discarded_futures
        return;
      }
      final ok =
          await engine.preloadNext(resolved.uri, httpHeaders: resolved.headers);
      if (!_isDisposed && ok) {
        _preloadedTrackId = expectedId;
        _preloadedTrackOffline = resolved.isOffline;
      }
    }).catchError((Object _) {
      _clearPreloadedMarker();
      engine.clearPreload(); // ignore: discarded_futures
    });
  }

  // ─── Completion / Auto-Next ──────────────────────────────────────────────

  void _onTrackCompleted() {
    if (_isDisposed || _teardownStarted || loopMode.value == LoopMode.one || _isAdvancing) return;
    _isAdvancing = true;
    Future.microtask(() async {
      try {
        final advanced = _queueManager.advanceToNext(loopMode: loopMode.value);
        if (advanced) {
          final next = _queueManager.currentTrack;
          if (next != null) await _enqueuePlayTrack(next, doPlay: true);
        } else {
          await engine.stop();
        }
      } finally {
        _isAdvancing = false;
      }
    });
  }

  Future<void> _retryCurrentTrack() async {
    final track = _queueManager.currentTrack;
    if (track == null) return;
    _errorHandler.clearError();
    await _enqueuePlayTrack(track,
        doPlay: true, initialPosition: engine.position);
  }

  // ─── Related Songs ───────────────────────────────────────────────────────

  bool _checkingRelated = false;

  Future<void> _checkRelatedSongs() async {
    if (_checkingRelated) return;
    _checkingRelated = true;
    try {
      final track = _queueManager.currentTrack;
      if (track == null) return;
      await _relatedSongsManager.checkForRelatedSongs(
        currentMedia: track,
        queue: _queueManager.tracks,
        currentPlayingIdx: _queueManager.currentIndex,
        loopMode: loopMode.value,
      );
    } finally {
      _checkingRelated = false;
    }
  }

  Future<void> check4RelatedSongs() => _checkRelatedSongs();

  // ─── Player Health ───────────────────────────────────────────────────────

  bool get isPlayerHealthy {
    if (_isDisposed) return false;
    if (fromPlaylist.isClosed ||
        isOffline.isClosed ||
        loopMode.isClosed ||
        isResolving.isClosed) {
      return false;
    }
    try {
      final _ = engine.state;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> revive() async {
    // A handler torn down by the OS is permanently dead.
    if (_teardownStarted) return;
    if (!_isDisposed && isPlayerHealthy) return;
    log('Reviving BloomeeMusicPlayer...', name: 'BloomeeMusicPlayer');

    _systemVolumePollTimer?.cancel();
    _systemVolumePollTimer = null;
    _duckRestoreVolume = null;

    try {
      _savedPositionForRevive = engine.position;
    } catch (_) {}

    if (fromPlaylist.isClosed) {
      fromPlaylist = BehaviorSubject<bool>.seeded(false);
    }
    if (isOffline.isClosed) isOffline = BehaviorSubject<bool>.seeded(false);
    if (loopMode.isClosed) {
      loopMode = BehaviorSubject<LoopMode>.seeded(LoopMode.off);
    }
    if (isResolving.isClosed) isResolving = BehaviorSubject<bool>.seeded(false);

    _shouldResumeAfterInterruption = false;

    _initEngine();
    _initModules();
    _initSubscriptions();
    _setupInterruptionListeners();
    _startSystemVolumePoll();
    _restoreEngineSettings();
    _isDisposed = false;

    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.idle,
      playing: false,
    ));

    final track = _queueManager.currentTrack;
    if (track != null) {
      Future.delayed(const Duration(milliseconds: 200), () async {
        if (!_isDisposed) {
          await _enqueuePlayTrack(track,
              doPlay: false, initialPosition: _savedPositionForRevive);
        }
      });
    }
  }

  void syncPublicState() {
    if (_isDisposed) return;
    queue.add(_queueManager.tracks.map(trackToMediaItem).toList());
    final current = _queueManager.currentTrack;
    if (current != null) _updateCurrentTrack(current);
    _broadcastPlaybackState(
      engine.state,
      engine.playing,
      engine.position,
      engine.buffered,
      engine.speed,
    );
  }

  Future<void> replaceTrackInQueue(Track replacement) async {
    if (_isDisposed) return;
    final changed = _queueManager.replaceTrackById(replacement.id, replacement);
    if (!changed) return;
    if (_currentTrack.id == replacement.id) _updateCurrentTrack(replacement);
  }

  // ─── Queue Operations ────────────────────────────────────────────────────

  @override
  Future<void> playMediaItem(MediaItem mi,
      {bool doPlay = true, Duration? initialPosition}) async {
    _errorHandler.resetCircuitBreaker();
    _shouldResumeAfterInterruption = false;
    await _enqueuePlayTrack(mediaItemToTrack(mi),
        doPlay: doPlay, initialPosition: initialPosition);
  }

  @override
  Future<void> skipToNext() async {
    _errorHandler.resetCircuitBreaker();
    _shouldResumeAfterInterruption = false;
    await _internalSkipToNext();
  }

  Future<void> _internalSkipToNext() async {
    _isAdvancing = true;
    try {
      final advanced = _queueManager.advanceToNext(loopMode: loopMode.value);
      if (advanced) {
        final next = _queueManager.currentTrack;
        if (next != null) await _enqueuePlayTrack(next, doPlay: true);
      } else {
        _playCompleter?.operation.cancel();
        _playCompleter = null;
        _currentResolveOp?.cancel();
        await engine.stop();
      }
    } finally {
      _isAdvancing = false;
    }
  }

  @override
  Future<void> skipToPrevious() async {
    _errorHandler.resetCircuitBreaker();
    _shouldResumeAfterInterruption = false;
    await _internalSkipToPrevious();
  }

  Future<void> _internalSkipToPrevious() async {
    _isAdvancing = true;
    try {
      final advanced =
          _queueManager.advanceToPrevious(loopMode: loopMode.value);
      if (advanced) {
        final prev = _queueManager.currentTrack;
        if (prev != null) await _enqueuePlayTrack(prev, doPlay: true);
      } else {
        _playCompleter?.operation.cancel();
        _playCompleter = null;
        await engine.stop();
      }
    } finally {
      _isAdvancing = false;
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    _errorHandler.resetCircuitBreaker();
    _shouldResumeAfterInterruption = false;
    _isAdvancing = true;
    try {
      _queueManager.jumpTo(index);
      final track = _queueManager.currentTrack;
      if (track != null) await _enqueuePlayTrack(track, doPlay: true);
    } finally {
      _isAdvancing = false;
    }
  }

  Future<void> loadPlaylist(
    Playlist playlist, {
    int idx = 0,
    bool doPlay = false,
    bool shuffling = false,
  }) async {
    _errorHandler.resetCircuitBreaker();
    _shouldResumeAfterInterruption = false;
    _isAdvancing = true;
    try {
      fromPlaylist.add(true);
      _relatedSongsManager.clearRelatedSongs();
      _clearPreloadedMarker();

      final trackToPlay = (idx >= 0 && idx < playlist.tracks.length)
          ? playlist.tracks[idx]
          : null;

      final sanitized = playlist.tracks
          .where((t) => t.id.trim().isNotEmpty && t.title.trim().isNotEmpty)
          .toList();

      if (sanitized.isEmpty) {
        SnackbarService.showMessage('This section has no playable tracks.',
            duration: const Duration(seconds: 2));
        return;
      }

      int newIdx = 0;
      if (trackToPlay != null) {
        final pos = sanitized.indexWhere((t) => t.id == trackToPlay.id);
        newIdx = pos != -1 ? pos : 0;
      }

      _queueManager.loadTracks(sanitized,
          playlistName: playlist.title, idx: newIdx, shuffling: shuffling);
      queueTitle.add(playlist.title);

      if (doPlay || shuffling) {
        final track = _queueManager.currentTrack;
        if (track != null) await _enqueuePlayTrack(track, doPlay: true);
      }
    } finally {
      _isAdvancing = false;
    }
  }

  @override
  Future<void> addQueueItem(MediaItem mi) async =>
      _queueManager.addTrack(mediaItemToTrack(mi));

  Future<void> addQueueTrack(Track track) async =>
      _queueManager.addTrack(track);

  @override
  Future<void> addQueueItems(List<MediaItem> items,
          {String queueName = 'Queue', bool atLast = false}) async =>
      _queueManager.addTracks(items.map(mediaItemToTrack).toList(),
          atLast: atLast);

  Future<void> addQueueTracks(List<Track> tracks,
          {bool atLast = false}) async =>
      _queueManager.addTracks(tracks, atLast: atLast);

  Future<void> updateQueueTracks(List<Track> tracks,
      {bool doPlay = false, int startIndex = 0}) async {
    _queueManager.updateQueue(tracks, startIndex: startIndex);
    if (doPlay) {
      final t = _queueManager.currentTrack;
      if (t != null) await _enqueuePlayTrack(t, doPlay: true);
    }
  }

  Future<void> addPlayNextItem(MediaItem item) async =>
      _queueManager.addPlayNext(mediaItemToTrack(item));

  Future<void> addPlayNextTrack(Track track) async =>
      _queueManager.addPlayNext(track);

  @override
  Future<void> insertQueueItem(int index, MediaItem mi) async =>
      _queueManager.insertTrack(index, mediaItemToTrack(mi));

  @override
  Future<void> removeQueueItemAt(int index) async =>
      _queueManager.removeTrackAt(index);

  Future<void> moveQueueItem(int oldIndex, int newIndex) async =>
      _queueManager.moveTrack(oldIndex, newIndex);

  void clearQueue() {
    _clearPreloadedMarker();
    _queueManager.clearQueue();
  }

  @override
  Future<void> updateQueue(List<MediaItem> newQueue,
      {bool doPlay = false}) async {
    _queueManager.updateQueue(newQueue.map(mediaItemToTrack).toList());
    if (doPlay) {
      final t = _queueManager.currentTrack;
      if (t != null) await _enqueuePlayTrack(t, doPlay: true);
    }
  }

  void setRecentlyPlayedThresholdSeconds(int s) =>
      _recentlyPlayedTracker.setThresholdSeconds(s);

  void setRecentlyPlayedPercentThreshold(double p) =>
      _recentlyPlayedTracker.setPercentThreshold(p);

  // ─── Lifecycle ───────────────────────────────────────────────────────────

  @override
  Future<void> onTaskRemoved() async {
    // Best-effort queue save; must never block the teardown.
    try {
      await _queueManager.persistQueueState();
    } catch (_) {}

    await _teardownFromSystem();

    return super.onTaskRemoved();
  }

  @override
  Future<void> onNotificationDeleted() async {
    await _teardownFromSystem();
    return super.onNotificationDeleted();
  }

  /// Single idempotent teardown for "user dismissed the app / killed playback".
  Future<void> _teardownFromSystem() async {
    if (_teardownStarted) return;
    _teardownStarted = true;

    // 1. Stop native audio first — this is the part the user hears.
    try {
      await engine.stop();
    } catch (_) {}

    // 2. Exactly ONE idle emission → audio_service stops the FGS,
    //    removes the MediaStyle notification, releases the media session.
    try {
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.idle,
        playing: false,
      ));
    } catch (_) {}

    // 3. Stop hands-free (Vosk recognizer + microphone FGS) if it was ON.
    try {
      if (ServiceLocator.voiceCommandService.isListening.value) {
        await ServiceLocator.voiceCommandService.stopListening();
      }
    } catch (_) {}

    // 4. Release every Dart-side resource (engine, subjects, timers, overlay).
    await _cleanup();

    // 5. Tell the initializer to build a fresh handler next launch.
    try {
      PlayerInitializer().markTornDown();
    } catch (_) {}

    // ── Final step: end the process ──────────────────────────────────────
    // This is deliberate, not a workaround. Reasons:
    //  1. audio_service cannot be re-initialised in the same process, so a
    //     "fresh player on reopen" is only possible in a new process.
    //  2. The audio FGS is BOUND by our own MediaBrowser client; stopSelf()
    //     cannot finish it while bound, so the FGS notification would linger.
    //  3. Killing the process removes FGS + notification + media session
    //     atomically, on every OEM, with no lifecycle races.
    await Future<void>.delayed(const Duration(milliseconds: 400)); // let Isar flush
    exit(0);
  }

  Future<void> _cleanup() async {
    if (_isDisposed) return;
    _isDisposed = true;

    _systemVolumePollTimer?.cancel();
    _systemVolumePollTimer = null;
    _duckRestoreVolume = null;

    _playCompleter?.operation.cancel();
    _playCompleter = null;
    _preResolveOp?.cancel();
    _currentResolveOp?.cancel();

    _relatedSongTimer?.cancel();
    _relatedSongTimer = null;

    await Future.wait([
      _engineStateSub?.cancel() ?? Future.value(),
      _completionSub?.cancel() ?? Future.value(),
      _errorSub?.cancel() ?? Future.value(),
      _queueSyncSub?.cancel() ?? Future.value(),
      _positionSuccessSub?.cancel() ?? Future.value(),
      _audioInterruptionSub?.cancel() ?? Future.value(),
      _audioNoisySub?.cancel() ?? Future.value(),
      _durationSub?.cancel() ?? Future.value(), // was missing
    ]);

    _errorHandler.dispose();
    _queueManager.dispose();
    _relatedSongsManager.dispose();
    await _recentlyPlayedTracker.dispose();

    DiscordService.clearPresence();
    try {
      await engine.dispose(); // disposes BOTH media_kit players
    } catch (_) {}
    await _deactivateAudioSession();

    try {
      DynamicIslandService.stopPolling(); // 700 ms timer must die
    } catch (_) {}

    fromPlaylist.add(false);
    isOffline.add(false);
    loopMode.add(LoopMode.off);

    // NOTE: no super.stop() here (see D2.c) — prevents the double idle.
  }
}