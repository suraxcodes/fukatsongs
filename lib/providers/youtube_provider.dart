import 'package:dio/dio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'dart:convert';
import 'dart:async';
import '../models/song.dart';
import 'music_provider.dart';

class YouTubeProvider implements MusicProvider {
  final YoutubeExplode _yt = YoutubeExplode();
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  // Layer 1: User-Agent Camouflage
  final List<String> _userAgents = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (iPhone; CPU iPhone OS 17_1_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Mobile/15E148 Safari/604.1',
  ];

  List<String> _pipedMirrors = [
    'https://api.piped.private.coffee',
    'https://pipedapi.kavin.rocks',
    'https://piped-api.lunar.icu',
    'https://api-piped.mha.fi',
    'https://pipedapi.oxen.moe',
    'https://inv.vern.cc',
    'https://invidious.sethforprivacy.com',
    'https://yewtu.be',
  ];

  // Layer 3: Stream Caching
  final Map<String, _CachedStream> _streamCache = {};

  YouTubeProvider() {
    _refreshMirrors();
  }

  // Layer 2: Dynamic Mirror Refreshing
  Future<void> _refreshMirrors() async {
    try {
      final response = await _dio.get(
        'https://raw.githubusercontent.com/TeamPiped/Piped-Frontend/master/src/assets/instance_list.json',
      );
      if (response.statusCode == 200) {
        final List data = (response.data is String)
            ? jsonDecode(response.data)
            : response.data;
        final newMirrors = data
            .where((inst) => inst['api'] == true)
            .map((inst) => inst['api_url'] as String)
            .toList();
        if (newMirrors.isNotEmpty) {
          _pipedMirrors = newMirrors;
          print(
            '--- YouTube Provider: Refreshed ${_pipedMirrors.length} mirrors.',
          );
        }
      }
    } catch (e) {
      print('--- YouTube Provider: Mirror refresh failed, using defaults.');
    }
  }

  String _getRandomUserAgent() => (_userAgents..shuffle()).first;

  @override
  String get id => 'youtube';

  @override
  String get name => 'YouTube Music';

  @override
  Future<List<Song>> search(String query, {int page = 1, int limit = 20}) async {
    try {
      final response = await _dio.post(
        'https://music.youtube.com/youtubei/v1/search',
        options: Options(headers: {'User-Agent': _getRandomUserAgent()}),
        data: {
          'context': {
            'client': {
              'clientName': 'WEB_REMIX',
              'clientVersion': '1.20231204.01.00',
            },
          },
          'query': query,
          'params': 'EgWKAQIIAWoKEAkQBRAKEAMQBA==', // "Songs" filter
        },
      );

      final List<dynamic> runs = response
          .data['contents']['tabbedSearchResultsRenderer']['tabs'][0]['content']['sectionListRenderer']['contents'][0]['musicShelfRenderer']['contents'];

      return runs
          .map((item) => _mapToSong(item['musicResponsiveListItemRenderer']))
          .whereType<Song>()
          .toList();
    } catch (e) {
      // Fallback to basic search if internal API fails
      try {
        final results = await _yt.search.search(query);
        return results.map((video) => _mapBasicVideoToSong(video)).toList();
      } catch (_) {
        return [];
      }
    }
  }

  @override
  Future<String?> getStreamUrl(String songId, {String quality = '320'}) async {
    // Check Cache first
    if (_streamCache.containsKey(songId)) {
      final cached = _streamCache[songId]!;
      if (cached.expiry.isAfter(DateTime.now())) {
        print('--- YouTube Provider: Cache HIT for $songId');
        return cached.url;
      }
      _streamCache.remove(songId);
    }

    String? songTitle;
    try {
      final video = await _yt.videos.get(songId);
      songTitle = video.title;
    } catch (e) {
      print(
        '--- YouTube Provider: Failed to fetch metadata for Magic Switch: $e',
      );
    }

    // 1. Try Piped Mirrors in parallel (RACING MODE)
    // We launch all requests and take the FIRST successful one immediately.
    print('--- YouTube Provider: Racing 4 mirrors...');
    
    final successfulUrl = await _raceMirrors(songId);
    
    if (successfulUrl != null) {
      // Cache for 2 hours
      _streamCache[songId] = _CachedStream(
        successfulUrl,
        DateTime.now().add(const Duration(hours: 2)),
      );
      return successfulUrl;
    }

    print('--- All Stealth Tunnels failed or timed out.');
    // --- STAGE 3: THE MAGIC SWITCH (Saavn Matching Fallback) ---
    print('--- YouTube Provider: Tunnels failed. Activating Magic Switch...');
    try {
      // Clean title for better Saavn matching
      final cleanTitle = (songTitle ?? "Music")
          .replaceAll(RegExp(r'\(.*?\)|\[.*?\]'), '')
          .replaceAll(
            RegExp(r'official (video|audio|lyric|audio|hd|4k|mv)'),
            '',
          )
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .trim();

      print('--- MAGIC SWITCH: Searching Saavn for: $cleanTitle');

      final saavnResponse = await _dio.get(
        'https://jiosaavn-api-sigma-sandy.vercel.app/search/songs',
        queryParameters: {'query': cleanTitle},
        options: Options(headers: {'User-Agent': _getRandomUserAgent()}),
      );

      var data = saavnResponse.data;
      if (data is String) {
        data = jsonDecode(data);
      }

      if (data['status'] == 'SUCCESS') {
        final List songList = data['data'] is List
            ? data['data']
            : (data['data']['results'] ?? []);
        if (songList.isNotEmpty) {
          final bestMatch = songList[0];
          final List downloadUrls = bestMatch['downloadUrl'];

          // Always pick 320kbps if available (it's usually the last one)
          final bestStream = downloadUrls.firstWhere(
            (s) => s['quality'] == '320kbps',
            orElse: () => downloadUrls.last,
          );

          print(
            '--- MAGIC SWITCH SUCCESS: Playing 320kbps match from Saavn: ${bestMatch['name']}',
          );
          return bestStream['link'];
        }
      }
    } catch (e) {
      print('--- MAGIC SWITCH FAILED: $e');
    }

    print('--- YouTube Provider: All fallback methods exhausted.');
    return null;
  }

  @override
  Future<List<Song>> getTrending() async => [];

  Song? _mapToSong(Map<String, dynamic> item) {
    try {
      final videoId = item['playlistItemData']['videoId'];
      final flexColumns = item['flexColumns'] as List;

      // Extract title
      final title =
          flexColumns[0]['musicResponsiveListItemFlexColumnRenderer']['text']['runs'][0]['text'];

      // Extract artist and album
      final secondColumn =
          flexColumns[1]['musicResponsiveListItemFlexColumnRenderer']['text']['runs']
              as List;
      final artist = secondColumn[0]['text'];
      final album = secondColumn.length > 2
          ? secondColumn[2]['text']
          : 'Unknown';

      // Extract thumbnail
      final thumbnails =
          item['thumbnail']['musicThumbnailRenderer']['thumbnail']['thumbnails']
              as List;
      final imageUrl = thumbnails.last['url'];

      return Song(
        id: videoId,
        title: title,
        artist: artist,
        albumName: album,
        year: '2024',
        imageUrl: imageUrl,
        duration: 0, // Duration requires another API call or parsing runs
        source: 'youtube',
        providers: {'youtube': videoId},
      );
    } catch (e) {
      return null;
    }
  }

  Song _mapBasicVideoToSong(Video video) {
    return Song(
      id: video.id.value,
      title: video.title,
      artist: video.author,
      albumName: 'YouTube Music',
      year: '2024',
      imageUrl: video.thumbnails.standardResUrl,
      duration: video.duration?.inSeconds ?? 0,
      source: 'youtube',
      providers: {'youtube': video.id.value},
    );
  }

  Future<String?> _raceMirrors(String songId) async {
    final completer = Completer<String?>();
    int failedCount = 0;
    final List<String> mirrorsToTry = (_pipedMirrors..shuffle()).take(4).toList();
    final int total = mirrorsToTry.length;

    for (final mirror in mirrorsToTry) {
      _dio
          .get(
            '$mirror/streams/$songId',
            options: Options(headers: {'User-Agent': _getRandomUserAgent()}),
          )
          .timeout(const Duration(seconds: 5))
          .then((response) {
        if (!completer.isCompleted) {
          if (response.statusCode == 200) {
            final List audioStreams = response.data['audioStreams'];
            if (audioStreams.isNotEmpty) {
              audioStreams.sort(
                (a, b) => (b['bitrate'] ?? 0).compareTo(a['bitrate'] ?? 0),
              );
              final url = audioStreams.first['url'] as String;
              print('--- RACING WINNER: $mirror | Bitrate: ${audioStreams.first['bitrate']}kbps');
              completer.complete(url);
            } else {
              failedCount++;
            }
          } else {
            failedCount++;
          }
        }
      }).catchError((e) {
        if (!completer.isCompleted) {
          failedCount++;
          if (failedCount >= total) {
            completer.complete(null);
          }
        }
      });
    }

    // Overall timeout for the entire race
    Timer(const Duration(seconds: 6), () {
      if (!completer.isCompleted) {
        print('--- RACING: All mirrors timed out after 6s');
        completer.complete(null);
      }
    });

    return completer.future;
  }

  void dispose() {
    _yt.close();
  }
}

class _CachedStream {
  final String url;
  final DateTime expiry;
  _CachedStream(this.url, this.expiry);
}
