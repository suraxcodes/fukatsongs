import 'package:flutter/foundation.dart';
import 'package:fukatsongs/services/bloomee_player.dart';
import 'package:fukatsongs/core/theme/app_theme.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';

/// Initializes the audio session and player.
///
/// ## Why configure() is called HERE (not in BloomeeMusicPlayer's constructor)
///
/// Dart constructors cannot `await`. If AudioSession.configure() is called
/// inside the player constructor (fire-and-forget), there is a race window
/// on slow/cold-start devices where the user taps a song before configure()
/// completes. setActive(true) then calls requestAudioFocus() with unconfigured
/// attributes → AUDIOFOCUS_REQUEST_FAILED on Xiaomi MIUI / Samsung OneUI.
///
/// Calling configure() here, before AudioService.init(), eliminates the race:
/// the session is fully configured before any BloomeeMusicPlayer method can run.
Future<void> setupAudioSession() async {
  final session = await AudioSession.instance;
  await session.configure(AudioSessionConfiguration(
    // iOS
    avAudioSessionCategory: AVAudioSessionCategory.playback,
    avAudioSessionCategoryOptions:
        AVAudioSessionCategoryOptions.allowBluetooth |
            AVAudioSessionCategoryOptions.allowAirPlay,
    avAudioSessionMode: AVAudioSessionMode.defaultMode,
    avAudioSessionRouteSharingPolicy:
        AVAudioSessionRouteSharingPolicy.defaultPolicy,
    avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
    // Android
    androidAudioAttributes: const AndroidAudioAttributes(
      contentType: AndroidAudioContentType.music,
      usage: AndroidAudioUsage.media,
    ),
    androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
    // We handle ducking ourselves via interruptionEventStream.
    androidWillPauseWhenDucked: false,
  ));
}

/// Singleton that creates and owns the [BloomeeMusicPlayer] instance.
///
/// Using a [Completer] (not a busy-wait while loop) to serialize concurrent
/// initialization calls. The old pattern with `while (_isInitializing)`
/// polled every 50ms and could theoretically spin indefinitely if init threw
/// an exception that bypassed the `finally` block.
class PlayerInitializer {
  static final PlayerInitializer _instance = PlayerInitializer._internal();
  factory PlayerInitializer() => _instance;
  PlayerInitializer._internal();

  BloomeeMusicPlayer? _player;
  // Completer is set during init, removed when done. Any callers that arrive
  // while init is in progress simply await the same future.
  Future<BloomeeMusicPlayer>? _initFuture;

  /// Set by the player when the user swipes the app out of Recents.
  /// A disposed handler must NEVER be revived in the same process — audio_service
  /// allows only one AudioService.init() per process. The app process terminates
  /// on teardown, so the next cold start occurs in a fresh process.
  bool _tornDown = false;
  bool _hasInitialized = false;

  void markTornDown() => _tornDown = true;

  Future<BloomeeMusicPlayer> getBloomeeMusicPlayer() async {
    final p = _player;

    // audio_service allows exactly ONE AudioService.init() per process
    // (it asserts on a static _cacheManager that can never be reset).
    // After task-removal teardown the process is killed on purpose, so if we
    // ever reach this point the handler is gone for good in this process.
    if (_tornDown || (p != null && p.isDisposed) || (_hasInitialized && p == null)) {
      throw StateError(
        'Player was torn down with the task; the app must be restarted.',
      );
    }

    if (p != null) {
      if (!p.isPlayerHealthy) await p.revive();
      return p;
    }

    // Cold-start initialization (exactly once per process).
    final running = _initFuture;
    if (running != null) return running;

    _initFuture = _initializeInternal();
    try {
      final player = await _initFuture!;
      _hasInitialized = true;
      return player;
    } finally {
      _initFuture = null;
    }
  }

  Future<BloomeeMusicPlayer> _initializeInternal() async {
    final player = await AudioService.init(
      builder: () => BloomeeMusicPlayer(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.BloomeePlayer.notification.status',
        androidNotificationChannelName: 'BloomeTunes',
        androidNotificationIcon: 'mipmap/ic_launcher',
        androidResumeOnClick: true,
        androidShowNotificationBadge: true,
        androidStopForegroundOnPause: false,
        notificationColor: Default_Theme.accentColor2,
      ),
    );

    // ─────────────────────────────────────────────────────────────────
    // Force media_kit engine volume to 100% permanently.
    //
    // After this, ALL volume changes — from voice commands, the physical
    // hardware buttons, the in-app volume slider, and the volume ducking
    // logic in BloomeeMusicPlayer._handleInterruptionSync — must go
    // through Android's AudioManager.STREAM_MUSIC (via the
    // setMediaVolume method channel). The engine's internal volume stays
    // pinned at 1.0 so that effective_loudness == system_volume, and the
    // Android volume UI is always the source of truth.
    // ─────────────────────────────────────────────────────────────────
    try {
      await player.engine.setVolume(1.0);
    } catch (e) {
      debugPrint('Failed to pin media_kit volume to 100%: $e');
    }

    _player = player;
    return player;
  }
}