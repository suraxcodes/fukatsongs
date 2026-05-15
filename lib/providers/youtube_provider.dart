import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/song.dart';
import 'music_provider.dart';

class YouTubeProvider implements MusicProvider {
  final YoutubeExplode _yt = YoutubeExplode();

  @override
  String get id => 'youtube';

  @override
  String get name => 'YouTube Music';

  @override
  Future<List<Song>> search(String query) async {
    try {
      final results = await _yt.search.search(query);
      return results.map((video) => _mapToSong(video)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<String?> getStreamUrl(String songId) async {
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(songId);
      final audioOnly = manifest.audioOnly.withHighestBitrate();
      return audioOnly.url.toString();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Song>> getTrending() async {
    // YouTube trending is complex, return empty for now
    return [];
  }

  Song _mapToSong(Video video) {
    return Song(
      id: video.id.value,
      title: video.title,
      artist: video.author,
      albumName: 'YouTube Music',
      year: video.uploadDate?.year.toString() ?? '',
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
