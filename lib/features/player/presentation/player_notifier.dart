import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fukat_songs/models/song.dart';
import 'package:fukat_songs/core/audio/audio_handler.dart';
import 'package:fukat_songs/core/audio/audio_handler_provider.dart';
import 'package:fukat_songs/providers/music_repository_provider.dart';
import 'package:fukat_songs/providers/playlist_repository_provider.dart';
import 'package:fukat_songs/features/settings/logic/settings_notifier.dart';
import 'package:fukat_songs/core/repositories/history_repository.dart';
import 'package:fukat_songs/core/constants/hive_boxes.dart';
import 'package:fukat_songs/features/player/presentation/player_state.dart';

class PlayerNotifier extends StateNotifier<PlayerState> {
  final Ref ref;
  List<Song> _originalQueue = [];
  List<Song> _shuffledQueue = [];
  int _playbackSessionId = 0;
  bool _isRetrying = false;

  DateTime _lastPositionSaveTime = DateTime.now();

  PlayerNotifier(this.ref) : super(const PlayerState()) {
    _init();
  }

  void _init() {
    final handler = ref.read(audioHandlerProvider);

    handler.playbackState.listen((s) {
      state = state.copyWith(
        isPlaying: s.playing,
        processingState: s.processingState,
        bufferedPosition: s.bufferedPosition,
      );

      if (s.processingState == AudioProcessingState.error) {
        if (state.currentSong != null && !_isRetrying) {
          _isRetrying = true;
          print('--- PLAYBACK STATE ERROR: Asynchronous player error! Clearing stream cache and retrying play... ---');
          ref.read(musicRepositoryProvider).clearStreamCache(state.currentSong!.id);
          
          Future.microtask(() async {
            try {
              await playSong(state.currentSong!, isRetry: true, initialPosition: state.position);
            } finally {
              _isRetrying = false;
            }
          });
        } else if (state.currentSong != null && _isRetrying) {
          print('--- REPLAY ATTEMPT FAILED ASYNCHRONOUSLY: Auto-skipping to next song... ---');
          _isRetrying = false;
          skipToNext();
        }
      }

      if (s.processingState == AudioProcessingState.completed) {
        if (state.repeatMode == AudioServiceRepeatMode.none) {
          if (state.currentIndex >= state.queue.length - 1) {
            _triggerAutoplay();
          } else {
            skipToNext();
          }
        } else if (state.repeatMode == AudioServiceRepeatMode.all) {
          skipToNext();
        }
      }
    });

    handler.mediaItem.listen((item) {
      if (item != null) {
        state = state.copyWith(totalDuration: item.duration ?? Duration.zero);
      }
    });

    (handler as MusicAudioHandler).positionStream.listen((pos) {
      state = state.copyWith(position: pos);
      _checkPreloadTrigger(pos);
      _persistPlaybackProgress(pos);
    });

    (handler as MusicAudioHandler).onSkipToNext = skipToNext;
    (handler as MusicAudioHandler).onSkipToPrevious = skipToPrevious;

    // Restore last session in a paused state after initialization completes
    Future.microtask(() => restoreLastSession());
  }

  void _persistPlaybackProgress(Duration pos) {
    if (state.currentSong == null) return;
    
    final now = DateTime.now();
    if (now.difference(_lastPositionSaveTime) >= const Duration(seconds: 2)) {
      _lastPositionSaveTime = now;
      try {
        final settingsBox = Hive.box(HiveBoxes.settings);
        settingsBox.put('last_played_song_json', state.currentSong!.toJson());
        settingsBox.put('last_played_position_ms', pos.inMilliseconds);
        
        if (state.queue.isNotEmpty) {
          final queueJsonList = state.queue.map((s) => s.toJson()).toList();
          settingsBox.put('last_played_queue', queueJsonList);
          settingsBox.put('last_played_index', state.currentIndex);
        }
      } catch (e) {
        debugPrint('Failed to save playback progress: $e');
      }
    }
  }

  Future<void> restoreLastSession() async {
    try {
      final settingsBox = Hive.box(HiveBoxes.settings);
      final songJson = settingsBox.get('last_played_song_json');
      final positionMs = settingsBox.get('last_played_position_ms', defaultValue: 0) as int;
      final queueJsonList = settingsBox.get('last_played_queue') as List?;
      final index = settingsBox.get('last_played_index', defaultValue: 0) as int;

      if (songJson != null) {
        final Song song = Song.fromJson(Map<String, dynamic>.from(songJson));
        
        List<Song> restoredQueue = [song];
        if (queueJsonList != null && queueJsonList.isNotEmpty) {
          restoredQueue = queueJsonList
              .map((item) => Song.fromJson(Map<String, dynamic>.from(item)))
              .toList();
        }

        _originalQueue = List.from(restoredQueue);
        _shuffledQueue = List.from(restoredQueue);

        state = state.copyWith(
          currentSong: song,
          queue: restoredQueue,
          currentIndex: index,
          position: Duration(milliseconds: positionMs),
          totalDuration: Duration(seconds: song.duration),
          isPlaying: false,
          processingState: AudioProcessingState.ready,
        );

        // restored in a perfect paused state
      }
    } catch (e) {
      debugPrint('Failed to restore last playback session: $e');
    }
  }

  Future<void> playSong(Song song, {bool isRetry = false, Duration? initialPosition}) async {
    _preloadedSongId = null;
    _isPreloading = false;
    final sessionId = ++_playbackSessionId;
    final audioHandler = ref.read(audioHandlerProvider);

    // ✅ Stop current playback IMMEDIATELY — no lingering old audio
    await audioHandler.stop();

    state = state.copyWith(
      currentSong: song,
      isPlaying: false,
      position: initialPosition ?? Duration.zero,
      processingState: AudioProcessingState.loading,
    );

    ref.read(historyRepositoryProvider).addToPlaybackHistory(song);
    await _doPlay(song, sessionId, isRetry: isRetry, initialPosition: initialPosition);
  }

  Future<void> setQueueAndPlay(List<Song> songs, {int startIndex = 0}) async {
    if (songs.isEmpty) return;
    _originalQueue = List.from(songs);
    _buildShuffledQueue(startIndex);

    final activeQueue = state.isShuffleModeEnabled
        ? _shuffledQueue
        : _originalQueue;
    final song = activeQueue[startIndex];
    state = state.copyWith(
      queue: activeQueue,
      currentIndex: startIndex,
      currentSong: song,
    );
    await playSong(song);
  }

  void addSongToQueue(Song song) {
    if (_originalQueue.isEmpty && state.currentSong != null) {
      _originalQueue = [state.currentSong!, song];
    } else {
      // Insert right after the current song so it's "at the start" of upcoming
      final insertIndex = state.currentIndex + 1;
      if (insertIndex >= _originalQueue.length) {
        _originalQueue.add(song);
      } else {
        _originalQueue.insert(insertIndex, song);
      }
    }

    if (state.isShuffleModeEnabled) {
      final insertIndex = state.currentIndex + 1;
      if (insertIndex >= _shuffledQueue.length) {
        _shuffledQueue.add(song);
      } else {
        _shuffledQueue.insert(insertIndex, song);
      }
    }
    state = state.copyWith(
      queue: state.isShuffleModeEnabled ? _shuffledQueue : _originalQueue,
    );
  }

  void playNext(Song song) {
    if (_originalQueue.isEmpty && state.currentSong != null) {
      _originalQueue = [state.currentSong!, song];
      state = state.copyWith(queue: _originalQueue, currentIndex: 0);
      return;
    }

    if (_originalQueue.isEmpty) {
      setQueueAndPlay([song]);
      return;
    }

    final currentIndex = state.currentIndex;
    _originalQueue.insert(currentIndex + 1, song);

    if (state.isShuffleModeEnabled) {
      _shuffledQueue.insert(currentIndex + 1, song);
    }

    state = state.copyWith(
      queue: state.isShuffleModeEnabled ? _shuffledQueue : _originalQueue,
    );
  }

  void _buildShuffledQueue(int anchorIndex) {
    final rest = List<Song>.from(_originalQueue)..removeAt(anchorIndex);
    rest.shuffle();
    _shuffledQueue = [_originalQueue[anchorIndex], ...rest];
  }

  void _onSongCompleted() {
    switch (state.repeatMode) {
      case AudioServiceRepeatMode.one:
        seek(Duration.zero);
        resume();
        break;
      case AudioServiceRepeatMode.all:
        _advance(wrap: true);
        break;
      case AudioServiceRepeatMode.none:
      default:
        _advance(wrap: false);
        break;
    }
  }

  void _advance({required bool wrap}) {
    final queue = state.queue;
    if (queue.isEmpty) return;
    final nextIndex = state.currentIndex + 1;
    if (nextIndex >= queue.length) {
      if (!wrap) return;
      state = state.copyWith(currentIndex: 0, currentSong: queue[0]);
      playSong(queue[0]);
    } else {
      state = state.copyWith(
        currentIndex: nextIndex,
        currentSong: queue[nextIndex],
      );
      playSong(queue[nextIndex]);
    }
  }

  void toggleShuffle() {
    final enabled = !state.isShuffleModeEnabled;
    if (enabled && _originalQueue.isNotEmpty) {
      _buildShuffledQueue(state.currentIndex);
      state = state.copyWith(
        isShuffleModeEnabled: true,
        queue: _shuffledQueue,
        currentIndex: 0,
      );
    } else {
      final currentSong = state.currentSong;
      final idx = currentSong != null
          ? _originalQueue.indexWhere((s) => s.id == currentSong.id)
          : 0;
      state = state.copyWith(
        isShuffleModeEnabled: false,
        queue: _originalQueue,
        currentIndex: idx >= 0 ? idx : 0,
      );
    }
  }

  void cycleRepeatMode() {
    final next = switch (state.repeatMode) {
      AudioServiceRepeatMode.none => AudioServiceRepeatMode.all,
      AudioServiceRepeatMode.all => AudioServiceRepeatMode.one,
      _ => AudioServiceRepeatMode.none,
    };
    state = state.copyWith(repeatMode: next);
    ref.read(audioHandlerProvider).setRepeatMode(next);
  }

  void skipToNext() {
    if (state.queue.isEmpty) {
      ref.read(audioHandlerProvider).skipToNext();
      return;
    }
    _advance(wrap: state.repeatMode == AudioServiceRepeatMode.all);
  }

  void skipToPrevious() {
    final queue = state.queue;
    if (queue.isEmpty) {
      ref.read(audioHandlerProvider).skipToPrevious();
      return;
    }
    if (state.position.inSeconds > 3) {
      seek(Duration.zero);
      return;
    }
    final prevIndex = (state.currentIndex - 1).clamp(0, queue.length - 1);
    state = state.copyWith(
      currentIndex: prevIndex,
      currentSong: queue[prevIndex],
    );
    playSong(queue[prevIndex]);
  }

  void skipToIndex(int index) {
    final queue = state.queue;
    if (index < 0 || index >= queue.length) return;
    state = state.copyWith(currentIndex: index, currentSong: queue[index]);
    playSong(queue[index]);
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    
    final queue = List<Song>.from(state.queue);
    final item = queue.removeAt(oldIndex);
    queue.insert(newIndex, item);
    
    // Update underlying lists too
    if (state.isShuffleModeEnabled) {
      _shuffledQueue = List.from(queue);
    } else {
      _originalQueue = List.from(queue);
    }
    
    // Calculate new currentIndex if necessary
    int newCurrentIndex = state.currentIndex;
    if (state.currentIndex == oldIndex) {
      newCurrentIndex = newIndex;
    } else if (oldIndex < state.currentIndex && newIndex >= state.currentIndex) {
      newCurrentIndex -= 1;
    } else if (oldIndex > state.currentIndex && newIndex <= state.currentIndex) {
      newCurrentIndex += 1;
    }
    
    state = state.copyWith(
      queue: queue,
      currentIndex: newCurrentIndex,
    );
  }

  Future<void> _doPlay(Song song, int sessionId, {bool isRetry = false, Duration? initialPosition}) async {
    final settings = ref.read(settingsNotifierProvider);
    final audioHandler = ref.read(audioHandlerProvider) as MusicAudioHandler;
    final repository = ref.read(musicRepositoryProvider);

    try {
      audioHandler.setLoudnessEnhancement(settings.loudnessEnhancement);
      
      final downloadsBox = Hive.box<Song>(HiveBoxes.downloads);
      final downloadedSong = downloadsBox.get(song.id);

      if (downloadedSong != null && downloadedSong.localPath != null) {
        final file = File(downloadedSong.localPath!);
        if (await file.exists()) {
          if (_playbackSessionId != sessionId) return;
          await audioHandler.playFile(
            downloadedSong.localPath!,
            downloadedSong,
            initialPosition: initialPosition,
          );
          return;
        }
      }

      // --- HYBRID QUALITY LOGIC ---
      String quality = settings.streamingQuality;
      if (settings.highFidelityMode) {
        final connectivity = await Connectivity().checkConnectivity();
        if (connectivity == ConnectivityResult.mobile) {
          quality = '160'; // Start at 160 on mobile to prevent stuttering
          print('--- HYBRID MODE: Mobile detected, starting at 160kbps ---');
        } else {
          quality = '320';
        }
      }

      // --- RESILIENT MULTI-PROVIDER STREAMING PIPELINE ---
      String? url;
      String actualProvider = song.source;
      
      // Attempt 1: Preferred / Original Provider (JioSaavn or YouTube)
      try {
        print('--- PLAYBACK: Attempt 1 - Trying original source "$actualProvider" (isRetry: $isRetry) ---');
        url = await repository.getStreamUrl(
          song,
          preferredProvider: actualProvider,
          quality: quality,
          isRetry: isRetry,
        );
      } catch (e) {
        print('--- PLAYBACK: Original source "$actualProvider" failed: $e ---');
      }

      // Attempt 2: Official YouTube/Piped fallback (if Saavn failed)
      if (url == null && song.source == 'saavn' && song.providers.containsKey('youtube')) {
        print('--- PLAYBACK: Attempt 2 - Falling back to official YouTube/Piped stream... ---');
        actualProvider = 'youtube';
        try {
          url = await repository.getStreamUrl(
            song,
            preferredProvider: 'youtube',
            quality: quality,
            isRetry: isRetry,
          );
        } catch (e) {
          print('--- PLAYBACK: Official YouTube fallback failed: $e ---');
        }
      }

      // Attempt 3: Unofficial Fan Channel last resort fallback (if both failed)
      if (url == null && song.providers.containsKey('youtube_fan')) {
        print('--- PLAYBACK: Attempt 3 (LAST RESORT) - Playing fan channel video stream... ---');
        actualProvider = 'youtube_fan';
        try {
          url = await repository.getStreamUrl(
            song,
            preferredProvider: 'youtube_fan',
            quality: quality,
            isRetry: isRetry,
          );
        } catch (e) {
          print('--- PLAYBACK: Last resort fan channel failed: $e ---');
        }
      }

      if (url != null) {
        if (_playbackSessionId != sessionId) return;
        await audioHandler.playUrl(url, song, initialPosition: initialPosition);
      } else {
        throw Exception('No playable stream URL could be fetched across Saavn, YouTube, and Piped');
      }
    } catch (e) {
      if (_playbackSessionId != sessionId) return;
      if (!isRetry) {
        await _repairAndPlay(song, sessionId);
      } else {
        state = state.copyWith(processingState: AudioProcessingState.error);
        print('--- PLAYBACK ERROR: Auto-skipping to next song in 2 seconds ---');
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && state.processingState == AudioProcessingState.error) {
            skipToNext();
          }
        });
      }
    }
  }

  Future<void> _repairAndPlay(Song song, int sessionId) async {
    final repository = ref.read(musicRepositoryProvider);
    final playlistRepo = ref.read(playlistRepositoryProvider);

    final cleanTitle = song.title
        .replaceAll(RegExp(r'\(.*?\)|\[.*?\]'), '')
        .replaceAll(RegExp(r'official (video|audio|lyric|hd|4k|mv)'), '')
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .trim();

    final results = await repository.search('$cleanTitle ${song.artist}');
    if (results.isNotEmpty) {
      final youtubeId = results.first.providers['youtube'];
      if (youtubeId != null) {
        final repairedSong = song.copyWith(
          providers: {...song.providers, 'youtube': youtubeId},
        );
        final libraryBox = Hive.box('library');
        if (libraryBox.containsKey(song.id)) {
          await libraryBox.put(song.id, repairedSong.toJson());
        }
        await playlistRepo.updateSongInAllPlaylists(repairedSong);

        if (_playbackSessionId != sessionId) return;
        await playSong(repairedSong, isRetry: true, initialPosition: state.position);
      }
    } else {
      if (_playbackSessionId != sessionId) return;
      state = state.copyWith(processingState: AudioProcessingState.error);
      print('--- REPAIR FAILED: Auto-skipping to next song in 2 seconds ---');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && state.processingState == AudioProcessingState.error) {
          skipToNext();
        }
      });
    }
  }

  void pause() => ref.read(audioHandlerProvider).pause();
  void resume() {
    final audioHandler = ref.read(audioHandlerProvider) as MusicAudioHandler;
    if (state.currentSong != null && audioHandler.mediaItem.value == null) {
      playSong(state.currentSong!, initialPosition: state.position);
    } else {
      audioHandler.play();
    }
  }
  void seek(Duration position) => ref.read(audioHandlerProvider).seek(position);
  void togglePlayPause() {
    if (state.isPlaying) {
      pause();
    } else {
      resume();
    }
  }

  Stream<Duration> get positionStream => (ref.read(audioHandlerProvider) as MusicAudioHandler).positionStream;

  Future<void> _triggerAutoplay() async {
    final settings = ref.read(settingsNotifierProvider);
    if (!settings.isAutoplayEnabled) return;
    
    final lastSong = state.currentSong;
    if (lastSong == null) return;

    print('--- AUTOPLAY TRIGGERED for artist: ${lastSong.artist} ---');
    
    try {
      final results = await ref.read(musicRepositoryProvider).search(lastSong.artist);
      final newSongs = results.where((s) => !state.queue.any((qs) => qs.id == s.id)).take(5).toList();
      
      if (newSongs.isNotEmpty) {
        for (var s in newSongs) {
          addSongToQueue(s);
        }
        skipToNext();
      }
    } catch (e) {
      print('--- Autoplay Failed: $e ---');
    }
  }

  bool _isPreloading = false;
  String? _preloadedSongId;

  Future<void> _checkPreloadTrigger(Duration position) async {
    final currentSong = state.currentSong;
    if (currentSong == null || state.queue.isEmpty) return;
    
    final total = state.totalDuration;
    if (total == Duration.zero) return;

    final progress = position.inMilliseconds / total.inMilliseconds;
    if (progress > 0.8) {
      final nextIndex = state.currentIndex + 1;
      if (nextIndex < state.queue.length) {
        final nextSong = state.queue[nextIndex];
        if (_preloadedSongId == nextSong.id || _isPreloading) return;

        final connectivity = await Connectivity().checkConnectivity();
        await preloadNextTrack(nextSong, isWifi: connectivity != ConnectivityResult.mobile);
      }
    }
  }

  Future<void> preloadNextTrack(Song song, {required bool isWifi}) async {
    _isPreloading = true;
    _preloadedSongId = song.id;
    print('--- PRELOAD: Resolving stream URL for next track: ${song.title} ---');
    try {
      final settings = ref.read(settingsNotifierProvider);
      String quality = settings.streamingQuality;
      if (settings.highFidelityMode) {
        quality = isWifi ? '320' : '160';
      }
      
      final url = await ref.read(musicRepositoryProvider).getStreamUrl(song, quality: quality);
      if (url != null) {
        print('--- PRELOAD: Successfully resolved stream URL for: ${song.title} ---');
      }
    } catch (e) {
      print('--- PRELOAD: Failed to preload: $e ---');
      _preloadedSongId = null;
    } finally {
      _isPreloading = false;
    }
  }
}

final playerNotifierProvider =
    StateNotifierProvider<PlayerNotifier, PlayerState>((ref) {
      return PlayerNotifier(ref);
    });
