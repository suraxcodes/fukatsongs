import 'package:dio/dio.dart';
import '../models/song.dart';
import 'music_provider.dart';

class SaavnProvider implements MusicProvider {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://saavn.me/api',
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
      final response = await _dio.get('/search/songs', queryParameters: {'query': query});
      if (response.data['status'] == 'SUCCESS') {
        final List data = response.data['data'];
        return data.map((json) => _mapToSong(json)).toList();
      }
      return [];
    });
  }

  @override
  Future<String?> getStreamUrl(String songId) async {
    return _withRetry(() async {
      final response = await _dio.get('/songs', queryParameters: {'id': songId});
      if (response.data['status'] == 'SUCCESS') {
        final List data = response.data['data'];
        if (data.isNotEmpty) {
          final downloadUrl = data[0]['downloadUrl'] as List;
          // Get the highest quality (last one usually)
          return downloadUrl.last['link'];
        }
      }
      return null;
    });
  }

  @override
  Future<List<Song>> getTrending() async {
    return _withRetry(() async {
      final response = await _dio.get('/modules', queryParameters: {'language': 'hindi,english'});
      if (response.data['status'] == 'SUCCESS') {
        final trending = response.data['data']['trending']['songs'] as List;
        return trending.map((json) => _mapToSong(json)).toList();
      }
      return [];
    });
  }

  Song _mapToSong(Map<String, dynamic> json) {
    final images = json['image'] as List;
    // image[1] is usually 150x150
    final imageUrl = images.length > 1 ? images[1]['link'] : images.last['link'];

    return Song(
      id: json['id'],
      title: json['name'],
      artist: json['primaryArtists'],
      albumName: json['album']['name'],
      year: json['year'].toString(),
      imageUrl: imageUrl,
      duration: int.tryParse(json['duration'].toString()) ?? 0,
      source: 'saavn',
      providers: {'saavn': json['id']},
    );
  }

  Future<T> _withRetry<T>(Future<T> Function() action, {int maxRetries = 3}) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        return await action();
      } on DioException catch (_) {
        attempts++;
        if (attempts >= maxRetries) rethrow;
        // Exponential backoff or simple delay
        await Future.delayed(Duration(seconds: attempts));
      }
    }
    throw Exception('Failed after $maxRetries retries');
  }
}
