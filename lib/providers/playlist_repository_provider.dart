import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'playlist_repository.dart';

final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  return PlaylistRepository();
});
