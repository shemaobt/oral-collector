import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/l10n/content_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../../genre/presentation/notifiers/genre_notifier.dart';
import '../../domain/entities/classification.dart';
import '../../domain/entities/register.dart';

class SecondaryValues {
  final String? genreId;
  final String? subcategoryId;
  final String? registerId;

  const SecondaryValues({this.genreId, this.subcategoryId, this.registerId});

  bool get isEmpty =>
      (genreId == null || genreId!.isEmpty) &&
      (registerId == null || registerId!.isEmpty);

  bool get isValid {
    final hasGenre = genreId != null && genreId!.isNotEmpty;
    final hasRegister = registerId != null && registerId!.isNotEmpty;
    return hasGenre && hasRegister;
  }
}

class SecondaryClassificationFields extends ConsumerStatefulWidget {
  final String? primaryGenreId;
  final SecondaryValues? initial;
  final ValueChanged<SecondaryValues?> onChanged;

  const SecondaryClassificationFields({
    super.key,
    required this.primaryGenreId,
    required this.onChanged,
    this.initial,
  });

  @override
  ConsumerState<SecondaryClassificationFields> createState() =>
      _SecondaryClassificationFieldsState();
}

class _SecondaryClassificationFieldsState
    extends ConsumerState<SecondaryClassificationFields> {
  String? _genreId;
  String? _subcategoryId;
  String? _registerId;

  @override
  void initState() {
    super.initState();
    _genreId = widget.initial?.genreId;
    _subcategoryId = widget.initial?.subcategoryId;
    _registerId = widget.initial?.registerId;
  }

  @override
  void didUpdateWidget(SecondaryClassificationFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.primaryGenreId != oldWidget.primaryGenreId &&
        _genreId == widget.primaryGenreId) {
      _genreId = null;
      _subcategoryId = null;
    }
  }

  void _emit() {
    if (_genreId == null && _subcategoryId == null && _registerId == null) {
      widget.onChanged(null);
      return;
    }
    widget.onChanged(
      SecondaryValues(
        genreId: _genreId,
        subcategoryId: _subcategoryId,
        registerId: _registerId,
      ),
    );
  }

  void _clear() {
    setState(() {
      _genreId = null;
      _subcategoryId = null;
      _registerId = null;
    });
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    final genreState = ref.watch(genreNotifierProvider);
    final genres = genreState.genres
        .where(
          (g) => g.id != widget.primaryGenreId && g.id != kUnclassifiedGenreId,
        )
        .toList();

    final selectedGenre = genres.where((g) => g.id == _genreId).firstOrNull;
    final subcategories = selectedGenre?.subcategories ?? [];

    final sameAsPrimary = _genreId != null && _genreId == widget.primaryGenreId;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.classify_secondaryNote,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.foreground.withValues(alpha: 0.6),
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: SpacingScale.s12),
        Text(
          l10n.classify_secondaryGenre,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.foreground.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: SpacingScale.s4),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: genres.any((g) => g.id == _genreId) ? _genreId : null,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: SpacingScale.s12,
              vertical: SpacingScale.s8,
            ),
          ),
          hint: Text(l10n.recording_selectGenre),
          items: genres
              .map(
                (g) => DropdownMenuItem(
                  value: g.id,
                  child: Text(localizedGenreName(l10n, g.name)),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() {
              _genreId = value;
              _subcategoryId = null;
            });
            _emit();
          },
        ),
        if (sameAsPrimary) ...[
          const SizedBox(height: SpacingScale.s8),
          Text(
            l10n.classify_secondarySameAsPrimary,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: SpacingScale.s12),
        if (subcategories.isNotEmpty) ...[
          Text(
            l10n.classify_secondarySubcategory,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.foreground.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: SpacingScale.s4),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: subcategories.any((s) => s.id == _subcategoryId)
                ? _subcategoryId
                : null,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: SpacingScale.s12,
                vertical: SpacingScale.s8,
              ),
            ),
            hint: Text(l10n.moveCategory_selectSubcategory),
            items: subcategories
                .map(
                  (s) => DropdownMenuItem(
                    value: s.id,
                    child: Text(localizedSubcategoryName(l10n, s.name)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _subcategoryId = value;
              });
              _emit();
            },
          ),
          const SizedBox(height: SpacingScale.s12),
        ],
        Text(
          l10n.classify_secondaryRegister,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.foreground.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: SpacingScale.s4),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: _registerId,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: SpacingScale.s12,
              vertical: SpacingScale.s8,
            ),
          ),
          hint: Text(l10n.classify_selectRegister),
          items: kRegisters
              .map(
                (r) => DropdownMenuItem(
                  value: r.id,
                  child: Text(localizedRegisterName(l10n, r.name)),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() {
              _registerId = value;
            });
            _emit();
          },
        ),
        if (_genreId != null || _registerId != null) ...[
          const SizedBox(height: SpacingScale.s8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _clear,
              icon: const Icon(Icons.close, size: 16),
              label: Text(l10n.classify_clearAlternative),
              style: TextButton.styleFrom(
                foregroundColor: colors.foreground.withValues(alpha: 0.7),
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingScale.s8,
                  vertical: SpacingScale.s4,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
