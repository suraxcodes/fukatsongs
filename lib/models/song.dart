import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'song.freezed.dart';
part 'song.g.dart';

@freezed
class Song with _$Song {
  @HiveType(typeId: 0)
  const factory Song({
    @HiveField(0) required String id,
    @HiveField(1) required String title,
    @HiveField(2) required String artist,
    @HiveField(3) required String albumName,
    @HiveField(4) required String year,
    @HiveField(5) required String imageUrl,
    @HiveField(6) required int duration, // in seconds
    @HiveField(7) required String source, // 'saavn' | 'youtube'
    @HiveField(8) required Map<String, String> providers, // provider_id -> song_id
    @HiveField(9) String? localPath,
  }) = _Song;
}
