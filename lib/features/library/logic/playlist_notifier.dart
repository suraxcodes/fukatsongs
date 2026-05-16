import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../models/playlist.dart';
import '../../../models/song.dart';
import '../../../providers/playlist_repository.dart';
import '../../../providers/playlist_repository_provider.dart';

part 'playlist_notifier.g.dart';

@riverpod
class PlaylistNotifier extends _$PlaylistNotifier {
  PlaylistRepository get _repo => ref.read(playlistRepositoryProvider);

  @override
  List<Playlist> build() {
    return _repo.getAllPlaylists();
  }

  Future<void> createPlaylist(String name) async {
    await _repo.createPlaylist(name);
    state = _repo.getAllPlaylists();
  }

  Future<void> deletePlaylist(String id) async {
    await _repo.deletePlaylist(id);
    state = _repo.getAllPlaylists();
  }

  Future<void> addSong(String playlistId, Song song) async {
    await _repo.addSongToPlaylist(playlistId, song);
    state = _repo.getAllPlaylists();
  }

  Future<void> removeSong(String playlistId, String songId) async {
    await _repo.removeSongFromPlaylist(playlistId, songId);
    state = _repo.getAllPlaylists();
  }

  // Returns the playlist matching the id, or null
  Playlist? getPlaylist(String id) {
    try {
      return state.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}

// ─── Liked Songs ─────────────────────────────────────────────

@riverpod
class LikedSongsNotifier extends _$LikedSongsNotifier {
  PlaylistRepository get _repo => ref.read(playlistRepositoryProvider);

  @override
  List<Song> build() {
    return _repo.getLikedSongs();
  }

  Future<void> toggle(Song song) async {
    await _repo.toggleLike(song);
    state = _repo.getLikedSongs();
  }

  bool isLiked(String songId) => _repo.isLiked(songId);
}
