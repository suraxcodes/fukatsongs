import 'dart:async';
import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

/// Answers one question, reliably: **can this device actually reach the
/// internet right now?**
///
/// Why not just use `connectivity_plus`?
/// `Connectivity().onConnectivityChanged` reports the *link* state
/// (wifi / mobile / ethernet), not reachability, and it only emits when the
/// link **changes**. Consequences:
///   * Cold start while already online → no event ever fires.
///   * Wi-Fi joined to a dead router / captive portal / no data balance →
///     reports `wifi` while nothing loads.
///
/// So this service combines two things:
///   1. An HTTP reachability probe (204 No Content endpoint) — the
///      authoritative answer to "is there internet?".
///   2. The `connectivity_plus` change stream — the *trigger* to re-probe
///      when the link changes (wifi -> mobile, airplane mode off, etc).
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  /// Both return `204 No Content` with an empty body (~1 KB round trip).
  /// Two hosts so a single DNS/ISP hiccup does not report "offline".
  static const List<String> _probeUrls = [
    'https://clients3.google.com/generate_204',
    'https://connectivitycheck.gstatic.com/generate_204',
  ];

  static const Duration _probeTimeout = Duration(seconds: 2);

  StreamSubscription<List<ConnectivityResult>>? _linkSub;
  Timer? _debounce;

  final StreamController<bool> _statusController =
      StreamController<bool>.broadcast();

  /// Emits **only when the result changes**. Used by the router to re-run
  /// `redirect` and by [ConnectivityCubit] to update its state.
  Stream<bool> get onStatusChanged => _statusController.stream;

  bool _online = false;
  bool _hasResult = false;
  Future<bool>? _inFlight;

  bool get isOnline => _online;

  /// Starts watching link changes. Safe to call more than once.
  void start() {
    if (_linkSub != null) return;
    _linkSub = Connectivity().onConnectivityChanged.listen(
      (_) {
        // The link flapped. Give DHCP/radio a beat to become usable before
        // probing, otherwise we would report "offline" a moment too early.
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 600), () {
          unawaited(refresh());
        });
      },
      onError: (Object e) {
        log('Connectivity link stream error: $e', name: 'ConnectivityService');
      },
    );
  }

  /// Returns the current answer. Probes only if no probe has ever completed.
  ///
  /// Used by the router on cold start so the very first route decision is
  /// based on the real network, not on the `disconnected` seed value.
  Future<bool> ensureChecked() {
    if (_hasResult) return Future<bool>.value(_online);
    return _inFlight ??=
        refresh().whenComplete(() => _inFlight = null);
  }

  /// Probes reachability once and publishes the result.
  Future<bool> refresh() {
    final running = _inFlight;
    if (running != null) return running;

    final future = _probe();
    _inFlight = future.whenComplete(() => _inFlight = null);
    return _inFlight!;
  }

  Future<bool> _probe() async {
    var online = false;

    for (final url in _probeUrls) {
      try {
        final res = await http.get(Uri.parse(url)).timeout(_probeTimeout);
        // 204 is the expected answer. Some proxies rewrite the code, so
        // accept any 2xx/3xx as "a working path to the internet exists".
        if (res.statusCode >= 200 && res.statusCode < 400) {
          online = true;
          break;
        }
      } catch (_) {
        // Timeout / DNS failure / no route — try the next host.
      }
    }

    final changed = !_hasResult || online != _online;
    _hasResult = true;
    _online = online;

    if (changed) {
      log('Internet reachability: ${online ? 'ONLINE' : 'OFFLINE'}',
          name: 'ConnectivityService');
      if (!_statusController.isClosed) _statusController.add(online);
    }
    return online;
  }

  void dispose() {
    _debounce?.cancel();
    _linkSub?.cancel();
    _statusController.close();
  }
}
