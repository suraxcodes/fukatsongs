import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'music_repository.dart';

part 'music_repository_provider.g.dart';

@riverpod
MusicRepository musicRepository(MusicRepositoryRef ref) {
  return MusicRepository();
}
