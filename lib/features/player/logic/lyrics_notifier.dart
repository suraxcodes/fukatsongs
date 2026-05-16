import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/song.dart';
import '../presentation/player_notifier.dart';
import '../presentation/player_state.dart';

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
  final Ref ref;
  String? _lastSongId;
  
  LyricsNotifier(this.ref) : super(LyricsState()) {
    // Listen to current song changes
    ref.listen<PlayerState>(playerNotifierProvider, (previous, next) {
      final newSong = next.currentSong;
      if (newSong != null && newSong.id != _lastSongId) {
        _lastSongId = newSong.id;
        fetchLyrics(newSong);
      }
    });
  }

  Future<void> fetchLyrics(Song song) async {
    if (song.title.isEmpty) return;

    // Reset state for new song
    state = LyricsState(isLoading: true);

    try {
      print('Lyrics: Fetching for "${song.title}"');
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
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final syncedText = data['syncedLyrics'] as String?;
        state = state.copyWith(
          plainLyrics: data['plainLyrics'],
          syncedLyrics: syncedText,
          lyrics: syncedText != null ? _parseLrc(syncedText) : [],
          isLoading: false,
        );
      } else {
        await _tryFuzzySearch(song);
      }
    } catch (e) {
      await _tryFuzzySearch(song);
    }
  }

  Future<void> _tryFuzzySearch(Song song) async {
    try {
      final cleanTitle = _getCleanTitle(song.title);
      final queryClean = '$cleanTitle ${song.artist}'.trim();
      
      if (queryClean.length < 3) {
        state = state.copyWith(isLoading: false, error: 'Lyrics not found');
        return;
      }

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
      } else {
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
        
        // Skip empty text lines if any
        if (text.isEmpty && lines.isNotEmpty && lines.last.text.isEmpty) continue;

        final duration = Duration(
          minutes: minutes,
          seconds: seconds.toInt(),
          milliseconds: ((seconds - seconds.toInt()) * 1000).toInt(),
        );
        
        lines.add(LyricLine(time: duration, text: text));
      }
    }
    // Sort by time just in case the API returns them unordered
    lines.sort((a, b) => a.time.compareTo(b.time));
    return lines;
  }

  String _getCleanTitle(String title) {
    return title
        .replaceAll(RegExp(r'\(.*\)'), '')
        .replaceAll(RegExp(r'\[.*\]'), '')
        .replaceAll(RegExp(r'full video|official video|lyrical|audio|karaoke|piano|cover', caseSensitive: false), '')
        .trim();
  }

  void clear() {
    state = LyricsState();
    _lastSongId = null;
  }
}

final lyricsProvider = StateNotifierProvider<LyricsNotifier, LyricsState>((ref) {
  return LyricsNotifier(ref);
});
