// lib/services/audio_pipeline_test_screen.dart
//
// TEMPORARY diagnostic screen for validating the audio capture + Vosk pipeline
// before integrating into vosk_voice_service.dart.
//
// Access: long-press the volume button overlay (added in volume_slider.dart).
// Remove this file + the entry point once the pipeline is validated and
// integrated into vosk_voice_service.dart.
//
// HOW TO TEST:
//   1. Tap "Start SCO"        → music quality drops (HFP active). Confirms
//                               Bluetooth mic routing is possible.
//   2. Tap "VOICE_RECOGNITION" → mic opens with hardware noise suppression.
//                               This is the phone mic. Test in a quiet room.
//   3. Tap "BLUETOOTH"        → mic routes to earbud/headset. Music quality
//                               stays HFP. Speak into your earbud. This is
//                               the on-bike scenario.
//   4. Say "pause music" / "next song" / "volume up" → watch the log
//      output on the screen. The Vosk model has been initialized with your
//      grammar list, so only these commands (plus noise) will be recognized.
//   5. Say "stop listening" → tap "Stop Capture" to reset.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:audio_capture_plugin/audio_capture_plugin.dart';
import 'package:flutter/material.dart';
import 'package:vosk_flutter_service/vosk_flutter_service.dart';

class AudioPipelineTestScreen extends StatefulWidget {
  const AudioPipelineTestScreen({super.key});

  @override
  State<AudioPipelineTestScreen> createState() =>
      _AudioPipelineTestScreenState();
}

class _AudioPipelineTestScreenState extends State<AudioPipelineTestScreen> {
  // ── Vosk ────────────────────────────────────────────────────────────
  final VoskFlutterPlugin _vosk = VoskFlutterPlugin.instance();
  Model? _model;
  Recognizer? _recognizer;
  bool _modelLoading = false;
  bool _modelReady = false;

  // ── Audio capture ───────────────────────────────────────────────────
  final AudioCapturePlugin _capture = AudioCapturePlugin();
  StreamSubscription<List<int>>? _pcmSub;
  bool _capturing = false;
  String _currentSource = '';

  // ── SCO state ───────────────────────────────────────────────────────
  bool _scoActive = false;
  bool? _scoAvailable;

  // ── Recognized events for UI ───────────────────────────────────────
  final List<_LogEntry> _log = [];
  static const int _maxLogEntries = 30;
  int _chunksReceived = 0;
  int _bytesReceived = 0;

  // ── Vosk grammar (same as production) ──────────────────────────────
  static const List<String> _grammar = [
    'pause music', 'stop music', 'pause song', 'stop song',
    'music pause', 'music stop', 'pause the music', 'stop the music',
    'next song', 'skip song', 'next track', 'skip track',
    'next music', 'skip music', 'music next', 'play next song',
    'play music', 'start music', 'resume music',
    'play song', 'start song', 'music play', 'music start',
    'previous song', 'previous track', 'previous music',
    'play previous song', 'music back', 'music previous',
    'volume up', 'increase volume', 'volume increase',
    'volume down', 'decrease volume', 'volume decrease',
    'shuffle on', 'shuffle off', 'turn on shuffle', 'turn off shuffle',
    'stop listening', 'stop voice', 'turn off voice', 'stop hands free',
    '[unk]',
  ];

  @override
  void initState() {
    super.initState();
    _checkSco();
    _initVosk();
  }

  @override
  void dispose() {
    _stopCaptureSync();
    _pcmSub?.cancel();
    super.dispose();
  }

  // ── Setup ──────────────────────────────────────────────────────────

  Future<void> _checkSco() async {
    try {
      final available = await _capture.isScoAvailable();
      if (mounted) setState(() => _scoAvailable = available);
    } catch (e) {
      _logLine('SCO check failed: $e');
    }
  }

  Future<void> _initVosk() async {
    if (_modelReady || _modelLoading) return;
    setState(() => _modelLoading = true);
    _logLine('Loading Vosk model...');
    try {
      final modelLoader = ModelLoader();
      final modelPath = await modelLoader.loadFromNetwork(
        'https://alphacephei.com/vosk/models/vosk-model-small-en-us-0.15.zip',
      );
      _logLine('Model downloaded to: $modelPath');
      _model = await _vosk.createModel(modelPath);
      _logLine('Model loaded. Creating recognizer with grammar...');
      _recognizer = await _vosk.createRecognizer(
        model: _model!,
        sampleRate: 16000,
        grammar: _grammar,
      );
      _logLine('Recognizer ready. Grammar has ${_grammar.length} entries.');
      if (mounted) {
        setState(() {
          _modelReady = true;
          _modelLoading = false;
        });
      }
    } catch (e, st) {
      _logLine('Vosk init FAILED: $e\n$st');
      if (mounted) {
        setState(() {
          _modelReady = false;
          _modelLoading = false;
        });
      }
    }
  }

  // ── SCO control ────────────────────────────────────────────────────

  Future<void> _toggleSco() async {
    if (_scoActive) {
      try {
        await _capture.stopSco();
        setState(() => _scoActive = false);
        _logLine('SCO stopped.');
      } catch (e) {
        _logLine('stopSco FAILED: $e');
      }
    } else {
      try {
        await _capture.startSco();
        setState(() => _scoActive = true);
        _logLine('SCO started (music quality should drop).');
      } catch (e) {
        _logLine('startSco FAILED: $e');
      }
    }
  }

  // ── Capture control ────────────────────────────────────────────────

  Future<void> _startCapture(String audioSource) async {
    if (!_modelReady || _recognizer == null) {
      _logLine('Cannot start: Vosk not ready.');
      return;
    }
    if (_capturing) {
      await _stopCapture();
    }

    _chunksReceived = 0;
    _bytesReceived = 0;

    try {
      _logLine('Starting capture: $audioSource');
      await _capture.startCapture(
        audioSource: audioSource,
        sampleRate: 16000,
      );
      setState(() {
        _capturing = true;
        _currentSource = audioSource;
      });
      _logLine('Capture started.');

      _pcmSub?.cancel();
      _pcmSub = _capture.pcmStream.listen(
        (chunk) {
          _chunksReceived++;
          _bytesReceived += chunk.length;
          _feedChunk(chunk);
        },
        onError: (e) {
          _logLine('PCM stream error: $e');
        },
      );
    } catch (e) {
      _logLine('startCapture FAILED: $e');
    }
  }

  Future<void> _stopCapture() async {
    await _pcmSub?.cancel();
    _pcmSub = null;
    try {
      await _capture.stopCapture();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _capturing = false;
        _currentSource = '';
      });
    }
    _logLine('Capture stopped. Chunks: $_chunksReceived, '
        'bytes: $_bytesReceived (~${(_bytesReceived / 32000).toStringAsFixed(1)}s of audio)');
  }

  void _stopCaptureSync() {
    _pcmSub?.cancel();
    _pcmSub = null;
    _capture.stopCapture().catchError((_) {});
  }

  // ── Feed PCM to Vosk ──────────────────────────────────────────────

  Future<void> _feedChunk(List<int> chunk) async {
    if (_recognizer == null) return;
    try {
      final bytes = chunk is Uint8List
          ? chunk
          : Uint8List.fromList(chunk);
      final gotResult = await _recognizer!.acceptWaveformBytes(bytes);
      if (gotResult) {
        // Vosk detected end of utterance (silence boundary) and has a final
        // result. Read and log it.
        final resultJson = await _recognizer!.getResult();
        _parseAndLog(resultJson, isFinal: true);
      } else {
        // No final result yet, but check partial to display live text.
        // Throttle: only log partials every ~5 chunks (~0.5s of audio).
        if (_chunksReceived % 5 == 0) {
          final partialJson = await _recognizer!.getPartialResult();
          _parseAndLog(partialJson, isFinal: false);
        }
      }
    } catch (e) {
      _logLine('Vosk feed error: $e');
    }
  }

  void _parseAndLog(String resultJson, {required bool isFinal}) {
    try {
      final map = jsonDecode(resultJson) as Map<String, dynamic>;
      final text = (map['text'] ?? map['partial'] ?? '').toString().trim();
      if (text.isEmpty) return;
      _logLine('${isFinal ? "FINAL" : "partial"}: "$text"');
    } catch (_) {}
  }

  // ── Logging ────────────────────────────────────────────────────────

  void _logLine(String message) {
    if (!mounted) return;
    final ts = DateTime.now();
    final entry = _LogEntry(
      ts,
      message,
    );
    setState(() {
      _log.insert(0, entry);
      if (_log.length > _maxLogEntries) {
        _log.removeRange(_maxLogEntries, _log.length);
      }
    });
    debugPrint('[PipelineTest] $message');
  }

  // ── UI ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF14141A),
        title: const Text('Audio Pipeline Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _log.clear());
            },
            tooltip: 'Clear log',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusCard(),
          _buildControls(),
          const Divider(height: 1, color: Colors.white24),
          Expanded(child: _buildLog()),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      color: const Color(0xFF14141A),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _statusRow(
            'SCO available',
            _scoAvailable == null ? '...' : (_scoAvailable! ? 'YES' : 'NO'),
            _scoAvailable == true ? Colors.green : Colors.red,
          ),
          _statusRow(
            'SCO active',
            _scoActive ? 'ON' : 'OFF',
            _scoActive ? Colors.green : Colors.grey,
          ),
          _statusRow(
            'Vosk model',
            _modelLoading
                ? 'loading...'
                : _modelReady
                    ? 'ready'
                    : 'not ready',
            _modelReady
                ? Colors.green
                : _modelLoading
                    ? Colors.orange
                    : Colors.red,
          ),
          _statusRow(
            'Capturing',
            _capturing ? '$_currentSource (${_chunksReceived} chunks)' : 'OFF',
            _capturing ? Colors.green : Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _statusRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _scoAvailable == true ? _toggleSco : null,
                  icon: Icon(_scoActive ? Icons.bluetooth_disabled : Icons.bluetooth),
                  label: Text(_scoActive ? 'Stop SCO' : 'Start SCO'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _scoActive
                        ? Colors.orange.shade700
                        : Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _capturing
                      ? null
                      : () => _startCapture('VOICE_RECOGNITION'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade700,
                  ),
                  child: const Text('VOICE_RECOGNITION'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _capturing
                      ? null
                      : () => _startCapture('BLUETOOTH'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                  ),
                  child: const Text('BLUETOOTH'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _capturing ? _stopCapture : null,
              icon: const Icon(Icons.stop),
              label: const Text('Stop Capture'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Test order: 1) Start SCO. 2) Try VOICE_RECOGNITION in quiet room. '
            '3) Try BLUETOOTH with earbuds. Say "pause music", "next song", "volume up".',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLog() {
    if (_log.isEmpty) {
      return const Center(
        child: Text(
          'No events yet. Tap a button above.',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _log.length,
      itemBuilder: (context, index) {
        final entry = _log[index];
        final isFinal = entry.message.startsWith('FINAL');
        final isPartial = entry.message.startsWith('partial');
        final isError = entry.message.contains('FAILED') ||
            entry.message.contains('error') ||
            entry.message.contains('Error');
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Colors.white70,
              ),
              children: [
                TextSpan(
                  text: '${entry.ts.hour.toString().padLeft(2, "0")}:'
                      '${entry.ts.minute.toString().padLeft(2, "0")}:'
                      '${entry.ts.second.toString().padLeft(2, "0")} '
                      '${entry.ts.millisecond.toString().padLeft(3, "0")} ',
                  style: const TextStyle(color: Colors.white30),
                ),
                TextSpan(
                  text: entry.message,
                  style: TextStyle(
                    color: isFinal
                        ? Colors.green
                        : isPartial
                            ? Colors.yellow
                            : isError
                                ? Colors.red
                                : Colors.white70,
                    fontWeight:
                        isFinal ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LogEntry {
  final DateTime ts;
  final String message;
  _LogEntry(this.ts, this.message);
}