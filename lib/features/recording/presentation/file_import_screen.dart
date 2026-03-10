import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../genre/data/providers/genre_provider.dart';
import '../../genre/domain/entities/genre.dart';
import '../../project/data/providers/project_provider.dart';
import '../data/providers/local_recording_repository_provider.dart';

/// Flow steps for file import.
enum _ImportStep { pickFile, selectGenre, selectSubcategory, confirm }

class FileImportScreen extends ConsumerStatefulWidget {
  const FileImportScreen({super.key});

  @override
  ConsumerState<FileImportScreen> createState() => _FileImportScreenState();
}

class _FileImportScreenState extends ConsumerState<FileImportScreen> {
  _ImportStep _currentStep = _ImportStep.pickFile;

  // File state
  String? _filePath;
  String? _fileName;
  int _fileSizeBytes = 0;
  double _durationSeconds = 0.0;
  String _format = 'm4a';
  bool _isAnalyzing = false;

  // Genre selection state
  String? _selectedGenreId;
  String? _selectedSubcategoryId;

  // Save state
  final _titleController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(genreNotifierProvider.notifier).fetchGenres();
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
          // User cancelled without having a file — go back.
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

      // Auto-detect duration using just_audio.
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
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
      // Duration detection failed — leave at 0.
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
        // Go back to file picker.
        _pickFile();
      case _ImportStep.selectSubcategory:
        setState(() {
          _selectedGenreId = null;
          _selectedSubcategoryId = null;
          _currentStep = _ImportStep.selectGenre;
        });
      case _ImportStep.confirm:
        final genreState = ref.read(genreNotifierProvider);
        final genre =
            genreState.genres.where((g) => g.id == _selectedGenreId).firstOrNull;
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

      // Copy file to app storage (non-web only).
      if (!kIsWeb) {
        final appDir = await getApplicationDocumentsDirectory();
        final recordingsDir = Directory('${appDir.path}/recordings');
        if (!await recordingsDir.exists()) {
          await recordingsDir.create(recursive: true);
        }
        final destFileName =
            '${DateTime.now().millisecondsSinceEpoch}_$_fileName';
        final destPath = '${recordingsDir.path}/$destFileName';
        await File(_filePath!).copy(destPath);
        savedFilePath = destPath;

        // Re-read file size from copied file.
        final savedFile = File(savedFilePath);
        _fileSizeBytes = await savedFile.length();
      }

      final id =
          '${DateTime.now().millisecondsSinceEpoch}_${_selectedGenreId.hashCode}';

      await repo.insertRecording(LocalRecordingsCompanion(
        id: Value(id),
        projectId: Value(projectId),
        genreId: Value(_selectedGenreId!),
        subcategoryId:
            _selectedSubcategoryId != null && _selectedSubcategoryId!.isNotEmpty
                ? Value(_selectedSubcategoryId!)
                : const Value.absent(),
        title: _titleController.text.trim().isNotEmpty
            ? Value(_titleController.text.trim())
            : const Value.absent(),
        durationSeconds: Value(_durationSeconds),
        fileSizeBytes: Value(_fileSizeBytes),
        format: Value(_format),
        localFilePath: Value(savedFilePath),
        recordedAt: Value(DateTime.now()),
      ));

      if (mounted) {
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving file: $e')),
        );
      }
    }
  }

  /// Map genre icon name strings to LucideIcons.
  IconData _mapIcon(String? iconName) {
    switch (iconName) {
      case 'book-open':
        return LucideIcons.bookOpen;
      case 'message-circle':
        return LucideIcons.messageCircle;
      case 'music':
        return LucideIcons.music;
      case 'users':
        return LucideIcons.users;
      case 'list-ordered':
        return LucideIcons.listOrdered;
      case 'heart':
        return LucideIcons.heart;
      case 'file-text':
        return LucideIcons.fileText;
      case 'megaphone':
        return LucideIcons.megaphone;
      case 'mic':
        return LucideIcons.mic;
      default:
        return LucideIcons.layoutGrid;
    }
  }

  /// Parse a hex color string like "#BE4A01" into a Color.
  Color _parseColor(String? hex) {
    if (hex == null || hex.length < 7) return AppColors.primary;
    try {
      final hexValue = hex.replaceFirst('#', '');
      return Color(int.parse('FF$hexValue', radix: 16));
    } catch (_) {
      return AppColors.primary;
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

  String _formatDuration(double totalSeconds) {
    final seconds = totalSeconds.round();
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
                    color: AppColors.foreground.withValues(alpha: 0.6),
                  ),
            ),
          ] else ...[
            Icon(LucideIcons.fileAudio, size: 64, color: AppColors.border),
            const SizedBox(height: 16),
            Text(
              'Select an audio file to import',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.foreground.withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(LucideIcons.folderOpen),
              label: const Text('Choose File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(160, 48),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep(GenreState genreState) {
    switch (_currentStep) {
      case _ImportStep.pickFile:
        return _buildPickingState();
      case _ImportStep.selectGenre:
        return _buildGenreSelection(genreState);
      case _ImportStep.selectSubcategory:
        final genre = genreState.genres
            .where((g) => g.id == _selectedGenreId)
            .firstOrNull;
        if (genre == null) {
          return const Center(child: Text('Genre not found'));
        }
        return _buildSubcategorySelection(genre);
      case _ImportStep.confirm:
        return _buildConfirmation(genreState);
    }
  }

  Widget _buildGenreSelection(GenreState genreState) {
    final theme = Theme.of(context);

    if (genreState.genres.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.layoutGrid, size: 64, color: AppColors.border),
              const SizedBox(height: 16),
              Text(
                'No genres available',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.foreground.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // File info banner at top.
    return Column(
      children: [
        _buildFileInfoBanner(theme),
        Expanded(
          child: _buildGenreGrid(theme, genreState.genres),
        ),
      ],
    );
  }

  Widget _buildFileInfoBanner(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.fileAudio, size: 20, color: AppColors.info),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fileName ?? 'Unknown file',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${_format.toUpperCase()} \u2022 ${_formatDuration(_durationSeconds)} \u2022 ${_formatFileSize(_fileSizeBytes)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.foreground.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreGrid(ThemeData theme, List<Genre> genres) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth >= 900
        ? 4
        : screenWidth >= 600
            ? 3
            : 2;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: genres.length,
      itemBuilder: (context, index) {
        final genre = genres[index];
        final color = _parseColor(genre.color);
        final icon = _mapIcon(genre.icon);

        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _selectGenre(genre),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 28, color: color),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    genre.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubcategorySelection(Genre genre) {
    final theme = Theme.of(context);
    final color = _parseColor(genre.color);

    return Column(
      children: [
        _buildFileInfoBanner(theme),

        // Genre header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.category, size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  genre.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Subcategory list
        Expanded(
          child: genre.subcategories.isEmpty
              ? Center(
                  child: Text(
                    'No subcategories available',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.foreground.withValues(alpha: 0.6),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: genre.subcategories.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final subcategory = genre.subcategories[index];
                    final isSelected =
                        subcategory.id == _selectedSubcategoryId;

                    return Card(
                      color:
                          isSelected ? color.withValues(alpha: 0.1) : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: isSelected
                            ? BorderSide(color: color, width: 2)
                            : BorderSide.none,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _selectSubcategory(subcategory),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      subcategory.name,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (subcategory.description != null &&
                                        subcategory
                                            .description!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        subcategory.description!,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: AppColors.foreground
                                              .withValues(alpha: 0.6),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(LucideIcons.checkCircle,
                                    color: color, size: 24),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Next button
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed:
                  _selectedSubcategoryId != null ? _advanceToConfirm : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AppColors.border.withValues(alpha: 0.3),
                disabledForegroundColor:
                    AppColors.foreground.withValues(alpha: 0.4),
              ),
              child: const Text('Next'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmation(GenreState genreState) {
    final theme = Theme.of(context);
    final genre = genreState.genres
        .where((g) => g.id == _selectedGenreId)
        .firstOrNull;
    final subcategory = genre?.subcategories
        .where((s) => s.id == _selectedSubcategoryId)
        .firstOrNull;

    final tagParts = <String>[];
    if (genre != null) tagParts.add(genre.name);
    if (subcategory != null) tagParts.add(subcategory.name);
    final tagLabel = tagParts.join(' / ');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // File info card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Icon(LucideIcons.fileAudio, size: 48, color: AppColors.info),
                const SizedBox(height: 12),
                Text(
                  _fileName ?? 'Unknown file',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '${_format.toUpperCase()} \u2022 ${_formatDuration(_durationSeconds)} \u2022 ${_formatFileSize(_fileSizeBytes)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.foreground.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Genre/subcategory badge
          if (tagLabel.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tagLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Optional title text field
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Add a title (optional)',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),

          const Spacer(),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(LucideIcons.download),
              label: const Text('Import & Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _isSaving ? null : () => Navigator.of(context).maybePop(),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }
}
