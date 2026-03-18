import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../shared/widgets/screen_header.dart';
import '../../genre/presentation/notifiers/genre_notifier.dart';
import '../../sync/presentation/notifiers/sync_notifier.dart';
import '../../genre/presentation/notifiers/genre_state.dart';
import '../../genre/domain/entities/genre.dart';
import 'notifiers/recording_session_state.dart';
import 'widgets/confirmation_step.dart';
import 'widgets/genre_selection_step.dart';
import 'widgets/recording_step.dart';
import 'widgets/subcategory_selection_step.dart';

enum _FlowStep { genre, subcategory, recording, confirmation }

class RecordingFlowScreen extends ConsumerStatefulWidget {
  const RecordingFlowScreen({super.key, this.genreId, this.subcategoryId});

  final String? genreId;
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
      if (ref.read(syncNotifierProvider).isOnline) {
        ref.read(genreNotifierProvider.notifier).fetchGenres();
      }
    });

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

  String get _title {
    switch (_currentStep) {
      case _FlowStep.genre:
        return 'Select Genre';
      case _FlowStep.subcategory:
        return 'Select Subcategory';
      case _FlowStep.recording:
        return 'Recording';
      case _FlowStep.confirmation:
        return 'Review Recording';
    }
  }

  String get _subtitle {
    switch (_currentStep) {
      case _FlowStep.genre:
        return 'Choose a genre for your story';
      case _FlowStep.subcategory:
        return 'Pick a subcategory';
      case _FlowStep.recording:
        return 'Capture your story';
      case _FlowStep.confirmation:
        return 'Listen and save';
    }
  }

  IconData get _icon {
    switch (_currentStep) {
      case _FlowStep.genre:
        return LucideIcons.music;
      case _FlowStep.subcategory:
        return LucideIcons.layers;
      case _FlowStep.recording:
        return LucideIcons.mic;
      case _FlowStep.confirmation:
        return LucideIcons.checkCircle2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final genreState = ref.watch(genreNotifierProvider);

    return Scaffold(
      appBar: ScreenHeader(title: _title, subtitle: _subtitle, icon: _icon),
      body: genreState.isLoading && genreState.genres.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _buildStep(genreState),
    );
  }

  Widget _buildStep(GenreState genreState) {
    switch (_currentStep) {
      case _FlowStep.genre:
        return GenreSelectionStep(
          genres: genreState.genres,
          onSelect: _selectGenre,
        );
      case _FlowStep.subcategory:
        final genre = genreState.genres
            .where((g) => g.id == _selectedGenreId)
            .firstOrNull;
        if (genre == null) {
          return const Center(child: Text('Genre not found'));
        }
        return SubcategorySelectionStep(
          genre: genre,
          selectedSubcategoryId: _selectedSubcategoryId,
          onSelect: _selectSubcategory,
          onNext: _advanceToRecording,
        );
      case _FlowStep.recording:
        final genre = genreState.genres
            .where((g) => g.id == _selectedGenreId)
            .firstOrNull;
        final subcategory = genre?.subcategories
            .where((s) => s.id == _selectedSubcategoryId)
            .firstOrNull;
        return RecordingStep(
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
        return ConfirmationStep(
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
