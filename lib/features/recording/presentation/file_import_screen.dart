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

import '../../../../core/l10n/content_l10n.dart';

import '../../../core/platform/file_ops.dart' as file_ops;
import '../../../core/platform/ffmpeg_ops.dart' as ffmpeg_ops;

import '../../../../l10n/app_localizations.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/utils/recording_title.dart';
import '../../../core/theme/app_colors.dart';
import '../../genre/presentation/notifiers/genre_notifier.dart';
import '../../sync/presentation/notifiers/sync_notifier.dart';
import '../../genre/presentation/notifiers/genre_state.dart';
import '../../genre/domain/entities/genre.dart';
import '../../project/presentation/notifiers/project_notifier.dart';
import '../data/providers.dart';
import '../domain/entities/register.dart';
import 'notifiers/recordings_list_notifier.dart';
import 'widgets/file_info_banner.dart';
import 'widgets/import_confirmation.dart';
import 'widgets/import_genre_selection.dart';
import 'widgets/import_subcategory_selection.dart';
import 'widgets/register_selection_step.dart';

class _PickedFile {
  final String path;
  final String name;
  final int sizeBytes;
  final String format;
  final double durationSeconds;
  final Uint8List? webBytes;

  _PickedFile({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.format,
    this.durationSeconds = 0.0,
    this.webBytes,
  });
}

enum _ImportStep {
  pickFile,
  selectGenre,
  selectSubcategory,
  selectRegister,
  confirm,
}

class FileImportScreen extends ConsumerStatefulWidget {
  const FileImportScreen({super.key});

  @override
  ConsumerState<FileImportScreen> createState() => _FileImportScreenState();
}

class _FileImportScreenState extends ConsumerState<FileImportScreen> {
  _ImportStep _currentStep = _ImportStep.pickFile;

  List<_PickedFile> _pickedFiles = [];
  bool _isAnalyzing = false;

  String? _selectedGenreId;
  String? _selectedSubcategoryId;
  String? _selectedRegisterId;

  final _titleController = TextEditingController();
  bool _isSaving = false;
  int _saveProgress = 0;
  bool _compressWav = true;

  bool get _isBatch => _pickedFiles.length > 1;

  bool get _hasWavFiles => _pickedFiles.any((f) => f.format == 'wav');

  int get _totalSizeBytes =>
      _pickedFiles.fold(0, (sum, f) => sum + f.sizeBytes);

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
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'ogg'],
        allowMultiple: true,
        withData: kIsWeb,
      );

      if (result == null || result.files.isEmpty) {
        if (mounted && _pickedFiles.isEmpty) {
          Navigator.of(context).maybePop();
        }
        return;
      }

      setState(() => _isAnalyzing = true);

      final files = <_PickedFile>[];

      for (final file in result.files) {
        String? filePath;
        Uint8List? webBytes;

        if (kIsWeb) {
          if (file.bytes == null) continue;
          webBytes = file.bytes;
          filePath =
              'web_import_${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        } else {
          filePath = file.path;
          if (filePath == null) continue;
        }

        final ext = p.extension(file.name).replaceFirst('.', '').toLowerCase();
        var duration = 0.0;

        if (kIsWeb && webBytes != null) {
          duration = await _detectDurationFromBytes(webBytes, ext);
        } else if (!kIsWeb) {
          duration = await _detectDuration(filePath);
        }

        files.add(
          _PickedFile(
            path: filePath,
            name: file.name,
            sizeBytes: file.size,
            format: ext.isNotEmpty ? ext : 'm4a',
            durationSeconds: duration,
            webBytes: webBytes,
          ),
        );
      }

      if (files.isEmpty) {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.import_accessFailed)));
          Navigator.of(context).maybePop();
        }
        return;
      }

      if (mounted) {
        setState(() {
          _pickedFiles = files;
          _isAnalyzing = false;
          _currentStep = _ImportStep.selectGenre;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.import_pickError(e.toString()))),
        );
        Navigator.of(context).maybePop();
      }
    }
  }

  Future<double> _detectDuration(String filePath) async {
    final player = AudioPlayer();
    try {
      final duration = await player.setFilePath(filePath);
      if (duration != null) {
        return duration.inMilliseconds / 1000.0;
      }
    } catch (_) {
    } finally {
      await player.dispose();
    }
    return 0.0;
  }

  Future<double> _detectDurationFromBytes(Uint8List bytes, String ext) async {
    final player = AudioPlayer();
    try {
      const mimeTypes = {
        'm4a': 'audio/mp4',
        'mp3': 'audio/mpeg',
        'wav': 'audio/wav',
        'ogg': 'audio/ogg',
      };
      final mime = mimeTypes[ext] ?? 'audio/mpeg';
      final dataUri = Uri.dataFromBytes(bytes, mimeType: mime).toString();
      final duration = await player.setUrl(dataUri);
      if (duration != null) {
        return duration.inMilliseconds / 1000.0;
      }
    } catch (_) {
    } finally {
      await player.dispose();
    }
    return 0.0;
  }

  void _selectGenre(Genre genre) {
    setState(() {
      _selectedGenreId = genre.id;
      _selectedSubcategoryId = null;
      _selectedRegisterId = null;
      if (genre.subcategories.isNotEmpty) {
        _currentStep = _ImportStep.selectSubcategory;
      } else {
        _currentStep = _ImportStep.selectRegister;
      }
    });
  }

  void _selectSubcategory(Subcategory subcategory) {
    setState(() {
      _selectedSubcategoryId = subcategory.id;
    });
  }

  void _advanceToRegister() {
    setState(() {
      _currentStep = _ImportStep.selectRegister;
    });
  }

  void _selectRegister(Register register) {
    setState(() {
      _selectedRegisterId = register.id;
    });
  }

  void _advanceToConfirm() {
    setState(() {
      _currentStep = _ImportStep.confirm;
    });
  }

  void _goBack() {
    switch (_currentStep) {
      case _ImportStep.pickFile:
        if (context.mounted) Navigator.of(context).maybePop();
      case _ImportStep.selectGenre:
        _pickFile();
      case _ImportStep.selectSubcategory:
        setState(() {
          _selectedGenreId = null;
          _selectedSubcategoryId = null;
          _selectedRegisterId = null;
          _currentStep = _ImportStep.selectGenre;
        });
      case _ImportStep.selectRegister:
        final genreState = ref.read(genreNotifierProvider);
        final genre = genreState.genres
            .where((g) => g.id == _selectedGenreId)
            .firstOrNull;
        if (genre != null && genre.subcategories.isNotEmpty) {
          setState(() {
            _selectedSubcategoryId = null;
            _selectedRegisterId = null;
            _currentStep = _ImportStep.selectSubcategory;
          });
        } else {
          setState(() {
            _selectedGenreId = null;
            _selectedRegisterId = null;
            _currentStep = _ImportStep.selectGenre;
          });
        }
      case _ImportStep.confirm:
        setState(() {
          _selectedRegisterId = null;
          _currentStep = _ImportStep.selectRegister;
        });
    }
  }

  Future<void> _save() async {
    if (_pickedFiles.isEmpty) return;

    setState(() {
      _isSaving = true;
      _saveProgress = 0;
    });

    final projectState = ref.read(projectNotifierProvider);
    final projectId = projectState.activeProject?.id ?? '';
    final repo = ref.read(localRecordingRepositoryProvider);

    try {
      for (var i = 0; i < _pickedFiles.length; i++) {
        final file = _pickedFiles[i];

        String savedFilePath = file.path;
        int fileSizeBytes = file.sizeBytes;
        String format = file.format;

        if (kIsWeb) {
          if (file.webBytes != null) {
            await file_ops.writeFileBytes(savedFilePath, file.webBytes!);
            fileSizeBytes = file.webBytes!.length;
          }
        } else {
          final appDir = await getApplicationDocumentsDirectory();
          final recordingsPath = '${appDir.path}/recordings';
          if (!await file_ops.dirExists(recordingsPath)) {
            await file_ops.createDir(recordingsPath);
          }
          final destFileName =
              '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
          final destPath = '$recordingsPath/$destFileName';
          await file_ops.copyFile(file.path, destPath);
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

        final id =
            '${DateTime.now().millisecondsSinceEpoch}_${_selectedGenreId.hashCode}_$i';

        final title = _isBatch
            ? file.name.replaceAll(RegExp(r'\.[^.]+$'), '')
            : (_titleController.text.trim().isNotEmpty
                  ? _titleController.text.trim()
                  : defaultRecordingTitle());

        await repo.insertRecording(
          LocalRecordingsCompanion(
            id: Value(id),
            projectId: Value(projectId),
            genreId: Value(_selectedGenreId!),
            subcategoryId:
                _selectedSubcategoryId != null &&
                    _selectedSubcategoryId!.isNotEmpty
                ? Value(_selectedSubcategoryId!)
                : const Value.absent(),
            registerId:
                _selectedRegisterId != null && _selectedRegisterId!.isNotEmpty
                ? Value(_selectedRegisterId!)
                : const Value.absent(),
            title: Value(title),
            durationSeconds: Value(file.durationSeconds),
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

  String _title(AppLocalizations l10n) {
    switch (_currentStep) {
      case _ImportStep.pickFile:
        return l10n.import_title;
      case _ImportStep.selectGenre:
        return l10n.import_selectGenre;
      case _ImportStep.selectSubcategory:
        return l10n.import_selectSubcategory;
      case _ImportStep.selectRegister:
        return l10n.import_selectRegister;
      case _ImportStep.confirm:
        return l10n.import_confirmImport;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final genreState = ref.watch(genreNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: _goBack),
        title: Text(_title(l10n)),
      ),
      body: _currentStep == _ImportStep.pickFile
          ? _buildPickingState()
          : genreState.isLoading && genreState.genres.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _buildStep(genreState),
    );
  }

  Widget _buildPickingState() {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    return Center(
      child: Column(
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
    );
  }

  Widget _fileInfoBanner() {
    if (_isBatch) {
      return FileInfoBanner(
        fileName: '${_pickedFiles.length} files',
        format: _pickedFiles.map((f) => f.format).toSet().join(', '),
        durationSeconds: _pickedFiles.fold(
          0.0,
          (sum, f) => sum + f.durationSeconds,
        ),
        fileSizeBytes: _totalSizeBytes,
      );
    }
    final f = _pickedFiles.first;
    return FileInfoBanner(
      fileName: f.name,
      format: f.format,
      durationSeconds: f.durationSeconds,
      fileSizeBytes: f.sizeBytes,
    );
  }

  Widget _buildStep(GenreState genreState) {
    final l10n = AppLocalizations.of(context);
    switch (_currentStep) {
      case _ImportStep.pickFile:
        return _buildPickingState();
      case _ImportStep.selectGenre:
        return ImportGenreSelection(
          genres: genreState.genres,
          onGenreSelected: _selectGenre,
          fileInfoBanner: _fileInfoBanner(),
        );
      case _ImportStep.selectSubcategory:
        final genre = genreState.genres
            .where((g) => g.id == _selectedGenreId)
            .firstOrNull;
        if (genre == null) {
          final l10n = AppLocalizations.of(context);
          return Center(child: Text(l10n.recording_genreNotFound));
        }
        return ImportSubcategorySelection(
          genre: genre,
          selectedSubcategoryId: _selectedSubcategoryId,
          onSubcategorySelected: _selectSubcategory,
          onNext: _advanceToRegister,
          fileInfoBanner: _fileInfoBanner(),
        );
      case _ImportStep.selectRegister:
        return RegisterSelectionStep(
          selectedRegisterId: _selectedRegisterId,
          onSelect: _selectRegister,
          onNext: _advanceToConfirm,
        );
      case _ImportStep.confirm:
        final rawG = genreState.genres
            .where((g) => g.id == _selectedGenreId)
            .firstOrNull
            ?.name;
        final rawS = genreState.genres
            .where((g) => g.id == _selectedGenreId)
            .firstOrNull
            ?.subcategories
            .where((s) => s.id == _selectedSubcategoryId)
            .firstOrNull
            ?.name;
        final rawR = getRegisterName(_selectedRegisterId);
        return ImportConfirmation(
          fileName: _isBatch
              ? '${_pickedFiles.length} files'
              : _pickedFiles.firstOrNull?.name,
          format: _isBatch
              ? _pickedFiles.map((f) => f.format).toSet().join(', ')
              : (_pickedFiles.firstOrNull?.format ?? 'm4a'),
          durationSeconds: _isBatch
              ? _pickedFiles.fold(0.0, (sum, f) => sum + f.durationSeconds)
              : (_pickedFiles.firstOrNull?.durationSeconds ?? 0.0),
          fileSizeBytes: _totalSizeBytes,
          fileCount: _pickedFiles.length,
          saveProgress: _saveProgress,
          genreName: rawG != null ? localizedGenreName(l10n, rawG) : null,
          subcategoryName: rawS != null
              ? localizedSubcategoryName(l10n, rawS)
              : null,
          registerName: rawR != null ? localizedRegisterName(l10n, rawR) : null,
          titleController: _titleController,
          isSaving: _isSaving,
          onSave: _save,
          onCancel: () => Navigator.of(context).maybePop(),
          hasWavFiles: _hasWavFiles,
          compressWav: _compressWav,
          onCompressWavChanged: (v) => setState(() => _compressWav = v),
        );
    }
  }
}
