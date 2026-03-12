import 'dart:async';

abstract class ConnectivityService {
  Future<bool> get isOnline;
  Stream<bool> get onConnectivityChanged;
}
