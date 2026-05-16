import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fukat_songs/core/audio/audio_handler.dart';

part 'audio_handler_provider.g.dart';

@Riverpod(keepAlive: true)
MusicAudioHandler audioHandler(AudioHandlerRef ref) {
  throw UnimplementedError('Initialize this in main.dart');
}
