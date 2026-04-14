import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/error_snack_bar.dart';
import '../../sync/presentation/notifiers/sync_notifier.dart';
import '../domain/entities/storyteller.dart';
import 'notifiers/project_storytellers_notifier.dart';

class StorytellerFormScreen extends ConsumerStatefulWidget {
  const StorytellerFormScreen({
    super.key,
    required this.projectId,
    this.storytellerId,
  });

  final String projectId;
  final String? storytellerId;

  bool get isEdit => storytellerId != null;

  @override
  ConsumerState<StorytellerFormScreen> createState() =>
      _StorytellerFormScreenState();
}

class _StorytellerFormScreenState extends ConsumerState<StorytellerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _dialectCtrl = TextEditingController();

  StorytellerSex? _sex;
  bool _acceptanceChecked = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) {
      Future.microtask(_loadExisting);
    }
  }

  void _loadExisting() {
    final list = ref.read(projectStorytellersNotifierProvider).storytellers;
    final found = list.where((s) => s.id == widget.storytellerId).firstOrNull;
    if (found != null) {
      _populateFrom(found);
    } else {
      ref
          .read(projectStorytellersNotifierProvider.notifier)
          .fetch(widget.projectId)
          .then((_) {
            if (!mounted) return;
            final updated = ref
                .read(projectStorytellersNotifierProvider)
                .storytellers
                .where((s) => s.id == widget.storytellerId)
                .firstOrNull;
            if (updated != null) _populateFrom(updated);
          });
    }
  }

  void _populateFrom(Storyteller s) {
    setState(() {
      _nameCtrl.text = s.name;
      _ageCtrl.text = s.age?.toString() ?? '';
      _locationCtrl.text = s.location ?? '';
      _dialectCtrl.text = s.dialect ?? '';
      _sex = s.sex;
      _acceptanceChecked = s.externalAcceptanceConfirmed;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _locationCtrl.dispose();
    _dialectCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    if (_isSaving) return false;
    if (_sex == null) return false;
    if (_nameCtrl.text.trim().isEmpty) return false;
    if (!widget.isEdit && !_acceptanceChecked) return false;
    return true;
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    if (!ref.read(syncNotifierProvider).isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.storyteller_createRequiresConnection)),
      );
      return;
    }

    setState(() => _isSaving = true);

    final notifier = ref.read(projectStorytellersNotifierProvider.notifier);
    final name = _nameCtrl.text.trim();
    final ageText = _ageCtrl.text.trim();
    final age = ageText.isEmpty ? null : int.tryParse(ageText);
    final loc = _locationCtrl.text.trim();
    final dia = _dialectCtrl.text.trim();

    try {
      if (widget.isEdit) {
        await notifier.update(
          widget.storytellerId!,
          name: name,
          sex: _sex,
          age: age,
          location: loc.isEmpty ? '' : loc,
          dialect: dia.isEmpty ? '' : dia,
        );
      } else {
        await notifier.create(
          projectId: widget.projectId,
          name: name,
          sex: _sex!,
          age: age,
          location: loc.isEmpty ? null : loc,
          dialect: dia.isEmpty ? null : dia,
          externalAcceptanceConfirmed: _acceptanceChecked,
        );
      }
      if (!mounted) return;
      final error = ref.read(projectStorytellersNotifierProvider).error;
      if (error != null) {
        showErrorSnackBar(context, error);
      } else {
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    final isOnline = ref.watch(syncNotifierProvider).isOnline;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/project/${widget.projectId}/storytellers');
            }
          },
        ),
        title: Text(
          widget.isEdit
              ? l10n.storyteller_editTitle
              : l10n.storyteller_createTitle,
        ),
      ),
      body: Form(
        key: _formKey,
        onChanged: () => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (!isOnline) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.wifiOff, size: 18, color: colors.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(l10n.storyteller_createRequiresConnection),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: l10n.storyteller_speakerName,
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.error_generic : null,
            ),
            const SizedBox(height: 20),
            Text(
              l10n.storyteller_sex,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            SegmentedButton<StorytellerSex>(
              segments: [
                ButtonSegment(
                  value: StorytellerSex.male,
                  label: Text(l10n.storyteller_sexMale),
                ),
                ButtonSegment(
                  value: StorytellerSex.female,
                  label: Text(l10n.storyteller_sexFemale),
                ),
              ],
              selected: _sex != null ? {_sex!} : <StorytellerSex>{},
              emptySelectionAllowed: true,
              onSelectionChanged: (s) {
                setState(() => _sex = s.isEmpty ? null : s.first);
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _ageCtrl,
              decoration: InputDecoration(labelText: l10n.storyteller_age),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final n = int.tryParse(v.trim());
                if (n == null || n < 1 || n > 120) {
                  return l10n.storyteller_ageValidator;
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _locationCtrl,
              decoration: InputDecoration(labelText: l10n.storyteller_location),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _dialectCtrl,
              decoration: InputDecoration(labelText: l10n.storyteller_dialect),
            ),
            const SizedBox(height: 24),
            if (!widget.isEdit) _buildAcceptanceBlock(context, l10n),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _canSubmit ? _submit : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.isEdit ? l10n.common_save : l10n.common_create),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcceptanceBlock(BuildContext context, AppLocalizations l10n) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.info.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.info.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.shieldCheck, size: 18, color: colors.info),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.storyteller_externalAcceptanceTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.storyteller_externalAcceptanceInfo,
                iconSize: 18,
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(l10n.storyteller_externalAcceptanceTitle),
                      content: Text(l10n.storyteller_externalAcceptanceInfo),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text(l10n.common_close),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(LucideIcons.info),
              ),
            ],
          ),
          const SizedBox(height: 4),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _acceptanceChecked,
            onChanged: (v) => setState(() => _acceptanceChecked = v ?? false),
            title: Text(l10n.storyteller_externalAcceptanceDescription),
          ),
        ],
      ),
    );
  }
}
