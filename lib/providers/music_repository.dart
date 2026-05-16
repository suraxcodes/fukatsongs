import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/song.dart';
import 'saavn_provider.dart';
import 'youtube_provider.dart';

class MusicRepository {
  final SaavnProvider _saavn = SaavnProvider();
  final YouTubeProvider _youtube = YouTubeProvider();

  Future<List<Song>> search(String query) async {
    final cacheBox = Hive.box<String>('search_cache');
    final cacheKey = query.toLowerCase().trim();

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

    // 2. Parallel execution with individual error handling
    final results = await Future.wait([
      _saavn.search(query).catchError((e) {
        print('Saavn search error: $e');
        return <Song>[];
      }),
      _youtube.search(query).catchError((e) {
        print('YouTube search error: $e');
        return <Song>[];
      }),
    ]);
    
    // ... (rest of the merging logic remains same)
    final saavnResults = results[0];
    final youtubeResults = results[1];
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

    final finalResults = unifiedMap.values.toList();

    // 3. Save to Cache (30 min TTL)
    final expiry = DateTime.now().add(const Duration(minutes: 30)).millisecondsSinceEpoch;
    final cacheValue = '$expiry|EXPIRY|${jsonEncode(finalResults)}';
    await cacheBox.put(cacheKey, cacheValue);

    return finalResults;
  }

  Future<List<Song>> getTrending() async {
    return _saavn.getTrending();
  }

  Future<String?> getStreamUrl(Song song, {String? preferredProvider, String quality = '320'}) async {
    final provider = preferredProvider ?? song.source;
    final providerId = song.providers[provider];
    print('--- MusicRepository: Fetching $quality quality for $provider ---');

    if (providerId == null) return null;

    if (provider == 'saavn') {
      return _saavn.getStreamUrl(providerId, quality: quality);
    } else {
      return _youtube.getStreamUrl(providerId, quality: quality);
    }
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
