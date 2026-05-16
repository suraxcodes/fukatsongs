import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/song.dart';

class LyricLine {
  final Duration time;
  final String text;

  LyricLine({required this.time, required this.text});
}

class LyricsState {
  final String? plainLyrics;
  final String? syncedLyrics;
  final List<LyricLine> lyrics;
  final bool isLoading;
  final String? error;

  LyricsState({
    this.plainLyrics,
    this.syncedLyrics,
    this.lyrics = const [],
    this.isLoading = false,
    this.error,
  });

  LyricsState copyWith({
    String? plainLyrics,
    String? syncedLyrics,
    List<LyricLine>? lyrics,
    bool? isLoading,
    String? error,
  }) {
    return LyricsState(
      plainLyrics: plainLyrics ?? this.plainLyrics,
      syncedLyrics: syncedLyrics ?? this.syncedLyrics,
      lyrics: lyrics ?? this.lyrics,
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

    state = state.copyWith(isLoading: true, error: null, plainLyrics: null, syncedLyrics: null, lyrics: []);

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
        final syncedText = data['syncedLyrics'] as String?;
        state = state.copyWith(
          plainLyrics: data['plainLyrics'],
          syncedLyrics: syncedText,
          lyrics: syncedText != null ? _parseLrc(syncedText) : [],
          isLoading: false,
        );
      } else {
        _tryFuzzySearch(song);
      }
    } catch (e) {
      _tryFuzzySearch(song);
    }
  }

  Future<void> _tryFuzzySearch(Song song) async {
    try {
      final cleanTitle = _getCleanTitle(song.title);
      final queries = ['$cleanTitle ${song.artist}', cleanTitle];

      bool found = false;
      for (final query in queries) {
        final queryClean = query.replaceAll(RegExp(r'\s+'), ' ').trim();
        if (queryClean.length < 3) continue;

        final searchResponse = await _dio.get(
          'https://lrclib.net/api/search',
          queryParameters: {'q': queryClean},
        );

        if (searchResponse.statusCode == 200 && (searchResponse.data as List).isNotEmpty) {
          final bestMatch = searchResponse.data[0];
          final syncedText = bestMatch['syncedLyrics'] as String?;
          state = state.copyWith(
            plainLyrics: bestMatch['plainLyrics'],
            syncedLyrics: syncedText,
            lyrics: syncedText != null ? _parseLrc(syncedText) : [],
            isLoading: false,
          );
          found = true;
          break;
        }
      }

      if (!found) {
        state = state.copyWith(isLoading: false, error: 'Lyrics not available');
      }
    } catch (err) {
      state = state.copyWith(isLoading: false, error: 'Lyrics not found');
    }
  }

  List<LyricLine> _parseLrc(String lrc) {
    final List<LyricLine> lines = [];
    final regExp = RegExp(r'\[(\d+):(\d+\.\d+)\](.*)');
    
    for (final line in lrc.split('\n')) {
      final match = regExp.firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = double.parse(match.group(2)!);
        final text = match.group(3)!.trim();
        
        final duration = Duration(
          minutes: minutes,
          seconds: seconds.toInt(),
          milliseconds: ((seconds - seconds.toInt()) * 1000).toInt(),
        );
        
        lines.add(LyricLine(time: duration, text: text));
      }
    }
    return lines;
  }

  String _getCleanTitle(String title) {
    return title
        .replaceAll(RegExp(r'\(.*\)'), '')
        .replaceAll(RegExp(r'\[.*\]'), '')
        .replaceAll(RegExp(r'full video|official video|lyrical|audio|karaoke|piano|cover', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  void clear() {
    state = LyricsState();
  }
}

final lyricsProvider = StateNotifierProvider<LyricsNotifier, LyricsState>((ref) {
  return LyricsNotifier();
});
