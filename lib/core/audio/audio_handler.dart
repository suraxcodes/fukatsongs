import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt_exp;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:fukat_songs/core/audio/youtube_audio_source.dart';
import 'package:fukat_songs/models/song.dart';
import '../../features/library/logic/song_download_notifier.dart';

class MusicAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  VoidCallback? onSkipToNext;
  VoidCallback? onSkipToPrevious;
  
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
      audioPipeline: AudioPipeline(
        androidAudioEffects: [_equalizer, _loudnessEnhancer],
      ),
      userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
    );
    _player.setSkipSilenceEnabled(true);
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
            _player.setVolume(0.5);
            break;
        }
      } else {
        switch (event.type) {
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            play();
            break;
          case AudioInterruptionType.duck:
            _player.setVolume(1.0);
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

    // Load the audio source with appropriate headers
    final headers = <String, String>{
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
      if (song.source == 'saavn') 'Referer': 'https://www.jiosaavn.com/',
    };

    await _player.setAudioSource(
      AudioSource.uri(Uri.parse(url), headers: headers),
      initialPosition: initialPosition,
      preload: true,
    );

    if (_playSessionId != sessionId) {
      print('--- PLAYBACK ABORTED (session expired) ---');
      return;
    }

    // Smart Wait: buffer at least 1.5s before playing — but cap at 1.5s total
    // so switching songs never feels frozen. If player is 'ready', start immediately.
    int attempts = 0;
    while (attempts < 8) {
      await Future.delayed(const Duration(milliseconds: 200));
      attempts++;
      if (_playSessionId != sessionId) return;
      // If player is ready or we have 1.5s buffered, start now
      if (_player.processingState == ProcessingState.ready &&
          _player.bufferedPosition >= const Duration(milliseconds: 1500)) {
        break;
      }
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
