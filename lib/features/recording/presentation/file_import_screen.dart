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

import '../../../core/database/app_database.dart';
import '../../../shared/utils/recording_title.dart';
import '../../../core/theme/app_colors.dart';
import '../../genre/presentation/notifiers/genre_notifier.dart';
import '../../sync/presentation/notifiers/sync_notifier.dart';
import '../../genre/presentation/notifiers/genre_state.dart';
import '../../genre/domain/entities/genre.dart';
import '../../project/presentation/notifiers/project_notifier.dart';
import '../data/providers.dart';
import 'widgets/file_info_banner.dart';
import 'widgets/import_confirmation.dart';
import 'widgets/import_genre_selection.dart';
import 'widgets/import_subcategory_selection.dart';

enum _ImportStep { pickFile, selectGenre, selectSubcategory, confirm }

class FileImportScreen extends ConsumerStatefulWidget {
  const FileImportScreen({super.key});

  @override
  ConsumerState<FileImportScreen> createState() => _FileImportScreenState();
}

class _FileImportScreenState extends ConsumerState<FileImportScreen> {
  _ImportStep _currentStep = _ImportStep.pickFile;

  String? _filePath;
  String? _fileName;
  int _fileSizeBytes = 0;
  double _durationSeconds = 0.0;
  String _format = 'm4a';
  bool _isAnalyzing = false;

  String? _selectedGenreId;
  String? _selectedSubcategoryId;

  final _titleController = TextEditingController();
  bool _isSaving = false;

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
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        if (mounted && _filePath == null) {
          Navigator.of(context).maybePop();
        }
        return;
      }

      final file = result.files.first;
      final filePath = file.path;

      if (filePath == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not access selected file')),
          );
          Navigator.of(context).maybePop();
        }
        return;
      }

      final ext = p.extension(filePath).replaceFirst('.', '').toLowerCase();

      setState(() {
        _filePath = filePath;
        _fileName = file.name;
        _fileSizeBytes = file.size;
        _format = ext.isNotEmpty ? ext : 'm4a';
        _isAnalyzing = true;
      });

      await _detectDuration(filePath);

      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _currentStep = _ImportStep.selectGenre;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
        Navigator.of(context).maybePop();
      }
    }
  }

  Future<void> _detectDuration(String filePath) async {
    final player = AudioPlayer();
    try {
      final duration = await player.setFilePath(filePath);
      if (duration != null) {
        _durationSeconds = duration.inMilliseconds / 1000.0;
      }
    } catch (_) {
    } finally {
      await player.dispose();
    }
  }

  void _selectGenre(Genre genre) {
    setState(() {
      _selectedGenreId = genre.id;
      _selectedSubcategoryId = null;
      if (genre.subcategories.isNotEmpty) {
        _currentStep = _ImportStep.selectSubcategory;
      } else {
        _currentStep = _ImportStep.confirm;
      }
    });
  }

  void _selectSubcategory(Subcategory subcategory) {
    setState(() {
      _selectedSubcategoryId = subcategory.id;
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
          _currentStep = _ImportStep.selectGenre;
        });
      case _ImportStep.confirm:
        final genreState = ref.read(genreNotifierProvider);
        final genre = genreState.genres
            .where((g) => g.id == _selectedGenreId)
            .firstOrNull;
        if (genre != null && genre.subcategories.isNotEmpty) {
          setState(() {
            _selectedSubcategoryId = null;
            _currentStep = _ImportStep.selectSubcategory;
          });
        } else {
          setState(() {
            _selectedGenreId = null;
            _currentStep = _ImportStep.selectGenre;
          });
        }
    }
  }

  Future<void> _save() async {
    if (_filePath == null) return;

    setState(() => _isSaving = true);

    final projectState = ref.read(projectNotifierProvider);
    final projectId = projectState.activeProject?.id ?? '';
    final repo = ref.read(localRecordingRepositoryProvider);

    try {
      String savedFilePath = _filePath!;

      if (!kIsWeb) {
        final appDir = await getApplicationDocumentsDirectory();
        final recordingsPath = '${appDir.path}/recordings';
        if (!await file_ops.dirExists(recordingsPath)) {
          await file_ops.createDir(recordingsPath);
        }
        final destFileName =
            '${DateTime.now().millisecondsSinceEpoch}_$_fileName';
        final destPath = '$recordingsPath/$destFileName';
        await file_ops.copyFile(_filePath!, destPath);
        savedFilePath = destPath;

        _fileSizeBytes = await file_ops.fileLength(savedFilePath);
      }

      final id =
          '${DateTime.now().millisecondsSinceEpoch}_${_selectedGenreId.hashCode}';

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
          title: Value(
            _titleController.text.trim().isNotEmpty
                ? _titleController.text.trim()
                : defaultRecordingTitle(),
          ),
          durationSeconds: Value(_durationSeconds),
          fileSizeBytes: Value(_fileSizeBytes),
          format: Value(_format),
          localFilePath: Value(savedFilePath),
          recordedAt: Value(DateTime.now()),
        ),
      );

      if (mounted) {
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving file: $e')));
      }
    }
  }

  String get _title {
    switch (_currentStep) {
      case _ImportStep.pickFile:
        return 'Import Audio';
      case _ImportStep.selectGenre:
        return 'Select Genre';
      case _ImportStep.selectSubcategory:
        return 'Select Subcategory';
      case _ImportStep.confirm:
        return 'Confirm Import';
    }
  }

  @override
  Widget build(BuildContext context) {
    final genreState = ref.watch(genreNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: _goBack),
        title: Text(_title),
      ),
      body: _currentStep == _ImportStep.pickFile
          ? _buildPickingState()
          : genreState.isLoading && genreState.genres.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _buildStep(genreState),
    );
  }

  Widget _buildPickingState() {
    final colors = AppColors.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isAnalyzing) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Analyzing audio file...',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colors.foreground.withValues(alpha: 0.6),
              ),
            ),
          ] else ...[
            Icon(LucideIcons.fileAudio, size: 64, color: colors.border),
            const SizedBox(height: 16),
            Text(
              'Select an audio file to import',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colors.foreground.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(LucideIcons.folderOpen),
              label: const Text('Choose File'),
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

  Widget _fileInfoBanner() => FileInfoBanner(
    fileName: _fileName,
    format: _format,
    durationSeconds: _durationSeconds,
    fileSizeBytes: _fileSizeBytes,
  );

  Widget _buildStep(GenreState genreState) {
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
          return const Center(child: Text('Genre not found'));
        }
        return ImportSubcategorySelection(
          genre: genre,
          selectedSubcategoryId: _selectedSubcategoryId,
          onSubcategorySelected: _selectSubcategory,
          onNext: _advanceToConfirm,
          fileInfoBanner: _fileInfoBanner(),
        );
      case _ImportStep.confirm:
        return ImportConfirmation(
          fileName: _fileName,
          format: _format,
          durationSeconds: _durationSeconds,
          fileSizeBytes: _fileSizeBytes,
          genreName: genreState.genres
              .where((g) => g.id == _selectedGenreId)
              .firstOrNull
              ?.name,
          subcategoryName: genreState.genres
              .where((g) => g.id == _selectedGenreId)
              .firstOrNull
              ?.subcategories
              .where((s) => s.id == _selectedSubcategoryId)
              .firstOrNull
              ?.name,
          titleController: _titleController,
          isSaving: _isSaving,
          onSave: _save,
          onCancel: () => Navigator.of(context).maybePop(),
        );
    }
  }
}
