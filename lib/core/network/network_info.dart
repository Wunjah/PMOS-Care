import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NetworkStatus { online, offline }

final networkStatusProvider = StreamProvider<NetworkStatus>((ref) {
  final connectivity = Connectivity();

  return connectivity.onConnectivityChanged.map((dynamic results) {
    ConnectivityResult result;
    if (results is List) {
      result = results.isNotEmpty ? (results.first as ConnectivityResult) : ConnectivityResult.none;
    } else if (results is ConnectivityResult) {
      result = results;
    } else {
      result = ConnectivityResult.none;
    }
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
    final dynamic result = await _connectivity.checkConnectivity();
    if (result is List) {
      return result.isNotEmpty && result.first != ConnectivityResult.none;
    } else if (result is ConnectivityResult) {
      return result != ConnectivityResult.none;
    }
    return false;
  }

  @override
  Stream<NetworkStatus> get networkStatusStream {
    return _connectivity.onConnectivityChanged.map((dynamic results) {
      ConnectivityResult result;
      if (results is List) {
        result = results.isNotEmpty ? (results.first as ConnectivityResult) : ConnectivityResult.none;
      } else if (results is ConnectivityResult) {
        result = results;
      } else {
        result = ConnectivityResult.none;
      }
      return result == ConnectivityResult.none ? NetworkStatus.offline : NetworkStatus.online;
    });
  }
}

final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return NetworkInfoImpl(Connectivity());
});
