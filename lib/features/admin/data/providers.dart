import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/authenticated_client.dart';
import '../domain/repositories/admin_repository.dart';
import 'repositories/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepositoryImpl(client: ref.watch(authenticatedClientProvider));
});
