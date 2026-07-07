import 'package:fukatsongs/services/spotify_api_service.dart';
import 'package:fukatsongs/src/rust/api/plugin/models.dart';
import 'package:fukatsongs/core/di/service_locator.dart';
import 'package:fukatsongs/src/rust/api/plugin/commands.dart';
import 'package:fukatsongs/services/plugin/plugin_service.dart';

/// Abstraction to fetch playlist items from various providers.
class PlaylistPaginationFetcher {
  final SpotifyApiService spotify;
  final PluginService pluginService;

  PlaylistPaginationFetcher({required this.spotify, PluginService? plugin})
      : pluginService = plugin ?? ServiceLocator.pluginService;

  /// Fetch Spotify playlist by playlist id (not full URL). Uses Spotify API pagination.
  Future<List<ImportTrackItem>> fetchSpotifyPlaylistById(
      String playlistId) async {
    return spotify.fetchAllPlaylistTracks(playlistId);
  }

  /// Fallback: ask plugin to fetch tracks for arbitrary URL. If the plugin
  /// supports continuation tokens later, this method can be extended to
  /// iterate using those tokens.
  Future<List<ImportTrackItem>> fetchViaPlugin(
      String pluginId, String url) async {
    final resp = await pluginService.execute(
      pluginId: pluginId,
      request: PluginRequest.contentImporter(
        ContentImporterCommand.getTracks(url: url),
      ),
    );

    if (resp is PluginResponse_ImportTracks) {
      return resp.field0;
    }

    return <ImportTrackItem>[];
  }
}
