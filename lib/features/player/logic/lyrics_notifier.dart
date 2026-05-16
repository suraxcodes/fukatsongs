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
        state = state.copyWith(isLoading: false, error: 'No lyrics found');
      }
    } catch (e) {
      print('Lyrics: Exact match failed, trying fuzzy search...');
      // If exact search fails, try general search
      try {
        final songTitleClean = song.title
          .replaceAll(RegExp(r'\(.*\)'), '')
          .replaceAll(RegExp(r'\[.*\]'), '')
          .replaceAll('Full Video', '')
          .replaceAll('Official Video', '')
          .replaceAll('Lyrical', '')
          .replaceAll('Audio', '')
          .trim();
          
        final searchQuery = '$songTitleClean ${song.artist}'.trim();
        print('Lyrics: Searching for "$searchQuery"');
        
        final searchResponse = await _dio.get(
          'https://lrclib.net/api/search',
          queryParameters: {
            'q': searchQuery,
          },
        );
        
        if (searchResponse.statusCode == 200 && (searchResponse.data as List).isNotEmpty) {
          final bestMatch = searchResponse.data[0];
          print('Lyrics: Found fuzzy match: ${bestMatch['trackName']}');
          state = state.copyWith(
            plainLyrics: bestMatch['plainLyrics'],
            syncedLyrics: bestMatch['syncedLyrics'],
            isLoading: false,
          );
        } else {
          print('Lyrics: No matches found in fuzzy search');
          state = state.copyWith(isLoading: false, error: 'Lyrics not available');
        }
      } catch (err) {
        print('Lyrics: Error during fuzzy search: $err');
        state = state.copyWith(isLoading: false, error: 'Lyrics not found');
      }
    }
  }

  void clear() {
    state = LyricsState();
  }
}

final lyricsProvider = StateNotifierProvider<LyricsNotifier, LyricsState>((ref) {
  return LyricsNotifier();
});
