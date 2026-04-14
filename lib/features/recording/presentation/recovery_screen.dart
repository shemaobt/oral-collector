import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/auth/auth_notifier.dart';
import '../../../core/database/app_database.dart';
import '../../../core/platform/file_ops.dart' as file_ops;
import '../../../shared/utils/recording_title.dart';
import '../data/providers.dart';
import '../data/services/recording_concat_service.dart';

class RecoveryScreen extends ConsumerStatefulWidget {
  const RecoveryScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends ConsumerState<RecoveryScreen> {
  _Status _status = _Status.working;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_run);
  }

  Future<void> _run() async {
    final sessionRepo = ref.read(recordingSessionRepositoryProvider);
    final session = await sessionRepo.getById(widget.sessionId);
    if (!mounted) return;

    if (session == null) {
      setState(() {
        _status = _Status.failed;
        _error = 'Session not found';
      });
      return;
    }

    final paths = sessionRepo.decodeSegmentPaths(session);
    final validPaths = <String>[];
    for (final p in paths) {
      if (await file_ops.fileExists(p)) {
        validPaths.add(p);
      }
    }

    if (validPaths.isEmpty) {
      await sessionRepo.markDiscarded(session.id);
      if (!mounted) return;
      setState(() {
        _status = _Status.failed;
        _error = 'No audio to recover';
      });
      return;
    }

    final concat = RecordingConcatService();
    final dir = await getApplicationDocumentsDirectory();
    final output = '${dir.path}/recording_${session.id}.m4a';
    final result = await concat.concatSegments(
      segmentPaths: validPaths,
      outputPath: output,
    );

    String? finalPath = result;
    if (finalPath == null && validPaths.isNotEmpty) {
      finalPath = validPaths.first;
    }

    if (finalPath == null) {
      if (!mounted) return;
      setState(() {
        _status = _Status.failed;
        _error = 'Concatenation failed';
      });
      return;
    }

    double duration = session.totalDurationSeconds;
    int fileSize = 0;
    try {
      fileSize = await file_ops.fileLength(finalPath);
    } catch (_) {}

    final userId = ref.read(authNotifierProvider).currentUser?.id;
    final repo = ref.read(localRecordingRepositoryProvider);
    final id =
        '${DateTime.now().millisecondsSinceEpoch}_${session.id.hashCode}';

    await repo.insertRecording(
      LocalRecordingsCompanion(
        id: Value(id),
        projectId: Value(session.projectId),
        genreId: Value(session.genreId),
        subcategoryId: session.subcategoryId != null
            ? Value(session.subcategoryId!)
            : const Value.absent(),
        registerId: session.registerId != null
            ? Value(session.registerId!)
            : const Value.absent(),
        storytellerId: session.storytellerId != null
            ? Value(session.storytellerId!)
            : const Value.absent(),
        userId: userId != null ? Value(userId) : const Value.absent(),
        title: Value(defaultRecordingTitle()),
        durationSeconds: Value(duration),
        fileSizeBytes: Value(fileSize),
        localFilePath: Value(finalPath),
        recordedAt: Value(session.startedAt),
      ),
    );

    await sessionRepo.markRecovered(session.id);

    if (finalPath == output) {
      for (final p in validPaths) {
        try {
          await file_ops.deleteFile(p);
        } catch (_) {}
      }
    }

    if (!mounted) return;
    setState(() => _status = _Status.done);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    context.go('/recordings');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.recording_recoverTitle)),
      body: Center(
        child: switch (_status) {
          _Status.working => const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Recovering…'),
            ],
          ),
          _Status.done => const Icon(Icons.check_circle, size: 64),
          _Status.failed => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                Text(_error ?? 'Recovery failed'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.go('/recordings'),
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
        },
      ),
    );
  }
}

enum _Status { working, done, failed }
