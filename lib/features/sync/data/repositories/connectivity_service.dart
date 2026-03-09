import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Service that monitors network connectivity status using connectivity_plus.
class ConnectivityService {
  final Connectivity _connectivity;

  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  /// Stream of connectivity status changes (true = online, false = offline).
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map(_isOnline);
  }

  /// Check current connectivity status.
  Future<bool> get isOnline async {
    final result = await _connectivity.checkConnectivity();
    return _isOnline(result);
  }

  /// Returns true if any of the connectivity results indicate an active
  /// network connection (not none).
  bool _isOnline(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }
}
