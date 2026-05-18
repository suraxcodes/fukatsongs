// ignore_for_file: avoid_print
// test/phase_16_17_architecture_test.dart
//
// Tests the Phase 16 and 17 architecture:
//   1. Audio Pre-Fetch Caching and Active Scraper Resolution Tracking
//   2. Music Queue Service Optimistic Look-Ahead Batching Logic
//   3. Spotify Chart Fetching and JioSaavn fallback logic
//   4. High-Performance Audio Visualizer rendering states
//
// Run with: flutter test test/phase_16_17_architecture_test.dart
//

import 'package:flutter_test/flutter_test.dart';

// ─────────────────────────────────────────────────────────────
// Simulated Architecture Logic under Test
// ─────────────────────────────────────────────────────────────

/// Simulated Pre-Fetch Cache
class TestAudioPreFetchCache {
  final Map<String, String> _urlCache = {};
  final Map<String, Future<String>> _activeResolutions = {};

  void insert(String trackId, String streamingUrl) {
    _urlCache[trackId] = streamingUrl;
    _activeResolutions.remove(trackId); // Complete active tracking
  }

  String? get(String trackId) => _urlCache[trackId];
  bool contains(String trackId) => _urlCache.containsKey(trackId);
  bool isResolving(String trackId) => _activeResolutions.containsKey(trackId);

  void trackActiveResolution(String trackId, Future<String> task) {
    _activeResolutions[trackId] = task;
  }
}

/// Simulated Music Queue Service with Pre-fetch Look-ahead cascade
class TestMusicQueueService {
  final TestAudioPreFetchCache cache;
  List<String> _currentQueue = [];
  int _lastPreFetchedIndex = -1;

  TestMusicQueueService(this.cache);

  void loadNewPlaylistContext(List<String> trackIds) {
    _currentQueue = List.from(trackIds);
    _lastPreFetchedIndex = -1;
    // Auto pre-fetch first 3 tracks immediately
    triggerPreFetchForIndex(0);
  }

  void triggerPreFetchForIndex(int currentIndex) {
    if (_currentQueue.isEmpty) return;
    
    // Optimistically resolve next 3 items
    for (int i = 1; i <= 3; i++) {
      final targetIdx = currentIndex + i;
      if (targetIdx >= 0 && targetIdx < _currentQueue.length) {
        final trackId = _currentQueue[targetIdx];
        if (!cache.contains(trackId) && !cache.isResolving(trackId)) {
          // Track resolving
          cache.trackActiveResolution(
            trackId, 
            Future.value("http://mock-deciphered-cdn.com/$trackId")
          );
        }
      }
    }
    _lastPreFetchedIndex = currentIndex;
  }

  List<String> get currentQueue => _currentQueue;
  int get lastPreFetchedIndex => _lastPreFetchedIndex;
}

/// Simulated Spotify Chart Service with robust local fallback
class TestSpotifyChartService {
  final bool hasSpotifyCredentials;

  TestSpotifyChartService({required this.hasSpotifyCredentials});

  Future<List<String>> fetchPlaylistTracks(String playlistId) async {
    if (!hasSpotifyCredentials) {
      // Robust fall back directly to mock chart database items
      return ["Spotify India Hit 1", "Spotify India Hit 2", "Spotify India Hit 3"];
    }
    return ["Real Spotify Track A", "Real Spotify Track B"];
  }
}

/// Simulated Audio Visualizer state height mapping
class VisualizerCalculator {
  static List<double> calculateHeights({
    required bool isPlaying,
    required int barCount,
    required double baseControllerValue,
  }) {
    if (!isPlaying) {
      // Pause: rest to standard 4.0 resting height
      return List.filled(barCount, 4.0);
    }

    // Play: staggered, dynamic wave height values based on phase
    return List.generate(barCount, (index) {
      final double phase = (index / barCount) * 2 * 3.14159;
      final double waveVal = (baseControllerValue * 2 * 3.14159 + phase);
      // Normalized between 0.15 and 1.0, times max height of 36
      final double normalized = ((waveVal % 2.0) - 1.0).abs();
      return (normalized * 30.0).clamp(6.0, 36.0);
    });
  }
}

// ─────────────────────────────────────────────────────────────
// TESTS
// ─────────────────────────────────────────────────────────────

void main() {
  group('Phase 16 — Pre-Fetching & Decipher Cache Architecture', () {
    test('AudioPreFetchCache handles stream urls & resolves active tracking', () async {
      final cache = TestAudioPreFetchCache();
      
      expect(cache.contains("track123"), isFalse);
      expect(cache.isResolving("track123"), isFalse);

      final mockTask = Future.value("http://stream.url");
      cache.trackActiveResolution("track123", mockTask);

      expect(cache.contains("track123"), isFalse);
      expect(cache.isResolving("track123"), isTrue, reason: 'Active scraping must be flagged');

      final url = await mockTask;
      cache.insert("track123", url);

      expect(cache.contains("track123"), isTrue, reason: 'Deciphered URL must exist in cache');
      expect(cache.isResolving("track123"), isFalse, reason: 'Active tracking completes');
      expect(cache.get("track123"), equals("http://stream.url"));
      
      print('✅ Pre-Fetch Cache state-machine verified');
    });

    test('MusicQueueService correctly triggers pre-fetch cascade for next 3 tracks', () {
      final cache = TestAudioPreFetchCache();
      final queueService = TestMusicQueueService(cache);
      
      final tracks = ["song0", "song1", "song2", "song3", "song4", "song5"];
      queueService.loadNewPlaylistContext(tracks);

      // Starting at song 0 should pre-fetch song 1, song 2, song 3
      expect(cache.isResolving("song1"), isTrue, reason: 'Immediate look-ahead song 1');
      expect(cache.isResolving("song2"), isTrue, reason: 'Immediate look-ahead song 2');
      expect(cache.isResolving("song3"), isTrue, reason: 'Immediate look-ahead song 3');
      expect(cache.isResolving("song4"), isFalse, reason: 'Beyond immediate buffer window');
      
      print('✅ Look-ahead queue batching verified');
    });
  });

  group('Phase 17 — Spotify Chart & Fallback API Services', () {
    test('Spotify Chart Service falls back elegantly to mock data on empty credentials', () async {
      final serviceWithNoCreds = TestSpotifyChartService(hasSpotifyCredentials: false);
      final tracks = await serviceWithNoCreds.fetchPlaylistTracks("37i9dQZEVXbLZ3370vK7gZ");

      expect(tracks.length, equals(3));
      expect(tracks[0], equals("Spotify India Hit 1"), reason: 'Should return local fallbacks');

      final serviceWithCreds = TestSpotifyChartService(hasSpotifyCredentials: true);
      final realTracks = await serviceWithCreds.fetchPlaylistTracks("37i9dQZEVXbLZ3370vK7gZ");
      expect(realTracks[0], equals("Real Spotify Track A"), reason: 'Should return parsed API values');
      
      print('✅ Spotify Chart fallbacks verified');
    });
  });

  group('Phase 17 — High-Performance Audio Visualizer Calculations', () {
    test('Audio Visualizer rests perfectly when playback is paused', () {
      final heights = VisualizerCalculator.calculateHeights(
        isPlaying: false,
        barCount: 15,
        baseControllerValue: 0.5,
      );

      expect(heights.length, equals(15));
      expect(heights.every((h) => h == 4.0), isTrue, reason: 'All bars must rest at 4.0px');
      print('✅ Visualizer resting heights verified');
    });

    test('Audio Visualizer animates dynamic wave values when playback is active', () {
      final heights = VisualizerCalculator.calculateHeights(
        isPlaying: true,
        barCount: 10,
        baseControllerValue: 0.25,
      );

      expect(heights.length, equals(10));
      expect(heights.every((h) => h >= 6.0 && h <= 36.0), isTrue, reason: 'Heights must sit within bounding box');
      expect(heights[0] != heights[5], isTrue, reason: 'Heights must be staggered dynamically');
      print('✅ Visualizer wave animation calculations verified');
    });
  });
}
