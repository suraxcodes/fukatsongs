// lib/services/voice_command_service.dart
import 'package:flutter/material.dart';
import 'package:fukatsongs/blocs/media_player/bloomee_player_cubit.dart';
import 'package:fukatsongs/services/vosk_voice_service.dart';

/// Hands-free Riding Voice Command Service.
///
/// Front-end facade powered by the offline Vosk Keyword Spotter engine.
/// Provides sub-50ms offline recognition for:
/// - 'pause' / 'stop'
/// - 'next' / 'skip'
/// - 'play' / 'start' / 'resume'
///
/// Operates seamlessly with screen locked in rider's pocket.
class VoiceCommandService {
  VoiceCommandService._();
  static final VoiceCommandService instance = VoiceCommandService._();

  final VoskVoiceService _vosk = VoskVoiceService.instance;

  ValueNotifier<bool> get isEnabled => _vosk.isListening;
  ValueNotifier<bool> get isListening => _vosk.isListening;
  ValueNotifier<String> get lastCommand => _vosk.lastCommand;

  bool get enabled => _vosk.isListening.value;

  /// Toggle hands-free voice command mode ON or OFF.
  Future<void> toggle({
    required bool on,
    required BloomeePlayerCubit cubit,
    BuildContext? context,
  }) async {
    await _vosk.toggle(on: on, cubit: cubit, context: context);
  }

  Future<void> stopListening([BloomeePlayerCubit? cubit]) async {
    await _vosk.stopListening();
  }
}