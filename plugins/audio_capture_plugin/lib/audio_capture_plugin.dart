import 'src/audio_capture_plugin_impl.dart';

/// A Flutter plugin that captures raw PCM audio from a configurable
/// Android audio source. Used by FukatMusic's hands-free voice pipeline.
class AudioCapturePlugin {
  static final AudioCapturePlugin _instance = AudioCapturePlugin._();
  factory AudioCapturePlugin() => _instance;
  AudioCapturePlugin._();

  final AudioCapturePluginImpl _impl = AudioCapturePluginImpl();

  Future<bool> startCapture({
    String audioSource = 'MIC',
    int sampleRate = 16000,
  }) =>
      _impl.startCapture(audioSource: audioSource, sampleRate: sampleRate);

  Future<void> stopCapture() => _impl.stopCapture();

  Stream<List<int>> get pcmStream => _impl.pcmStream;

  Future<bool> isScoAvailable() => _impl.isScoAvailable();

  Future<void> startSco() => _impl.startSco();

  Future<void> stopSco() => _impl.stopSco();
}