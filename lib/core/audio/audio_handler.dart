import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt_exp;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:fukat_songs/core/audio/youtube_audio_source.dart';
import 'package:fukat_songs/models/song.dart';

class MusicAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
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
        androidAudioEffects: [
          _equalizer,
          _loudnessEnhancer,
        ],
      ),
    );
    _player.setSkipSilenceEnabled(true);
  }

  AndroidEqualizer get equalizer => _equalizer;

  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
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
      playbackState.add(playbackState.value.copyWith(
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
        processingState: {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState] ?? AudioProcessingState.idle,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
      ));
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
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

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

  Future<void> playUrl(String url, Song song) async {
    final sessionId = ++_playSessionId;
    print('--- ATTEMPTING HYBRID PLAYBACK ---');
    
    final providersToTry = [
      song.source,
      ...song.providers.keys.where((p) => p != song.source),
    ];

    String? lastError;

    for (var provider in providersToTry) {
      try {
        print('--- TRYING PROVIDER: $provider ---');
        
        String currentUrl = url;
        final mediaItem = _toMediaItem(song).copyWith(
          extras: {...?_toMediaItem(song).extras, 'active_provider': provider},
        );
        this.mediaItem.add(mediaItem);
        
        playbackState.add(playbackState.value.copyWith(
          processingState: AudioProcessingState.loading,
        ));

        if (provider == 'youtube') {
          await _player.setUrl(currentUrl);
        } else {
          await _player.setAudioSource(
            AudioSource.uri(
              Uri.parse(currentUrl),
              headers: {
                'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
                'Referer': 'https://www.jiosaavn.com/',
              },
            ),
          );
        }

        if (_playSessionId != sessionId) {
          print('--- PLAYBACK ABORTED (Superseded by new track) ---');
          return;
        }

        print('--- PLAYBACK STARTING ($provider) ---');
        await _player.play();
        return;
      } catch (e) {
        print('--- PROVIDER $provider FAILED: $e ---');
        lastError = e.toString();
      }
    }

    print('--- ALL PROVIDERS FAILED ---');
    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.error,
    ));
    throw Exception('Playback failed on all sources: $lastError');
  }

  Future<void> playFile(String path, Song song) async {
    final sessionId = ++_playSessionId;
    try {
      final mediaItem = _toMediaItem(song);
      this.mediaItem.add(mediaItem);
      
      await _player.setAudioSource(AudioSource.file(path));
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
