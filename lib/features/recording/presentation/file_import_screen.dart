import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../../core/platform/file_ops.dart' as file_ops;
import '../../../core/platform/ffmpeg_ops.dart' as ffmpeg_ops;

import '../../../../l10n/app_localizations.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../genre/presentation/notifiers/genre_notifier.dart';
import '../../sync/presentation/notifiers/sync_notifier.dart';
import '../../project/presentation/notifiers/project_notifier.dart';
import '../../storyteller/domain/entities/storyteller.dart';
import '../data/providers.dart';
import '../data/supported_audio_formats.dart';
import 'file_import_entry.dart';
import 'notifiers/recordings_list_notifier.dart';
import 'widgets/file_metadata_editor.dart';
import 'widgets/supported_formats_banner.dart';

class FileImportScreen extends ConsumerStatefulWidget {
  const FileImportScreen({super.key});

  @override
  ConsumerState<FileImportScreen> createState() => _FileImportScreenState();
}

class _RejectedFile {
  const _RejectedFile(this.name, this.reason);
  final String name;
  final String reason;
}

class _FileImportScreenState extends ConsumerState<FileImportScreen> {
  final List<FileImportEntry> _entries = [];
  bool _isAnalyzing = false;
  bool _isSaving = false;
  int _saveProgress = 0;
  bool _compressWav = true;
  bool _formatsBannerDismissed = false;

  String? _bulkGenreId;
  String? _bulkSubcategoryId;
  String? _bulkRegisterId;
  Storyteller? _bulkStoryteller;

  final Set<String> _errorEntryIds = {};
  final Map<String, GlobalKey> _errorKeys = {};
  final ScrollController _scrollController = ScrollController();

  bool get _hasWavFiles => _entries.any((f) => f.format == 'wav');

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (ref.read(syncNotifierProvider).isOnline) {
        ref.read(genreNotifierProvider.notifier).fetchGenres();
      }
      _pickFile();
    });
  }

  @override
  void dispose() {
    for (final e in _entries) {
      e.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: kSupportedAudioExtensions.toList(),
        allowMultiple: true,
        withData: kIsWeb,
      );

      if (result == null || result.files.isEmpty) {
        if (mounted && _entries.isEmpty) {
          Navigator.of(context).maybePop();
        }
        return;
      }

      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(() => _isAnalyzing = true);

      final newEntries = <FileImportEntry>[];
      final rejected = <_RejectedFile>[];

      for (var i = 0; i < result.files.length; i++) {
        final file = result.files[i];
        final ext = p.extension(file.name).replaceFirst('.', '').toLowerCase();

        if (ext.isEmpty || !kSupportedAudioExtensions.contains(ext)) {
          rejected.add(_RejectedFile(file.name, 'unsupported'));
          continue;
        }
        if (file.size <= 0) {
          rejected.add(_RejectedFile(file.name, l10n.import_emptyFile));
          continue;
        }

        String filePath;
        Uint8List? webBytes;
        if (kIsWeb) {
          if (file.bytes == null) {
            rejected.add(_RejectedFile(file.name, 'unreadable'));
            continue;
          }
          webBytes = file.bytes;
          filePath =
              'web_import_${DateTime.now().microsecondsSinceEpoch}_$i'
              '_${file.name}';
        } else {
          final path = file.path;
          if (path == null) {
            rejected.add(_RejectedFile(file.name, 'unreadable'));
            continue;
          }
          filePath = path;
        }

        final duration = kIsWeb
            ? await _detectDurationFromBytes(webBytes!, ext)
            : await _detectDuration(filePath);

        if (duration <= 0) {
          rejected.add(_RejectedFile(file.name, 'unreadable'));
          continue;
        }

        newEntries.add(
          FileImportEntry(
            id: '${DateTime.now().microsecondsSinceEpoch}_$i',
            path: filePath,
            fileName: file.name,
            sizeBytes: file.size,
            format: ext,
            durationSeconds: duration,
            webBytes: webBytes,
          ),
        );
      }

      if (newEntries.isEmpty) {
        if (mounted) {
          _showRejectedSnack(rejected);
          if (_entries.isEmpty) {
            Navigator.of(context).maybePop();
          } else {
            setState(() => _isAnalyzing = false);
          }
        }
        return;
      }

      if (mounted) {
        setState(() {
          _entries.addAll(newEntries);
          _isAnalyzing = false;
        });
        if (rejected.isNotEmpty) _showRejectedSnack(rejected);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.import_pickError(e.toString()))),
        );
        if (_entries.isEmpty) {
          Navigator.of(context).maybePop();
        }
      }
    }
  }

  void _showRejectedSnack(List<_RejectedFile> rejected) {
    if (rejected.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    final names = rejected.take(5).map((r) => r.name).join(', ');
    final suffix = rejected.length > 5 ? '…' : '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.import_rejectedFiles(rejected.length, '$names$suffix'),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<double> _detectDuration(String filePath) async {
    final player = AudioPlayer();
    try {
      final duration = await player.setFilePath(filePath);
      if (duration != null) {
        return duration.inMilliseconds / 1000.0;
      }
    } catch (_) {
      return 0.0;
    } finally {
      await player.dispose();
    }
    return 0.0;
  }

  Future<double> _detectDurationFromBytes(Uint8List bytes, String ext) async {
    final player = AudioPlayer();
    try {
      final mime = kSupportedAudioMimeTypes[ext] ?? 'audio/mpeg';
      final dataUri = Uri.dataFromBytes(bytes, mimeType: mime).toString();
      final duration = await player.setUrl(dataUri);
      if (duration != null) {
        return duration.inMilliseconds / 1000.0;
      }
    } catch (_) {
      return 0.0;
    } finally {
      await player.dispose();
    }
    return 0.0;
  }

  bool _isEntryValid(FileImportEntry e) {
    if (e.genreId == null || e.genreId!.isEmpty) return false;
    if (e.registerId == null || e.registerId!.isEmpty) return false;
    final genres = ref.read(genreNotifierProvider).genres;
    final genre = genres.where((g) => g.id == e.genreId).firstOrNull;
    if (genre != null && genre.subcategories.isNotEmpty) {
      if (e.subcategoryId == null || e.subcategoryId!.isEmpty) return false;
    }
    return true;
  }

  void _clearErrorIfResolved(FileImportEntry e) {
    if (!_errorEntryIds.contains(e.id)) return;
    if (_isEntryValid(e)) {
      _errorEntryIds.remove(e.id);
    }
  }

  void _updateEntryGenre(String id, String? value) {
    setState(() {
      final e = _entries.firstWhere((x) => x.id == id);
      e.genreId = value;
      e.subcategoryId = null;
      _clearErrorIfResolved(e);
    });
  }

  void _updateEntrySubcategory(String id, String? value) {
    setState(() {
      final e = _entries.firstWhere((x) => x.id == id);
      e.subcategoryId = value;
      _clearErrorIfResolved(e);
    });
  }

  void _updateEntryRegister(String id, String? value) {
    setState(() {
      final e = _entries.firstWhere((x) => x.id == id);
      e.registerId = value;
      _clearErrorIfResolved(e);
    });
  }

  void _updateEntryStoryteller(String id, Storyteller? value) {
    setState(() {
      final e = _entries.firstWhere((x) => x.id == id);
      e.storyteller = value;
    });
  }

  void _removeEntry(String id) {
    setState(() {
      final idx = _entries.indexWhere((x) => x.id == id);
      if (idx == -1) return;
      _entries[idx].dispose();
      _entries.removeAt(idx);
      _errorEntryIds.remove(id);
      _errorKeys.remove(id);
    });
    if (_entries.isEmpty && mounted) {
      Navigator.of(context).maybePop();
    }
  }

  void _applyBulkToAll() {
    if (_bulkGenreId == null &&
        _bulkSubcategoryId == null &&
        _bulkRegisterId == null &&
        _bulkStoryteller == null) {
      return;
    }
    setState(() {
      final genres = ref.read(genreNotifierProvider).genres;
      for (final e in _entries) {
        if (_bulkGenreId != null) {
          e.genreId = _bulkGenreId;
          if (_bulkSubcategoryId != null) {
            final g = genres.where((g) => g.id == _bulkGenreId).firstOrNull;
            final valid =
                g?.subcategories.any((s) => s.id == _bulkSubcategoryId) ??
                false;
            e.subcategoryId = valid ? _bulkSubcategoryId : null;
          } else {
            e.subcategoryId = null;
          }
        } else if (_bulkSubcategoryId != null) {
          final g = genres.where((g) => g.id == e.genreId).firstOrNull;
          final valid =
              g?.subcategories.any((s) => s.id == _bulkSubcategoryId) ?? false;
          if (valid) e.subcategoryId = _bulkSubcategoryId;
        }
        if (_bulkRegisterId != null) {
          e.registerId = _bulkRegisterId;
        }
        if (_bulkStoryteller != null) {
          e.storyteller = _bulkStoryteller;
        }
        _clearErrorIfResolved(e);
      }
      _bulkGenreId = null;
      _bulkSubcategoryId = null;
      _bulkRegisterId = null;
      _bulkStoryteller = null;
    });
  }

  Future<void> _onSavePressed() async {
    final invalid = _entries.where((e) => !_isEntryValid(e)).toList();
    if (invalid.isNotEmpty) {
      setState(() {
        _errorEntryIds
          ..clear()
          ..addAll(invalid.map((e) => e.id));
        for (final e in invalid) {
          _errorKeys.putIfAbsent(e.id, () => GlobalKey());
        }
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final firstKey = _errorKeys[invalid.first.id];
        final ctx = firstKey?.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 300),
            alignment: 0.1,
            alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
          );
        }
      });

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.import_validationBanner(invalid.length)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    await _save();
  }

  Future<void> _save() async {
    if (_entries.isEmpty) return;

    setState(() {
      _isSaving = true;
      _saveProgress = 0;
    });

    final projectState = ref.read(projectNotifierProvider);
    final projectId = projectState.activeProject?.id ?? '';
    final repo = ref.read(localRecordingRepositoryProvider);

    try {
      for (var i = 0; i < _entries.length; i++) {
        final entry = _entries[i];

        String savedFilePath = entry.path;
        int fileSizeBytes = entry.sizeBytes;
        String format = entry.format;

        if (kIsWeb) {
          if (entry.webBytes != null) {
            await file_ops.writeFileBytes(savedFilePath, entry.webBytes!);
            fileSizeBytes = entry.webBytes!.length;
          }
        } else {
          final appDir = await getApplicationDocumentsDirectory();
          final recordingsPath = '${appDir.path}/recordings';
          if (!await file_ops.dirExists(recordingsPath)) {
            await file_ops.createDir(recordingsPath);
          }
          final destFileName =
              '${DateTime.now().millisecondsSinceEpoch}_${entry.fileName}';
          final destPath = '$recordingsPath/$destFileName';
          await file_ops.copyFile(entry.path, destPath);
          savedFilePath = destPath;

          if (_compressWav && format == 'wav') {
            final m4aPath = destPath.replaceAll(
              RegExp(r'\.wav$', caseSensitive: false),
              '.m4a',
            );
            final success = await ffmpeg_ops.compressToM4a(destPath, m4aPath);
            if (success) {
              await file_ops.deleteFile(destPath);
              savedFilePath = m4aPath;
              format = 'm4a';
            }
          }

          fileSizeBytes = await file_ops.fileLength(savedFilePath);
        }

        final id = '${DateTime.now().microsecondsSinceEpoch}_$i';
        final title = entry.fileName.replaceAll(RegExp(r'\.[^.]+$'), '');
        final description = entry.descriptionController.text.trim();

        await repo.insertRecording(
          LocalRecordingsCompanion(
            id: Value(id),
            projectId: Value(projectId),
            genreId: Value(entry.genreId!),
            subcategoryId:
                entry.subcategoryId != null && entry.subcategoryId!.isNotEmpty
                ? Value(entry.subcategoryId!)
                : const Value.absent(),
            registerId: entry.registerId != null && entry.registerId!.isNotEmpty
                ? Value(entry.registerId!)
                : const Value.absent(),
            storytellerId: entry.storytellerId != null
                ? Value(entry.storytellerId!)
                : const Value.absent(),
            title: Value(title),
            description: description.isNotEmpty
                ? Value(description)
                : const Value.absent(),
            durationSeconds: Value(entry.durationSeconds),
            fileSizeBytes: Value(fileSizeBytes),
            format: Value(format),
            localFilePath: Value(savedFilePath),
            recordedAt: Value(DateTime.now()),
          ),
        );

        if (mounted) {
          setState(() => _saveProgress = i + 1);
        }
      }

      ref.read(syncNotifierProvider.notifier).processQueue();
      ref.read(recordingsListNotifierProvider.notifier).fetchRecordings();

      if (mounted) {
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.import_saveError(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final genreState = ref.watch(genreNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).maybePop()),
        title: Text(l10n.import_title),
      ),
      body: _entries.isEmpty || _isAnalyzing
          ? _buildPickingState()
          : FileMetadataEditor(
              entries: _entries,
              projectId:
                  ref.read(projectNotifierProvider).activeProject?.id ?? '',
              genres: genreState.genres,
              genresLoading: genreState.isLoading,
              errorEntryIds: _errorEntryIds,
              errorKeys: _errorKeys,
              bulkGenreId: _bulkGenreId,
              bulkSubcategoryId: _bulkSubcategoryId,
              bulkRegisterId: _bulkRegisterId,
              bulkStoryteller: _bulkStoryteller,
              onBulkGenreChanged: (v) => setState(() {
                _bulkGenreId = v;
                _bulkSubcategoryId = null;
              }),
              onBulkSubcategoryChanged: (v) =>
                  setState(() => _bulkSubcategoryId = v),
              onBulkRegisterChanged: (v) => setState(() => _bulkRegisterId = v),
              onBulkStorytellerChanged: (v) =>
                  setState(() => _bulkStoryteller = v),
              onApplyBulk: _applyBulkToAll,
              onEntryGenreChanged: _updateEntryGenre,
              onEntrySubcategoryChanged: _updateEntrySubcategory,
              onEntryRegisterChanged: _updateEntryRegister,
              onEntryStorytellerChanged: _updateEntryStoryteller,
              onRemoveEntry: _removeEntry,
              isSaving: _isSaving,
              saveProgress: _saveProgress,
              hasWavFiles: _hasWavFiles,
              compressWav: _compressWav,
              onCompressWavChanged: (v) => setState(() => _compressWav = v),
              onCancel: () => Navigator.of(context).maybePop(),
              onSave: _onSavePressed,
              showFormatsBanner: !_formatsBannerDismissed,
              onDismissFormatsBanner: () =>
                  setState(() => _formatsBannerDismissed = true),
            ),
    );
  }

  Widget _buildPickingState() {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isAnalyzing) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                l10n.import_analyzing,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colors.foreground.withValues(alpha: 0.6),
                ),
              ),
            ] else ...[
              Icon(LucideIcons.fileAudio, size: 64, color: colors.border),
              const SizedBox(height: 16),
              Text(
                l10n.import_selectFile,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colors.foreground.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 20),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: const SupportedFormatsBanner(),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(LucideIcons.folderOpen),
                label: Text(l10n.import_chooseFile),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(160, 48),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
