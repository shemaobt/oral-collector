/// The banner that offers to finish a browser upload that was cut short
/// (ENG-427).
///
/// What a person lives through is the only thing asserted here: they press
/// Resume, and either the app gets on with it or it asks them for the file.
/// Nothing below looks at how the banner decides, which localization key it
/// picked, or in what order it called things — another implementation with the
/// same behaviour keeps these green.
///
/// The storage is `idb_shim`'s in-memory factory behind the real
/// [WebFileStore], the same complete implementation of the IndexedDB API the
/// browser exposes, running on the plain Dart VM. The only stand-in is the file
/// chooser: it is a browser boundary that cannot exist on the VM, and even it
/// is observed by "was it opened", never by what it returned.
///
/// Two things about the harness are load-bearing:
///
/// * The binding is the **live** one. Under the default binding a widget test
///   runs on a fake clock, and IndexedDB — through `idb_shim`, through sembast
///   — never completes a single transaction there, no matter how many frames
///   are pumped. Swapping the store for a map would make the tests pass and
///   stop them from proving anything about the real one, so the clock moved
///   instead of the storage.
/// * Nothing waits with `pumpAndSettle`. The resume button holds a
///   `CircularProgressIndicator` while it works, and that animation never
///   settles; [pumpUntil] waits for the thing the test is actually about.
library;

import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:idb_shim/idb_client_memory.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/platform/file_source.dart';
import 'package:oral_collector/core/platform/web_file_store.dart';
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_notifier.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recordings_list_notifier.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recordings_list_state.dart';
import 'package:oral_collector/features/recording/presentation/widgets/pending_web_upload_card.dart';
import 'package:oral_collector/features/recording/presentation/widgets/pending_web_uploads_banner.dart';
import 'package:oral_collector/features/sync/data/services/resumable_upload_service.dart';
import 'package:oral_collector/l10n/app_localizations.dart';

/// Records what it was handed to upload and answers success or failure on
/// command. It never reads the source, so a test can tell "the upload happened"
/// apart from "the bytes were readable" only through what it kept.
class _SpyUploadService extends Fake implements ResumableUploadService {
  final uploaded = <FileSource>[];

  @override
  Future<ResumableUploadResult> uploadFromSource({
    required String recordingId,
    required String serverId,
    required FileSource source,
    required String format,
    void Function(int bytesSent, int totalBytes)? onProgress,
  }) async {
    uploaded.add(source);
    return const ResumableUploadResult(success: true);
  }
}

/// The list refetch the banner kicks off after a successful resume is not what
/// these tests are about; this keeps it from reaching the network.
class _StubRecordingsList extends RecordingsListNotifier {
  @override
  RecordingsListState build() => const RecordingsListState(isLoading: false);

  @override
  Future<void> fetchRecordings() async {}
}

/// Pumps frames until [done] answers true, or gives up. Waiting on a condition
/// rather than on quiescence is what lets a spinning button coexist with a test
/// that has something definite to wait for.
Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() done, {
  Duration limit = const Duration(seconds: 10),
}) async {
  final deadline = DateTime.now().add(limit);
  while (!done() && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 10));
  }
}

int cardCount(WidgetTester tester) =>
    find.byType(PendingWebUploadCard).evaluate().length;

void main() {
  LiveTestWidgetsFlutterBinding.ensureInitialized();

  late WebFileStore browserStorage;
  late AppDatabase db;
  late LocalRecordingRepository repo;
  late _SpyUploadService upload;

  /// How many times the file chooser was opened, and what it answers when it
  /// is. Null answers the way a person who cancels the dialog does.
  late int pickerOpened;
  late FileSource? pickedFile;

  setUp(() {
    browserStorage = WebFileStore(newIdbFactoryMemory());
    db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    repo = LocalRecordingRepository(db);
    upload = _SpyUploadService();
    pickerOpened = 0;
    pickedFile = null;
  });

  Uint8List recordedBytes(int length) =>
      Uint8List.fromList(List.generate(length, (i) => (i * 7) % 251));

  String recordingKey(int seed) =>
      'web_record_${DateTime.utc(2026, 8, 19).millisecondsSinceEpoch + seed}.webm';

  Future<void> pendingRow({
    required String id,
    required String localFilePath,
    required int fileSizeBytes,
    String? serverId = 'srv-1',
    String title = 'Uma gravação longa',
    DateTime? createdAt,
  }) => db
      .into(db.localRecordings)
      .insert(
        LocalRecordingsCompanion.insert(
          id: id,
          projectId: 'proj-1',
          genreId: 'genre-1',
          title: Value(title),
          fileSizeBytes: Value(fileSizeBytes),
          format: const Value('webm'),
          localFilePath: localFilePath,
          uploadStatus: const Value('web_uploading'),
          serverId: Value(serverId),
          recordedAt: DateTime.utc(2026, 8, 19, 10),
          createdAt: Value(createdAt ?? DateTime.utc(2026, 8, 19, 10)),
        ),
      );

  Future<void> pumpBanner(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isWebPlatformProvider.overrideWithValue(true),
          localRecordingRepositoryProvider.overrideWithValue(repo),
          resumableUploadServiceProvider.overrideWithValue(upload),
          fileExistsProvider.overrideWithValue(browserStorage.exists),
          readFileBytesProvider.overrideWithValue(browserStorage.read),
          deleteFileProvider.overrideWithValue(browserStorage.delete),
          audioFilePickerProvider.overrideWithValue(({
            required List<String> allowedExtensions,
          }) async {
            pickerOpened++;
            return pickedFile;
          }),
          recordingsListNotifierProvider.overrideWith(_StubRecordingsList.new),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: PendingWebUploadsBanner()),
        ),
      ),
    );
    await pumpUntil(tester, () => cardCount(tester) > 0);
  }

  Future<void> tapResume(WidgetTester tester, {int card = 0}) async {
    await tester.tap(
      find.descendant(
        of: find.byType(PendingWebUploadCard).at(card),
        matching: find.byType(FilledButton),
      ),
    );
    // The button takes its spinner in the frame right after the tap, and the
    // resume is over when it gives it back — whether the row survived or was
    // cleared away. Waiting for the spinner to appear first is what keeps the
    // wait from ending before the work has started.
    await tester.pump();
    await pumpUntil(
      tester,
      () => find.byType(CircularProgressIndicator).evaluate().isEmpty,
    );
  }

  testWidgets('resumes from the stored audio without asking for the file', (
    tester,
  ) async {
    final key = recordingKey(1);
    final bytes = recordedBytes(4096);
    await browserStorage.write(key, bytes);
    await pendingRow(id: 'rec-1', localFilePath: key, fileSizeBytes: 4096);

    await pumpBanner(tester);
    await tapResume(tester);

    expect(pickerOpened, 0);
    expect(upload.uploaded, hasLength(1));
  });

  testWidgets('asks for the file when the row carries no address', (
    tester,
  ) async {
    await pendingRow(id: 'rec-1', localFilePath: '', fileSizeBytes: 4096);
    pickedFile = FileSource.fromBytes(
      recordedBytes(4096),
      name: 'gravacao.webm',
      mimeType: 'audio/webm',
    );

    await pumpBanner(tester);
    await tapResume(tester);

    expect(pickerOpened, 1);
    expect(upload.uploaded, hasLength(1));
  });

  testWidgets('refuses a file of a different size and keeps the row', (
    tester,
  ) async {
    await pendingRow(id: 'rec-1', localFilePath: '', fileSizeBytes: 4096);
    pickedFile = FileSource.fromBytes(
      recordedBytes(2048),
      name: 'outra-gravacao.webm',
      mimeType: 'audio/webm',
    );

    await pumpBanner(tester);
    await tapResume(tester);

    expect(pickerOpened, 1);
    expect(upload.uploaded, isEmpty);
    expect(await repo.getPendingWebUploads(), hasLength(1));
  });

  testWidgets('asks for the file when the address finds no bytes', (
    tester,
  ) async {
    // A row written before the address was real carries an invented name, and a
    // recording the 24-hour sweep already collected leaves a real key with
    // nothing under it. Neither is an error: both are "ask for the file".
    await pendingRow(
      id: 'rec-1',
      localFilePath: 'web_import_1755600000000_srv-1',
      fileSizeBytes: 4096,
    );
    pickedFile = FileSource.fromBytes(
      recordedBytes(4096),
      name: 'gravacao.webm',
      mimeType: 'audio/webm',
    );

    await pumpBanner(tester);
    await tapResume(tester);

    expect(pickerOpened, 1);
    expect(upload.uploaded, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('says something different when the audio is still here', (
    tester,
  ) async {
    // Same title and same size on every row, so the only thing that can differ
    // between the bodies is the sentence itself.
    //
    // Three rows, because "the app does not have the audio" has two shapes and
    // only one of them is an empty address. The third row carries an address
    // that reads like a real key and has nothing under it — a row written
    // before ENG-427, or a recording the 24-hour sweep already collected. It
    // has to read as the same "hand me the file" as the empty one: telling
    // someone the upload will carry on from where it stopped when the bytes are
    // gone is the same lie as this issue's, pointed the other way.
    final key = recordingKey(2);
    await browserStorage.write(key, recordedBytes(4096));
    await pendingRow(
      id: 'rec-stored',
      localFilePath: key,
      fileSizeBytes: 4096,
      createdAt: DateTime.utc(2026, 8, 19, 10),
    );
    await pendingRow(
      id: 'rec-no-address',
      localFilePath: '',
      fileSizeBytes: 4096,
      createdAt: DateTime.utc(2026, 8, 19, 11),
    );
    await pendingRow(
      id: 'rec-dead-address',
      localFilePath: 'web_import_1755600000000_srv-1',
      fileSizeBytes: 4096,
      createdAt: DateTime.utc(2026, 8, 19, 12),
    );

    await pumpBanner(tester);
    await pumpUntil(tester, () => cardCount(tester) == 3);

    final cards = find.byType(PendingWebUploadCard);
    expect(cards, findsNWidgets(3));

    String bodyOf(int card) => tester
        .widgetList<Text>(
          find.descendant(
            of: cards.at(card),
            matching: find.textContaining('Uma gravação longa'),
          ),
        )
        .single
        .data!;

    final storedBody = bodyOf(0);
    final pickFileBody = bodyOf(1);
    final deadAddressBody = bodyOf(2);

    expect(storedBody, isNot(pickFileBody));
    expect(
      find.descendant(of: cards.at(0), matching: find.text(pickFileBody)),
      findsNothing,
    );
    expect(deadAddressBody, pickFileBody);
  });

  testWidgets('lets the stored audio go once the upload is through', (
    tester,
  ) async {
    final key = recordingKey(3);
    await browserStorage.write(key, recordedBytes(4096));
    await pendingRow(id: 'rec-1', localFilePath: key, fileSizeBytes: 4096);
    // An answer the chooser could give, so this fails on the bytes that were
    // left behind rather than on an upload that never happened.
    pickedFile = FileSource.fromBytes(
      recordedBytes(4096),
      name: 'gravacao.webm',
      mimeType: 'audio/webm',
    );

    await pumpBanner(tester);
    await tapResume(tester);

    expect(upload.uploaded, hasLength(1));
    expect(await browserStorage.exists(key), isFalse);
  });
}
