import 'dart:async';
import 'dart:developer';
import 'package:bloc/bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fukatsongs/services/connectivity_service.dart';
part 'connectivity_state.dart';

class ConnectivityCubit extends Cubit<ConnectivityState> {
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  StreamSubscription<bool>? _statusSub;

  ConnectivityCubit() : super(ConnectivityState.disconnected) {
    final service = ConnectivityService.instance;

    // A real probe decides the state — the link state alone cannot tell us
    // whether the internet actually works (captive portals, no data balance).
    _statusSub = service.onStatusChanged.listen((online) {
      emit(online ? ConnectivityState.connected : ConnectivityState.disconnected);
    });

    // Emit as soon as the first probe finishes, and on every later flap.
    service.start();
    unawaited(service.refresh());

    // Fallback: keep the OS link state as a secondary trigger. If we have a
    // wifi/mobile link we re-probe; if all links are gone we know we are
    // offline immediately and skip the 2 s HTTP timeout.
    _subscription = Connectivity().onConnectivityChanged.listen((event) {
      final hasLink = event.contains(ConnectivityResult.wifi) ||
          event.contains(ConnectivityResult.mobile) ||
          event.contains(ConnectivityResult.ethernet) ||
          event.contains(ConnectivityResult.bluetooth) ||
          event.contains(ConnectivityResult.vpn);
      if (hasLink) {
        unawaited(ConnectivityService.instance.refresh());
      } else {
        emit(ConnectivityState.disconnected);
        log('Network link lost: $event', name: 'ConnectivityCubit');
      }
    });
  }
  @override
  Future<void> close() {
    _subscription?.cancel();
    _statusSub?.cancel();
    return super.close();
  }
}
