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
  int? _lastFetchedDuration;
  
  LyricsNotifier(this.ref) : super(LyricsState()) {
    // Listen to current song changes and duration changes
    ref.listen<PlayerState>(playerNotifierProvider, (previous, next) {
      final newSong = next.currentSong;
      if (newSong != null) {
        final durationSec = next.totalDuration.inSeconds;
        
        // 1. Initial song change trigger
        if (newSong.id != _lastSongId) {
          _lastSongId = newSong.id;
          _lastFetchedDuration = durationSec > 0 ? durationSec : null;
          fetchLyrics(newSong, duration: durationSec > 0 ? durationSec : null);
        } 
        // 2. Re-fetch when zero duration is finally resolved to actual duration
        else if (durationSec > 0 && _lastFetchedDuration == null && state.lyrics.isEmpty && !state.isLoading) {
          _lastFetchedDuration = durationSec;
          print('--- LyricsNotifier: Song duration resolved to ${durationSec}s. Re-fetching with exact duration! ---');
          fetchLyrics(newSong, duration: durationSec);
        }
      }
    });
  }

  Future<void> fetchLyrics(Song song, {int? duration}) async {
    if (song.title.isEmpty) return;

    // Reset state for new song (unless just updating duration)
    if (state.lyrics.isEmpty || state.error != null) {
      state = LyricsState(isLoading: true);
    }

    final queryDuration = duration ?? song.duration;

    try {
      print('--- LyricsNotifier: Fetching for "${song.title}" (Duration: ${queryDuration}s) ---');
      final response = await _dio.get(
        'https://lrclib.net/api/get',
        queryParameters: {
          'artist_name': song.artist,
          'track_name': _getCleanTitleOnly(song.title, song.artist),
          'album_name': song.albumName,
          'duration': queryDuration,
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
          error: null,
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
      final cleanTitle = _getCleanTitle(song.title, song.artist);
      final queryClean = '$cleanTitle ${song.artist}'.trim();
      
      if (queryClean.length < 3) {
        state = state.copyWith(isLoading: false, error: 'Lyrics not found');
        return;
      }

      print('--- LyricsNotifier: Falling back to fuzzy search: "$queryClean" ---');
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
          error: null,
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

  String _getCleanTitle(String title, String artist) {
    String clean = title
        .replaceAll(RegExp(r'\(.*?\)'), '')
        .replaceAll(RegExp(r'\[.*?\]'), '')
        .replaceAll(RegExp(r'full video|official video|lyrical|audio|karaoke|piano|cover', caseSensitive: false), '')
        .trim();
        
    final artistLower = artist.toLowerCase();
    if (clean.toLowerCase().contains(artistLower)) {
      final idx = clean.toLowerCase().indexOf(artistLower);
      clean = clean.substring(0, idx) + clean.substring(idx + artist.length);
    }
    
    // Clean up stray hyphens, double spaces, and colons
    clean = clean
        .replaceAll(RegExp(r'^\s*[-:\s]\s*|\s*[-:\s]\s*$'), '')
        .replaceAll(RegExp(r'\s+-\s+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
        
    return clean;
  }

  String _getCleanTitleOnly(String title, String artist) {
    String clean = title
        .replaceAll(RegExp(r'\(.*?\)'), '')
        .replaceAll(RegExp(r'\[.*?\]'), '')
        .replaceAll(RegExp(r'full video|official video|lyrical|audio|karaoke|piano|cover', caseSensitive: false), '')
        .trim();
        
    final artistLower = artist.toLowerCase();
    if (clean.toLowerCase().contains(artistLower)) {
      final idx = clean.toLowerCase().indexOf(artistLower);
      clean = clean.substring(0, idx) + clean.substring(idx + artist.length);
    }
    
    return clean.replaceAll(RegExp(r'^\s*[-:\s]\s*|\s*[-:\s]\s*$'), '').trim();
  }

  void clear() {
    state = LyricsState();
    _lastSongId = null;
    _lastFetchedDuration = null;
  }
}

final lyricsProvider = StateNotifierProvider<LyricsNotifier, LyricsState>((ref) {
  return LyricsNotifier(ref);
});
