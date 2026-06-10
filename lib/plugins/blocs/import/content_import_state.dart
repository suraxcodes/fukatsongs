import 'dart:convert' show utf8;
import 'package:crypto/crypto.dart' show md5;
import 'package:equatable/equatable.dart';

import 'package:fukatsongs/src/rust/api/plugin/models.dart';

enum ImportPhase {
  idle,
  checkingUrl,
  fetchingInfo,
  fetchingTracks,
  resolving,
  review,
  saving,
  done,
  error,
}

/// Resolution status of a single track during import.
enum TrackResolutionStatus {
  pending,
  resolving,
  resolved,
  failed,
}

/// A track from the import source paired with its resolution state.
class ImportTrackEntry extends Equatable {
  final ImportTrackItem sourceTrack;
  final TrackResolutionStatus status;

  /// Best auto-resolved track (first candidate found).
  final Track? resolvedTrack;

  /// Up to 5 candidate tracks from search results.
  final List<Track> candidates;

  /// User-selected candidate index.
  /// - null  → use [resolvedTrack] (auto best)
  /// - >= 0  → use [candidates[selectedCandidateIndex]]
  /// - -1    → user explicitly skipped this track
  final int? selectedCandidateIndex;

  const ImportTrackEntry({
    required this.sourceTrack,
    this.status = TrackResolutionStatus.pending,
    this.resolvedTrack,
    this.candidates = const [],
    this.selectedCandidateIndex,
  });

  /// Whether the user has explicitly chosen to skip this track.
  bool get isSkipped => selectedCandidateIndex == -1;

  /// The track that will be saved (respects user selection / skip).
  Track? get effectiveTrack {
    if (isSkipped) return null;
    final idx = selectedCandidateIndex;
    if (idx != null && idx >= 0 && idx < candidates.length) {
      return candidates[idx];
    }
    if (resolvedTrack != null) return resolvedTrack;
    return _toFallbackTrack();
  }

  Track _toFallbackTrack() {
    final it = sourceTrack;
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

  ImportTrackEntry copyWith({
    TrackResolutionStatus? status,
    Track? resolvedTrack,
    List<Track>? candidates,
    int? selectedCandidateIndex,
    bool clearSelection = false,
  }) {
    return ImportTrackEntry(
      sourceTrack: sourceTrack,
      status: status ?? this.status,
      resolvedTrack: resolvedTrack ?? this.resolvedTrack,
      candidates: candidates ?? this.candidates,
      selectedCandidateIndex: clearSelection
          ? null
          : (selectedCandidateIndex ?? this.selectedCandidateIndex),
    );
  }

  @override
  List<Object?> get props =>
      [sourceTrack, status, resolvedTrack, candidates, selectedCandidateIndex];
}

class ContentImportState extends Equatable {
  final ImportPhase phase;
  final String? pluginId;
  final String? url;
  final ImportCollectionSummary? collectionInfo;
  final List<ImportTrackEntry> tracks;
  final int resolvedCount;
  final int failedCount;
  final int savingTotal;
  final int savingImported;
  final int savingSkipped;
  final int savingFailed;
  final String? error;

  const ContentImportState({
    this.phase = ImportPhase.idle,
    this.pluginId,
    this.url,
    this.collectionInfo,
    this.tracks = const [],
    this.resolvedCount = 0,
    this.failedCount = 0,
    this.savingTotal = 0,
    this.savingImported = 0,
    this.savingSkipped = 0,
    this.savingFailed = 0,
    this.error,
  });

  ContentImportState copyWith({
    ImportPhase? phase,
    String? pluginId,
    String? url,
    ImportCollectionSummary? collectionInfo,
    List<ImportTrackEntry>? tracks,
    int? resolvedCount,
    int? failedCount,
    int? savingTotal,
    int? savingImported,
    int? savingSkipped,
    int? savingFailed,
    String? error,
    bool clearError = false,
  }) {
    return ContentImportState(
      phase: phase ?? this.phase,
      pluginId: pluginId ?? this.pluginId,
      url: url ?? this.url,
      collectionInfo: collectionInfo ?? this.collectionInfo,
      tracks: tracks ?? this.tracks,
      resolvedCount: resolvedCount ?? this.resolvedCount,
      failedCount: failedCount ?? this.failedCount,
      savingTotal: savingTotal ?? this.savingTotal,
      savingImported: savingImported ?? this.savingImported,
      savingSkipped: savingSkipped ?? this.savingSkipped,
      savingFailed: savingFailed ?? this.savingFailed,
      error: clearError ? null : (error ?? this.error),
    );
  }

  int get totalTracks => tracks.length;

  @override
  List<Object?> get props => [
        phase,
        pluginId,
        url,
        collectionInfo,
        tracks,
        resolvedCount,
        failedCount,
        savingTotal,
        savingImported,
        savingSkipped,
        savingFailed,
        error,
      ];
}
