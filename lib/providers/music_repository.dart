import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/song.dart';
import 'saavn_provider.dart';
import 'youtube_provider.dart';

class MusicRepository {
  final SaavnProvider _saavn = SaavnProvider();
  final YouTubeProvider _youtube = YouTubeProvider();

  Future<List<Song>> search(String query, {String source = 'both', int page = 1, int limit = 20}) async {
    final cacheBox = Hive.box<String>('search_cache');
    final cacheKey = '${source}_${query.toLowerCase().trim()}_${page}_${limit}';

    // 1. Check Cache
    if (cacheBox.containsKey(cacheKey)) {
      final cachedData = cacheBox.get(cacheKey)!;
      final parts = cachedData.split('|EXPIRY|');
      final expiry = int.parse(parts[0]);
      
      if (DateTime.now().millisecondsSinceEpoch < expiry) {
        final List<dynamic> jsonList = jsonDecode(parts[1]);
        return jsonList.map((j) => Song.fromJson(j)).toList();
      }
    }

    // 2. Execute based on source
    List<Song> saavnResults = [];
    List<Song> youtubeResults = [];

    if (source == 'saavn' || source == 'both') {
      saavnResults = await _saavn.search(query, page: page, limit: limit).catchError((e) {
        print('Saavn search error: $e');
        return <Song>[];
      });
    }

    if (source == 'youtube' || source == 'both') {
      youtubeResults = await _youtube.search(query, page: page, limit: limit).catchError((e) {
        print('YouTube search error: $e');
        return <Song>[];
      });
    }
    final Map<String, Song> unifiedMap = {};

    for (var song in saavnResults) {
      final key = _normalizeTitle(song.title, song.artist);
      unifiedMap[key] = song;
    }

    for (var song in youtubeResults) {
      final key = _normalizeTitle(song.title, song.artist);
      if (unifiedMap.containsKey(key)) {
        final existing = unifiedMap[key]!;
        unifiedMap[key] = existing.copyWith(
          providers: {...existing.providers, 'youtube': song.id},
        );
      } else {
        unifiedMap[key] = song;
      }
    }

    // --- SMART SEARCH FILTER ---
    // Remove remixes, covers, slowed versions unless user explicitly searched for them
    const blocklist = [
      'slowed', 'reverb', 'lofi', 'lo-fi', 'remix', 'cover',
      'karaoke', 'instrumental', 'sped up', 'nightcore', '8d audio',
      'slowed + reverb', 'slowed reverb', '8d',
    ];

    final queryLower = query.toLowerCase();
    final userWantsFiltered = blocklist.any((term) => queryLower.contains(term));

    List<Song> filteredResults = finalResults;
    if (!userWantsFiltered) {
      filteredResults = finalResults.where((song) {
        final titleLower = song.title.toLowerCase();
        return !blocklist.any((term) => titleLower.contains(term));
      }).toList();
      print('--- MusicRepository: Search filter removed ${finalResults.length - filteredResults.length} remix/cover results ---');
    }

    // 3. Save filtered results to Cache (30 min TTL)
    final expiry = DateTime.now().add(const Duration(minutes: 30)).millisecondsSinceEpoch;
    final cacheValue = '$expiry|EXPIRY|${jsonEncode(filteredResults)}';
    await cacheBox.put(cacheKey, cacheValue);

    return filteredResults;
  }

  final Map<String, _CachedStreamUrl> _streamUrlCache = {};

  Future<List<Song>> getTrending() async {
    return _saavn.getTrending();
  }

  Future<String?> getStreamUrl(Song song, {String? preferredProvider, String quality = '320'}) async {
    final provider = preferredProvider ?? song.source;
    final providerId = song.providers[provider];

    if (providerId == null) return null;

    final cacheKey = '${song.id}_${provider}_$quality';
    if (_streamUrlCache.containsKey(cacheKey)) {
      final cached = _streamUrlCache[cacheKey]!;
      if (cached.expiry.isAfter(DateTime.now())) {
        print('--- MusicRepository: Cache HIT for preloaded stream of ${song.title} ---');
        return cached.url;
      }
      _streamUrlCache.remove(cacheKey);
    }

    print('--- MusicRepository: Fetching $quality quality for $provider ---');

    String? url;
    if (provider == 'saavn') {
      url = await _saavn.getStreamUrl(providerId, quality: quality);
    } else {
      url = await _youtube.getStreamUrl(providerId, quality: quality);
    }

    if (url != null) {
      _streamUrlCache[cacheKey] = _CachedStreamUrl(url, DateTime.now().add(const Duration(hours: 1)));
    }
    return url;
  }

  String _normalizeTitle(String title, String artist) {
    String cleanTitle = title.toLowerCase()
        .replaceAll(RegExp(r'\(.*?\)|\[.*?\]'), '') // Remove brackets
        .replaceAll(RegExp(r'official (video|audio|lyric)'), '')
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove special chars
        .trim();
    
    String cleanArtist = artist.toLowerCase()
        .split(',')[0] // Take primary artist
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .trim();

    return '$cleanTitle|$cleanArtist';
  }
}

class _CachedStreamUrl {
  final String url;
  final DateTime expiry;
  _CachedStreamUrl(this.url, this.expiry);
}
