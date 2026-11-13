// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:fukatsongs/core/models/exported.dart';
import 'package:fukatsongs/core/models/media_playlist_model.dart';
import 'package:fukatsongs/services/db/dao/playlist_dao.dart';
import 'package:fukatsongs/services/db/mappers/media_item_mapper.dart';
import 'package:fukatsongs/services/playlist_sort/playlist_sort_store.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:fukatsongs/utils/pallete_generator.dart';

part 'current_playlist_state.dart';

/// Uses one sorted ID snapshot per open/sort, then hydrates 40 tracks per page.
/// Playback consumes this SAME snapshot, not a fresh differently ordered query.
class CurrentPlaylistCubit extends Cubit<CurrentPlaylistState> {
  static const int _pageSize = 40;

  Playlist? _playlist;
  PaletteGenerator? _paletteGenerator;
  final PlaylistDAO _playlistDao;
  int? _playlistId;
  int _offset = 0;
  int _loadRevision = 0;
  List<int> _orderedIds = const [];
  Future<void>? _pageFuture;

  int? get playlistId => _playlistId;
  int get loadRevision => _loadRevision;

  CurrentPlaylistCubit({
    Playlist? playlist,
    required PlaylistDAO playlistDao})  : _playlist = playlist,
        _playlistDao = playlistDao,
        super(const CurrentPlaylistInitial());

  bool _alive(int revision) => !isClosed && revision == _loadRevision;

  Future<void> setupPlaylist(String playlistName) => openPlaylist(playlistName);

  Future<void> openPlaylist(
    String playlistName, {
    bool deferFirstPage = false,
  }) async {
    final revision = ++_loadRevision;
    _pageFuture = null;
    _paletteGenerator = null;
    _offset = 0;
    _orderedIds = const [];
    _playlistId = null;
    emit(
      state.copyWith(
        isFetched: false,
        status: CurrentPlaylistLoadStatus.loading,
        playlist: Playlist(tracks: const [], title: playlistName),
        totalTracks: 0,
        hasMore: false,
        isLoadingMore: false,
      ),
    );
    try {
      final dbPlaylist = await _playlistDao.getPlaylistByName(playlistName);
    if (!_alive(revision)) return;
      if (dbPlaylist == null)
        throw StateError('Playlist "$playlistName" not found');
      final snapshot = await _playlistDao.getOrderSnapshot(dbPlaylist.id);
      if (!_alive(revision)) return;
      _playlistId = dbPlaylist.id;
      _orderedIds = snapshot.trackDbIds;
      _playlist = playlistDBToPlaylist(dbPlaylist).copyWith(tracks: const []);
      emit(
        state.copyWith(
          isFetched: true,
          playlist: _playlist,
          sortMode: snapshot.mode,
          totalTracks: _orderedIds.length,
          hasMore: _orderedIds.isNotEmpty,
          isLoadingMore: false,
          status: _orderedIds.isEmpty
              ? CurrentPlaylistLoadStatus.success
              : CurrentPlaylistLoadStatus.partial,
        ),
      );
      if (_orderedIds.isNotEmpty && !deferFirstPage) await loadMoreTracks();
    } catch (error) {
      if (_alive(revision))
        emit(
        state.copyWith(
          status: CurrentPlaylistLoadStatus.error,
          errorMessage: error.toString(),
            isLoadingMore: false,
        ),
      );
    }
  }

  Future<void> loadMoreTracks() {
    if (_pageFuture != null) return _pageFuture!;
    if (_playlistId == null || !state.hasMore || isClosed)
      return Future.value();
    final revision = _loadRevision;
    final completer = Completer<void>();
    _pageFuture = completer.future;
    unawaited(
      _loadPage(revision).then(
        (_) {
          if (_alive(revision)) _pageFuture = null;
          completer.complete();
        },
        onError: (Object error, StackTrace stack) {
          if (_alive(revision)) _pageFuture = null;
          completer.completeError(error, stack);
        },
      ),
    );
    return completer.future;
  }

  Future<void> _loadPage(int revision) async {
    emit(state.copyWith(isLoadingMore: true));

    try {
      final end = (_offset + _pageSize).clamp(0, _orderedIds.length);
      final ids = _orderedIds.sublist(_offset, end);
      final rows = await _playlistDao.getTracksByDbIds(ids);
      if (!_alive(revision)) return;

      final merged = <Track>[
        ...state.playlist.tracks,
        ...rows.map(trackDBToTrack),
      ];
      _offset = end;
      final more = _offset < _orderedIds.length;
      _playlist = state.playlist.copyWith(tracks: merged);

      emit(
        state.copyWith(
          playlist: _playlist,
          hasMore: more,
          totalTracks: more ? _orderedIds.length : merged.length,
          isLoadingMore: false,
          status: more
              ? CurrentPlaylistLoadStatus.partial
              : CurrentPlaylistLoadStatus.success,
        ),
      );

      if (_paletteGenerator == null && merged.isNotEmpty) {
        unawaited(_generatePalette(merged.first.thumbnail.url, revision));
      }
    } catch (error) {
      if (_alive(revision))
        emit(
        state.copyWith(
          isLoadingMore: false,
          status: CurrentPlaylistLoadStatus.error,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _generatePalette(String imageUrl, int revision) async {
    if (imageUrl.isEmpty) return;
    try {
      final palette = await getPalleteFromImage(imageUrl);
      if (!_alive(revision)) return;
    _paletteGenerator = palette;
    emit(state.copyWith());
  } catch (_) {
      /* artwork failure must not block sorting/playback */
    }
  }

  Future<Playlist> ensureAllTracksLoaded() async {
    final revision = _loadRevision;
    while (_alive(revision) && state.hasMore) {
      await loadMoreTracks();
      if (state.status == CurrentPlaylistLoadStatus.error) {
        throw StateError(state.errorMessage ?? 'Could not load playlist');
      }
    }
    if (!_alive(revision)) throw StateError('Playlist changed while loading');
    return state.playlist;
  }

  Future<void> setSortMode(PlaylistSortMode mode) async {
    final id = _playlistId;
    final name = _playlist?.title;
    if (id == null || name == null) return;
    final revision = ++_loadRevision;
    _pageFuture = null;
    emit(
      state.copyWith(
        isFetched: false,
        isLoadingMore: false,
        status: CurrentPlaylistLoadStatus.loading,
      ),
    );
    try {
      await _playlistDao.setSortMode(id, mode);
      if (_alive(revision)) await openPlaylist(name);
    } catch (error) {
      if (_alive(revision))
        emit(
          state.copyWith(
            isFetched: true,
            status: CurrentPlaylistLoadStatus.error,
            errorMessage: error.toString(),
          ),
        );
      rethrow;
    }
  }

  Future<(Track, int)?> removeTrack(Track track) async {
    final id = _playlistId;
    final name = _playlist?.title;
    final revision = _loadRevision;
    if (id == null || name == null) return null;
    final index = state.playlist.tracks.indexWhere((t) => t.id == track.id);
    if (index < 0) return null;
    await _playlistDao.removeTrackFromPlaylist(id, track.id);
    if (_alive(revision)) await openPlaylist(name);
    return (track, index);
  }

  String getTitle() => state.playlist.title;

  int getPlaylistLength() => _playlist?.tracks.length ?? 0;

  String? getPlaylistCoverArt() => _playlist?.tracks.isNotEmpty == true
      ? _playlist!.tracks.first.thumbnail.url
      : '';
  PaletteGenerator? getCurrentPlaylistPallete() => _paletteGenerator;

  Future<void> updatePlaylist(List<Track> reorderedTracks) async {
    final id = _playlistId;
    final name = _playlist?.title;
    final revision = _loadRevision;
    if (id == null || name == null) return;
    final loaded = await ensureAllTracksLoaded();
    if (!_alive(revision)) return;
    final expected = loaded.tracks.map((t) => t.id).toSet();
    final provided = reorderedTracks.map((t) => t.id).toSet();
    if (reorderedTracks.length != loaded.tracks.length ||
        provided.length != expected.length ||
        !expected.containsAll(provided)) {
      throw StateError('Refusing partial or mismatched playlist reorder');
    }
    await _playlistDao.setPlaylistTracks(id, reorderedTracks);
    if (_alive(revision)) await openPlaylist(name);
  }

  Future<void> reorderTrack(int oldIndex, int newIndex) async {
    final loaded = await ensureAllTracksLoaded();
    final tracks = List<Track>.of(loaded.tracks);
    if (oldIndex < 0 ||
        oldIndex >= tracks.length ||
        newIndex < 0 ||
        newIndex >= tracks.length)
      return;
    final item = tracks.removeAt(oldIndex);
    tracks.insert(newIndex, item);
    await updatePlaylist(tracks);
  }

  void replaceTrack(Track original, Track replacement) {
    if (_playlist == null) return;
    _playlist = _playlist!.copyWith(
      tracks: state.playlist.tracks
        .map((t) => t.id == original.id ? replacement : t)
        .toList(),
    );
    emit(state.copyWith(playlist: _playlist));
  }

  String? get currentPlaylistName => _playlist?.title;

  @override
  Future<void> close() {
    _loadRevision++;
    return super.close();
  }
}
