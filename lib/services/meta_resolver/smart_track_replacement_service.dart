import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';

import 'package:fukatsongs/core/constants/setting_keys.dart';
import 'package:fukatsongs/plugins/utils/media_id.dart';
import 'package:fukatsongs/services/db/dao/lyrics_dao.dart';
import 'package:fukatsongs/services/db/dao/playlist_dao.dart';
import 'package:fukatsongs/services/db/dao/settings_dao.dart';
import 'package:fukatsongs/services/db/dao/track_dao.dart';
import 'package:fukatsongs/services/db/db_provider.dart';
import 'package:fukatsongs/services/meta_resolver/cross_plugin_resolver.dart';
import 'package:fukatsongs/services/plugin/plugin_service.dart';
import 'package:fukatsongs/src/rust/api/plugin/models.dart';
import 'package:fukatsongs/src/rust/api/plugin/plugin_info.dart';
import 'package:fukatsongs/src/rust/api/plugin/types.dart';

class SmartTrackReplacementCandidate {
  final Track track;
  final String pluginId;
  final String pluginName;
  final double confidence;

  const SmartTrackReplacementCandidate({
    required this.track,
    required this.pluginId,
    required this.pluginName,
    required this.confidence,
  });
}

class SmartTrackReplacementApplyResult {
  final List<String> updatedPlaylists;
  final int skippedDuplicates;

  const SmartTrackReplacementApplyResult({
    required this.updatedPlaylists,
    this.skippedDuplicates = 0,
  });
}

class SmartTrackReplacementService {
  final CrossPluginResolver _resolver;
  final PluginService _pluginService;
  final PlaylistDAO _playlistDao;
  final SettingsDAO _settingsDao;
  final LyricsDAO _lyricsDao;

  List<PluginInfo>? _cachedResolvers;

  static const Set<String> _excludedPlaylistNames = {
    SettingKeys.localMusicPlaylist,
    SettingKeys.downloadPlaylist,
    SettingKeys.recentlyPlayedPlaylist,
  };

  SmartTrackReplacementService({
    required CrossPluginResolver resolver,
    required PluginService pluginService,
    required PlaylistDAO playlistDao,
    required SettingsDAO settingsDao,
    required LyricsDAO lyricsDao,
  })  : _resolver = resolver,
        _pluginService = pluginService,
        _playlistDao = playlistDao,
        _settingsDao = settingsDao,
        _lyricsDao = lyricsDao;

  factory SmartTrackReplacementService.create(PluginService pluginService) {
    final trackDao = TrackDAO(DBProvider.db);
    return SmartTrackReplacementService(
      resolver: CrossPluginResolver(pluginService: pluginService),
      pluginService: pluginService,
      playlistDao: PlaylistDAO(DBProvider.db, trackDao),
      settingsDao: SettingsDAO(DBProvider.db),
      lyricsDao: LyricsDAO(DBProvider.db),
    );
  }

  void invalidateCache() => _cachedResolvers = null;

  // ── Search ───────────────────────────────────────────────────────────────

  Future<List<SmartTrackReplacementCandidate>> searchCandidates(
    Track originalTrack, {
    int limit = 8,
  }) async {
    if (isLocalMediaId(originalTrack.id)) return const [];

    final plugins = await _getLoadedResolverPlugins();
    if (plugins.isEmpty) return const [];

    final pluginIds = plugins.map((p) => p.manifest.id).toList(growable: false);
    final pluginNameMap = {
      for (final p in plugins) p.manifest.id: p.name,
    };

    final target = TrackMatchTarget.fromTrack(originalTrack);

    final scored = await _resolver.resolveTrack(
      target: target,
      pluginIds: pluginIds,
      sequential: false,
      excludeTrackIds: {originalTrack.id},
      limit: limit,
    );

    return scored
        .map((c) => SmartTrackReplacementCandidate(
              track: c.track,
              pluginId: c.pluginId,
              pluginName: pluginNameMap[c.pluginId] ?? c.pluginId,
              confidence: c.confidence,
            ))
        .toList(growable: false);
  }
  /// Playback-only search. Never changes stored playlists or manual replacement.
  Future<List<SmartTrackReplacementCandidate>> searchPlaybackCandidates(
    Track originalTrack, {
    required Set<String> excludeTrackIds,
    int limit = 3,
  }) async {
    if (isLocalMediaId(originalTrack.id) || limit <= 0) return const [];
    invalidateCache();
    final plugins = await _getLoadedResolverPlugins();
    final originalProvider = tryParseMediaId(originalTrack.id)?.pluginId;
    final excluded = {...excludeTrackIds, originalTrack.id};
    final target = TrackMatchTarget.fromTrack(originalTrack);
    final titleKey = _resolver.playbackTitleKey(target.title);
    debugPrint('[FallbackSearch] START title="${target.title}" '
        'artists=${target.artistNames} duration=${target.durationMs} '
        'providers=${plugins.map((p) => p.manifest.id).join(",")} '
        'excluded=${excluded.join(",")}');
    if (plugins.isEmpty || titleKey.isEmpty) {
      debugPrint('[FallbackSearch] EMPTY no providers or usable title');
      return const [];
    }

    // One query per provider, in parallel: no multi-query waterfall under
    // the caller's 20-second search deadline. Include the original provider,
    // but exclude its failed track ID. Keep each provider's own candidate pool.
    final batches = await Future.wait(plugins.map((plugin) async {
      final id = plugin.manifest.id;
      final scored = await _resolver.resolveTrack(
        target: target,
        pluginIds: [id],
        queries: [target.artistNames.isEmpty
            ? titleKey : '$titleKey ${target.allArtists}'],
        excludeTrackIds: excluded,
        sequential: false,
        limit: 12,
        // The generic score penalizes missing artists and title decorations.
        // Inspect these results with the explicit playback guards below.
        minConfidence: 0.0,
      );
      debugPrint('[FallbackSearch] RESULTS provider=$id count=${scored.length}');
      final accepted = <ScoredTrackCandidate>[];
      for (final candidate in scored) {
        final track = candidate.track;
        final artists = TrackMatchTarget.matchingArtists(
            track.artists.map((a) => a.name));
        String? reason;
        if (excluded.contains(track.id)) {
          reason = 'failed-track-id';
        } else if (!_resolver.playbackVersionMatches(target, track)) {
          reason = 'different-version';
        } else if (_resolver.playbackTitleKey(track.title) != titleKey) {
          reason = 'title-mismatch';
        } else if (artists.isEmpty) {
          reason = 'missing-candidate-artist';
        } else if (target.artistNames.isNotEmpty) {
          final originalArtists = target.artistNames
              .map((name) => _resolver.normalized(name))
              .where((name) => name.isNotEmpty)
              .toSet();

          final candidateArtists = artists
              .map((name) => _resolver.normalized(name))
              .where((name) => name.isNotEmpty)
              .toSet();

          // Providers may include additional singer/composer credits.
          // Accept that difference when ALL original artists are present.
          final containsAllOriginalArtists =
              originalArtists.isNotEmpty &&
              candidateArtists.containsAll(originalArtists);

          final similarArtists =
              _resolver.artistNamesSimilarity(
                target.artistNames,
                artists,
              ) >= 0.85;

          if (!containsAllOriginalArtists && !similarArtists) {
            reason = 'artist-mismatch';
          }
        }
        final duration = target.durationMs;
        final candidateDuration = track.durationMs;
        if (reason == null && duration != null &&
            candidateDuration != null && candidateDuration > BigInt.zero) {
          final difference = (duration - candidateDuration).abs().toDouble();
          if (difference > 8000 || difference / duration.toDouble() > 0.05) {
            reason = 'duration-mismatch';
          }
        }
        debugPrint('[FallbackSearch] ${reason == null ? "ACCEPT" : "REJECT"} '
            'provider=$id id=${track.id} title="${track.title}" '
            'artists=$artists reason=${reason ?? "matched"}');
        if (reason == null) accepted.add(candidate);
      }

      // Missing original artist: reject ambiguity within this provider.
      // A different provider's uploader/artist formatting must not invalidate
      // a clean catalogue match from this provider.
      if (target.artistNames.isEmpty) {
        final artistKeys = accepted.map((c) {
          final names = TrackMatchTarget.matchingArtists(
              c.track.artists.map((a) => a.name))
              .map(_resolver.normalized).toList()..sort();
          return names.join('|');
        }).toSet();
        if (artistKeys.length > 1) {
          debugPrint('[FallbackSearch] REJECT_PROVIDER provider=$id '
              'reason=ambiguous-artists');
          return <SmartTrackReplacementCandidate>[];
        }
      }
      return accepted.map((c) => SmartTrackReplacementCandidate(
        track: c.track,
        pluginId: id,
        pluginName: plugin.name,
        confidence: c.confidence,
      )).toList(growable: false);
    }));

    // Other providers first. Preserve configured provider priority, and give
    // each provider a first chance before taking its additional candidates.
    final ordered = <List<SmartTrackReplacementCandidate>>[
      for (var i = 0; i < plugins.length; i++)
        if (plugins[i].manifest.id != originalProvider) batches[i],
      for (var i = 0; i < plugins.length; i++)
        if (plugins[i].manifest.id == originalProvider) batches[i],
    ];
    final selected = <SmartTrackReplacementCandidate>[];
    final seen = <String>{};
    for (var rank = 0; rank < 12 && selected.length < limit; rank++) {
      for (final batch in ordered) {
        if (rank >= batch.length) continue;
        final c = batch[rank];
        if (seen.add(c.track.id)) selected.add(c);
        if (selected.length == limit) break;
      }
    }
    debugPrint('[FallbackSearch] SELECTED '
        '${selected.map((c) => "${c.pluginId}:${c.track.id}").join(",")}');
    return selected;
  }


  Future<SmartTrackReplacementCandidate?> findBestReplacement(
    Track originalTrack,
  ) async {
    final candidates = await searchCandidates(originalTrack, limit: 1);
    if (candidates.isEmpty) return null;
    return candidates.first.confidence >= 0.45 ? candidates.first : null;
  }

  // ── Apply ────────────────────────────────────────────────────────────────

  Future<SmartTrackReplacementApplyResult> applyReplacement({
    required Track originalTrack,
    required Track replacement,
  }) async {
    final affected = await _playlistDao.getPlaylistsContainingTrack(
      originalTrack.id,
    );

    final eligible = affected
        .where((name) => !_excludedPlaylistNames.contains(name))
        .toList(growable: false);

    final updated = <String>[];
    int skipped = 0;

    for (final name in eligible) {
      final playlist = await _playlistDao.getPlaylistByName(name);
      if (playlist == null) continue;

      final tracks = (await _playlistDao.loadPlaylist(name)).tracks;

      if (tracks.any((t) => t.id == replacement.id)) {
        final filtered = tracks.where((t) => t.id != originalTrack.id).toList();
        if (filtered.length != tracks.length) {
          await _playlistDao.setPlaylistTracks(playlist.id, filtered);
          updated.add(name);
          skipped++;
          log('Playlist "$name": removed original (replacement present)',
              name: 'SmartTrackReplacementService');
        }
        continue;
      }

      final replaced = tracks
          .map((t) => t.id == originalTrack.id ? replacement : t)
          .toList(growable: false);
      final changed =
          replaced.asMap().entries.any((e) => tracks[e.key].id != e.value.id);
      if (!changed) continue;

      await _playlistDao.setPlaylistTracks(playlist.id, replaced);
      updated.add(name);
      log('Playlist "$name": replaced in-place',
          name: 'SmartTrackReplacementService');
    }

    // Replace ID in lyrics DB so existing lyrics (and offsets) map to the new track.
    try {
      await _lyricsDao.updateMediaId(originalTrack.id, replacement.id);
      log('Lyrics mediaID updated from ${originalTrack.id} to ${replacement.id}',
          name: 'SmartTrackReplacementService');
    } catch (e) {
      log('Failed to update lyrics mediaID during smart replace: $e',
          name: 'SmartTrackReplacementService');
    }

    return SmartTrackReplacementApplyResult(
      updatedPlaylists: updated,
      skippedDuplicates: skipped,
    );
  }

  // ── Plugin priority ──────────────────────────────────────────────────────

  Future<List<PluginInfo>> _getLoadedResolverPlugins() async {
    if (_cachedResolvers != null) return _cachedResolvers!;

    final available = await _pluginService.getAvailablePlugins();
    final loadedIds = _pluginService.getLoadedPlugins().toSet();
    final resolvers = available
        .where((p) =>
            p.pluginType == PluginType.contentResolver &&
            loadedIds.contains(p.manifest.id))
        .toList();

    var priority = const <String>[];
    try {
      final stored = await _settingsDao.getSettingStr(
        SettingKeys.resolverPriority,
        defaultValue: '[]',
      );
      if (stored != null && stored.isNotEmpty) {
        priority = (jsonDecode(stored) as List).cast<String>();
      }
    } catch (e) {
      log('Failed to decode resolver priority: $e',
          name: 'SmartTrackReplacementService');
    }

    resolvers.sort((a, b) {
      final ai = priority.indexOf(a.manifest.id);
      final bi = priority.indexOf(b.manifest.id);
      final na = ai == -1 ? 1 << 20 : ai;
      final nb = bi == -1 ? 1 << 20 : bi;
      if (na != nb) return na.compareTo(nb);
      return a.name.compareTo(b.name);
    });

    return _cachedResolvers = resolvers;
  }
}
