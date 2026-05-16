import 'package:freezed_annotation/freezed_annotation.dart';
import 'song.dart';

part 'playlist.freezed.dart';
part 'playlist.g.dart';

@freezed
class Playlist with _$Playlist {
  const factory Playlist({
    required String id,
    required String name,
    @Default([]) List<Song> songs,
    @Default(0) int createdAt,
  }) = _Playlist;

  factory Playlist.fromJson(Map<String, dynamic> json) => _$PlaylistFromJson(json);
}
