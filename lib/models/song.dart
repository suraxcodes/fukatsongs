import 'package:hive/hive.dart';

@HiveType(typeId: 0)
class Song {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String artist;
  @HiveField(3)
  final String albumName;
  @HiveField(4)
  final String year;
  @HiveField(5)
  final String imageUrl;
  @HiveField(6)
  final int duration;
  @HiveField(7)
  final String source;
  @HiveField(8)
  final Map<String, String> providers;
  @HiveField(9)
  final String? localPath;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.albumName,
    required this.year,
    required String imageUrl,
    required this.duration,
    required this.source,
    required this.providers,
    this.localPath,
  }) : this.imageUrl = sanitizeImageUrl(imageUrl);

  static String sanitizeImageUrl(String url) {
    if (url.contains('host=')) {
      try {
        final uri = Uri.parse(url);
        final host = uri.queryParameters['host'];
        if (host != null && host.isNotEmpty) {
          return 'https://$host${uri.path}';
        }
      } catch (_) {}
    }
    return url;
  }

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? albumName,
    String? year,
    String? imageUrl,
    int? duration,
    String? source,
    Map<String, String>? providers,
    String? localPath,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      albumName: albumName ?? this.albumName,
      year: year ?? this.year,
      imageUrl: imageUrl ?? this.imageUrl,
      duration: duration ?? this.duration,
      source: source ?? this.source,
      providers: providers ?? this.providers,
      localPath: localPath ?? this.localPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'albumName': albumName,
      'year': year,
      'imageUrl': imageUrl,
      'duration': duration,
      'source': source,
      'providers': providers,
      'localPath': localPath,
    };
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      albumName: json['albumName'] as String? ?? '',
      year: json['year']?.toString() ?? '',
      imageUrl: json['imageUrl'] as String,
      duration: json['duration'] as int? ?? 0,
      source: json['source'] as String? ?? 'saavn',
      providers: Map<String, String>.from(json['providers'] ?? {}),
      localPath: json['localPath'] as String?,
    );
  }
}

class SongAdapter extends TypeAdapter<Song> {
  @override
  final int typeId = 0;

  @override
  Song read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Song(
      id: fields[0] as String,
      title: fields[1] as String,
      artist: fields[2] as String,
      albumName: fields[3] as String,
      year: fields[4] as String,
      imageUrl: fields[5] as String,
      duration: fields[6] as int,
      source: fields[7] as String,
      providers: (fields[8] as Map).cast<String, String>(),
      localPath: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Song obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.artist)
      ..writeByte(3)
      ..write(obj.albumName)
      ..writeByte(4)
      ..write(obj.year)
      ..writeByte(5)
      ..write(obj.imageUrl)
      ..writeByte(6)
      ..write(obj.duration)
      ..writeByte(7)
      ..write(obj.source)
      ..writeByte(8)
      ..write(obj.providers)
      ..writeByte(9)
      ..write(obj.localPath);
  }
}
