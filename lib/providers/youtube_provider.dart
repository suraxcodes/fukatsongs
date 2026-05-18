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
    'https://pipedapi.kavin.rocks',
    'https://pipedapi.leptons.xyz',
    'https://pipedapi.nosebs.ru',
    'https://pipedapi-libre.kavin.rocks',
    'https://piped-api.privacy.com.de',
    'https://pipedapi.adminforge.de',
    'https://api.piped.yt',
    'https://pipedapi.drgns.space',
    'https://pipedapi.owo.si',
    'https://pipedapi.ducks.party',
    'https://piped-api.codespace.cz',
    'https://pipedapi.reallyaweso.me',
    'https://api.piped.private.coffee',
    'https://pipedapi.darkness.services',
    'https://pipedapi.orangenet.cc',
  ];

  List<String> _invidiousMirrors = [
    'https://inv.nadeko.net',
    'https://invidious.nerdvpn.de',
    'https://yt.chocolatemoo53.com',
    'https://inv.thepixora.com',
  ];

  // Layer 3: Stream Caching
  final Map<String, _CachedStream> _streamCache = {};

  YouTubeProvider() {
    _refreshMirrors();
  }

  // Layer 2: Dynamic Mirror Refreshing
  Future<void> _refreshMirrors() async {
    // 1. Refresh Piped mirrors
    try {
      print('--- YouTube Provider: Dynamic refresh of Piped mirrors... ---');
      final response = await _dio.get(
        'https://piped-instances.kavin.rocks',
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final List data = (response.data is String)
            ? jsonDecode(response.data)
            : response.data;
        
        final List<String> newMirrors = [];
        for (var inst in data) {
          final apiUrl = inst['api_url']?.toString().trim();
          if (apiUrl != null && apiUrl.isNotEmpty) {
            newMirrors.add(apiUrl);
          }
        }
        
        if (newMirrors.isNotEmpty) {
          _pipedMirrors = newMirrors;
          print('--- YouTube Provider: Dynamic Piped mirrors refreshed: ${_pipedMirrors.length} mirrors ---');
        }
      }
    } catch (e) {
      print('--- YouTube Provider: Piped mirror refresh failed: $e ---');
    }

    // 2. Refresh Invidious mirrors
    try {
      print('--- YouTube Provider: Dynamic refresh of Invidious mirrors... ---');
      final response = await _dio.get(
        'https://api.invidious.io/instances.json?sort_by=type,users',
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final List data = (response.data is String)
            ? jsonDecode(response.data)
            : response.data;
        
        final List<String> newInvidious = [];
        for (var item in data) {
          if (item is List && item.length > 1) {
            final name = item[0]?.toString() ?? '';
            final details = item[1];
            if (details is Map) {
              final isApi = details['api'] == true;
              final isHttps = details['type'] == 'https';
              final uri = details['uri']?.toString() ?? 'https://$name';
              if (isHttps && uri.isNotEmpty) {
                newInvidious.add(uri);
              }
            }
          }
        }
        
        if (newInvidious.isNotEmpty) {
          _invidiousMirrors = newInvidious;
          print('--- YouTube Provider: Dynamic Invidious mirrors refreshed: ${_invidiousMirrors.length} mirrors ---');
        }
      }
    } catch (e) {
      print('--- YouTube Provider: Invidious mirror refresh failed: $e ---');
    }
  }

  String _getRandomUserAgent() => (_userAgents..shuffle()).first;

  @override
  String get id => 'youtube';

  @override
  String get name => 'YouTube Music';

  @override
  Future<List<Song>> search(
    String query, {
    int page = 1,
    int limit = 20,
  }) async {
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
      print(
        '--- YouTube Provider: Primary search failed. Trying Piped search... ---',
      );
      try {
        final pipedResults = await _searchPipedMirrors(query);
        if (pipedResults.isNotEmpty) return pipedResults;
      } catch (_) {}

      // Ultimate backup: Fallback to basic YoutubeExplode search
      print(
        '--- YouTube Provider: Piped search failed. Trying basic YoutubeExplode search... ---',
      );
      try {
        final results = await _yt.search.search(query);
        return results.map((video) => _mapBasicVideoToSong(video)).toList();
      } catch (_) {
        return [];
      }
    }
  }

  Future<List<Song>> _searchPipedMirrors(String query) async {
    final List<String> mirrorsToTry = (_pipedMirrors..shuffle())
        .take(3)
        .toList();
    for (final mirror in mirrorsToTry) {
      try {
        print('--- YouTube Provider: Trying Piped search mirror: $mirror ---');
        final response = await _dio
            .get(
              '$mirror/search',
              queryParameters: {'q': query, 'filter': 'music_songs'},
            )
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final List items = response.data['items'] ?? [];
          if (items.isNotEmpty) {
            print(
              '--- YouTube Provider: Piped search mirror SUCCESS: $mirror ---',
            );
            final List<Song> songs = [];
            for (var item in items) {
              final url = item['url']?.toString() ?? '';
              if (url.contains('/watch?v=')) {
                final videoId = url.replaceAll('/watch?v=', '');
                final title = item['title'] ?? 'Unknown';
                final artist = item['uploaderName'] ?? 'Unknown';
                final imageUrl = item['thumbnail'] ?? '';
                final duration = item['duration'] as int? ?? 0;

                songs.add(
                  Song(
                    id: videoId,
                    title: title,
                    artist: artist,
                    albumName: 'YouTube Music',
                    year: '2024',
                    imageUrl: imageUrl,
                    duration: duration,
                    source: 'youtube',
                    providers: {'youtube': videoId},
                  ),
                );
              }
            }
            if (songs.isNotEmpty) return songs;
          }
        }
      } catch (e) {
        print('--- Piped search mirror FAILED: $mirror ($e) ---');
      }
    }
    return [];
  }

  void clearCache(String songId) {
    _streamCache.remove(songId);
    print('--- YouTube Provider: Cleared cached stream URL for $songId ---');
  }

  @override
  Future<String?> getStreamUrl(String songId, {String quality = '320', String? fallbackSearchTitle}) async {
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
    String? expectedArtist;
    bool forceSaavn = false;

    // Parse fallbackSearchTitle if it contains piped title, artist, and force_saavn flag
    if (fallbackSearchTitle != null && fallbackSearchTitle.contains('|')) {
      final parts = fallbackSearchTitle.split('|');
      songTitle = parts[0].trim();
      expectedArtist = parts[1].trim();
      if (parts.length > 2 && parts[2].trim() == 'force_saavn') {
        forceSaavn = true;
      }
    } else {
      songTitle = fallbackSearchTitle;
    }

    try {
      final video = await _yt.videos.get(songId).timeout(const Duration(milliseconds: 2500));
      if (video.title.isNotEmpty) {
        songTitle = video.title;
      }
      if (expectedArtist == null || expectedArtist.isEmpty) {
        expectedArtist = video.author;
      }
    } catch (e) {
      print(
        '--- YouTube Provider: Failed to fetch metadata for Magic Switch: $e',
      );
    }

    if (!forceSaavn) {
      // --- STAGE 1: PIPED MIRRORS (Racing Mode) ---
      // We launch all requests and take the FIRST successful one immediately.
      try {
        print(
          '--- YouTube Provider: Layer 1 - Racing ${_pipedMirrors.length} Piped mirrors...',
        );

        final successfulUrl = await _raceMirrors(songId);

        if (successfulUrl != null) {
          // Cache for 2 hours
          _streamCache[songId] = _CachedStream(
            successfulUrl,
            DateTime.now().add(const Duration(hours: 2)),
          );
          print('--- YouTube Provider: Layer 1 Piped/Invidious Racing SUCCESS ---');
          return successfulUrl;
        } else {
          print('--- YouTube Provider: Layer 1 Piped/Invidious Racing FAILED. Trying Stage 2 Fallback... ---');
        }
      } catch (e) {
        print('--- YouTube Provider: Layer 1 Piped Racing FAILED: $e ---');
      }

      // --- STAGE 2: DIRECT EXTRACTION (WITH HTTP VERIFICATION) ---
      try {
        print('--- YouTube Provider: Layer 2 - Direct Extraction ---');
        final manifest = await _yt.videos.streamsClient.getManifest(songId).timeout(const Duration(milliseconds: 5000));
        final audioStream = manifest.audioOnly.withHighestBitrate();
        final url = audioStream.url.toString();

        // ✅ RAPID HTTP VERIFICATION: Verify the URL is not blocked (403) before returning
        print(
          '--- YouTube Provider: Layer 2 - Verifying stream URL validity... ---',
        );
        final response = await _dio
            .get(
              url,
              options: Options(
                headers: {
                  'User-Agent':
                      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                  'Range':
                      'bytes=0-0', // Request just 1 byte to keep it ultra-fast and lightweight
                },
                validateStatus: (status) => true,
              ),
            )
            .timeout(const Duration(milliseconds: 4000));

        if (response.statusCode != 403) {
          _streamCache[songId] = _CachedStream(
            url,
            DateTime.now().add(const Duration(hours: 2)),
          );
          print(
            '--- YouTube Provider: Layer 2 SUCCESS (Verified ${response.statusCode}) ---',
          );
          return url;
        } else {
          print(
            '--- YouTube Provider: Layer 2 FAILED (Verified 403 Forbidden). ---',
          );
        }
      } catch (e) {
        print('--- YouTube Provider: Layer 2 FAILED: $e ---');
      }

      print('--- All YouTube layers failed or timed out.');
    } else {
      print('--- YouTube Provider: force_saavn detected! Skipping Stage 1 and 2 to activate JioSaavn Magic Switch directly... ---');
    }
    // --- STAGE 3: JIOSAAVN MAGIC SWITCH ---
    print(
      '--- YouTube Provider: Layer 3 - Activating JioSaavn Magic Switch...',
    );
    try {
      // Clean title for better Saavn matching
      final cleanTitle = (songTitle ?? fallbackSearchTitle ?? "Music")
          .replaceAll(RegExp(r'\(.*?\)|\[.*?\]'), '')
          .replaceAll(
            RegExp(r'official (video|audio|lyric|audio|hd|4k|mv)'),
            '',
          )
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .trim();

      // Enforce artist in query for maximum relevance
      String searchQuery = cleanTitle;
      if (expectedArtist != null && expectedArtist.isNotEmpty) {
        final cleanArtist = expectedArtist
            .replaceAll(RegExp(r'\(.*?\)|\[.*?\]'), '')
            .replaceAll(RegExp(r'[^\w\s]'), '')
            .trim();
        searchQuery = '$cleanArtist $cleanTitle';
      }

      print('--- MAGIC SWITCH: Searching Saavn for: $searchQuery');

      final List<String> saavnMirrors = [
        'https://jiosaavn-api-sigma-sandy.vercel.app',
        'https://saavn.me/api',
        'https://jiosaavn-api-beta.vercel.app',
      ];

      Response? saavnResponse;
      for (final mirror in saavnMirrors) {
        try {
          print('--- MAGIC SWITCH: Trying Saavn mirror: $mirror ---');
          final response = await _dio.get(
            '$mirror/search/songs',
            queryParameters: {'query': searchQuery},
            options: Options(headers: {'User-Agent': _getRandomUserAgent()}),
          ).timeout(const Duration(seconds: 4));
          
          if (response.statusCode == 200) {
            var data = response.data;
            if (data is String) {
              data = jsonDecode(data);
            }
            if (data['status'] == 'SUCCESS' || data['data'] != null) {
              saavnResponse = response;
              break;
            }
          }
        } catch (e) {
          print('--- MAGIC SWITCH: Saavn mirror failed: $mirror ($e) ---');
        }
      }

      if (saavnResponse == null) {
        throw Exception('All Saavn mirrors failed');
      }

      var data = saavnResponse.data;
      if (data is String) {
        data = jsonDecode(data);
      }

      if (data['status'] == 'SUCCESS') {
        final List songList = data['data'] is List
            ? data['data']
            : (data['data']['results'] ?? []);
        if (songList.isNotEmpty) {
          // Intelligent Best Match Selection (Filters out covers/karaoke/instrumentals to get official vocals)
          dynamic bestMatch;
          final queryLower = cleanTitle.toLowerCase();
          final userWantsCover = queryLower.contains('cover') || 
                                 queryLower.contains('karaoke') || 
                                 queryLower.contains('instrumental') || 
                                 queryLower.contains('tribute');
          
          if (!userWantsCover) {
            // First pass: Match BOTH Title (no block words) AND Artist
            for (final song in songList) {
              final songName = (song['name'] ?? song['title'] ?? '').toString().toLowerCase();
              final hasBlockWord = songName.contains('cover') || 
                                   songName.contains('karaoke') || 
                                   songName.contains('instrumental') || 
                                   songName.contains('tribute') ||
                                   songName.contains('originally performed by');
              
              if (!hasBlockWord) {
                // Extract artist name
                String songArtist = '';
                try {
                  final primary = song['primaryArtists'];
                  final artists = song['artists'];
                  final artistsObj = primary ?? artists;
                  if (artistsObj is List && artistsObj.isNotEmpty) {
                    songArtist = (artistsObj[0]['name'] ?? artistsObj[0]['title'] ?? '').toString().toLowerCase();
                  } else if (artistsObj != null) {
                    songArtist = artistsObj.toString().toLowerCase();
                  }
                } catch (_) {}

                bool artistMatches = true;
                if (expectedArtist != null && expectedArtist.isNotEmpty) {
                  final expArtistLower = expectedArtist.toLowerCase().trim();
                  artistMatches = songArtist.contains(expArtistLower) || 
                                  expArtistLower.contains(songArtist) ||
                                  songArtist.split(',').any((a) => a.trim().contains(expArtistLower));
                }

                if (artistMatches) {
                  bestMatch = song;
                  break;
                }
              }
            }

            // Second pass: If no artist match found, fallback to title-only blocklist matching
            if (bestMatch == null) {
              print('--- MAGIC SWITCH: No perfect artist match found, falling back to title-only blocklist matching ---');
              for (final song in songList) {
                final songName = (song['name'] ?? song['title'] ?? '').toString().toLowerCase();
                final hasBlockWord = songName.contains('cover') || 
                                     songName.contains('karaoke') || 
                                     songName.contains('instrumental') || 
                                     songName.contains('tribute') ||
                                     songName.contains('originally performed by');
                if (!hasBlockWord) {
                  bestMatch = song;
                  break;
                }
              }
            }
          }
          
          bestMatch ??= songList[0];
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

    // Take up to 3 random Piped mirrors and 3 random Invidious mirrors
    final pipedToTry = (_pipedMirrors..shuffle()).take(3).toList();
    final invidiousToTry = (_invidiousMirrors..shuffle()).take(3).toList();

    print('--- YouTube Provider: Piped mirrors selected for race: $pipedToTry ---');
    print('--- YouTube Provider: Invidious mirrors selected for race: $invidiousToTry ---');

    final List<_MirrorJob> jobs = [];
    for (final m in pipedToTry) {
      jobs.add(_MirrorJob(url: '$m/streams/$songId', isPiped: true));
    }
    for (final m in invidiousToTry) {
      jobs.add(_MirrorJob(url: '$m/api/v1/videos/$songId', isPiped: false));
    }

    final int total = jobs.length;
    if (total == 0) return null;

    for (final job in jobs) {
      _dio
          .get(
            job.url,
            options: Options(headers: {'User-Agent': _getRandomUserAgent()}),
          )
          .timeout(const Duration(seconds: 5))
          .then((response) {
            if (!completer.isCompleted) {
              if (response.statusCode == 200 && response.data != null) {
                var data = response.data;
                if (data is String) {
                  data = jsonDecode(data);
                }

                if (job.isPiped) {
                  // Parse Piped response
                  final List? audioStreams = data['audioStreams'];
                  if (audioStreams != null && audioStreams.isNotEmpty) {
                    audioStreams.sort(
                      (a, b) =>
                          (b['bitrate'] ?? 0).compareTo(a['bitrate'] ?? 0),
                    );
                    final url = audioStreams.first['url'] as String;
                    print('--- RACING WINNER (Piped): ${job.url} ---');
                    completer.complete(url);
                    return;
                  }
                } else {
                  // Parse Invidious response
                  final formats = data['adaptiveFormats'] as List?;
                  if (formats != null) {
                    final audioStream = formats.firstWhere(
                      (f) => f['type'].toString().contains('audio'),
                      orElse: () => null,
                    );
                    if (audioStream != null && audioStream['url'] != null) {
                      final url = audioStream['url'] as String;
                      print('--- RACING WINNER (Invidious): ${job.url} ---');
                      completer.complete(url);
                      return;
                    }
                  }
                }
              }

              failedCount++;
              if (failedCount >= total) {
                completer.complete(null);
              }
            }
          })
          .catchError((e) {
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

class _MirrorJob {
  final String url;
  final bool isPiped;
  _MirrorJob({required this.url, required this.isPiped});
}

class _CachedStream {
  final String url;
  final DateTime expiry;
  _CachedStream(this.url, this.expiry);
}
