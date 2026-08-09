/// Builds the `RecordingApiRepository` the sync engine needs for its metadata
/// drain (ENG-403).
///
/// The upload-path engine tests do not exercise the drain, but the engine now
/// requires the dependency. Handing them the real implementation over the same
/// `MockClient` keeps them free of a stub whose behaviour could drift from the
/// endpoint's — a stray metadata call would show up on their MockClient as a
/// PATCH they never answered, rather than being silently absorbed.
library;

import 'package:oral_collector/core/network/authenticated_client.dart';
import 'package:oral_collector/core/observability/error_reporter.dart';
import 'package:oral_collector/features/recording/data/repositories/recording_api_repository_impl.dart';
import 'package:oral_collector/features/recording/domain/repositories/recording_api_repository.dart';

RecordingApiRepository apiRepoFor(AuthenticatedClient client) =>
    RecordingApiRepositoryImpl(
      client: client,
      reporter: const NoopErrorReporter(),
    );
