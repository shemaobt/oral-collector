import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/authenticated_client.dart';
import '../../../core/observability/error_reporter.dart';
import '../domain/repositories/invite_repository.dart';
import 'repositories/invite_repository.dart';

final inviteRepositoryProvider = Provider<InviteRepository>((ref) {
  return InviteRepositoryImpl(
    client: ref.watch(authenticatedClientProvider),
    reporter: ref.watch(errorReporterProvider),
  );
});
