import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fukat_songs/models/playlist.dart';
import 'package:fukat_songs/models/song.dart';
import 'package:fukat_songs/providers/playlist_repository.dart';
import 'package:fukat_songs/providers/playlist_repository_provider.dart';

class PlaylistNotifier extends StateNotifier<List<Playlist>> {
  final PlaylistRepository _repo;

  PlaylistNotifier(this._repo) : super([]) {
    state = _repo.getAllPlaylists();
  }

  Future<void> createPlaylist(String name, {List<Song>? songs}) async {
    await _repo.createPlaylist(name, songs: songs);
    state = _repo.getAllPlaylists();
  }

  Future<void> renamePlaylist(String id, String newName) async {
    await _repo.renamePlaylist(id, newName);
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

  Future<void> removeSongFromAllPlaylists(String songId) async {
    for (final pl in state) {
      if (pl.songs.any((s) => s.id == songId)) {
        await _repo.removeSongFromPlaylist(pl.id, songId);
      }
    }
    state = _repo.getAllPlaylists();
  }

  Playlist? getPlaylist(String id) {
    try {
      return state.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}

final playlistNotifierProvider = StateNotifierProvider<PlaylistNotifier, List<Playlist>>((ref) {
  final repo = ref.watch(playlistRepositoryProvider);
  return PlaylistNotifier(repo);
});

// ─── Liked Songs ─────────────────────────────────────────────

class LikedSongsNotifier extends StateNotifier<List<Song>> {
  final PlaylistRepository _repo;

  LikedSongsNotifier(this._repo) : super([]) {
    state = _repo.getLikedSongs();
  }

  Future<void> toggle(Song song) async {
    await _repo.toggleLike(song);
    state = _repo.getLikedSongs();
  }

  bool isLiked(String songId) => _repo.isLiked(songId);
}

final likedSongsNotifierProvider = StateNotifierProvider<LikedSongsNotifier, List<Song>>((ref) {
  final repo = ref.watch(playlistRepositoryProvider);
  return LikedSongsNotifier(repo);
});
