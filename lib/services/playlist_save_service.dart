import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:fukatsongs/services/db/dao/playlist_dao.dart';
import 'package:fukatsongs/src/rust/api/plugin/models.dart';
import 'package:crypto/crypto.dart';
import 'dart:developer';

typedef ProgressCallback = void Function(int imported, int total, int skipped);

class PlaylistSaveService {
  final PlaylistDAO playlistDao;

  PlaylistSaveService({required this.playlistDao});

  /// Saves tracks into an existing playlist (by id) using batching.
  /// Emits progress via [onProgress]. Resumable using a temp file named
  /// after [playlistName]. Returns a map with counts: imported, skipped, failed.
  Future<Map<String, int>> saveTracks(
    int playlistId,
    String playlistName,
    List<ImportTrackItem> tracks, {
    int batchSize = 200,
    ProgressCallback? onProgress,
  }) async {
    final totalToSave = tracks.length;
    int importedSoFar = 0;
    int duplicatesSkipped = 0;

    final tempDir = await getTemporaryDirectory();
    final safeName = playlistName.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    final progressFile =
        File('${tempDir.path}/import_progress_$safeName.json');

    int resumeIndex = 0;
    if (await progressFile.exists()) {
      try {
        final content = await progressFile.readAsString();
        final map = jsonDecode(content) as Map<String, dynamic>;
        if (map['nextIndex'] is int) resumeIndex = map['nextIndex'] as int;
      } catch (_) {}
    }

    while (resumeIndex < tracks.length) {
      final end = (resumeIndex + batchSize).clamp(0, tracks.length);
      final batch = tracks.sublist(resumeIndex, end);

      // Convert ImportTrackItem -> Track domain model
      final domainTracks =
          batch.map((it) => _toTrack(it)).toList(growable: false);

      final before = await playlistDao.getPlaylistTrackCount(playlistId);
      await playlistDao.addTracksToPlaylist(playlistId, domainTracks);
      final after = await playlistDao.getPlaylistTrackCount(playlistId);
      final added = (after - before).clamp(0, domainTracks.length);

      final dups = batch.length - added;
      duplicatesSkipped += dups;
      importedSoFar += added;
      resumeIndex = end;

      try {
        await progressFile
            .writeAsString(jsonEncode({'nextIndex': resumeIndex}));
      } catch (e) {
        log('Failed to persist progress file: $e', name: 'PlaylistSaveService');
      }

      onProgress?.call(importedSoFar, totalToSave, duplicatesSkipped);
    }

    try {
      if (await progressFile.exists()) await progressFile.delete();
    } catch (_) {}

    return {
      'imported': importedSoFar,
      'skipped': duplicatesSkipped,
      'failed': 0,
    };
  }

  Track _toTrack(ImportTrackItem it) {
    // Use sourceId if present, otherwise stable hash of title+artists to form media id.
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
            url: null)
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

  /// Save domain `Track` objects with batching and progress; useful when
  /// tracks have already been resolved to `Track` by the resolver.
  Future<Map<String, int>> saveDomainTracks(
    int playlistId,
    String playlistName,
    List<Track> tracks, {
    int batchSize = 200,
    ProgressCallback? onProgress,
  }) async {
    final totalToSave = tracks.length;
    int importedSoFar = 0;
    int duplicatesSkipped = 0;

    final tempDir = await getTemporaryDirectory();
    final safeName = playlistName.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    final progressFile =
        File('${tempDir.path}/import_progress_$safeName.json');

    int resumeIndex = 0;
    if (await progressFile.exists()) {
      try {
        final content = await progressFile.readAsString();
        final map = jsonDecode(content) as Map<String, dynamic>;
        if (map['nextIndex'] is int) resumeIndex = map['nextIndex'] as int;
      } catch (_) {}
    }

    while (resumeIndex < tracks.length) {
      final end = (resumeIndex + batchSize).clamp(0, tracks.length);
      final batch = tracks.sublist(resumeIndex, end);

      final before = await playlistDao.getPlaylistTrackCount(playlistId);
      await playlistDao.addTracksToPlaylist(playlistId, batch);
      final after = await playlistDao.getPlaylistTrackCount(playlistId);
      final added = (after - before).clamp(0, batch.length);

      final dups = batch.length - added;
      duplicatesSkipped += dups;
      importedSoFar += added;
      resumeIndex = end;

      try {
        await progressFile
            .writeAsString(jsonEncode({'nextIndex': resumeIndex}));
      } catch (e) {
        log('Failed to persist progress file: $e', name: 'PlaylistSaveService');
      }

      onProgress?.call(importedSoFar, totalToSave, duplicatesSkipped);
    }

    try {
      if (await progressFile.exists()) await progressFile.delete();
    } catch (_) {}

    return {
      'imported': importedSoFar,
      'skipped': duplicatesSkipped,
      'failed': 0,
    };
  }
}
