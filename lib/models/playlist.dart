import 'song.dart';

class Playlist {
  final String id;
  final String name;
  final List<Song> songs;
  final int createdAt;

  const Playlist({
    required this.id,
    required this.name,
    this.songs = const [],
    this.createdAt = 0,
  });

  Playlist copyWith({
    String? id,
    String? name,
    List<Song>? songs,
    int? createdAt,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      songs: songs ?? this.songs,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'songs': songs.map((s) => s.toJson()).toList(),
      'createdAt': createdAt,
    };
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as String,
      name: json['name'] as String,
      songs: (json['songs'] as List?)?.map((s) => Song.fromJson(s as Map<String, dynamic>)).toList() ?? [],
      createdAt: json['createdAt'] as int? ?? 0,
    );
  }
}
