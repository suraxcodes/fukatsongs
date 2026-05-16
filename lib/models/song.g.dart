// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SongImplAdapter extends TypeAdapter<_$SongImpl> {
  @override
  final int typeId = 0;

  @override
  _$SongImpl read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return _$SongImpl(
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
  void write(BinaryWriter writer, _$SongImpl obj) {
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
      ..writeByte(9)
      ..write(obj.localPath)
      ..writeByte(8)
      ..write(obj.providers);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SongImplAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SongImpl _$$SongImplFromJson(Map<String, dynamic> json) => _$SongImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      albumName: json['albumName'] as String,
      year: json['year'] as String,
      imageUrl: json['imageUrl'] as String,
      duration: (json['duration'] as num).toInt(),
      source: json['source'] as String,
      providers: Map<String, String>.from(json['providers'] as Map),
      localPath: json['localPath'] as String?,
    );

Map<String, dynamic> _$$SongImplToJson(_$SongImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'artist': instance.artist,
      'albumName': instance.albumName,
      'year': instance.year,
      'imageUrl': instance.imageUrl,
      'duration': instance.duration,
      'source': instance.source,
      'providers': instance.providers,
      'localPath': instance.localPath,
    };
