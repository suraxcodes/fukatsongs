import 'package:hive_flutter/hive_flutter.dart';
import '../models/playlist.dart';
import '../models/song.dart';

class PlaylistRepository {
  static const String boxName = 'playlists';
  static const String likedBoxName = 'liked_songs';

  // ─── Safe Serialization Helpers ──────────────────────────────
  // Freezed's toJson() does NOT deeply serialize List<Song> — songs come
  // back from Hive as _$SongImpl objects, not Maps. We manually build the
  // map to guarantee songs are always stored as Map<String,dynamic>.

  Map<String, dynamic> _playlistToMap(Playlist playlist) {
    return {
      'id': playlist.id,
      'name': playlist.name,
      'createdAt': playlist.createdAt,
      'songs': playlist.songs.map((s) => s.toJson()).toList(),
    };
  }

  Playlist _playlistFromRaw(dynamic raw) {
    final map = Map<String, dynamic>.from(raw as Map);
    final songsRaw = (map['songs'] as List? ?? []);
    final songs = songsRaw.map((s) {
      if (s is Map) return Song.fromJson(Map<String, dynamic>.from(s));
      // Already a Song object (legacy data) — return as-is
      return s as Song;
    }).toList();
    return Playlist(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: (map['createdAt'] as num).toInt(),
      songs: songs,
    );
  }

  // ─── Playlist CRUD ───────────────────────────────────────────

  Future<void> savePlaylist(Playlist playlist) async {
    final box = Hive.box(boxName);
    await box.put(playlist.id, _playlistToMap(playlist));
  }

  List<Playlist> getAllPlaylists() {
    final box = Hive.box(boxName);
    return box.values
        .map((item) => _playlistFromRaw(item))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> createPlaylist(String name) async {
    final playlist = Playlist(
      id: 'pl_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await savePlaylist(playlist);
  }

  Future<void> deletePlaylist(String id) async {
    final box = Hive.box(boxName);
    await box.delete(id);
  }

  Future<void> addSongToPlaylist(String playlistId, Song song) async {
    final box = Hive.box(boxName);
    final raw = box.get(playlistId);
    if (raw == null) return;
    final playlist = _playlistFromRaw(raw);
    if (playlist.songs.any((s) => s.id == song.id)) return;
    final updated = playlist.copyWith(songs: [...playlist.songs, song]);
    await box.put(playlistId, _playlistToMap(updated));
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    final box = Hive.box(boxName);
    final raw = box.get(playlistId);
    if (raw == null) return;
    final playlist = _playlistFromRaw(raw);
    final updated = playlist.copyWith(
      songs: playlist.songs.where((s) => s.id != songId).toList(),
    );
    await box.put(playlistId, _playlistToMap(updated));
  }

  Future<void> updateSongInAllPlaylists(Song repairedSong) async {
    final box = Hive.box(boxName);
    for (var key in box.keys) {
      final playlist = _playlistFromRaw(box.get(key));
      bool modified = false;
      final updatedSongs = playlist.songs.map((s) {
        if (s.id == repairedSong.id) {
          modified = true;
          return repairedSong;
        }
        return s;
      }).toList();
      if (modified) {
        await box.put(key, _playlistToMap(playlist.copyWith(songs: updatedSongs)));
      }
    }
  }

  // ─── Liked Songs ─────────────────────────────────────────────

  List<Song> getLikedSongs() {
    final box = Hive.box(likedBoxName);
    return box.values
        .map((v) => Song.fromJson(Map<String, dynamic>.from(v as Map)))
        .toList()
        .reversed
        .toList();
  }

  bool isLiked(String songId) {
    return Hive.box(likedBoxName).containsKey(songId);
  }

  Future<void> toggleLike(Song song) async {
    final box = Hive.box(likedBoxName);
    if (box.containsKey(song.id)) {
      await box.delete(song.id);
    } else {
      await box.put(song.id, song.toJson());
    }
  }
}
