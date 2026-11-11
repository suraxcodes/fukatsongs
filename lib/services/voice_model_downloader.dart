// lib/services/voice_model_downloader.dart
import 'dart:async';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Live status of the hands-free voice model download.
@immutable
class VoiceModelProgress {
  const VoiceModelProgress({
    this.received = 0,
    this.total = 0,
    this.phase = VoiceModelPhase.idle,
    this.message = '',
    this.bytesPerSecond = 0,
  });

  final int received;
  final int total;
  final VoiceModelPhase phase;
  final String message;
  final double bytesPerSecond;

  /// 0.0 – 1.0. Falls back to 0 until the first chunk arrives.
  double get fraction {
    if (phase == VoiceModelPhase.done) return 1;
    if (total <= 0) return 0;
    return (received / total).clamp(0.0, 1.0);
  }

  /// "12.3 MB / 39.3 MB"
  String get text => '${_fmt(received)} / ${_fmt(total)}';

  /// "1.4 MB/s"
  String get speedText => '${_fmt(bytesPerSecond)}/s';

  /// Seconds remaining, or null when it cannot be estimated yet.
  int? get etaSeconds {
    if (bytesPerSecond <= 1 || total <= 0) return null;
    final left = total - received;
    if (left <= 0) return 0;
    return (left / bytesPerSecond).round();
  }

  /// [num], not [double]: [received] and [total] are `int`, and Dart does not
  /// implicitly convert `int` to `double` for arguments.
  static String _fmt(num bytes) {
    if (bytes < 1024) return '${bytes.toStringAsFixed(0)} B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  String toString() => 'VoiceModelProgress($phase, $received/$total)';
}

enum VoiceModelPhase { idle, connecting, downloading, extracting, done, failed }

/// Downloads + unzips the offline Vosk model with **live progress**.
///
/// Why this exists instead of `ModelLoader().loadFromNetwork(url)`:
/// that helper does a single `http.get()`, which buffers all ~39 MB in RAM
/// before writing anything, gives no progress, has no timeout, and can't be
/// cancelled. It also never tells you *why* it failed.
class VoiceModelDownloader {
  VoiceModelDownloader._();
  static final VoiceModelDownloader instance = VoiceModelDownloader._();

  /// Root folder name inside the zip AND the final folder name on disk.
  static const String modelFolderName = 'vosk-model-small-en-us-0.15';

  static const String modelUrl =
      'https://alphacephei.com/vosk/models/$modelFolderName.zip';

  /// Server reports Content-Length: 41205931 (~39.3 MB).
  static const int _expectedBytes = 41205931;

  static const Duration _connectTimeout = Duration(seconds: 20);

  /// Per-chunk budget. A single stalled chunk (tunnel, captive portal) aborts
  /// the download instead of hanging forever at "Connecting…".
  static const Duration _chunkTimeout = Duration(seconds: 30);

  /// Marker file that records "the full voice-command list has been shown
  /// once already". Deliberately a file, not a SharedPreferences key: this
  /// class has no settings/DB dependency and must not grow one.
  static const String _seenMarkerName = '.voice_commands_seen';

  /// Publishes progress. UI listens to this for the bar.
  final ValueNotifier<VoiceModelProgress> progress =
      ValueNotifier<VoiceModelProgress>(const VoiceModelProgress());

  final ValueNotifier<bool> isDownloading = ValueNotifier<bool>(false);

  http.Client? _client;
  Future<String?>? _inFlight;
  bool _cancelled = false;

  /// Where the finished model lives: <appDocs>/models/vosk-model-small-en-us-0.15
  Future<String> get modelDirPath async {
    final docs = await getApplicationDocumentsDirectory();
    return p.join(docs.path, 'models', modelFolderName);
  }

  /// True when the model is already on disk.
  ///
  /// The Vosk model zip contains exactly: `am/`, `conf/`, `graph/`,
  /// `ivector/`, `README`. A half-extracted folder left behind by an
  /// interrupted run is missing at least one of these, so require `am/`
  /// and `conf/` (both tiny, both always present).
  Future<bool> isReady() async {
    try {
      final dir = await modelDirPath;
      return Directory(p.join(dir, 'am')).existsSync() &&
          Directory(p.join(dir, 'conf')).existsSync();
    } catch (_) {
      return false;
    }
  }

  /// <appDocs>/models/.voice_commands_seen
  Future<File> get _seenMarkerFile async {
    final docs = await getApplicationDocumentsDirectory();
    return File(p.join(docs.path, 'models', _seenMarkerName));
  }

  /// True once the full command list has been shown to this install.
  ///
  /// Called on every hands-free ON toggle, so it must never throw and must
  /// be cheap — a single `exists()` stat, no downloader state touched.
  Future<bool> get hasSeenCommands async {
    try {
      return (await _seenMarkerFile).existsSync();
    } catch (_) {
      return false;
    }
  }

  /// Record that the command list has been shown. Best-effort: if the write
  /// fails the only consequence is that the list shows once more next time.
  Future<void> markCommandsSeen() async {
    try {
      final f = await _seenMarkerFile;
      await f.parent.create(recursive: true);
      await f.writeAsString('1', flush: true);
    } catch (_) {
      // Non-fatal by design.
    }
  }

  /// Abort an in-flight download (user pressed Cancel / left the screen).
  ///
  /// Closing the client does NOT reliably abort an `await for` over the
  /// response stream — it can simply end the stream normally. [_cancelled]
  /// is what tells [ensureModel] that the short/empty result is expected
  /// and must not be reported as a failure.
  void cancel() {
    _cancelled = true;
    _client?.close();
    _client = null;
    isDownloading.value = false;
    progress.value = const VoiceModelProgress(phase: VoiceModelPhase.idle);
  }

  /// Download + extract. Returns the model folder path, or null on failure
  /// **or cancellation**. Callers can tell them apart with
  /// [isDownloading] / [progress].phase.
  ///
  /// Concurrent callers share one download instead of the second one being
  /// silently reported as a failure.
  Future<String?> ensureModel({void Function(VoiceModelProgress)? onProgress}) {
    final running = _inFlight;
    if (running != null) return running;
    return _inFlight = _ensureModel(onProgress: onProgress)
        .whenComplete(() => _inFlight = null);
  }

  Future<String?> _ensureModel(
      {void Function(VoiceModelProgress)? onProgress}) async {
    final existing = await modelDirPath;
    if (await isReady()) {
      _emit(const VoiceModelProgress(phase: VoiceModelPhase.done), onProgress);
      return existing;
    }

    _cancelled = false;
    isDownloading.value = true;

    final client = http.Client();
    _client = client;
    final sw = Stopwatch()..start();

    try {
      _emit(
        const VoiceModelProgress(
            phase: VoiceModelPhase.connecting, message: 'Connecting…'),
        onProgress,
      );

      final request = http.Request('GET', Uri.parse(modelUrl));
      final response = await client.send(request).timeout(_connectTimeout);

      if (_cancelled) return null;

      if (response.statusCode != 200) {
        throw 'Server returned HTTP ${response.statusCode}';
      }

      final total = response.contentLength ?? _expectedBytes;

      // BytesBuilder(copy: false) instead of `<int>[]..addAll(chunk)`:
      // a growable list of 41 M ints reallocates ~25 times and spikes RAM.
      final bytes = BytesBuilder(copy: false);

      _emit(
        VoiceModelProgress(
            phase: VoiceModelPhase.downloading, total: total),
        onProgress,
      );

      await for (final chunk in response.stream.timeout(_chunkTimeout)) {
        bytes.add(chunk);
        final elapsed = sw.elapsedMilliseconds;
        _emit(
          VoiceModelProgress(
            phase: VoiceModelPhase.downloading,
            received: bytes.length,
            total: total,
            bytesPerSecond:
                elapsed > 0 ? bytes.length / (elapsed / 1000) : 0,
          ),
          onProgress,
        );
      }

      if (_cancelled) return null;

      final raw = bytes.takeBytes();
      if (raw.isEmpty) throw 'Downloaded 0 bytes';

      // ── Extract ─────────────────────────────────────────────────────────
      _emit(
        VoiceModelProgress(
          phase: VoiceModelPhase.extracting,
          received: raw.length,
          total: total,
          message: 'Extracting…',
        ),
        onProgress,
      );

      // Let one frame render the "Extracting…" state before the synchronous
      // unzip blocks the UI isolate.
      await Future<void>.delayed(Duration.zero);
      if (_cancelled) return null;

      final docs = await getApplicationDocumentsDirectory();
      final modelsRoot = Directory(p.join(docs.path, 'models'));
      await modelsRoot.create(recursive: true);

      final archive = ZipDecoder().decodeBytes(raw, verify: false);

      // Remove a partial folder from a previous interrupted attempt, so the
      // extractor writes into a clean tree.
      final target = Directory(existing);
      if (target.existsSync()) {
        try {
          await target.delete(recursive: true);
        } catch (_) {}
      }

      await extractArchiveToDisk(archive, modelsRoot.path);

      if (!await isReady()) {
        throw 'Extraction finished but the model folder is incomplete';
      }

      _emit(const VoiceModelProgress(phase: VoiceModelPhase.done), onProgress);
      return existing;
    } catch (e) {
      // A cancelled download throws too (client closed mid-stream) — that is
      // not a failure and must not be shown as one.
      if (!_cancelled) {
        _emit(
          VoiceModelProgress(
            phase: VoiceModelPhase.failed,
            message: _friendlyError(e),
          ),
          onProgress,
        );
      }
      return null;
    } finally {
      client.close();
      _client = null;
      isDownloading.value = false;
      sw.stop();
    }
  }

  void _emit(VoiceModelProgress value, void Function(VoiceModelProgress)? cb) {
    progress.value = value;
    try {
      cb?.call(value);
    } catch (_) {}
  }

  String _friendlyError(Object e) {
    final s = e.toString();
    if (s.contains('SocketException') || s.contains('Failed host lookup')) {
      return 'No internet connection.';
    }
    if (s.contains('TimeoutException')) {
      return 'Connection timed out. Check your internet and try again.';
    }
    if (s.contains('HandshakeException')) {
      return 'Secure connection failed.';
    }
    if (s.contains('ClientException')) return 'Connection closed.';
    if (s.contains('HTTP 4')) {
      return 'Server refused the request (${s.split('HTTP ').last}).';
    }
    if (s.contains('HTTP 5')) {
      return 'Server error (${s.split('HTTP ').last}). Try again later.';
    }
    if (s.contains('No space left')) {
      return 'Not enough storage. Free up some space and retry.';
    }
    return s.replaceFirst('Exception: ', '');
  }
}
