// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'song.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Song _$SongFromJson(Map<String, dynamic> json) {
  return _Song.fromJson(json);
}

/// @nodoc
mixin _$Song {
  @HiveField(0)
  String get id => throw _privateConstructorUsedError;
  @HiveField(1)
  String get title => throw _privateConstructorUsedError;
  @HiveField(2)
  String get artist => throw _privateConstructorUsedError;
  @HiveField(3)
  String get albumName => throw _privateConstructorUsedError;
  @HiveField(4)
  String get year => throw _privateConstructorUsedError;
  @HiveField(5)
  String get imageUrl => throw _privateConstructorUsedError;
  @HiveField(6)
  int get duration => throw _privateConstructorUsedError; // in seconds
  @HiveField(7)
  String get source =>
      throw _privateConstructorUsedError; // 'saavn' | 'youtube'
  @HiveField(8)
  Map<String, String> get providers =>
      throw _privateConstructorUsedError; // provider_id -> song_id
  @HiveField(9)
  String? get localPath => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SongCopyWith<Song> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SongCopyWith<$Res> {
  factory $SongCopyWith(Song value, $Res Function(Song) then) =
      _$SongCopyWithImpl<$Res, Song>;
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) String title,
      @HiveField(2) String artist,
      @HiveField(3) String albumName,
      @HiveField(4) String year,
      @HiveField(5) String imageUrl,
      @HiveField(6) int duration,
      @HiveField(7) String source,
      @HiveField(8) Map<String, String> providers,
      @HiveField(9) String? localPath});
}

/// @nodoc
class _$SongCopyWithImpl<$Res, $Val extends Song>
    implements $SongCopyWith<$Res> {
  _$SongCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? artist = null,
    Object? albumName = null,
    Object? year = null,
    Object? imageUrl = null,
    Object? duration = null,
    Object? source = null,
    Object? providers = null,
    Object? localPath = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      artist: null == artist
          ? _value.artist
          : artist // ignore: cast_nullable_to_non_nullable
              as String,
      albumName: null == albumName
          ? _value.albumName
          : albumName // ignore: cast_nullable_to_non_nullable
              as String,
      year: null == year
          ? _value.year
          : year // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: null == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String,
      duration: null == duration
          ? _value.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as int,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String,
      providers: null == providers
          ? _value.providers
          : providers // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      localPath: freezed == localPath
          ? _value.localPath
          : localPath // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SongImplCopyWith<$Res> implements $SongCopyWith<$Res> {
  factory _$$SongImplCopyWith(
          _$SongImpl value, $Res Function(_$SongImpl) then) =
      __$$SongImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) String title,
      @HiveField(2) String artist,
      @HiveField(3) String albumName,
      @HiveField(4) String year,
      @HiveField(5) String imageUrl,
      @HiveField(6) int duration,
      @HiveField(7) String source,
      @HiveField(8) Map<String, String> providers,
      @HiveField(9) String? localPath});
}

/// @nodoc
class __$$SongImplCopyWithImpl<$Res>
    extends _$SongCopyWithImpl<$Res, _$SongImpl>
    implements _$$SongImplCopyWith<$Res> {
  __$$SongImplCopyWithImpl(_$SongImpl _value, $Res Function(_$SongImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? artist = null,
    Object? albumName = null,
    Object? year = null,
    Object? imageUrl = null,
    Object? duration = null,
    Object? source = null,
    Object? providers = null,
    Object? localPath = freezed,
  }) {
    return _then(_$SongImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      artist: null == artist
          ? _value.artist
          : artist // ignore: cast_nullable_to_non_nullable
              as String,
      albumName: null == albumName
          ? _value.albumName
          : albumName // ignore: cast_nullable_to_non_nullable
              as String,
      year: null == year
          ? _value.year
          : year // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: null == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String,
      duration: null == duration
          ? _value.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as int,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String,
      providers: null == providers
          ? _value._providers
          : providers // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      localPath: freezed == localPath
          ? _value.localPath
          : localPath // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
@HiveType(typeId: 0)
class _$SongImpl implements _Song {
  const _$SongImpl(
      {@HiveField(0) required this.id,
      @HiveField(1) required this.title,
      @HiveField(2) required this.artist,
      @HiveField(3) required this.albumName,
      @HiveField(4) required this.year,
      @HiveField(5) required this.imageUrl,
      @HiveField(6) required this.duration,
      @HiveField(7) required this.source,
      @HiveField(8) required final Map<String, String> providers,
      @HiveField(9) this.localPath})
      : _providers = providers;

  factory _$SongImpl.fromJson(Map<String, dynamic> json) =>
      _$$SongImplFromJson(json);

  @override
  @HiveField(0)
  final String id;
  @override
  @HiveField(1)
  final String title;
  @override
  @HiveField(2)
  final String artist;
  @override
  @HiveField(3)
  final String albumName;
  @override
  @HiveField(4)
  final String year;
  @override
  @HiveField(5)
  final String imageUrl;
  @override
  @HiveField(6)
  final int duration;
// in seconds
  @override
  @HiveField(7)
  final String source;
// 'saavn' | 'youtube'
  final Map<String, String> _providers;
// 'saavn' | 'youtube'
  @override
  @HiveField(8)
  Map<String, String> get providers {
    if (_providers is EqualUnmodifiableMapView) return _providers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_providers);
  }

// provider_id -> song_id
  @override
  @HiveField(9)
  final String? localPath;

  @override
  String toString() {
    return 'Song(id: $id, title: $title, artist: $artist, albumName: $albumName, year: $year, imageUrl: $imageUrl, duration: $duration, source: $source, providers: $providers, localPath: $localPath)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SongImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.artist, artist) || other.artist == artist) &&
            (identical(other.albumName, albumName) ||
                other.albumName == albumName) &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.source, source) || other.source == source) &&
            const DeepCollectionEquality()
                .equals(other._providers, _providers) &&
            (identical(other.localPath, localPath) ||
                other.localPath == localPath));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      artist,
      albumName,
      year,
      imageUrl,
      duration,
      source,
      const DeepCollectionEquality().hash(_providers),
      localPath);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SongImplCopyWith<_$SongImpl> get copyWith =>
      __$$SongImplCopyWithImpl<_$SongImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SongImplToJson(
      this,
    );
  }
}

abstract class _Song implements Song {
  const factory _Song(
      {@HiveField(0) required final String id,
      @HiveField(1) required final String title,
      @HiveField(2) required final String artist,
      @HiveField(3) required final String albumName,
      @HiveField(4) required final String year,
      @HiveField(5) required final String imageUrl,
      @HiveField(6) required final int duration,
      @HiveField(7) required final String source,
      @HiveField(8) required final Map<String, String> providers,
      @HiveField(9) final String? localPath}) = _$SongImpl;

  factory _Song.fromJson(Map<String, dynamic> json) = _$SongImpl.fromJson;

  @override
  @HiveField(0)
  String get id;
  @override
  @HiveField(1)
  String get title;
  @override
  @HiveField(2)
  String get artist;
  @override
  @HiveField(3)
  String get albumName;
  @override
  @HiveField(4)
  String get year;
  @override
  @HiveField(5)
  String get imageUrl;
  @override
  @HiveField(6)
  int get duration;
  @override // in seconds
  @HiveField(7)
  String get source;
  @override // 'saavn' | 'youtube'
  @HiveField(8)
  Map<String, String> get providers;
  @override // provider_id -> song_id
  @HiveField(9)
  String? get localPath;
  @override
  @JsonKey(ignore: true)
  _$$SongImplCopyWith<_$SongImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
