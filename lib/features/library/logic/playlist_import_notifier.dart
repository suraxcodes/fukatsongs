import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:fukat_songs/models/song.dart';
import 'package:fukat_songs/providers/music_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'playlist_import_notifier.g.dart';

enum ImportStatus { idle, parsing, matching, completed, error }

class PlaylistImportState {
  final ImportStatus status;
  final int currentCount;
  final int totalCount;
  final List<Song> importedSongs;
  final List<String> failedSongs;
  final String? errorMessage;
  final String? playlistName;

  PlaylistImportState({
    this.status = ImportStatus.idle,
    this.currentCount = 0,
    this.totalCount = 0,
    this.importedSongs = const [],
    this.failedSongs = const [],
    this.errorMessage,
    this.playlistName,
  });

  PlaylistImportState copyWith({
    ImportStatus? status,
    int? currentCount,
    int? totalCount,
    List<Song>? importedSongs,
    List<String>? failedSongs,
    String? errorMessage,
    String? playlistName,
  }) {
    return PlaylistImportState(
      status: status ?? this.status,
      currentCount: currentCount ?? this.currentCount,
      totalCount: totalCount ?? this.totalCount,
      importedSongs: importedSongs ?? this.importedSongs,
      failedSongs: failedSongs ?? this.failedSongs,
      errorMessage: errorMessage ?? this.errorMessage,
      playlistName: playlistName ?? this.playlistName,
    );
  }
}

@riverpod
class PlaylistImportNotifier extends _$PlaylistImportNotifier {
  final _yt = YoutubeExplode();

  @override
  PlaylistImportState build() => PlaylistImportState();

  Future<void> importFromUrl(String url) async {
    state = state.copyWith(status: ImportStatus.parsing, errorMessage: null, importedSongs: [], failedSongs: []);

    try {
      if (url.contains('youtube.com') || url.contains('youtu.be')) {
        await _importFromYoutube(url);
      } else if (url.contains('spotify.com')) {
        await _importFromSpotify(url);
      } else {
        throw Exception('Unsupported URL. Please provide a YouTube or Spotify playlist link.');
      }
    } catch (e) {
      state = state.copyWith(status: ImportStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> _importFromYoutube(String url) async {
    try {
      final playlistId = PlaylistId.parsePlaylistId(url);
      if (playlistId == null) throw Exception('Invalid YouTube Playlist URL');

      final playlist = await _yt.playlists.get(playlistId);
      final videos = await _yt.playlists.getVideos(playlistId).toList();

      state = state.copyWith(
        status: ImportStatus.matching,
        totalCount: videos.length,
        playlistName: playlist.title,
      );

      final musicRepo = ref.read(musicRepositoryProvider);
      final List<Song> found = [];
      final List<String> missed = [];

      for (int i = 0; i < videos.length; i++) {
        final video = videos[i];
        state = state.copyWith(currentCount: i + 1);

        try {
          // Search for a better Saavn match first for high quality
          final cleanTitle = video.title
              .replaceAll(RegExp(r'\(.*?\)|\[.*?\]'), '')
              .replaceAll(RegExp(r'official (video|audio|lyric|hd|4k|mv)'), '')
              .trim();
          
          final searchResults = await musicRepo.search(cleanTitle);
          if (searchResults.isNotEmpty) {
            // Try to find a very close match
            final match = searchResults.first;
            found.add(match);
          } else {
            // Fallback to the YouTube video itself
            found.add(Song(
              id: video.id.value,
              title: video.title,
              artist: video.author,
              albumName: 'YouTube Import',
              year: DateTime.now().year.toString(),
              imageUrl: video.thumbnails.standardResUrl,
              duration: video.duration?.inSeconds ?? 0,
              source: 'youtube',
              providers: {'youtube': video.id.value},
            ));
          }
        } catch (e) {
          missed.add(video.title);
        }
      }

      state = state.copyWith(
        status: ImportStatus.completed,
        importedSongs: found,
        failedSongs: missed,
      );
    } catch (e) {
      state = state.copyWith(status: ImportStatus.error, errorMessage: 'YouTube Import Error: $e');
    }
  }

  Future<void> _importFromSpotify(String url) async {
    // Spotify import requires scraping or a specialized API
    // For now, we'll mark as a placeholder to be implemented or use a simple regex scraper
    state = state.copyWith(status: ImportStatus.error, errorMessage: 'Spotify import coming soon! Try a YouTube link for now.');
  }

  void reset() {
    state = PlaylistImportState();
  }
}
