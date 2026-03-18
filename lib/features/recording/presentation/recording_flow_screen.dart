import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/l10n/content_l10n.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../genre/presentation/notifiers/genre_notifier.dart';
import '../../genre/presentation/notifiers/genre_state.dart';
import '../../genre/domain/entities/genre.dart';
import '../domain/entities/register.dart';
import 'notifiers/recording_session_state.dart';
import 'widgets/confirmation_step.dart';
import 'widgets/genre_selection_step.dart';
import 'widgets/recording_step.dart';
import 'widgets/register_selection_step.dart';
import 'widgets/subcategory_selection_step.dart';

enum _FlowStep { genre, subcategory, register, recording, confirmation }

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
  String? _selectedRegisterId;
  RecordingResult? _recordingResult;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(genreNotifierProvider.notifier).fetchGenres();
    });

    if (widget.genreId != null && widget.subcategoryId != null) {
      _selectedGenreId = widget.genreId;
      _selectedSubcategoryId = widget.subcategoryId;
      _currentStep = _FlowStep.register;
    } else if (widget.genreId != null) {
      _selectedGenreId = widget.genreId;
      _currentStep = _FlowStep.subcategory;
    }
  }

  void _selectGenre(Genre genre) {
    setState(() {
      _selectedGenreId = genre.id;
      _selectedSubcategoryId = null;
      _selectedRegisterId = null;

      if (genre.subcategories.isNotEmpty) {
        _currentStep = _FlowStep.subcategory;
      } else {
        _currentStep = _FlowStep.register;
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
      _currentStep = _FlowStep.register;
    });
  }

  void _selectRegister(Register register) {
    setState(() {
      _selectedRegisterId = register.id;
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

  String _title(AppLocalizations l10n) {
    switch (_currentStep) {
      case _FlowStep.genre:
        return l10n.recording_selectGenre;
      case _FlowStep.subcategory:
        return l10n.recording_selectSubcategory;
      case _FlowStep.register:
        return l10n.recording_selectRegister;
      case _FlowStep.recording:
        return l10n.recording_recordingStep;
      case _FlowStep.confirmation:
        return l10n.recording_reviewStep;
    }
  }

  String _subtitle(AppLocalizations l10n) {
    switch (_currentStep) {
      case _FlowStep.genre:
        return l10n.recording_selectGenreSubtitle;
      case _FlowStep.subcategory:
        return l10n.recording_selectSubcategorySubtitle;
      case _FlowStep.register:
        return l10n.recording_selectRegisterSubtitle;
      case _FlowStep.recording:
        return l10n.recording_recordingStepSubtitle;
      case _FlowStep.confirmation:
        return l10n.recording_reviewStepSubtitle;
    }
  }

  IconData get _icon {
    switch (_currentStep) {
      case _FlowStep.genre:
        return LucideIcons.music;
      case _FlowStep.subcategory:
        return LucideIcons.layers;
      case _FlowStep.register:
        return LucideIcons.volume2;
      case _FlowStep.recording:
        return LucideIcons.mic;
      case _FlowStep.confirmation:
        return LucideIcons.checkCircle2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final genreState = ref.watch(genreNotifierProvider);

    return Scaffold(
      appBar: ScreenHeader(
        title: _title(l10n),
        subtitle: _subtitle(l10n),
        icon: _icon,
      ),
      body: genreState.isLoading && genreState.genres.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _buildStep(genreState, l10n),
    );
  }

  Widget _buildStep(GenreState genreState, AppLocalizations l10n) {
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
          return Center(child: Text(l10n.recording_genreNotFound));
        }
        return SubcategorySelectionStep(
          genre: genre,
          selectedSubcategoryId: _selectedSubcategoryId,
          onSelect: _selectSubcategory,
          onNext: _advanceToRegister,
        );
      case _FlowStep.register:
        return RegisterSelectionStep(
          selectedRegisterId: _selectedRegisterId,
          onSelect: _selectRegister,
          onNext: _advanceToRecording,
        );
      case _FlowStep.recording:
        final genre = genreState.genres
            .where((g) => g.id == _selectedGenreId)
            .firstOrNull;
        final subcategory = genre?.subcategories
            .where((s) => s.id == _selectedSubcategoryId)
            .firstOrNull;
        final rawRegName = getRegisterName(_selectedRegisterId);
        return RecordingStep(
          genreId: _selectedGenreId!,
          subcategoryId: _selectedSubcategoryId ?? '',
          genreName: genre?.name != null
              ? localizedGenreName(l10n, genre!.name)
              : null,
          subcategoryName: subcategory?.name != null
              ? localizedSubcategoryName(l10n, subcategory!.name)
              : null,
          registerName: rawRegName != null
              ? localizedRegisterName(l10n, rawRegName)
              : null,
          onRecordingComplete: _onRecordingComplete,
        );
      case _FlowStep.confirmation:
        final genre = genreState.genres
            .where((g) => g.id == _selectedGenreId)
            .firstOrNull;
        final subcategory = genre?.subcategories
            .where((s) => s.id == _selectedSubcategoryId)
            .firstOrNull;
        final rawRegName2 = getRegisterName(_selectedRegisterId);
        return ConfirmationStep(
          result: _recordingResult!,
          genreId: _selectedGenreId!,
          subcategoryId: _selectedSubcategoryId,
          registerId: _selectedRegisterId,
          genreName: genre?.name != null
              ? localizedGenreName(l10n, genre!.name)
              : null,
          subcategoryName: subcategory?.name != null
              ? localizedSubcategoryName(l10n, subcategory!.name)
              : null,
          registerName: rawRegName2 != null
              ? localizedRegisterName(l10n, rawRegName2)
              : null,
          onReRecord: _reRecord,
        );
    }
  }
}
