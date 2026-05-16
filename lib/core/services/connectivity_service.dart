import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_service.g.dart';

@riverpod
class ConnectivityService extends _$ConnectivityService {
  @override
  Stream<ConnectivityResult> build() {
    return Connectivity().onConnectivityChanged;
  }

  Future<bool> isConnected() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }
}
