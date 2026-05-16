import 'package:dio/dio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/song.dart';
import 'music_provider.dart';

class YouTubeProvider implements MusicProvider {
  final YoutubeExplode _yt = YoutubeExplode();
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://music.youtube.com/youtubei/v1',
    headers: {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Origin': 'https://music.youtube.com',
    },
  ));

  @override
  String get id => 'youtube';

  @override
  String get name => 'YouTube Music';

  @override
  Future<List<Song>> search(String query) async {
    try {
      final response = await _dio.post(
        '/search',
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

      final List<dynamic> runs = response.data['contents']
              ['tabbedSearchResultsRenderer']['tabs'][0]['content']
              ['sectionListRenderer']['contents'][0]['musicShelfRenderer']
          ['contents'];

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

  final List<String> _pipedMirrors = [
    'https://api.piped.private.coffee',
    'https://pipedapi.kavin.rocks',
    'https://piped-api.lunar.icu',
    'https://api-piped.mha.fi',
    'https://pipedapi.oxen.moe',
  ];

  @override
  Future<String?> getStreamUrl(String songId, {String quality = '320'}) async {
    // 1. Try Piped Mirrors first (proxied URLs bypass 403 IP/header blocks in just_audio)
    for (final mirror in _pipedMirrors) {
      try {
        print('--- Attempting YouTube Stealth Tunnel: $mirror');
        final response = await _dio.get('$mirror/streams/$songId');
        if (response.statusCode == 200) {
          final List audioStreams = response.data['audioStreams'];
          final stream = audioStreams.firstWhere(
            (s) => s['format'] == 'M4A' || s['format'] == 'WEBM',
            orElse: () => audioStreams.first,
          );
          return stream['url'];
        }
      } catch (e) {
        print('--- Mirror $mirror failed: $e');
      }
    }

    print('--- All Stealth Tunnels failed for this song.');
    return null;
  }

  @override
  Future<List<Song>> getTrending() async => [];

  Song? _mapToSong(Map<String, dynamic> item) {
    try {
      final videoId = item['playlistItemData']['videoId'];
      final flexColumns = item['flexColumns'] as List;

      // Extract title
      final title = flexColumns[0]['musicResponsiveListItemFlexColumnRenderer']
          ['text']['runs'][0]['text'];

      // Extract artist and album
      final secondColumn =
          flexColumns[1]['musicResponsiveListItemFlexColumnRenderer']['text']
              ['runs'] as List;
      final artist = secondColumn[0]['text'];
      final album = secondColumn.length > 2 ? secondColumn[2]['text'] : 'Unknown';

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

  void dispose() {
    _yt.close();
  }
}
