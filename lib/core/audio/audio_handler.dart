import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt_exp;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:fukat_songs/models/song.dart';
import '../../features/library/logic/song_download_notifier.dart';

class MusicAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  void Function()? onSkipToNext;
  void Function()? onSkipToPrevious;
  
  late final AndroidEqualizer _equalizer;
  late final AndroidLoudnessEnhancer _loudnessEnhancer;
  final yt_exp.YoutubeExplode _yt = yt_exp.YoutubeExplode();

  MusicAudioHandler() {
    _equalizer = AndroidEqualizer();
    _loudnessEnhancer = AndroidLoudnessEnhancer();
    _initPlayer();
    _initAudioSession();
    _notifyAudioHandlerAboutPlaybackEvents();
    _listenToDurationChanges();
  }

  late final AudioPlayer _player;

  void _initPlayer() {
    _player = AudioPlayer(
      userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
    );
    _player.setVolume(0.45); // Spotify/YouTube Music Loudness Normalization (-10dB)
  }

  AndroidEqualizer get equalizer => _equalizer;

  void setLoudnessEnhancement(bool enabled) {
    _loudnessEnhancer.setEnabled(enabled);
    if (enabled) {
      _loudnessEnhancer.setTargetGain(400); // Safer boost (+4dB)
    }
  }

  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // Handle interruptions (like phone calls)
    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        switch (event.type) {
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            pause();
            break;
          case AudioInterruptionType.duck:
            _player.setVolume(0.2); // Duck to 20%
            break;
        }
      } else {
        switch (event.type) {
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            play();
            break;
          case AudioInterruptionType.duck:
            _player.setVolume(0.45); // Restore to normalized 45% level
            break;
        }
      }
    });

    // Handle unplugging headphones
    session.becomingNoisyEventStream.listen((_) => pause());
  }

  void _listenToDurationChanges() {
    _player.durationStream.listen((duration) {
      final item = mediaItem.value;
      if (item != null && duration != null) {
        mediaItem.add(item.copyWith(duration: duration));
      }
    });
  }

  void _notifyAudioHandlerAboutPlaybackEvents() {
    _player.playbackEventStream.listen((PlaybackEvent event) {
      final playing = _player.playing;
      playbackState.add(
        playbackState.value.copyWith(
          controls: [
            MediaControl.skipToPrevious,
            if (playing) MediaControl.pause else MediaControl.play,
            MediaControl.stop,
            MediaControl.skipToNext,
          ],
          systemActions: const {
            MediaAction.seek,
            MediaAction.skipToNext,
            MediaAction.skipToPrevious,
          },
          androidCompactActionIndices: const [0, 1, 3],
          processingState:
              {
                ProcessingState.idle: AudioProcessingState.idle,
                ProcessingState.loading: AudioProcessingState.loading,
                ProcessingState.buffering: AudioProcessingState.buffering,
                ProcessingState.ready: AudioProcessingState.ready,
                ProcessingState.completed: AudioProcessingState.completed,
              }[_player.processingState] ??
              AudioProcessingState.idle,
          playing: playing,
          updatePosition: _player.position,
          bufferedPosition: _player.bufferedPosition,
          speed: _player.speed,
          queueIndex: event.currentIndex,
        ),
      );
    }, onError: (Object e, StackTrace stackTrace) {
      print('--- AUDIO HANDLER PLAYBACK ERROR: $e ---');
      playbackState.add(
        playbackState.value.copyWith(
          processingState: AudioProcessingState.error,
          errorMessage: e.toString(),
        ),
      );
    });
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> skipToNext() async {
    if (onSkipToNext != null) {
      onSkipToNext!();
    } else {
      await _player.seekToNext();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (onSkipToPrevious != null) {
      onSkipToPrevious!();
    } else {
      await _player.seekToPrevious();
    }
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        await _player.setLoopMode(LoopMode.off);
        break;
      case AudioServiceRepeatMode.one:
        await _player.setLoopMode(LoopMode.one);
        break;
      case AudioServiceRepeatMode.all:
        await _player.setLoopMode(LoopMode.all);
        break;
      case AudioServiceRepeatMode.group:
        break;
    }
  }

  int _playSessionId = 0;

  Future<String?> _testUrl(String url) async {
    try {
      final dio = Dio();
      final response = await dio.get(
        url,
        options: Options(
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
            'Range': 'bytes=0-0',
          },
          validateStatus: (status) => true,
        ),
      ).timeout(const Duration(seconds: 4));
      return response.statusCode != 403 ? url : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> playUrl(String url, Song song, {Duration? initialPosition}) async {
    final sessionId = ++_playSessionId;
    print('--- PLAYURL CALLED: ${song.title} (${song.source}) ---');

    // Cancel any existing buffering by bumping the session first
    try {
      await _player.stop();
    } catch (_) {}

    if (_playSessionId != sessionId) return;

    final mediaItem = _toMediaItem(song);
    this.mediaItem.add(mediaItem);

    playbackState.add(
      playbackState.value.copyWith(processingState: AudioProcessingState.loading),
    );

    try {
      AudioSource audioSource;

      // Determine if this is a YouTube play
      String? youtubeVideoId;
      if (song.source == 'youtube' || song.source == 'youtube_fan') {
        youtubeVideoId = song.providers[song.source] ?? song.id;
      } else if (url == 'youtube_stream_placeholder') {
        youtubeVideoId = song.providers['youtube'] ?? song.providers['youtube_fan'];
      }

      if (youtubeVideoId != null) {
        // Resolve manifest ON the device so the googlevideo.com URL is IP-bound
        // to the device's own IP — not the Render/Piped server's IP.
        print('--- AUDIO HANDLER: Resolving YouTube manifest on-device for $youtubeVideoId ---');
        final manifest = await _yt.videos.streamsClient
            .getManifest(youtubeVideoId)
            .timeout(const Duration(seconds: 10));
        final audioStream = manifest.audioOnly.withHighestBitrate();
        final ytUrl = audioStream.url.toString();
        print('--- AUDIO HANDLER: Got IP-bound URL (c=ANDROID). Playing via ExoPlayer with Android UA. ---');

        // CRITICAL: The URL has &c=ANDROID&rqh=1 — it was generated with the Android
        // YouTube client. ExoPlayer MUST send the matching Android YouTube user-agent,
        // otherwise Google CDN returns 403 on &rqh=1 (required query headers).
        audioSource = AudioSource.uri(
          Uri.parse(ytUrl),
          headers: {
            'User-Agent': 'com.google.android.youtube/19.09.37 (Linux; U; Android 12) gzip',
            'X-YouTube-Client-Name': '3',
            'X-YouTube-Client-Version': '19.09.37',
          },
        );
      } else {
        // Saavn: pass resolved URL with Saavn Referer header
        audioSource = AudioSource.uri(
          Uri.parse(url),
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
            'Referer': 'https://www.jiosaavn.com/',
          },
        );
      }

      await _player.setAudioSource(
        audioSource,
        initialPosition: initialPosition,
        preload: false, // Don't block — let ExoPlayer buffer in background
      ).timeout(const Duration(milliseconds: 8000));
    } catch (e) {
      print('--- AUDIO HANDLER: setAudioSource failed or timed out: $e ---');
      if (_playSessionId == sessionId) {
        playbackState.add(
          playbackState.value.copyWith(
            processingState: AudioProcessingState.error,
            errorMessage: e.toString(),
          ),
        );
      }
      rethrow; // propagate to triggers (e.g. PlayerNotifier._repairAndPlay)
    }

    if (_playSessionId != sessionId) {
      print('--- PLAYBACK ABORTED (session expired) ---');
      return;
    }

    // Smart Wait: if player is ready, start playing immediately. Otherwise, wait up to 1.6s.
    int attempts = 0;
    while (attempts < 8) {
      if (_player.processingState == ProcessingState.ready) {
        break;
      }
      await Future.delayed(const Duration(milliseconds: 200));
      attempts++;
      if (_playSessionId != sessionId) return;
    }

    print('--- PLAYBACK STARTING (${song.source}) ---');
    await _player.play();
  }

  Future<void> playFile(String path, Song song, {Duration? initialPosition}) async {
    final sessionId = ++_playSessionId;
    try {
      final mediaItem = _toMediaItem(song);
      this.mediaItem.add(mediaItem);

      await _player.setAudioSource(
        AudioSource.file(path),
        initialPosition: initialPosition,
      );
      if (_playSessionId != sessionId) {
        print('--- FILE PLAYBACK ABORTED ---');
        return;
      }
      _player.play();
    } catch (e) {
      rethrow;
    }
  }

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  MediaItem _toMediaItem(Song song) {
    return MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist,
      album: song.albumName,
      duration: song.duration > 0 ? Duration(seconds: song.duration) : null,
      artUri: Uri.parse(song.imageUrl),
      extras: {'source': song.source},
    );
  }
}
