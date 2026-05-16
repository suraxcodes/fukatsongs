import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'music_repository.dart';

final musicRepositoryProvider = Provider<MusicRepository>((ref) {
  return MusicRepository();
});
