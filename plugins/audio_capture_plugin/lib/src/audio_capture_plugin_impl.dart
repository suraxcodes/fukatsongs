import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';

class AudioCapturePluginImpl {
  static const MethodChannel _method =
      MethodChannel('audio_capture_plugin/method');
  static const EventChannel _pcm =
      EventChannel('audio_capture_plugin/pcm');

  Stream<List<int>>? _pcmStream;

  Future<bool> startCapture({
    required String audioSource,
    required int sampleRate,
  }) async {
    final result = await _method.invokeMethod<bool>('startCapture', {
      'audioSource': audioSource,
      'sampleRate': sampleRate,
    });
    return result ?? false;
  }

  Future<void> stopCapture() async {
    await _method.invokeMethod('stopCapture');
  }

  Stream<List<int>> get pcmStream =>
      _pcmStream ??= _pcm.receiveBroadcastStream().map((event) {
        if (event is Uint8List) return event;
        if (event is List<int>) return event;
        return <int>[];
      });

  Future<bool> isScoAvailable() async {
    final result = await _method.invokeMethod<bool>('isScoAvailable');
    return result ?? false;
  }

  Future<void> startSco() async {
    await _method.invokeMethod('startSco');
  }

  Future<void> stopSco() async {
    await _method.invokeMethod('stopSco');
  }
}