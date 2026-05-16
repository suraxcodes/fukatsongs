// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$playlistNotifierHash() => r'513d635a688c20a87e458c085a091284efb6db41';

/// See also [PlaylistNotifier].
@ProviderFor(PlaylistNotifier)
final playlistNotifierProvider =
    AutoDisposeNotifierProvider<PlaylistNotifier, List<Playlist>>.internal(
  PlaylistNotifier.new,
  name: r'playlistNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$playlistNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PlaylistNotifier = AutoDisposeNotifier<List<Playlist>>;
String _$likedSongsNotifierHash() =>
    r'0a65306717a83f60ea45157228d942678d8a30e0';

/// See also [LikedSongsNotifier].
@ProviderFor(LikedSongsNotifier)
final likedSongsNotifierProvider =
    AutoDisposeNotifierProvider<LikedSongsNotifier, List<Song>>.internal(
  LikedSongsNotifier.new,
  name: r'likedSongsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$likedSongsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$LikedSongsNotifier = AutoDisposeNotifier<List<Song>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
