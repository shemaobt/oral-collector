import 'dart:async';

abstract class ConnectivityService {
  Future<bool> get isOnline;
  Future<bool> get isOnWifi;
  Stream<bool> get onConnectivityChanged;
}
