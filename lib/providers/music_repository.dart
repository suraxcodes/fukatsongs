import '../models/song.dart';
import 'saavn_provider.dart';
import 'youtube_provider.dart';

class MusicRepository {
  final SaavnProvider _saavn = SaavnProvider();
  final YouTubeProvider _youtube = YouTubeProvider();

  Future<List<Song>> search(String query) async {
    // Parallel execution
    final results = await Future.wait([
      _saavn.search(query),
      _youtube.search(query),
    ]);

    final List<Song> combined = [];
    final Set<String> seenTitles = {};

    // Merge logic: Interleave results for variety
    final saavnResults = results[0];
    final youtubeResults = results[1];

    int i = 0;
    while (i < saavnResults.length || i < youtubeResults.length) {
      if (i < saavnResults.length) {
        final song = saavnResults[i];
        if (!seenTitles.contains(_normalizeTitle(song.title, song.artist))) {
          combined.add(song);
          seenTitles.add(_normalizeTitle(song.title, song.artist));
        }
      }
      if (i < youtubeResults.length) {
        final song = youtubeResults[i];
        if (!seenTitles.contains(_normalizeTitle(song.title, song.artist))) {
          combined.add(song);
          seenTitles.add(_normalizeTitle(song.title, song.artist));
        }
      }
      i++;
    }

    return combined;
  }

  Future<List<Song>> getTrending() async {
    return _saavn.getTrending();
  }

  Future<String?> getStreamUrl(Song song) async {
    if (song.source == 'saavn') {
      return _saavn.getStreamUrl(song.id);
    } else {
      return _youtube.getStreamUrl(song.id);
    }
  }

  String _normalizeTitle(String title, String artist) {
    return '${title.toLowerCase().trim()}|${artist.toLowerCase().trim()}';
  }
}
