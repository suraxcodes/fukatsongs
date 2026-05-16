import 'package:dio/dio.dart';
import '../models/song.dart';
import 'music_provider.dart';

class SaavnProvider implements MusicProvider {
  final List<String> _baseUrls = [
    'https://jiosaavn-api-sigma-sandy.vercel.app',
    'https://saavn.me/api',
    'https://jiosaavn-api-beta.vercel.app',
  ];
  int _currentUrlIndex = 0;

  Dio _getDio() => Dio(BaseOptions(
    baseUrl: _baseUrls[_currentUrlIndex],
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  @override
  String get id => 'saavn';

  @override
  String get name => 'JioSaavn';

  @override
  Future<List<Song>> search(String query) async {
    return _withRetry(() async {
      final dio = _getDio();
      print('--- Saavn Search: ${dio.options.baseUrl}/search/songs?query=$query');
      final response = await dio.get('/search/songs', queryParameters: {'query': query});
      if (response.data['status'] == 'SUCCESS' || response.data['data'] != null) {
        final dynamic rawData = response.data['data'];
        final List data = rawData is List ? rawData : (rawData['results'] ?? []);
        return data.map((json) => _mapToSong(json)).toList();
      }
      return [];
    });
  }

  @override
  Future<String?> getStreamUrl(String songId, {String quality = '320'}) async {
    return _withRetry(() async {
      final dio = _getDio();
      final response = await dio.get('/songs', queryParameters: {'id': songId});
      if (response.data['status'] == 'SUCCESS' || response.data['data'] != null) {
        final List data = response.data['data'] is List ? response.data['data'] : [response.data['data']];
        if (data.isNotEmpty) {
          final downloadUrl = data[0]['downloadUrl'] as List;
          
          // Quality selection logic: find exact match or fall back to highest
          dynamic stream = downloadUrl.firstWhere(
            (s) => s['quality'].toString().contains(quality),
            orElse: () => downloadUrl.last, // Fallback to highest available if requested not found
          );
          
          String link = (stream['link'] ?? stream['url']).toString();
          return link.replaceAll('http:', 'https:');
        }
      }
      return null;
    });
  }

  @override
  Future<List<Song>> getTrending() async {
    return _withRetry(() async {
      final dio = _getDio();
      final response = await dio.get('/modules', queryParameters: {'language': 'hindi,english'});
      if (response.data['status'] == 'SUCCESS' || response.data['data'] != null) {
        final data = response.data['data'];
        if (data != null && data['trending'] != null && data['trending']['songs'] != null) {
          final trending = data['trending']['songs'] as List;
          return trending.map((json) => _mapToSong(json)).toList();
        }
      }
      return [];
    });
  }

  Song _mapToSong(Map<String, dynamic> json) {
    String imageUrl = '';
    try {
      final images = json['image'];
      if (images is List && images.isNotEmpty) {
        imageUrl = images.length > 1 ? images[1]['link'] : images.last['link'];
      } else if (images is String) {
        imageUrl = images;
      }
    } catch (_) {}

    String artistName = 'Unknown';
    try {
      final primary = json['primaryArtists'];
      final artists = json['artists'];
      final artistsObj = primary ?? artists;
      
      if (artistsObj is List && artistsObj.isNotEmpty) {
        artistName = (artistsObj[0]['name'] ?? artistsObj[0]['title'] ?? 'Unknown').toString();
      } else if (artistsObj != null) {
        artistName = artistsObj.toString();
      }
    } catch (_) {}

    return Song(
      id: json['id']?.toString() ?? '',
      title: (json['name'] ?? json['title'] ?? 'Unknown').toString(),
      artist: artistName,
      albumName: (json['album'] is Map ? (json['album']['name'] ?? '') : (json['album'] ?? '')).toString(),
      year: json['year']?.toString() ?? '',
      imageUrl: imageUrl,
      duration: int.tryParse(json['duration']?.toString() ?? '0') ?? 0,
      source: 'saavn',
      providers: {'saavn': json['id']?.toString() ?? ''},
    );
  }

  Future<T> _withRetry<T>(Future<T> Function() action, {int maxRetries = 3}) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        return await action();
      } on DioException catch (e) {
        attempts++;
        print('Saavn attempt $attempts failed on ${_baseUrls[_currentUrlIndex]}: $e');
        
        // Rotate to next mirror for next attempt
        _currentUrlIndex = (_currentUrlIndex + 1) % _baseUrls.length;
        print('--- Rotating to Saavn Lifeboat: ${_baseUrls[_currentUrlIndex]}');
        
        if (attempts >= maxRetries) rethrow;
        await Future.delayed(Duration(seconds: attempts));
      }
    }
    throw Exception('Failed after $maxRetries retries');
  }
}
