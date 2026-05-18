import 'dart:async';

class AudioPreFetchCache {
  // Singleton instance pattern for global application access
  static final AudioPreFetchCache _instance = AudioPreFetchCache._internal();
  factory AudioPreFetchCache() => _instance;
  AudioPreFetchCache._internal();

  // Stores successfully resolved streaming URLs mapped to Spotify/YouTube Track IDs
  final Map<String, String> _urlCache = {};

  // Tracks active resolution operations to prevent duplicate network calls
  final Map<String, Future<String>> _activeResolutions = {};

  void insert(String trackId, String streamingUrl) {
    _urlCache[trackId] = streamingUrl;
  }

  String? get(String trackId) => _urlCache[trackId];

  bool contains(String trackId) => _urlCache.containsKey(trackId);

  bool isResolving(String trackId) => _activeResolutions.containsKey(trackId);

  void trackActiveResolution(String trackId, Future<String> generationTask) {
    _activeResolutions[trackId] = generationTask;
    generationTask.then(
      (_) => _activeResolutions.remove(trackId),
      onError: (_) => _activeResolutions.remove(trackId),
    );
  }

  Future<String>? getActiveResolution(String trackId) => _activeResolutions[trackId];

  void clearAllCache() {
    _urlCache.clear();
    _activeResolutions.clear();
  }
}
