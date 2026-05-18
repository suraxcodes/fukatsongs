import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fukat_songs/models/song.dart';

class SpotifyChartService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  // Paste your Spotify Developer credentials here
  final String clientId = "YOUR_SPOTIFY_CLIENT_ID";
  final String clientSecret = "YOUR_SPOTIFY_CLIENT_SECRET";
  String? _accessToken;

  /// Fetches a guest token from Spotify using the Client Credentials Flow
  Future<String> _getAuthToken() async {
    if (_accessToken != null) return _accessToken!;

    // Safe Check: If client credentials are not pasted yet, trigger mock chart fallback
    if (clientId == "YOUR_SPOTIFY_CLIENT_ID" || clientSecret == "YOUR_SPOTIFY_CLIENT_SECRET") {
      throw const FormatException("Spotify Developer credentials not configured.");
    }

    try {
      final base64Credential = base64Encode(utf8.encode("$clientId:$clientSecret"));

      final response = await _dio.post(
        "https://accounts.spotify.com/api/token",
        options: Options(
          headers: {
            'Authorization': 'Basic $base64Credential',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
        data: {'grant_type': 'client_credentials'},
      );

      if (response.statusCode == 200 && response.data != null) {
        _accessToken = response.data['access_token']?.toString();
        return _accessToken!;
      }
      throw Exception("Failed to authenticate with Spotify API (Status: ${response.statusCode})");
    } catch (e) {
      throw Exception("Spotify Authentication error: $e");
    }
  }

  /// Fetches track data from a public Spotify playlist ID and maps them directly to FukatSongs models
  /// Top 50 India Playlist ID: 37i9dQZEVXbLZ3370vK7gZ
  Future<List<Song>> fetchPlaylistTracks(String playlistId) async {
    try {
      final token = await _getAuthToken();
      final response = await _dio.get(
        "https://api.spotify.com/v1/playlists/$playlistId/tracks",
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
        queryParameters: {
          'fields': 'items(track(id,name,duration_ms,artists(name),album(name,release_date,images)))',
          'limit': 20,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> items = response.data['items'] as List<dynamic>? ?? [];
        final List<Song> tracks = [];

        for (var item in items) {
          final track = item['track'];
          if (track == null) continue;

          final String trackId = track['id']?.toString() ?? '';
          final String title = track['name']?.toString() ?? 'Unknown Track';
          final String artist = (track['artists'] as List<dynamic>?)?.map((a) => a['name']).join(', ') ?? 'Unknown Artist';
          final String albumName = track['album']?['name']?.toString() ?? 'Unknown Album';
          final String releaseDate = track['album']?['release_date']?.toString() ?? '';
          final String year = releaseDate.split('-').first;
          final List<dynamic>? images = track['album']?['images'] as List<dynamic>?;
          final String albumArt = (images != null && images.isNotEmpty) ? images.first['url']?.toString() ?? '' : '';
          final int durationSec = (track['duration_ms'] as int? ?? 0) ~/ 1000;

          tracks.add(
            Song(
              id: trackId,
              title: title,
              artist: artist,
              albumName: albumName,
              year: year,
              imageUrl: albumArt,
              duration: durationSec,
              source: 'youtube', // The Vercel Scraper maps Spotify searches directly to YouTube
              providers: {
                'youtube': '', // Resolved dynamically when streaming starts
              },
            ),
          );
        }
        return tracks;
      }
      return _buildMockChartTracks();
    } catch (e) {
      print('--- SpotifyChartService: Spotify API error ($e). Falling back to mock trending charts ---');
      return _buildMockChartTracks();
    }
  }

  /// Ultimate Premium Fallback: Pre-baked trending Bollywood and Global charts
  /// to ensure the app works beautifully out of the box with zero user configuration!
  List<Song> _buildMockChartTracks() {
    return [
      const Song(
        id: "track_believer_imagine",
        title: "Believer",
        artist: "Imagine Dragons",
        albumName: "Evolve",
        year: "2017",
        imageUrl: "https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=400",
        duration: 204,
        source: 'youtube',
        providers: {'youtube': '7wtfhZwyrcc'},
      ),
      const Song(
        id: "track_let_me_love_dj",
        title: "Let Me Love You",
        artist: "DJ Snake, Justin Bieber",
        albumName: "Encore",
        year: "2016",
        imageUrl: "https://images.unsplash.com/photo-1514525253161-7a46d19cd819?q=80&w=400",
        duration: 205,
        source: 'youtube',
        providers: {'youtube': 'euCqAq6dda4'},
      ),
      const Song(
        id: "track_kesariya_arijit",
        title: "Kesariya",
        artist: "Arijit Singh, Pritam",
        albumName: "Brahmastra",
        year: "2022",
        imageUrl: "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?q=80&w=400",
        duration: 268,
        source: 'youtube',
        providers: {'youtube': 'BddP6PYo2Gs'},
      ),
      const Song(
        id: "track_shape_of_you_ed",
        title: "Shape of You",
        artist: "Ed Sheeran",
        albumName: "Divide",
        year: "2017",
        imageUrl: "https://images.unsplash.com/photo-1516280440614-37939bbacd6a?q=80&w=400",
        duration: 233,
        source: 'youtube',
        providers: {'youtube': 'JGwWNGJdvx8'},
      ),
    ];
  }
}

final spotifyChartServiceProvider = Provider<SpotifyChartService>((ref) {
  return SpotifyChartService();
});
