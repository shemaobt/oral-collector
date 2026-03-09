import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/record_button.dart';
import '../../../shared/widgets/waveform_visualizer.dart';
import '../../genre/data/providers/genre_provider.dart';
import '../../genre/domain/entities/genre.dart';
import '../../project/data/providers/project_provider.dart';
import '../data/providers/local_recording_repository_provider.dart';
import '../data/providers/recording_provider.dart';

/// Step indices for the recording flow.
enum _FlowStep { genre, subcategory, recording, confirmation }

class RecordingFlowScreen extends ConsumerStatefulWidget {
  const RecordingFlowScreen({
    super.key,
    this.genreId,
    this.subcategoryId,
  });

  /// Pre-selected genre (e.g. from genre detail screen).
  final String? genreId;

  /// Pre-selected subcategory (e.g. from genre detail screen).
  final String? subcategoryId;

  @override
  ConsumerState<RecordingFlowScreen> createState() =>
      _RecordingFlowScreenState();
}

class _RecordingFlowScreenState extends ConsumerState<RecordingFlowScreen> {
  _FlowStep _currentStep = _FlowStep.genre;
  String? _selectedGenreId;
  String? _selectedSubcategoryId;
  RecordingResult? _recordingResult;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(genreNotifierProvider.notifier).fetchGenres();
    });

    // If pre-selected genre/subcategory provided, skip to recording step.
    if (widget.genreId != null && widget.subcategoryId != null) {
      _selectedGenreId = widget.genreId;
      _selectedSubcategoryId = widget.subcategoryId;
      _currentStep = _FlowStep.recording;
    } else if (widget.genreId != null) {
      _selectedGenreId = widget.genreId;
      _currentStep = _FlowStep.subcategory;
    }
  }

  void _selectGenre(Genre genre) {
    setState(() {
      _selectedGenreId = genre.id;
      _selectedSubcategoryId = null;
      // If genre has subcategories, go to subcategory step; otherwise go to recording.
      if (genre.subcategories.isNotEmpty) {
        _currentStep = _FlowStep.subcategory;
      } else {
        _currentStep = _FlowStep.recording;
      }
    });
  }

  void _selectSubcategory(Subcategory subcategory) {
    setState(() {
      _selectedSubcategoryId = subcategory.id;
    });
  }

  void _advanceToRecording() {
    setState(() {
      _currentStep = _FlowStep.recording;
    });
  }

  void _onRecordingComplete(RecordingResult result) {
    setState(() {
      _recordingResult = result;
      _currentStep = _FlowStep.confirmation;
    });
  }

  void _reRecord() {
    setState(() {
      _recordingResult = null;
      _currentStep = _FlowStep.recording;
    });
  }

  void _goBack() {
    switch (_currentStep) {
      case _FlowStep.genre:
        // Already at first step — pop navigation.
        if (context.mounted) Navigator.of(context).maybePop();
      case _FlowStep.subcategory:
        setState(() {
          _selectedGenreId = null;
          _selectedSubcategoryId = null;
          _currentStep = _FlowStep.genre;
        });
      case _FlowStep.recording:
        setState(() {
          _selectedSubcategoryId = null;
          _currentStep = _FlowStep.subcategory;
        });
      case _FlowStep.confirmation:
        // Back from confirmation goes to recording step (re-record).
        _reRecord();
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
      case _FlowStep.genre:
        return 'Select Genre';
      case _FlowStep.subcategory:
        return 'Select Subcategory';
      case _FlowStep.recording:
        return 'Record';
      case _FlowStep.confirmation:
        return 'Review Recording';
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
      body: genreState.isLoading && genreState.genres.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _buildStep(genreState),
    );
  }

  Widget _buildStep(GenreState genreState) {
    switch (_currentStep) {
      case _FlowStep.genre:
        return _GenreSelectionStep(
          genres: genreState.genres,
          onSelect: _selectGenre,
          mapIcon: _mapIcon,
          parseColor: _parseColor,
        );
      case _FlowStep.subcategory:
        final genre = genreState.genres
            .where((g) => g.id == _selectedGenreId)
            .firstOrNull;
        if (genre == null) {
          return const Center(child: Text('Genre not found'));
        }
        return _SubcategorySelectionStep(
          genre: genre,
          selectedSubcategoryId: _selectedSubcategoryId,
          onSelect: _selectSubcategory,
          onNext: _advanceToRecording,
          parseColor: _parseColor,
        );
      case _FlowStep.recording:
        final genre = genreState.genres
            .where((g) => g.id == _selectedGenreId)
            .firstOrNull;
        final subcategory = genre?.subcategories
            .where((s) => s.id == _selectedSubcategoryId)
            .firstOrNull;
        return _RecordingStep(
          genreId: _selectedGenreId!,
          subcategoryId: _selectedSubcategoryId ?? '',
          genreName: genre?.name,
          subcategoryName: subcategory?.name,
          onRecordingComplete: _onRecordingComplete,
        );
      case _FlowStep.confirmation:
        final genre = genreState.genres
            .where((g) => g.id == _selectedGenreId)
            .firstOrNull;
        final subcategory = genre?.subcategories
            .where((s) => s.id == _selectedSubcategoryId)
            .firstOrNull;
        return _ConfirmationStep(
          result: _recordingResult!,
          genreId: _selectedGenreId!,
          subcategoryId: _selectedSubcategoryId,
          genreName: genre?.name,
          subcategoryName: subcategory?.name,
          onReRecord: _reRecord,
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Step 1: Genre selection
// ---------------------------------------------------------------------------

class _GenreSelectionStep extends StatelessWidget {
  const _GenreSelectionStep({
    required this.genres,
    required this.onSelect,
    required this.mapIcon,
    required this.parseColor,
  });

  final List<Genre> genres;
  final ValueChanged<Genre> onSelect;
  final IconData Function(String?) mapIcon;
  final Color Function(String?) parseColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (genres.isEmpty) {
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
        final color = parseColor(genre.color);
        final icon = mapIcon(genre.icon);

        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onSelect(genre),
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
}

// ---------------------------------------------------------------------------
// Step 2: Subcategory selection
// ---------------------------------------------------------------------------

class _SubcategorySelectionStep extends StatelessWidget {
  const _SubcategorySelectionStep({
    required this.genre,
    required this.selectedSubcategoryId,
    required this.onSelect,
    required this.onNext,
    required this.parseColor,
  });

  final Genre genre;
  final String? selectedSubcategoryId;
  final ValueChanged<Subcategory> onSelect;
  final VoidCallback onNext;
  final Color Function(String?) parseColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = parseColor(genre.color);

    return Column(
      children: [
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
                        subcategory.id == selectedSubcategoryId;

                    return Card(
                      color: isSelected
                          ? color.withValues(alpha: 0.1)
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: isSelected
                            ? BorderSide(color: color, width: 2)
                            : BorderSide.none,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => onSelect(subcategory),
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
              onPressed: selectedSubcategoryId != null ? onNext : null,
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
}

// ---------------------------------------------------------------------------
// Step 3: Recording
// ---------------------------------------------------------------------------

class _RecordingStep extends ConsumerWidget {
  const _RecordingStep({
    required this.genreId,
    required this.subcategoryId,
    required this.genreName,
    required this.subcategoryName,
    required this.onRecordingComplete,
  });

  final String genreId;
  final String subcategoryId;
  final String? genreName;
  final String? subcategoryName;
  final ValueChanged<RecordingResult> onRecordingComplete;

  String _formatElapsed(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recState = ref.watch(recordingNotifierProvider);
    final notifier = ref.read(recordingNotifierProvider.notifier);

    // Derive the button state.
    RecordButtonState buttonState;
    if (recState.isRecording && !recState.isPaused) {
      buttonState = RecordButtonState.recording;
    } else if (recState.isPaused) {
      buttonState = RecordButtonState.paused;
    } else {
      buttonState = RecordButtonState.ready;
    }

    // Build the genre/subcategory tag label.
    final tagParts = <String>[];
    if (genreName != null) tagParts.add(genreName!);
    if (subcategoryName != null) tagParts.add(subcategoryName!);
    final tagLabel = tagParts.join(' / ');

    return Container(
      color: AppColors.foreground,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Genre/subcategory tag at top
            if (tagLabel.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tagLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                  ),
                ),
              ),

            // Expanded center area
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Waveform visualizer (shown when recording or paused)
                    if (recState.isRecording || recState.isPaused)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: recState.isPaused
                            ? WaveformVisualizer(
                                amplitudes:
                                    List.filled(30, 0.0), // frozen waveform
                                barColor: AppColors.primary,
                                height: 80,
                              )
                            : WaveformVisualizer(
                                amplitudeStream: recState.amplitudeStream,
                                barColor: AppColors.primary,
                                height: 80,
                              ),
                      ),

                    // Elapsed time (shown when recording or paused)
                    if (recState.isRecording || recState.isPaused)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 32),
                        child: Text(
                          _formatElapsed(recState.elapsed),
                          style:
                              Theme.of(context).textTheme.displaySmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w300,
                                    fontFeatures: [
                                      const FontFeature.tabularFigures(),
                                    ],
                                  ),
                        ),
                      ),

                    // Record button
                    RecordButton(
                      state: buttonState,
                      onTap: () => _handleRecordTap(notifier, recState),
                    ),

                    const SizedBox(height: 16),

                    // Label / controls below button
                    if (!recState.isRecording && !recState.isPaused)
                      Text(
                        'Tap to Record',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                      ),

                    // Pause + Stop row (shown when recording)
                    if (recState.isRecording && !recState.isPaused)
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _ControlButton(
                              icon: LucideIcons.pause,
                              label: 'Pause',
                              onTap: () => notifier.pauseRecording(),
                            ),
                            const SizedBox(width: 48),
                            _ControlButton(
                              icon: LucideIcons.square,
                              label: 'Stop',
                              onTap: () => _handleStop(notifier),
                            ),
                          ],
                        ),
                      ),

                    // Resume + Stop row (shown when paused)
                    if (recState.isPaused)
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _ControlButton(
                              icon: LucideIcons.play,
                              label: 'Resume',
                              onTap: () => notifier.resumeRecording(),
                            ),
                            const SizedBox(width: 48),
                            _ControlButton(
                              icon: LucideIcons.square,
                              label: 'Stop',
                              onTap: () => _handleStop(notifier),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleStop(RecordingNotifier notifier) async {
    final result = await notifier.stopRecording();
    if (result != null) {
      onRecordingComplete(result);
    }
  }

  void _handleRecordTap(
    RecordingNotifier notifier,
    RecordingState recState,
  ) {
    if (!recState.isRecording && !recState.isPaused) {
      notifier.startRecording(genreId, subcategoryId);
    } else if (recState.isRecording && !recState.isPaused) {
      notifier.pauseRecording();
    } else if (recState.isPaused) {
      notifier.resumeRecording();
    }
  }
}

// ---------------------------------------------------------------------------
// Step 4: Confirmation (after recording stops)
// ---------------------------------------------------------------------------

class _ConfirmationStep extends ConsumerStatefulWidget {
  const _ConfirmationStep({
    required this.result,
    required this.genreId,
    required this.subcategoryId,
    required this.genreName,
    required this.subcategoryName,
    required this.onReRecord,
  });

  final RecordingResult result;
  final String genreId;
  final String? subcategoryId;
  final String? genreName;
  final String? subcategoryName;
  final VoidCallback onReRecord;

  @override
  ConsumerState<_ConfirmationStep> createState() => _ConfirmationStepState();
}

class _ConfirmationStepState extends ConsumerState<_ConfirmationStep> {
  final _titleController = TextEditingController();
  AudioPlayer? _player;
  bool _isPlaying = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _player!.playerStateStream.listen((playerState) {
      if (!mounted) return;
      final playing = playerState.playing;
      final completed =
          playerState.processingState == ProcessingState.completed;
      setState(() {
        _isPlaying = playing && !completed;
      });
      if (completed) {
        _player!.seek(Duration.zero);
        _player!.pause();
      }
    });
    _player!.setFilePath(widget.result.filePath);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _player?.dispose();
    super.dispose();
  }

  String _formatDuration(double seconds) {
    final dur = Duration(milliseconds: (seconds * 1000).round());
    final m = dur.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = dur.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _togglePlayback() async {
    if (_player == null) return;
    if (_isPlaying) {
      await _player!.pause();
    } else {
      await _player!.play();
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    final projectState = ref.read(projectNotifierProvider);
    final projectId = projectState.activeProject?.id ?? '';
    final repo = ref.read(localRecordingRepositoryProvider);

    // Compute file size.
    int fileSize = 0;
    try {
      final file = File(widget.result.filePath);
      fileSize = await file.length();
    } catch (_) {}

    final id =
        '${DateTime.now().millisecondsSinceEpoch}_${widget.genreId.hashCode}';

    await repo.insertRecording(LocalRecordingsCompanion(
      id: Value(id),
      projectId: Value(projectId),
      genreId: Value(widget.genreId),
      subcategoryId: widget.subcategoryId != null && widget.subcategoryId!.isNotEmpty
          ? Value(widget.subcategoryId!)
          : const Value.absent(),
      title: _titleController.text.trim().isNotEmpty
          ? Value(_titleController.text.trim())
          : const Value.absent(),
      durationSeconds: Value(widget.result.durationSeconds),
      fileSizeBytes: Value(fileSize),
      localFilePath: Value(widget.result.filePath),
      recordedAt: Value(DateTime.now()),
    ));

    if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _discard() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Recording?'),
        content:
            const Text('This recording will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Delete the recorded file.
      try {
        final file = File(widget.result.filePath);
        if (await file.exists()) await file.delete();
      } catch (_) {}

      if (mounted) Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Build genre/subcategory tag.
    final tagParts = <String>[];
    if (widget.genreName != null) tagParts.add(widget.genreName!);
    if (widget.subcategoryName != null) tagParts.add(widget.subcategoryName!);
    final tagLabel = tagParts.join(' / ');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
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

          // Static waveform display
          WaveformVisualizer(
            amplitudes: List.generate(
                30, (i) => (i % 3 == 0 ? 0.7 : 0.3) * ((i % 5 + 1) / 5)),
            barColor: AppColors.primary,
            height: 80,
          ),

          const SizedBox(height: 12),

          // Duration label
          Text(
            _formatDuration(widget.result.durationSeconds),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w300,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),

          const SizedBox(height: 16),

          // Play/pause button
          IconButton.filled(
            onPressed: _togglePlayback,
            icon: Icon(
              _isPlaying ? LucideIcons.pause : LucideIcons.play,
              size: 28,
            ),
            iconSize: 28,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(56, 56),
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

          // Action buttons
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _isSaving
                  ? null
                  : () {
                      _player?.stop();
                      widget.onReRecord();
                    },
              child: const Text('Re-record'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: _isSaving ? null : _discard,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
              child: const Text('Discard'),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small control button used in the recording step
// ---------------------------------------------------------------------------

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.15),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
          ),
        ],
      ),
    );
  }
}
