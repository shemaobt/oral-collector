import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../genre/data/providers/genre_provider.dart';
import '../../genre/domain/entities/genre.dart';

/// Step indices for the recording flow.
enum _FlowStep { genre, subcategory, recording }

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
        // Placeholder for US-039 (recording step).
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.mic, size: 64, color: AppColors.primary),
                const SizedBox(height: 16),
                Text(
                  'Recording Step',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Recording functionality coming soon.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.foreground.withValues(alpha: 0.6),
                      ),
                ),
              ],
            ),
          ),
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
