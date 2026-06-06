import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NetworkStatus { online, offline }

final networkStatusProvider = StreamProvider<NetworkStatus>((ref) {
  final connectivity = Connectivity();

  return connectivity.onConnectivityChanged.map((results) {
    final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
    if (result == ConnectivityResult.none) {
      return NetworkStatus.offline;
    } else {
      return NetworkStatus.online;
    }
  });
});

abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<NetworkStatus> get networkStatusStream;
}

class NetworkInfoImpl implements NetworkInfo {
  final Connectivity _connectivity;

  NetworkInfoImpl(this._connectivity);

  @override
  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return result.isNotEmpty && result.first != ConnectivityResult.none;
  }

  @override
  Stream<NetworkStatus> get networkStatusStream {
    return _connectivity.onConnectivityChanged.map((results) {
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      return result == ConnectivityResult.none ? NetworkStatus.offline : NetworkStatus.online;
    });
  }
}

final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return NetworkInfoImpl(Connectivity());
});
