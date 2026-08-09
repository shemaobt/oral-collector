import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/network/authenticated_client.dart';
import '../../../core/observability/error_reporter.dart';
import '../../../core/platform/file_ops.dart' as file_ops;
import '../../sync/data/services/resumable_upload_service.dart';
import '../domain/entities/local_recording_entity.dart';
import '../domain/entities/pending_metadata_field.dart';
import '../domain/repositories/recording_api_repository.dart';
import 'repositories/local_recording_repository.dart';
import 'repositories/recording_api_repository_impl.dart';
import 'repositories/recording_session_repository.dart';
import 'services/direct_recording_uploader.dart';

final recordingApiRepositoryProvider = Provider<RecordingApiRepository>((ref) {
  return RecordingApiRepositoryImpl(
    client: ref.watch(authenticatedClientProvider),
    reporter: ref.watch(errorReporterProvider),
  );
});

final localRecordingRepositoryProvider = Provider<LocalRecordingRepository>((
  ref,
) {
  final db = ref.watch(appDatabaseProvider);
  return LocalRecordingRepository(db);
});

final recordingSessionRepositoryProvider = Provider<RecordingSessionRepository>(
  (ref) {
    final db = ref.watch(appDatabaseProvider);
    return RecordingSessionRepository(db);
  },
);

final resumableUploadServiceProvider = Provider<ResumableUploadService>((ref) {
  return ResumableUploadService(
    client: ref.watch(authenticatedClientProvider),
    recordingRepo: ref.watch(localRecordingRepositoryProvider),
  );
});

final directRecordingUploaderProvider = Provider<DirectRecordingUploader>((
  ref,
) {
  return DirectRecordingUploader(
    client: ref.watch(authenticatedClientProvider),
    resumableUploadService: ref.watch(resumableUploadServiceProvider),
    recordingRepo: ref.watch(localRecordingRepositoryProvider),
  );
});

/// Every recording that still owes the server a metadata write, keyed by local
/// id and by server id (ENG-405).
///
/// One stream for the whole list rather than one per card: the answer is
/// almost always an empty map, and a subscription per row would pay a Drift
/// query each for it.
final metadataOutboxProvider = StreamProvider<Map<String, MetadataOutboxEntry>>(
  (ref) => ref.watch(localRecordingRepositoryProvider).watchMetadataOutbox(),
);

final localRecordingStreamProvider =
    StreamProvider.family<LocalRecordingEntity?, String>((ref, id) {
      final repo = ref.watch(localRecordingRepositoryProvider);
      return repo.watchRecordingEntityById(id);
    });

/// Injectable file-existence probe so the trim editor's load path can be driven
/// in widget tests without touching the real filesystem (real dart:io futures
/// never resolve under the fake-async test zone).
final fileExistsProvider = Provider<Future<bool> Function(String path)>(
  (_) => file_ops.fileExists,
);
