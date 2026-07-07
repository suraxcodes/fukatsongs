import 'dart:async';
import 'dart:developer';
import 'dart:convert';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'package:fukatsongs/services/spotify_api_service.dart';
import 'package:fukatsongs/services/playlist_pagination_fetcher.dart';
import 'package:fukatsongs/services/playlist_save_service.dart';

import 'package:fukatsongs/services/meta_resolver/cross_plugin_resolver.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fukatsongs/core/di/service_locator.dart';
import 'package:fukatsongs/plugins/blocs/import/content_import_state.dart';
import 'package:fukatsongs/services/db/dao/playlist_dao.dart';
import 'package:fukatsongs/services/db/dao/track_dao.dart';
import 'package:fukatsongs/services/db/db_provider.dart';
import 'package:fukatsongs/services/plugin/plugin_service.dart';
import 'package:fukatsongs/src/rust/api/plugin/commands.dart';
import 'package:fukatsongs/src/rust/api/plugin/types.dart';
import 'package:fukatsongs/src/rust/api/plugin/models.dart';
// Additional imports for file handling and JSON
import 'dart:convert';
import 'package:crypto/crypto.dart';

class ContentImportCubit extends Cubit<ContentImportState> {
  // Constants for import processing
  static const int _kResolutionConcurrency = 5;
  static const Duration _kPluginTimeout = Duration(seconds: 10);
  static const double _kMinConfidence = 0.45;
  static const int _kMaxCandidatesPerTrack = 5;

  // Private dependencies
  final PluginService _pluginService;
  final CrossPluginResolver _resolver;
  final PlaylistDAO _playlistDao;
  final SpotifyApiService? _spotifyService;
  final PlaylistPaginationFetcher _paginationFetcher;
  final PlaylistSaveService _playlistSaveService;

  bool _cancelRequested = false;

  ContentImportCubit({
    PluginService? pluginService,
    CrossPluginResolver? resolver,
    PlaylistDAO? playlistDao,
    SpotifyApiService? spotifyService,
    PlaylistPaginationFetcher? paginationFetcher,
    PlaylistSaveService? playlistSaveService,
  })  : _pluginService = pluginService ?? ServiceLocator.pluginService,
        _resolver = resolver ??
            CrossPluginResolver(
              pluginService: pluginService ?? ServiceLocator.pluginService,
            ),
        _playlistDao = playlistDao ?? _defaultPlaylistDao(),
        _spotifyService = spotifyService,
        _paginationFetcher = paginationFetcher ??
            PlaylistPaginationFetcher(
                spotify: spotifyService ??
                    SpotifyApiService(clientId: '<YOUR_SPOTIFY_CLIENT_ID>')),
        _playlistSaveService = playlistSaveService ??
            PlaylistSaveService(
                playlistDao: playlistDao ?? _defaultPlaylistDao()),
        super(const ContentImportState());

  static PlaylistDAO _defaultPlaylistDao() {
    final trackDao = TrackDAO(DBProvider.db);
    return PlaylistDAO(DBProvider.db, trackDao);
  }

  // ── Step 1: Check URL ────────────────────────────────────────────────────

  Future<void> checkUrl(String pluginId, String url) async {
    _cancelRequested = false;
    emit(state.copyWith(
      phase: ImportPhase.checkingUrl,
      pluginId: pluginId,
      url: url,
      clearError: true,
    ));

    // Force direct import for youtube and spotify because the WASM plugins are currently failing
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      await _importFromYoutubeDirect(url);
      return;
    } else if (url.contains('spotify.com')) {
      await _importFromSpotifyDirect(url);
      return;
    }

    bool canHandle = false;
    if (pluginId.isNotEmpty) {
      try {
        final response = await _pluginService
            .execute(
              pluginId: pluginId,
              request: PluginRequest.contentImporter(
                ContentImporterCommand.canHandleUrl(url: url),
              ),
            )
            .timeout(_kPluginTimeout);
        if (response is PluginResponse_CanHandle) {
          canHandle = response.field0;
        }
      } catch (e) {
        log('Plugin check failed: $e, falling back to direct check',
            name: 'ContentImportCubit');
      }
    }

    if (canHandle) {
      await _fetchCollectionInfo(pluginId, url);
    } else {
      emit(state.copyWith(
        phase: ImportPhase.error,
        error: 'This URL cannot be handled by the selected importer.',
      ));
    }
  }

  // ── Step 2: Fetch Collection Info ────────────────────────────────────────

  Future<void> _fetchCollectionInfo(String pluginId, String url) async {
    emit(state.copyWith(phase: ImportPhase.fetchingInfo));

    try {
      final response = await _pluginService
          .execute(
            pluginId: pluginId,
            request: PluginRequest.contentImporter(
              ContentImporterCommand.getCollectionInfo(url: url),
            ),
          )
          .timeout(_kPluginTimeout);

      if (response is PluginResponse_CollectionInfo) {
        emit(state.copyWith(
          collectionInfo: response.field0,
          phase: ImportPhase.fetchingTracks,
        ));
        await _fetchTracks(pluginId, url);
      } else {
        emit(state.copyWith(
          phase: ImportPhase.error,
          error: 'Unexpected response when fetching collection info.',
        ));
      }
    } on TimeoutException {
      emit(state.copyWith(
        phase: ImportPhase.error,
        error: 'Timed out fetching collection info.',
      ));
    } catch (e) {
      log('_fetchCollectionInfo failed: $e', name: 'ContentImportCubit');
      emit(state.copyWith(
        phase: ImportPhase.error,
        error: 'Failed to fetch collection info: $e',
      ));
    }
  }

  // ── Step 3: Fetch Tracks ─────────────────────────────────────────────────

  Future<void> _fetchTracks(String pluginId, String url) async {
    try {
      final response = await _pluginService
          .execute(
            pluginId: pluginId,
            request: PluginRequest.contentImporter(
              ContentImporterCommand.getTracks(url: url),
            ),
          )
          .timeout(_kPluginTimeout);

      if (response is PluginResponse_ImportTracks) {
        final entries = response.field0
            .map((t) => ImportTrackEntry(sourceTrack: t))
            .toList();
        log('Fetched ${entries.length} tracks from provider for url=$url',
            name: 'ContentImportCubit');
        if (state.collectionInfo != null) {
          log('Provider reports total ${state.collectionInfo!.trackCount} tracks',
              name: 'ContentImportCubit');
        }
        emit(state.copyWith(
          tracks: List.unmodifiable(entries),
          phase: ImportPhase.resolving,
        ));
        await _resolveTracks();
      } else {
        emit(state.copyWith(
          phase: ImportPhase.error,
          error: 'Unexpected response when fetching tracks.',
        ));
      }
    } on TimeoutException {
      emit(state.copyWith(
        phase: ImportPhase.error,
        error: 'Timed out fetching tracks.',
      ));
    } catch (e) {
      log('_fetchTracks failed: $e', name: 'ContentImportCubit');
      emit(state.copyWith(
        phase: ImportPhase.error,
        error: 'Failed to fetch tracks: $e',
      ));
    }
  }

  // ── Step 4: Resolve Tracks ───────────────────────────────────────────────

  Future<void> _resolveTracks() async {
    final resolverPluginIds = await _getContentResolverPluginIds();
    if (resolverPluginIds.isEmpty) {
      log('No content-resolver plugins loaded; using fallback tracks directly.',
          name: 'ContentImportCubit');
      final fallbackTracks = state.tracks.map((entry) {
        final fallback = _toTrack(entry.sourceTrack);
        return entry.copyWith(
          status: TrackResolutionStatus.resolved,
          resolvedTrack: fallback,
          candidates: const [],
        );
      }).toList();
      emit(state.copyWith(
        tracks: List.unmodifiable(fallbackTracks),
        resolvedCount: fallbackTracks.length,
        failedCount: 0,
        phase: ImportPhase.review,
      ));
      return;
    }

    final tracks = List<ImportTrackEntry>.from(state.tracks);
    final semaphore = Semaphore(_kResolutionConcurrency);
    final futures = <Future<void>>[];

    for (var i = 0; i < tracks.length; i++) {
      final index = i;
      futures.add(
        semaphore.run(() => _resolveOneEntry(
              tracks: tracks,
              index: index,
              pluginIds: resolverPluginIds,
            )),
      );
    }

    await Future.wait(futures);

    if (!isClosed && !_cancelRequested) {
      final counts = _recount(tracks);
      log(
        'Resolution complete: ${counts.resolved} resolved, '
        '${counts.failed} failed out of ${tracks.length}',
        name: 'ContentImportCubit',
      );
      emit(state.copyWith(
        tracks: List.unmodifiable(tracks),
        resolvedCount: counts.resolved,
        failedCount: counts.failed,
        phase: ImportPhase.review,
      ));
    }
  }

  Future<void> _resolveOneEntry({
    required List<ImportTrackEntry> tracks,
    required int index,
    required List<String> pluginIds,
  }) async {
    if (isClosed || _cancelRequested) return;

    final entry = tracks[index];

    // Mark as resolving.
    tracks[index] = entry.copyWith(status: TrackResolutionStatus.resolving);
    if (!isClosed) {
      emit(state.copyWith(tracks: List.unmodifiable(tracks)));
    }

    try {
      final target = TrackMatchTarget.fromImport(
        title: entry.sourceTrack.title,
        artists: entry.sourceTrack.artists,
        durationMs: entry.sourceTrack.durationMs?.toInt(),
      );

      // Use the shared resolver — parallel across plugins, scored, with
      // early-exit on high confidence.
      final candidates = await _resolver.resolveTrack(
        target: target,
        pluginIds: pluginIds,
        sequential: false,
        minConfidence: _kMinConfidence,
        earlyAcceptThreshold: 0.93,
        limit: _kMaxCandidatesPerTrack,
      );

      if (isClosed || _cancelRequested) return;

      if (candidates.isNotEmpty) {
        // Normal case: we have at least one candidate.
        tracks[index] = entry.copyWith(
          status: TrackResolutionStatus.resolved,
          resolvedTrack: candidates.first.track,
          candidates: candidates.map((c) => c.track).toList(growable: false),
        );
      } else {
        // Fallback: no resolver candidate found. Use the source track itself
        // (converted to a Track) so it can still be saved.
        final fallbackTrack = _toTrack(entry.sourceTrack);
        tracks[index] = entry.copyWith(
          status: TrackResolutionStatus.resolved,
          resolvedTrack: fallbackTrack,
          candidates: const [],
        );
      }
    } catch (e) {
      log(
        'Failed to resolve "${entry.sourceTrack.title}": $e',
        name: 'ContentImportCubit',
      );
      if (!isClosed && !_cancelRequested) {
        tracks[index] = entry.copyWith(
          status: TrackResolutionStatus.failed,
          candidates: const [],
        );
      }
    }

    // Emit progress.
    if (!isClosed && !_cancelRequested) {
      final counts = _recount(tracks);
      emit(state.copyWith(
        tracks: List.unmodifiable(tracks),
        resolvedCount: counts.resolved,
        failedCount: counts.failed,
      ));
    }
  }

  // ── Cancellation ─────────────────────────────────────────────────────────

  void cancelResolution() {
    if (state.phase != ImportPhase.resolving) return;
    _cancelRequested = true;
    log('Resolution cancelled by user.', name: 'ContentImportCubit');

    final counts = _recount(state.tracks);
    emit(state.copyWith(
      phase: ImportPhase.review,
      resolvedCount: counts.resolved,
      failedCount: counts.failed,
    ));
  }

  // ── User candidate selection ─────────────────────────────────────────────

  void pickCandidate(int trackIndex, int? candidateIdx) {
    final tracks = List<ImportTrackEntry>.from(state.tracks);
    if (trackIndex < 0 || trackIndex >= tracks.length) return;

    tracks[trackIndex] = tracks[trackIndex].copyWith(
      selectedCandidateIndex: candidateIdx,
    );

    final counts = _recount(tracks);
    emit(state.copyWith(
      tracks: List.unmodifiable(tracks),
      resolvedCount: counts.resolved,
      failedCount: counts.failed,
    ));
  }

  // ── Step 5: Save to Library ──────────────────────────────────────────────

  Future<void> saveToLibrary({String? customName}) async {
    final info = state.collectionInfo;
    if (info == null) return;

    emit(state.copyWith(phase: ImportPhase.saving));

    try {
      final rawName = customName?.trim().isNotEmpty == true
          ? customName!.trim()
          : info.title.trim();
      final playlistName = rawName.isNotEmpty ? rawName : 'Imported Playlist';

      final playlistId = await _playlistDao.ensurePlaylist(playlistName);

      final thumbUrl = info.thumbnailUrl;
      if (thumbUrl != null && thumbUrl.isNotEmpty) {
        await _playlistDao.updatePlaylistThumbnail(playlistId, thumbUrl);
      }

      final entries = state.tracks;
      final totalToSave = entries.where((e) => e.effectiveTrack != null).length;
      int importedSoFar = 0;
      int userSkipped = entries.where((e) => e.isSkipped).length;
      int duplicatesSkipped = 0;

      // Progress resume file (temporary) to allow resuming interrupted imports.
      final tempDir = await getTemporaryDirectory();
      final safeName = playlistName.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
      final progressFile =
          File('${tempDir.path}/import_progress_${safeName}.json');

      int resumeIndex = 0;
      if (await progressFile.exists()) {
        try {
          final content = await progressFile.readAsString();
          final map = jsonDecode(content) as Map<String, dynamic>;
          if (map['nextIndex'] is int) resumeIndex = map['nextIndex'] as int;
          log('Resuming import from index $resumeIndex for "$playlistName"',
              name: 'ContentImportCubit');
        } catch (_) {
          // ignore and start from 0
        }
      }

      // Build list of tracks to save (preserve order), then process in batches.
      final tracksToSave = entries
          .where((e) => e.effectiveTrack != null)
          .map((e) => e.effectiveTrack!)
          .toList(growable: false);

      // Update initial progress state
      emit(state.copyWith(
        savingTotal: totalToSave,
        savingImported: importedSoFar,
        savingSkipped: userSkipped,
        savingFailed: 0,
      ));

      // Delegate to PlaylistSaveService which handles batching and resume.
      final result = await _playlistSaveService.saveDomainTracks(
        playlistId,
        playlistName,
        tracksToSave,
        batchSize: 500,
        onProgress: (imported, total, skipped) {
          emit(state.copyWith(
            savingImported: imported,
            savingTotal: total,
            savingSkipped: userSkipped + (skipped as int),
          ));
        },
      );

      importedSoFar = result['imported'] ?? importedSoFar;
      duplicatesSkipped = result['skipped'] ?? duplicatesSkipped;

      // Completed — remove progress file
      try {
        if (await progressFile.exists()) await progressFile.delete();
      } catch (_) {}

      log('Saved $importedSoFar tracks to "$playlistName"; duplicatesSkipped=$duplicatesSkipped, userSkipped=$userSkipped',
          name: 'ContentImportCubit');

      emit(state.copyWith(
        phase: ImportPhase.done,
        resolvedCount: importedSoFar,
        savingImported: importedSoFar,
        savingSkipped: userSkipped + duplicatesSkipped,
      ));
    } catch (e) {
      log('saveToLibrary failed: $e', name: 'ContentImportCubit');
      emit(state.copyWith(
        phase: ImportPhase.error,
        error: 'Failed to save playlist: $e',
      ));
    }
  }

  // ── Reset ────────────────────────────────────────────────────────────────

  void reset() {
    _cancelRequested = false;
    emit(const ContentImportState());
  }

  // ── M3U Import ────────────────────────────────────────────────────────────

  /// Directly loads tracks parsed from an M3U file and starts resolution.
  ///
  /// Bypasses the URL-check / collection-info / fetch-tracks plugin steps.
  /// The [summary] provides playlist metadata (title, kind, trackCount).
  Future<void> loadFromM3U(
    List<ImportTrackItem> tracks,
    ImportCollectionSummary summary,
  ) async {
    _cancelRequested = false;
    emit(state.copyWith(
      phase: ImportPhase.resolving,
      collectionInfo: summary,
      tracks: List.unmodifiable(
        tracks.map((t) => ImportTrackEntry(sourceTrack: t)).toList(),
      ),
      clearError: true,
    ));
    await _resolveTracks();
  }

  // Updated to support pagination/resume for large YouTube playlists
  Future<void> _importFromYoutubeDirect(String url) async {
    try {
      final uri = Uri.tryParse(url);
      if (uri == null) throw Exception('Invalid YouTube URL');

      final playlistId = uri.queryParameters['list'];
      if (playlistId == null || playlistId.isEmpty) {
        throw Exception('Invalid YouTube Playlist URL (missing list= parameter)');
      }

      // Determine progress file for this playlist to resume imports
      final tempDir = await getTemporaryDirectory();
      final progressFile = File(
          '${tempDir.path}/youtube_import_progress_$playlistId.json');
      int resumeIndex = 0;
      if (await progressFile.exists()) {
        try {
          final content = await progressFile.readAsString();
          final map = jsonDecode(content) as Map<String, dynamic>;
          if (map['nextIndex'] is int) resumeIndex = map['nextIndex'] as int;
          log('Resuming YouTube import from index $resumeIndex for playlist $playlistId',
              name: 'ContentImportCubit');
        } catch (_) {
          // ignore malformed progress file
        }
      }

      final fetchUrl = 'https://www.youtube.com/playlist?list=$playlistId';
      final dio = Dio();
      final response = await dio.get(
        fetchUrl,
        options: Options(
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          },
        ),
      );

      final html = response.data as String;
      final nextDataStart = html.indexOf('var ytInitialData = ');
      if (nextDataStart == -1) {
        throw Exception('ytInitialData not found in YouTube page.');
      }

      final jsonStart = nextDataStart + 'var ytInitialData = '.length;
      final jsonEnd = html.indexOf(';</script>', jsonStart);
      final jsonStr = html.substring(jsonStart, jsonEnd);

      final data = jsonDecode(jsonStr);

      final metadata = data['metadata']?['playlistMetadataRenderer'] ?? {};
      final title = metadata['title'] as String? ?? 'YouTube Playlist';
      final description = metadata['description'] as String?;

      // Find API key and Context for pagination
      final keyRegex = RegExp(r'"INNERTUBE_API_KEY"\s*:\s*"([^"]+)"');
      final keyMatch = keyRegex.firstMatch(html);
      final apiKey = keyMatch?.group(1);
      
      final clientRegex = RegExp(r'"INNERTUBE_CONTEXT"\s*:\s*(\{.*?\})');
      final clientMatch = clientRegex.firstMatch(html);
      final clientContext = clientMatch?.group(1);

      List<Map<String, dynamic>> extractVideos(dynamic node) {
        List<Map<String, dynamic>> results = [];
        if (node is Map) {
          if (node.containsKey('playlistVideoRenderer')) {
            final renderer = node['playlistVideoRenderer'];
            final videoId = renderer['videoId'] as String?;
            final titleObj = renderer['title'];
            final vTitle = titleObj?['simpleText'] ?? titleObj?['runs']?[0]?['text'];
            if (videoId != null && vTitle != null) {
              results.add({'videoId': videoId, 'title': vTitle, 'author': ''});
            }
          } else if (node.containsKey('lockupViewModel')) {
            final lockup = node['lockupViewModel'];
            final videoId = lockup['contentId'] as String?;
            final meta = lockup['metadata']?['lockupMetadataViewModel'];
            final vTitle = meta?['title']?['content'] as String?;
            if (videoId != null && vTitle != null) {
              results.add({'videoId': videoId, 'title': vTitle, 'author': ''});
            }
          } else if (node.containsKey('musicResponsiveListItemRenderer')) {
            final renderer = node['musicResponsiveListItemRenderer'];
            final titleObj = renderer['flexColumns']?[0]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs']?[0];
            final vTitle = titleObj?['text'] as String?;
            final videoId = renderer['playlistItemData']?['videoId'] as String?;
            if (videoId != null && vTitle != null) {
              results.add({'videoId': videoId, 'title': vTitle, 'author': ''});
            }
          }
          for (var value in node.values) {
            results.addAll(extractVideos(value));
          }
        } else if (node is List) {
          for (var item in node) {
            results.addAll(extractVideos(item));
          }
        }
        return results;
      }

      String? findContinuation(dynamic node) {
        if (node is Map) {
          if (node.containsKey('continuationItemRenderer')) {
            final token = node['continuationItemRenderer']?['continuationEndpoint']?['continuationCommand']?['token'];
            if (token != null) return token as String;
          } else if (node.containsKey('continuationItemViewModel')) {
            final token = node['continuationItemViewModel']?['continuationCommand']?['innertubeCommand']?['continuationCommand']?['token'];
            if (token != null) return token as String;
          }
          for (var value in node.values) {
            final token = findContinuation(value);
            if (token != null) return token;
          }
        } else if (node is List) {
          for (var item in node) {
            final token = findContinuation(item);
            if (token != null) return token;
          }
        }
        return null;
      }

      final allExtracted = extractVideos(data);
      String? currentContinuation = findContinuation(data);

      final summary = ImportCollectionSummary(
        title: title,
        kind: ImportCollectionType.playlist,
        description: description,
        thumbnailUrl: null,
        trackCount: allExtracted.length, // Initial guess
      );

      final playlistName = title.isNotEmpty ? title : 'YouTube Playlist';
      final dbPlaylistId = await _playlistDao.ensurePlaylist(playlistName);

      // We don't want duplicate tracks across the whole import
      final uniqueVideos = <String, Map<String, dynamic>>{};
      int importedSoFar = 0;
      int duplicatesSkipped = 0;

      emit(state.copyWith(
        phase: ImportPhase.saving, // Jump straight to saving!
        collectionInfo: summary,
        savingTotal: 0,
        savingImported: 0,
        savingSkipped: 0,
        clearError: true,
      ));

      Future<void> saveBatch(List<Map<String, dynamic>> videosBatch) async {
        if (videosBatch.isEmpty) return;
        
        final tracks = videosBatch.map((video) {
          return ImportTrackItem(
            title: video['title'],
            artists: ['YouTube Audio'], // Fallback artist
            thumbnailUrl: 'https://i.ytimg.com/vi/${video['videoId']}/hqdefault.jpg',
            isExplicit: false,
            durationMs: BigInt.zero, // Duration hard to extract reliably without full metadata
            url: 'https://youtube.com/watch?v=${video['videoId']}',
            sourceId: video['videoId'],
          );
        }).toList();

        final result = await _playlistSaveService.saveTracks(
          dbPlaylistId,
          playlistName,
          tracks,
          batchSize: 500,
          onProgress: null, // We handle state updates manually below
        );

        importedSoFar += (result['imported'] as int? ?? 0);
        duplicatesSkipped += (result['skipped'] as int? ?? 0);

        emit(state.copyWith(
          savingImported: importedSoFar,
          savingSkipped: duplicatesSkipped,
          savingTotal: uniqueVideos.length, // update total
          resolvedCount: importedSoFar,
        ));
      }

      // Save initial batch
      final newInitial = <Map<String, dynamic>>[];
      for (var v in allExtracted) {
        if (!uniqueVideos.containsKey(v['videoId'])) {
          uniqueVideos[v['videoId']] = v;
          newInitial.add(v);
        }
      }
      await saveBatch(newInitial);

      while (currentContinuation != null && apiKey != null && clientContext != null) {
        try {
          final contextJson = jsonDecode(clientContext);
          final postData = {
            'context': contextJson,
            'continuation': currentContinuation,
          };
          
          final nextRes = await dio.post(
            'https://www.youtube.com/youtubei/v1/browse?key=$apiKey',
            options: Options(headers: {'Content-Type': 'application/json'}),
            data: jsonEncode(postData),
          );
          
          final nextData = (nextRes.data is String) ? jsonDecode(nextRes.data) : nextRes.data;
          final nextVideos = extractVideos(nextData);
          
          final newBatch = <Map<String, dynamic>>[];
          for (var v in nextVideos) {
            if (!uniqueVideos.containsKey(v['videoId'])) {
              uniqueVideos[v['videoId']] = v;
              newBatch.add(v);
            }
          }
          await saveBatch(newBatch);
          
          currentContinuation = findContinuation(nextData);
        } catch (e) {
          log('Pagination failed: $e', name: 'ContentImportCubit');
          break;
        }
      }

      log('YouTube playlist $title imported $importedSoFar tracks, $duplicatesSkipped duplicates skipped',
          name: 'ContentImportCubit');

      emit(state.copyWith(
        phase: ImportPhase.done,
      ));

      // Cleanup progress file after successful import
      try {
        await progressFile.delete();
      } catch (_) {}
    } catch (e) {
      log('_importFromYoutubeDirect failed: $e', name: 'ContentImportCubit');
      emit(state.copyWith(
        phase: ImportPhase.error,
        error: 'YouTube Import Error: $e',
      ));
    }
  }

  Future<void> _importFromSpotifyDirect(String url) async {
    try {
      final regExp = RegExp(r'(playlist|album)/([a-zA-Z0-9]{15,})');
      final match = regExp.firstMatch(url);
      final kind = match?.group(1);
      final id = match?.group(2);
      if (id == null || kind == null) throw Exception('Invalid Spotify URL');

      List<ImportTrackItem> items = [];
      String title = kind == 'album' ? 'Spotify Album' : 'Spotify Playlist';
      String? description;
      String? thumbnailUrl;

      // Only attempt official API if clientId is not default/placeholder
      if (_spotifyService != null &&
          _spotifyService!.clientId != '<YOUR_SPOTIFY_CLIENT_ID>') {
        try {
          if (kind == 'playlist') {
            items = await _paginationFetcher.fetchSpotifyPlaylistById(id);
          }
        } catch (apiError) {
          log('Spotify API failed, falling back to embed scraper: $apiError',
              name: 'ContentImportCubit');
        }
      }

      // If items list is empty, use the embed scraper
      if (items.isEmpty) {
        final embedUrl = 'https://open.spotify.com/embed/$kind/$id';
        final dio = Dio();
        final response = await dio.get(
          embedUrl,
          options: Options(
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            },
          ),
        );
        final html = response.data as String;
        final nextDataStart = html.indexOf('id="__NEXT_DATA__"');
        if (nextDataStart == -1) {
          throw Exception('__NEXT_DATA__ script not found in Spotify page.');
        }
        final tagStart = html.lastIndexOf('<script', nextDataStart);
        final jsonStart = html.indexOf('{', tagStart);
        final jsonEnd = html.indexOf('</script>', jsonStart);
        final jsonStr = html.substring(jsonStart, jsonEnd);
        final data = jsonDecode(jsonStr);

        final pageProps = data['props']?['pageProps'] ?? {};
        final state = pageProps['state'] ?? {};
        final entity = state['data']?['entity'] ?? {};

        title = entity['name'] as String? ??
            (kind == 'album' ? 'Spotify Album' : 'Spotify Playlist');
        description = entity['description'] as String?;
        final images = entity['images'] as List? ?? [];
        if (images.isNotEmpty) {
          thumbnailUrl = images[0]['url'] as String?;
        }

        var rawItems = entity['tracks']?['items'] as List?;
        if (rawItems == null || rawItems.isEmpty) {
          rawItems = entity['trackList'] as List?;
        }
        rawItems ??= [];

        for (final item in rawItems) {
          if (item == null || item is! Map) continue;

          if (item.containsKey('track') || item.containsKey('artists')) {
            // Old format
            final track = item['track'] ?? item;
            if (track == null) continue;

            final name = track['name'] as String? ?? 'Unknown Title';
            final trackId = track['id'] as String?;

            final artists = <String>[];
            final artistItems = track['artists']?['items'] as List? ?? [];
            for (final a in artistItems) {
              if (a is Map) {
                final profileName = a['profile']?['name'] as String?;
                if (profileName != null) {
                  artists.add(profileName);
                }
              }
            }

            final durationMs = track['duration']?['totalMilliseconds'] as int? ??
                track['duration_ms'] as int?;

            final albumName = track['album']?['name'] as String?;
            final uri = track['uri'] as String?;

            items.add(ImportTrackItem(
              title: name,
              artists: artists.isNotEmpty ? artists : const ['Unknown Artist'],
              thumbnailUrl: null,
              albumTitle: albumName,
              durationMs: durationMs != null ? BigInt.from(durationMs) : null,
              isExplicit: track['explicit'] as bool? ?? false,
              url: uri,
              sourceId: trackId,
            ));
          } else {
            // New format (trackList)
            final name = item['title'] as String? ?? 'Unknown Title';
            final subtitle = item['subtitle'] as String?;
            final artists = subtitle != null ? [subtitle] : const ['Unknown Artist'];
            final durationMs = item['duration'] as int?;
            final isExplicit = item['isExplicit'] as bool? ?? false;
            final uri = item['uri'] as String?;
            String? trackId;
            if (uri != null && uri.contains(':')) {
              trackId = uri.split(':').last;
            }
            
            items.add(ImportTrackItem(
              title: name,
              artists: artists,
              thumbnailUrl: null,
              albumTitle: null,
              durationMs: durationMs != null ? BigInt.from(durationMs) : null,
              isExplicit: isExplicit,
              url: uri,
              sourceId: trackId,
            ));
          }
        }
      }

      if (items.isEmpty) {
        throw Exception('No tracks found or failed to parse Spotify page.');
      }

      final summary = ImportCollectionSummary(
        title: title,
        kind: kind == 'album'
            ? ImportCollectionType.album
            : ImportCollectionType.playlist,
        description: description,
        thumbnailUrl: thumbnailUrl,
        trackCount: items.length,
      );

      emit(state.copyWith(
        phase: ImportPhase.resolving,
        collectionInfo: summary,
        tracks: List.unmodifiable(
          items.map((t) => ImportTrackEntry(sourceTrack: t)).toList(),
        ),
        clearError: true,
      ));

      await _resolveTracks();
    } catch (e) {
      log('_importFromSpotifyDirect failed: $e', name: 'ContentImportCubit');
      emit(state.copyWith(
        phase: ImportPhase.error,
        error: 'Spotify Import Error: $e',
      ));
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Returns only loaded content-resolver plugin IDs.
  Future<List<String>> _getContentResolverPluginIds() async {
    final available = await _pluginService.getAvailablePlugins();
    final loadedIds = _pluginService.getLoadedPlugins().toSet();
    return available
        .where((p) =>
            p.pluginType == PluginType.contentResolver &&
            loadedIds.contains(p.manifest.id))
        .map((p) => p.manifest.id)
        .toList(growable: false);
  }

  /// Single source of truth for resolved/failed counts.
  ({int resolved, int failed}) _recount(List<ImportTrackEntry> tracks) {
    var resolved = 0;
    var failed = 0;
    for (final t in tracks) {
      if (t.isSkipped) {
        failed++;
      } else if (t.status == TrackResolutionStatus.resolved) {
        resolved++;
      } else if (t.status != TrackResolutionStatus.pending &&
          t.status != TrackResolutionStatus.resolving) {
        failed++;
      }
    }
    return (resolved: resolved, failed: failed);
  }

  // Converts ImportTrackItem to domain Track. Used as fallback when resolver fails.
  Track _toTrack(ImportTrackItem it) {
    final rawId = (it.sourceId != null && it.sourceId!.trim().isNotEmpty)
        ? it.sourceId!
        : md5
            .convert(utf8.encode('${it.title}|${it.artists.join(',')}'))
            .toString();
    final id = rawId.contains('::') ? rawId : 'unresolved::$rawId';

    final artists = it.artists.map((a) {
      final aid = md5.convert(utf8.encode(a)).toString();
      return ArtistSummary(
          id: aid, name: a, thumbnail: null, subtitle: null, url: null);
    }).toList(growable: false);

    final artwork = Artwork(
      url: it.thumbnailUrl ?? '',
      urlLow: null,
      urlHigh: null,
      layout: ImageLayout.square,
    );

    final album = (it.albumTitle != null && it.albumTitle!.isNotEmpty)
        ? AlbumSummary(
            id: md5.convert(utf8.encode(it.albumTitle!)).toString(),
            title: it.albumTitle!,
            artists: artists,
            thumbnail: artwork,
            subtitle: null,
            year: null,
            url: null,
          )
        : null;

    return Track(
      id: id,
      title: it.title,
      artists: artists,
      album: album,
      durationMs: it.durationMs,
      thumbnail: artwork,
      url: it.url,
      isExplicit: it.isExplicit,
      lyrics: null,
    );
  }
}
