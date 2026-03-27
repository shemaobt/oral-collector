import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../shared/widgets/screen_header.dart';
import '../domain/entities/classification.dart';
import 'notifiers/recording_session_state.dart';
import 'widgets/confirmation_step.dart';
import 'widgets/recording_step.dart';

enum _QuickStep { recording, confirmation }

class QuickRecordingScreen extends ConsumerStatefulWidget {
  const QuickRecordingScreen({super.key});

  @override
  ConsumerState<QuickRecordingScreen> createState() =>
      _QuickRecordingScreenState();
}

class _QuickRecordingScreenState extends ConsumerState<QuickRecordingScreen> {
  _QuickStep _currentStep = _QuickStep.recording;
  RecordingResult? _recordingResult;

  void _onRecordingComplete(RecordingResult result) {
    setState(() {
      _recordingResult = result;
      _currentStep = _QuickStep.confirmation;
    });
  }

  void _reRecord() {
    setState(() {
      _recordingResult = null;
      _currentStep = _QuickStep.recording;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: ScreenHeader(
        title: l10n.quickRecord_title,
        subtitle: l10n.quickRecord_subtitle,
        icon: LucideIcons.zap,
      ),
      body: _currentStep == _QuickStep.recording
          ? RecordingStep(
              genreId: kUnclassifiedGenreId,
              subcategoryId: '',
              genreName: null,
              subcategoryName: null,
              registerName: null,
              onRecordingComplete: _onRecordingComplete,
            )
          : ConfirmationStep(
              result: _recordingResult!,
              genreId: kUnclassifiedGenreId,
              subcategoryId: null,
              registerId: null,
              genreName: null,
              subcategoryName: null,
              registerName: null,
              onReRecord: _reRecord,
            ),
    );
  }
}
