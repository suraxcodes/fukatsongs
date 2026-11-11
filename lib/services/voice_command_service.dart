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

  /// Every phrase the offline recogniser accepts, grouped for display.
  ///
  /// Delegates to [VoskVoiceService.grammarGroups] so the settings screen,
  /// the download dialog and the actual Vosk grammar can never drift apart.
  Map<String, List<String>> get commandGroups =>
      VoskVoiceService.grammarGroups;

  /// Number of user-facing phrases (the `[unk]` noise sink is excluded).
  int get commandCount => VoskVoiceService.grammar.length;

  /// True once the ~39 MB offline model exists on disk.
  Future<bool> isModelReady() => _vosk.isModelReady();

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