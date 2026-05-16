import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/song.dart';

class LyricsState {
  final String? plainLyrics;
  final String? syncedLyrics;
  final bool isLoading;
  final String? error;

  LyricsState({
    this.plainLyrics,
    this.syncedLyrics,
    this.isLoading = false,
    this.error,
  });

  LyricsState copyWith({
    String? plainLyrics,
    String? syncedLyrics,
    bool? isLoading,
    String? error,
  }) {
    return LyricsState(
      plainLyrics: plainLyrics ?? this.plainLyrics,
      syncedLyrics: syncedLyrics ?? this.syncedLyrics,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class LyricsNotifier extends StateNotifier<LyricsState> {
  final Dio _dio = Dio();
  
  LyricsNotifier() : super(LyricsState());

  Future<void> fetchLyrics(Song song) async {
    if (song.title.isEmpty) return;

    state = state.copyWith(isLoading: true, error: null, plainLyrics: null, syncedLyrics: null);

    try {
      print('Lyrics: Fetching exact match for "${song.title}" by "${song.artist}"');
      final response = await _dio.get(
        'https://lrclib.net/api/get',
        queryParameters: {
          'artist_name': song.artist,
          'track_name': song.title,
          'album_name': song.albumName,
          'duration': song.duration,
        },
        options: Options(
          headers: {'User-Agent': 'fukatSongs/1.0'},
          sendTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        print('Lyrics: Found exact match!');
        state = state.copyWith(
          plainLyrics: data['plainLyrics'],
          syncedLyrics: data['syncedLyrics'],
          isLoading: false,
        );
      } else {
        print('Lyrics: Exact match not found (Status: ${response.statusCode})');
        _tryFuzzySearch(song);
      }
    } catch (e) {
      print('Lyrics: Exact match failed, trying fuzzy search...');
      _tryFuzzySearch(song);
    }
  }

  Future<void> _tryFuzzySearch(Song song) async {
    try {
      final title = song.title;
      final artist = song.artist;

      // Strategy 1: Cleaned Title + Artist
      final cleanTitle = _getCleanTitle(title);
      final queries = [
        '$cleanTitle $artist', // Standard
        cleanTitle,            // Just title (often contains artist in YT titles)
      ];

      // If title has a dash, add the first part as a query
      if (cleanTitle.contains('-')) {
        queries.add(cleanTitle.split('-')[0].trim());
      }

      bool found = false;
      for (final query in queries) {
        final queryClean = query.replaceAll(RegExp(r'\s+'), ' ').trim();
        if (queryClean.length < 3) continue;

        print('Lyrics: Searching for "$queryClean"...');
        final searchResponse = await _dio.get(
          'https://lrclib.net/api/search',
          queryParameters: {'q': queryClean},
        );

        if (searchResponse.statusCode == 200 && (searchResponse.data as List).isNotEmpty) {
          final bestMatch = searchResponse.data[0];
          print('Lyrics: Found match for "$queryClean": ${bestMatch['trackName']}');
          state = state.copyWith(
            plainLyrics: bestMatch['plainLyrics'],
            syncedLyrics: bestMatch['syncedLyrics'],
            isLoading: false,
          );
          found = true;
          break;
        }
      }

      if (!found) {
        print('Lyrics: All search strategies failed');
        state = state.copyWith(isLoading: false, error: 'Lyrics not available');
      }
    } catch (err) {
      print('Lyrics: Error during fuzzy search: $err');
      state = state.copyWith(isLoading: false, error: 'Lyrics not found');
    }
  }

  String _getCleanTitle(String title) {
    return title
        .replaceAll(RegExp(r'\(.*\)'), '') // Remove (text)
        .replaceAll(RegExp(r'\[.*\]'), '') // Remove [text]
        .replaceAll(RegExp(r'full video|official video|lyrical|audio|karaoke|piano|cover', caseSensitive: false), '') // Remove common tags
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize spaces
        .trim();
  }

  void clear() {
    state = LyricsState();
  }
}

final lyricsProvider = StateNotifierProvider<LyricsNotifier, LyricsState>((ref) {
  return LyricsNotifier();
});
