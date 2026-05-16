import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:fukat_songs/models/song.dart';
import 'package:fukat_songs/core/audio/audio_handler.dart';
import 'package:fukat_songs/core/audio/audio_handler_provider.dart';
import 'package:fukat_songs/providers/music_repository_provider.dart';
import 'package:fukat_songs/providers/playlist_repository_provider.dart';
import 'package:fukat_songs/features/settings/logic/settings_notifier.dart';
import 'package:fukat_songs/core/repositories/history_repository.dart';
import 'player_state.dart';

part 'player_notifier.g.dart';

@Riverpod(keepAlive: true)
class PlayerNotifier extends _$PlayerNotifier {
  // Both queues are kept in sync — never destructively shuffle
  List<Song> _originalQueue = [];
  List<Song> _shuffledQueue = [];

  @override
  PlayerState build() {
    final handler = ref.watch(audioHandlerProvider);

    final playbackSubscription = handler.playbackState.listen((s) {
      this.state = this.state.copyWith(
        isPlaying: s.playing,
        processingState: s.processingState,
        bufferedPosition: s.bufferedPosition,
      );

      // Auto-advance when a song completes
      if (s.processingState == AudioProcessingState.completed) {
        _onSongCompleted();
      }
    });

    final mediaItemSubscription = handler.mediaItem.listen((item) {
      if (item != null) {
        this.state = this.state.copyWith(
          totalDuration: item.duration ?? Duration.zero,
        );
      }
    });

    final positionSubscription =
        (handler as MusicAudioHandler).positionStream.listen((pos) {
      this.state = this.state.copyWith(position: pos);
    });

    ref.onDispose(() {
      playbackSubscription.cancel();
      mediaItemSubscription.cancel();
      positionSubscription.cancel();
    });

    return const PlayerState();
  }

  // ─── Queue Management ───────────────────────────────────────────

  int _playbackSessionId = 0;

  /// Play a single song without changing the queue.
  Future<void> playSong(Song song, {bool isRetry = false}) async {
    final sessionId = ++_playbackSessionId;
    final audioHandler = ref.read(audioHandlerProvider);
    
    // Immediately pause previous audio to prevent ghost-playing while fetching URL
    audioHandler.pause();

    state = state.copyWith(
      currentSong: song, 
      isPlaying: true,
      position: Duration.zero,
      processingState: AudioProcessingState.loading,
    );
    
    ref.read(historyRepositoryProvider).addToPlaybackHistory(song);
    await _doPlay(song, sessionId, isRetry: isRetry);
  }

  /// Set a full queue and start playing from [startIndex].
  Future<void> setQueueAndPlay(List<Song> songs, {int startIndex = 0}) async {
    if (songs.isEmpty) return;
    _originalQueue = List.from(songs);
    _buildShuffledQueue(startIndex);

    final activeQueue = state.isShuffleModeEnabled ? _shuffledQueue : _originalQueue;
    final song = activeQueue[startIndex];
    state = state.copyWith(
      queue: activeQueue,
      currentIndex: startIndex,
      currentSong: song,
    );
    await playSong(song);
  }

  void _buildShuffledQueue(int anchorIndex) {
    final rest = List<Song>.from(_originalQueue)..removeAt(anchorIndex);
    rest.shuffle();
    _shuffledQueue = [_originalQueue[anchorIndex], ...rest];
  }

  void _onSongCompleted() {
    switch (state.repeatMode) {
      case AudioServiceRepeatMode.one:
        // Native just_audio LoopMode.one usually prevents 'completed' state,
        // but if it ever triggers, simply seek to 0 to loop it instantly
        // without hitting the network again.
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
      if (!wrap) return; // End of queue, stop
      state = state.copyWith(currentIndex: 0, currentSong: queue[0]);
      playSong(queue[0]);
    } else {
      state = state.copyWith(currentIndex: nextIndex, currentSong: queue[nextIndex]);
      playSong(queue[nextIndex]);
    }
  }

  // ─── Shuffle ─────────────────────────────────────────────────

  void toggleShuffle() {
    final enabled = !state.isShuffleModeEnabled;
    if (enabled && _originalQueue.isNotEmpty) {
      _buildShuffledQueue(state.currentIndex);
      state = state.copyWith(isShuffleModeEnabled: true, queue: _shuffledQueue, currentIndex: 0);
    } else {
      // Restore original queue, keep current song position
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

  // ─── Repeat ──────────────────────────────────────────────────

  void cycleRepeatMode() {
    final next = switch (state.repeatMode) {
      AudioServiceRepeatMode.none => AudioServiceRepeatMode.all,
      AudioServiceRepeatMode.all  => AudioServiceRepeatMode.one,
      _                           => AudioServiceRepeatMode.none,
    };
    state = state.copyWith(repeatMode: next);
    ref.read(audioHandlerProvider).setRepeatMode(next);
  }

  // ─── Skip controls ───────────────────────────────────────────

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
    // If more than 3s in, restart current song instead
    if (state.position.inSeconds > 3) {
      seek(Duration.zero);
      return;
    }
    final prevIndex = (state.currentIndex - 1).clamp(0, queue.length - 1);
    state = state.copyWith(currentIndex: prevIndex, currentSong: queue[prevIndex]);
    playSong(queue[prevIndex]);
  }

  void skipToIndex(int index) {
    final queue = state.queue;
    if (index < 0 || index >= queue.length) return;
    state = state.copyWith(currentIndex: index, currentSong: queue[index]);
    playSong(queue[index]);
  }

  // ─── Playback helpers ─────────────────────────────────────────

  Future<void> _doPlay(Song song, int sessionId, {bool isRetry = false}) async {
    final settings = ref.read(settingsNotifierProvider);
    final audioHandler = ref.read(audioHandlerProvider);
    final repository = ref.read(musicRepositoryProvider);

    try {
      if (song.localPath != null) {
        final file = File(song.localPath!);
        if (await file.exists()) {
          if (_playbackSessionId != sessionId) return;
          await audioHandler.playFile(song.localPath!, song);
          return;
        }
      }
      final url = await repository.getStreamUrl(song, quality: settings.streamingQuality);
      if (url != null) {
        if (_playbackSessionId != sessionId) return;
        await audioHandler.playUrl(url, song);
      } else {
        throw Exception('No URL found');
      }
    } catch (e) {
      if (_playbackSessionId != sessionId) return;
      if (!isRetry) {
        await _repairAndPlay(song, sessionId);
      } else {
        debugPrint('Permanent playback failure for: ${song.title}');
        state = state.copyWith(processingState: AudioProcessingState.error);
      }
    }
  }

  Future<void> _repairAndPlay(Song song, int sessionId) async {
    final repository = ref.read(musicRepositoryProvider);
    final playlistRepo = ref.read(playlistRepositoryProvider);
    debugPrint('Attempting self-healing for: ${song.title}');
    final results = await repository.search('${song.title} ${song.artist}');
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
        await playSong(repairedSong, isRetry: true);
      }
    } else {
      if (_playbackSessionId != sessionId) return;
      state = state.copyWith(processingState: AudioProcessingState.error);
    }
  }

  void pause() => ref.read(audioHandlerProvider).pause();
  void resume() => ref.read(audioHandlerProvider).play();
  void seek(Duration position) => ref.read(audioHandlerProvider).seek(position);
}
