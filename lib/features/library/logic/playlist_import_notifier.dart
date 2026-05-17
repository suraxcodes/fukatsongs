import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:fukat_songs/models/song.dart';
import 'package:fukat_songs/providers/music_repository_provider.dart';
import 'package:fukat_songs/features/library/logic/song_download_notifier.dart';
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
  final bool isAutoDownloadEnabled;
  final bool isSaveToPlaylistEnabled;

  PlaylistImportState({
    this.status = ImportStatus.idle,
    this.currentCount = 0,
    this.totalCount = 0,
    this.importedSongs = const [],
    this.failedSongs = const [],
    this.errorMessage,
    this.playlistName,
    this.isAutoDownloadEnabled = false,
    this.isSaveToPlaylistEnabled = true,
  });

  PlaylistImportState copyWith({
    ImportStatus? status,
    int? currentCount,
    int? totalCount,
    List<Song>? importedSongs,
    List<String>? failedSongs,
    String? errorMessage,
    String? playlistName,
    bool? isAutoDownloadEnabled,
    bool? isSaveToPlaylistEnabled,
  }) {
    return PlaylistImportState(
      status: status ?? this.status,
      currentCount: currentCount ?? this.currentCount,
      totalCount: totalCount ?? this.totalCount,
      importedSongs: importedSongs ?? this.importedSongs,
      failedSongs: failedSongs ?? this.failedSongs,
      errorMessage: errorMessage ?? this.errorMessage,
      playlistName: playlistName ?? this.playlistName,
      isAutoDownloadEnabled: isAutoDownloadEnabled ?? this.isAutoDownloadEnabled,
      isSaveToPlaylistEnabled: isSaveToPlaylistEnabled ?? this.isSaveToPlaylistEnabled,
    );
  }
}

@riverpod
class PlaylistImportNotifier extends _$PlaylistImportNotifier {
  final _yt = YoutubeExplode();
  bool _shouldStop = false;

  @override
  PlaylistImportState build() => PlaylistImportState();

  void toggleAutoDownload(bool enabled) {
    state = state.copyWith(isAutoDownloadEnabled: enabled);
  }

  void toggleSaveToPlaylist(bool enabled) {
    state = state.copyWith(isSaveToPlaylistEnabled: enabled);
  }

  void stopImport() {
    _shouldStop = true;
    state = state.copyWith(status: ImportStatus.completed);
    debugPrint('Import stopped by user');
  }

  void reset() {
    _shouldStop = false;
    state = PlaylistImportState();
  }

  Future<void> importFromUrl(String url) async {
    _shouldStop = false;
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
      if (!_shouldStop) {
        state = state.copyWith(status: ImportStatus.error, errorMessage: e.toString());
      }
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
        if (_shouldStop) break;
        final video = videos[i];
        
        try {
          final cleanTitle = video.title
              .replaceAll(RegExp(r'\(.*?\)|\[.*?\]'), '')
              .replaceAll(RegExp(r'official (video|audio|lyric|hd|4k|mv)'), '')
              .trim();
          
          final searchResults = await musicRepo.search('${cleanTitle} ${video.author}');
          Song? matchedSong;
          
          if (searchResults.isNotEmpty) {
            // Strict match for title
            for (var result in searchResults) {
              final resTitle = result.title.toLowerCase();
              final resArtist = result.artist.toLowerCase();
              final targetTitle = cleanTitle.toLowerCase();
              final targetArtist = video.author.toLowerCase().replaceAll('vevo', '').trim();
              
              if (resTitle.contains(targetTitle) || targetTitle.contains(resTitle)) {
                // If it's a YouTube video, the author is the channel. Just match title mostly, or if channel matches artist
                matchedSong = result;
                break;
              }
            }
          }
          
          if (matchedSong == null) {
            matchedSong = Song(
              id: video.id.value,
              title: video.title,
              artist: video.author,
              albumName: 'YouTube Import',
              year: DateTime.now().year.toString(),
              imageUrl: video.thumbnails.standardResUrl,
              duration: video.duration?.inSeconds ?? 0,
              source: 'youtube',
              providers: {'youtube': video.id.value},
            );
          }
          
          found.add(matchedSong);
          
          if (state.isAutoDownloadEnabled) {
            ref.read(downloadNotifierProvider.notifier).downloadSong(matchedSong);
          }

          state = state.copyWith(
            currentCount: i + 1,
            importedSongs: List.from(found),
          );
        } catch (e) {
          missed.add(video.title);
          state = state.copyWith(
            currentCount: i + 1,
            failedSongs: List.from(missed),
          );
        }
      }

      state = state.copyWith(status: ImportStatus.completed);
    } catch (e) {
      if (!_shouldStop) {
        state = state.copyWith(status: ImportStatus.error, errorMessage: 'YouTube Import Error: $e');
      }
    }
  }

  Future<void> _importFromSpotify(String url) async {
    try {
      debugPrint('Starting Spotify import for: $url');
      
      final regExp = RegExp(r'playlist/([a-zA-Z0-9]{15,})');
      final match = regExp.firstMatch(url);
      if (match == null) throw Exception('Invalid Spotify Playlist URL');
      final playlistId = match.group(1);

      final embedUrl = 'https://open.spotify.com/embed/playlist/$playlistId';
      final dio = Dio();
      final response = await dio.get(
        embedUrl,
        options: Options(headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
        }),
      );

      final html = response.data.toString();
      final dataRegExp = RegExp(r'<script id="__NEXT_DATA__" type="application/json">(.*?)</script>');
      final dataMatch = dataRegExp.firstMatch(html);
      
      Map<String, dynamic> entity;
      if (dataMatch != null) {
        final jsonData = jsonDecode(dataMatch.group(1)!);
        entity = jsonData['props']?['pageProps']?['state']?['data']?['entity'] ??
                 jsonData['props']?['pageProps']?['entity'] ??
                 jsonData['props']?['entity'] ??
                 {};
      } else {
        throw Exception('Could not parse Spotify data. Ensure the playlist is public.');
      }

      final playlistName = entity['title'] ?? entity['name'] ?? 'Spotify Import';
      final List tracks = entity['trackList'] ?? entity['items'] ?? [];

      if (tracks.isEmpty) {
        throw Exception('No tracks found in this Spotify playlist.');
      }

      state = state.copyWith(
        status: ImportStatus.matching,
        totalCount: tracks.length,
        playlistName: playlistName,
      );

      final musicRepo = ref.read(musicRepositoryProvider);
      final downloadNotifier = ref.read(downloadNotifierProvider.notifier);
      final List<Song> found = [];
      final List<String> missed = [];

      for (int i = 0; i < tracks.length; i++) {
        if (_shouldStop) break;
        final track = tracks[i];
        final title = track['title'] ?? track['name'] as String? ?? 'Unknown Title';
        
        String artist = 'Unknown Artist';
        if (track['subtitle'] != null) {
          artist = track['subtitle'].toString();
        } else if (track['artists'] != null && track['artists'] is List && (track['artists'] as List).isNotEmpty) {
          artist = track['artists'][0]['name'].toString();
        }
        
        try {
          final cleanTitle = title.toString().replaceAll(RegExp(r'\(.*?\)|\[.*?\]'), '').trim();
          final cleanArtist = artist.split(',').first.trim();
          
          final searchResults = await musicRepo.search('$cleanTitle $cleanArtist');
          Song? matchedSong;
          
          if (searchResults.isNotEmpty) {
            for (var result in searchResults) {
              final resTitle = result.title.toLowerCase();
              final resArtist = result.artist.toLowerCase();
              final targetTitle = cleanTitle.toLowerCase();
              final targetArtist = cleanArtist.toLowerCase();
              
              bool titleMatch = resTitle.contains(targetTitle) || targetTitle.contains(resTitle);
              bool artistMatch = resArtist.contains(targetArtist) || targetArtist.contains(resArtist);
              
              if (titleMatch && artistMatch) {
                matchedSong = result;
                break;
              }
            }
          }
          
          if (matchedSong != null) {
            found.add(matchedSong);
            if (state.isAutoDownloadEnabled) {
              downloadNotifier.downloadSong(matchedSong);
            }
          } else {
            missed.add('$title - $artist');
          }
          
          state = state.copyWith(
            currentCount: i + 1,
            importedSongs: List.from(found),
            failedSongs: List.from(missed),
          );
        } catch (e) {
          missed.add('$title - $artist');
          state = state.copyWith(
            currentCount: i + 1,
            failedSongs: List.from(missed),
          );
        }
      }

      state = state.copyWith(status: ImportStatus.completed);
    } catch (e) {
      if (!_shouldStop) {
        state = state.copyWith(status: ImportStatus.error, errorMessage: e.toString());
      }
    }
  }
}
