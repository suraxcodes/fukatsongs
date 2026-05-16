import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'playlist_repository.dart';

part 'playlist_repository_provider.g.dart';

@riverpod
PlaylistRepository playlistRepository(PlaylistRepositoryRef ref) {
  return PlaylistRepository();
}
