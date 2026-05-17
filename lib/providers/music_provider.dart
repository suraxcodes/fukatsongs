import '../models/song.dart';

abstract class MusicProvider {
  /// Unique identifier for the provider (e.g., 'saavn', 'youtube')
  String get id;

  /// Human-readable name of the provider
  String get name;

  /// Search for songs matching the query
  Future<List<Song>> search(String query, {int page = 1, int limit = 20});

  /// Fetch a fresh stream URL for the given song ID
  Future<String?> getStreamUrl(String songId, {String quality = '320'});

  /// Get trending or recommended songs (optional for V1, but good for abstraction)
  Future<List<Song>> getTrending();
}
