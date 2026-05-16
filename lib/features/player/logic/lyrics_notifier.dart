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
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        state = state.copyWith(
          plainLyrics: data['plainLyrics'],
          syncedLyrics: data['syncedLyrics'],
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false, error: 'No lyrics found');
      }
    } catch (e) {
      // If exact search fails, try general search
      try {
        final searchResponse = await _dio.get(
          'https://lrclib.net/api/search',
          queryParameters: {
            'q': '${song.title} ${song.artist}',
          },
        );
        
        if (searchResponse.statusCode == 200 && (searchResponse.data as List).isNotEmpty) {
          final bestMatch = searchResponse.data[0];
          state = state.copyWith(
            plainLyrics: bestMatch['plainLyrics'],
            syncedLyrics: bestMatch['syncedLyrics'],
            isLoading: false,
          );
        } else {
          state = state.copyWith(isLoading: false, error: 'Lyrics not available');
        }
      } catch (_) {
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
