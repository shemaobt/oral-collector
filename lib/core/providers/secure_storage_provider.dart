import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>(
  // iOS first_unlock_this_device: token device-bound, legível em background após o 1º unlock (ENG-128, ADR-0005).
  // Android (v10): cifra em repouso por default; resetOnError limpa o store v9 ilegível (re-login único) e
  // migrateOnAlgorithmChange:false evita o migrador v10 instável (ENG-170, ADR-0005).
  (_) => const FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    aOptions: AndroidOptions(
      resetOnError: true,
      migrateOnAlgorithmChange: false,
    ),
  ),
);
