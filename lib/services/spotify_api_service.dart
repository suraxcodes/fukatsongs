import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:fukatsongs/src/rust/api/plugin/models.dart';

/// Minimal Spotify Web API client with PKCE-based auth helper.
///
/// Notes:
/// - Requires a registered Spotify app with a redirect URI set to
///   `http://localhost:<port>/callback`.
/// - This implementation opens the system browser and starts a temporary
///   local HTTP server to receive the authorization code (desktop/mobile
///   behavior may vary). It intentionally keeps the implementation
///   self-contained for the app to perform PKCE without additional
///   native plumbing.
class SpotifyApiService {
  final Dio _dio;
  final String clientId;

  String? _accessToken;
  String? _refreshToken;

  SpotifyApiService({required this.clientId, Dio? dio}) : _dio = dio ?? Dio();

  void setAccessToken(String token, {String? refreshToken}) {
    _accessToken = token;
    _refreshToken = refreshToken;
  }

  /// PKCE flow: opens browser and listens for redirect on localhost.
  /// Returns when tokens are obtained and stored internally.
  Future<void> authenticateWithPKCE({int listenPort = 4390}) async {
    final verifier = _generateCodeVerifier();
    final challenge = _codeChallengeFromVerifier(verifier);

    final redirectUri = 'http://127.0.0.1:$listenPort/callback';
    final authUrl = Uri.https('accounts.spotify.com', '/authorize', {
      'client_id': clientId,
      'response_type': 'code',
      'redirect_uri': redirectUri,
      'code_challenge_method': 'S256',
      'code_challenge': challenge,
      'scope': 'playlist-read-private playlist-read-collaborative',
      'show_dialog': 'true',
    }).toString();

    // Start temporary HTTP server
    final server =
        await HttpServer.bind(InternetAddress.loopbackIPv4, listenPort);

    await launchUrlString(authUrl, webOnlyWindowName: '_blank');

    final req = await server.firstWhere((r) => r.uri.path == '/callback');
    final code = req.uri.queryParameters['code'];

    // Respond to browser immediately.
    req.response.statusCode = 200;
    req.response.headers.contentType = ContentType.html;
    req.response.write(
        '<html><body><h3>Authentication complete. You can close this window.</h3></body></html>');
    await req.response.close();
    await server.close(force: true);

    if (code == null)
      throw Exception('Authorization code missing from redirect.');

    // Exchange code for tokens
    final tokenResp = await _dio.post(
      'https://accounts.spotify.com/api/token',
      data: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUri,
        'client_id': clientId,
        'code_verifier': verifier,
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    final data = tokenResp.data as Map<String, dynamic>;
    _accessToken = data['access_token'] as String?;
    _refreshToken = data['refresh_token'] as String?;
    if (_accessToken == null) throw Exception('Spotify token exchange failed.');
  }

  Future<Map<String, dynamic>> _get(String path,
      [Map<String, dynamic>? params]) async {
    if (_accessToken == null) throw Exception('Spotify access token not set.');
    final resp = await _dio.get('https://api.spotify.com/v1$path',
        queryParameters: params,
        options: Options(headers: {'Authorization': 'Bearer $_accessToken'}));
    return resp.data as Map<String, dynamic>;
  }

  /// Fetch a single page of playlist tracks.
  /// `limit` max is 100 per Spotify API.
  Future<({List<ImportTrackItem> items, int total, int fetched})>
      fetchPlaylistTracksPage(
    String playlistId, {
    int limit = 100,
    int offset = 0,
  }) async {
    final params = {'limit': limit.toString(), 'offset': offset.toString()};
    final data = await _get('/playlists/$playlistId/tracks', params);

    final total = (data['total'] as int?) ?? 0;
    final itemsRaw = data['items'] as List<dynamic>? ?? <dynamic>[];
    final items = <ImportTrackItem>[];
    for (final it in itemsRaw) {
      final track =
          it['track'] as Map<String, dynamic>? ?? it as Map<String, dynamic>;
      final name = track['name'] as String? ?? 'Unknown Title';
      final artists = <String>[];
      if (track['artists'] is List) {
        for (final a in (track['artists'] as List)) {
          if (a is Map && a['name'] is String) artists.add(a['name'] as String);
        }
      }
      final duration = track['duration_ms'] is int
          ? BigInt.from(track['duration_ms'] as int)
          : null;
      final url = track['external_urls'] is Map
          ? (track['external_urls']['spotify'] as String?)
          : null;
      final id = track['id'] as String?;

      items.add(ImportTrackItem(
        title: name,
        artists: artists.isNotEmpty ? artists : const ['Unknown Artist'],
        thumbnailUrl: null,
        albumTitle:
            track['album'] is Map ? track['album']['name'] as String? : null,
        durationMs: duration,
        isExplicit: track['explicit'] as bool? ?? false,
        url: url,
        sourceId: id,
      ));
    }

    return (items: items, total: total, fetched: items.length);
  }

  /// Fetch all tracks for a playlist using limit/offset pagination.
  Future<List<ImportTrackItem>> fetchAllPlaylistTracks(String playlistId,
      {int pageLimit = 100}) async {
    final results = <ImportTrackItem>[];
    int offset = 0;
    int total = -1;
    while (total < 0 || results.length < total) {
      final page = await fetchPlaylistTracksPage(playlistId,
          limit: pageLimit, offset: offset);
      results.addAll(page.items);
      total = page.total;
      offset += page.items.length;
      if (page.items.isEmpty) break; // defensive
    }
    return results;
  }

  String _generateCodeVerifier([int length = 64]) {
    final r = Random.secure();
    final bytes = List<int>.generate(length, (_) => r.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  String _codeChallengeFromVerifier(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }
}
