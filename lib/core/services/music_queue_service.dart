import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fukat_songs/core/audio/audio_handler.dart';
import 'package:fukat_songs/core/audio/audio_handler_provider.dart';
import 'package:fukat_songs/models/song.dart';
import 'package:fukat_songs/providers/music_repository.dart';
import 'package:fukat_songs/providers/music_repository_provider.dart';
import '../network/audio_pre_fetch_cache.dart';
import '../network/client_link_resolver.dart';

part 'music_queue_service.g.dart';

class MusicQueueService {
  final MusicAudioHandler _audioHandler;
  final MusicRepository _musicRepository;
  final ClientLinkResolver _linkResolver = ClientLinkResolver();
  final AudioPreFetchCache _cache = AudioPreFetchCache();

  // Active tracklist matching the current playlist view models
  List<Song> _currentPlaylistSongs = [];
  
  MusicQueueService({
    required MusicAudioHandler audioHandler,
    required MusicRepository musicRepository,
  }) : _audioHandler = audioHandler,
       _musicRepository = musicRepository;

  /// Sets up a playlist structure and immediately launches background pre-fetching
  void loadNewPlaylistContext(List<Song> songs) {
    _currentPlaylistSongs = songs;
    
    // Clear out old playlist bindings to conserve device memory resources
    _cache.clearAllCache();

    // Trigger immediate background pre-fetching for the top 3 tracks optimistically
    _preFetchNextBatch(startIndex: 0, batchSize: 3);
  }

  /// Plays a track with zero buffering latency using cache matching
  Future<void> playTrackAtIndex(int index) async {
    if (index < 0 || index >= _currentPlaylistSongs.length) return;

    final Song targetSong = _currentPlaylistSongs[index];
    final String targetTrackId = targetSong.id;
    String? resolvedAudioUrl;

    // 1. Check if the song was already pre-fetched in the background
    if (_cache.contains(targetTrackId)) {
      resolvedAudioUrl = _cache.get(targetTrackId);
      print('--- MusicQueueService: Cache HIT for "${targetSong.title}" ---');
    } 
    // 2. Check if it is currently in the middle of being resolved
    else if (_cache.isResolving(targetTrackId)) {
      print('--- MusicQueueService: Active resolution in-progress for "${targetSong.title}". Waiting... ---');
      resolvedAudioUrl = await _cache.getActiveResolution(targetTrackId);
    } 
    // 3. Worst-case scenario fallback (user clicked a non-pre-fetched song)
    else {
      print('--- MusicQueueService: Cache MISS for "${targetSong.title}". Resolving on-demand... ---');
      resolvedAudioUrl = await _resolveAndCacheTrack(targetSong);
    }

    if (resolvedAudioUrl != null) {
      // Stream is passed straight to global audio handler for instant playback and lock screen sync
      await _audioHandler.playUrl(resolvedAudioUrl, targetSong);

      // 4. Cascade Look-Ahead: Once current track plays, pre-fetch the next upcoming tracks
      _preFetchNextBatch(startIndex: index + 1, batchSize: 2);
    }
  }

  /// Retrieves a deciphered YouTube streaming URL either from cache, active resolution, or resolves on-the-fly
  Future<String?> getDecipheredUrl(Song song) async {
    final String trackId = song.id;
    if (_cache.contains(trackId)) {
      print('--- MusicQueueService: Cache HIT for "${song.title}" ---');
      return _cache.get(trackId);
    }
    if (_cache.isResolving(trackId)) {
      print('--- MusicQueueService: Waiting on active pre-fetch for "${song.title}" ---');
      return await _cache.getActiveResolution(trackId);
    }
    print('--- MusicQueueService: Cache MISS for "${song.title}". Resolving on-demand... ---');
    try {
      return await _resolveAndCacheTrack(song);
    } catch (e) {
      print('--- MusicQueueService: On-demand resolution failed for "${song.title}": $e ---');
      return null;
    }
  }

  /// Triggers a pre-fetch for upcoming tracks based on the current playing index
  void triggerPreFetchForIndex(int currentIndex) {
    _preFetchNextBatch(startIndex: currentIndex + 1, batchSize: 3);
  }

  /// Handles sequential background tasks without blocking the application flow
  void _preFetchNextBatch({required int startIndex, required int batchSize}) {
    for (int i = 0; i < batchSize; i++) {
      int targetIndex = startIndex + i;
      
      // Stop execution loop if we hit the end of the playlist array length
      if (targetIndex >= _currentPlaylistSongs.length) break;

      final Song nextSong = _currentPlaylistSongs[targetIndex];
      final String nextTrackId = nextSong.id;

      // Skip processing if the track is already cached or actively resolving
      if (_cache.contains(nextTrackId) || _cache.isResolving(nextTrackId)) continue;

      // Launch link resolution in the background safely without 'await'ing it here
      final Future<String> resolutionTask = _resolveAndCacheTrack(nextSong);
      _cache.trackActiveResolution(nextTrackId, resolutionTask);
    }
  }

  /// Internal worker pipeline to resolve and cache the string result
  Future<String> _resolveAndCacheTrack(Song song) async {
    try {
      String? clearStreamingUrl;
      
      // If it is a YouTube song, use the premium ClientLinkResolver Vercel/Render proxy deciphering bridge!
      if (song.source == 'youtube') {
        clearStreamingUrl = await _linkResolver.resolveStreamLinkLocally(
          song.id,
          source: song.source,
        );
      } 
      // If it is any other source (like Saavn or Spotify), resolve it directly via the central MusicRepository!
      else {
        print('--- MusicQueueService: Resolving non-YouTube track "${song.title}" via MusicRepository ---');
        clearStreamingUrl = await _musicRepository.getStreamUrl(song);
      }

      if (clearStreamingUrl == null || clearStreamingUrl.isEmpty) {
        throw Exception('Failed to resolve streaming URL for track: ${song.title}');
      }

      _cache.insert(song.id, clearStreamingUrl);
      return clearStreamingUrl;
    } catch (e) {
      print("Pre-fetch pipeline warning for track ${song.title}: $e");
      rethrow;
    }
  }
}

@Riverpod(keepAlive: true)
MusicQueueService musicQueueService(MusicQueueServiceRef ref) {
  final handler = ref.watch(audioHandlerProvider);
  final repository = ref.watch(musicRepositoryProvider);
  return MusicQueueService(
    audioHandler: handler,
    musicRepository: repository,
  );
}
